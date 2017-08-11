-- Car profile

-- Define sql_conn and redis_conn
require "profile-config"

api_version = 1

local find_access_tag = require("lib/access").find_access_tag
local Set = require('lib/set')
local Sequence = require('lib/sequence')
local Handlers = require("lib/handlers")
local next = next       -- bind to local for speed

-- set profile properties
properties.max_speed_for_map_matching           = 180/3.6 -- 180kmph -> m/s
properties.use_turn_restrictions                = true
properties.continue_straight_at_waypoint        = true
properties.left_hand_driving                    = false
-- For routing based on duration, but weighted for preferring certain roads
properties.weight_name                          = 'routability'
-- For shortest duration without penalties for accessibility
--properties.weight_name                        = 'duration'
-- For shortest distance without penalties for accessibility
--properties.weight_name                        = 'distance'

-- Set to true if you need to call the node_function for every node.
-- Generally can be left as false to avoid unnecessary Lua calls
-- (which slow down pre-processing).
properties.call_tagless_node_function      = false


local profile = {
  default_mode      = mode.driving,
  default_speed     = function (way) return speed_profile(speed_coef(way), 'default') end,
  oneway_handling   = true,

  side_road_multiplier       = 0.8,
  turn_penalty               = 7.5,
  speed_reduction            = 0.8, -- Not Used
  traffic_light_penalty      = 2,
  u_turn_penalty             = 20,

  -- Note: this biases right-side driving.
  -- Should be inverted for left-driving countries.
  turn_bias   = properties.left_hand_driving and 1/1.075 or 1.075,

  -- a list of suffixes to suppress in name change instructions
  suffix_list = {
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'North', 'South', 'West', 'East'
  },

  barrier_whitelist = Set {
    'cattle_grid',
    'border_control',
    'checkpoint',
    'toll_booth',
    'sally_port',
    'gate',
    'lift_gate',
    'no',
    'entrance'
  },

  access_tag_whitelist = Set {
    'yes',
    'motorcar',
    'motor_vehicle',
    'vehicle',
    'permissive',
    'designated',
    'hov'
  },

  access_tag_blacklist = Set {
    'no',
    'agricultural',
    'forestry',
    'emergency',
    'psv',
    'customers',
    'private',
    'delivery',
    'destination'
  },

  restricted_access_tag_list = Set {
    'private',
    'delivery',
    'destination',
    'customers',
  },

  access_tags_hierarchy = Sequence {
    'motorcar',
    'motor_vehicle',
    'vehicle',
    'access'
  },

  construction_whitelist = Set {
    'no',
    'widening',
    'minor',
  },


  service_tag_forbidden = Set {
    'emergency_access'
  },

  restrictions = Sequence {
    'motorcar',
    'motor_vehicle',
    'vehicle'
  },

  avoid = Set {
    'area',
    -- 'toll',    -- uncomment this to avoid tolls
    'reversible',
    'impassable',
    'hov_lanes',
    'steps',
    'construction',
    'proposed'
  },

  speeds = function (way) return speed_profile(speed_coef(way), way:get_value_by_key('highway')) end,

  maxspeeds = function (way, max_speed) return max_speed_coef(speed_coef(way), max_speed) end,

  service_penalties = {
    alley             = 0.5,
    parking           = 0.5,
    parking_aisle     = 0.5,
    driveway          = 0.5,
    ["drive-through"] = 0.5,
    ["drive-thru"] = 0.5
  },

 restricted_highway_whitelist = Set {
      'motorway',
      'motorway_link',
      'trunk',
      'trunk_link',
      'primary',
      'primary_link',
      'secondary',
      'secondary_link',
      'tertiary',
      'tertiary_link',
      'residential',
      'living_street',
  },

  route_speeds = {
    ferry = 5,
    shuttle_train = 10
  },

  bridge_speeds = {
    movable = 5
  },

  -- surface/trackype/smoothness
  -- values were estimated from looking at the photos at the relevant wiki pages

  -- max speed for surfaces
  surface_speeds = {
    asphalt = nil,    -- nil mean no limit. removing the line has the same effect
    concrete = nil,
    ["concrete:plates"] = nil,
    ["concrete:lanes"] = nil,
    paved = nil,

    cement = 80,
    compacted = 80,
    fine_gravel = 80,

    paving_stones = 60,
    metal = 60,
    bricks = 60,

    grass = 40,
    wood = 40,
    sett = 40,
    grass_paver = 40,
    gravel = 40,
    unpaved = 40,
    ground = 40,
    dirt = 40,
    pebblestone = 40,
    tartan = 40,

    cobblestone = 30,
    clay = 30,

    earth = 20,
    stone = 20,
    rocky = 20,
    sand = 20,

    mud = 10
  },

  -- max speed for tracktypes
  tracktype_speeds = {
    grade1 =  60,
    grade2 =  40,
    grade3 =  30,
    grade4 =  25,
    grade5 =  20
  },

  -- max speed for smoothnesses
  smoothness_speeds = {
    intermediate    =  80,
    bad             =  40,
    very_bad        =  20,
    horrible        =  10,
    very_horrible   =  5,
    impassable      =  0
  },

  -- http://wiki.openstreetmap.org/wiki/Speed_limits
  maxspeed_table_default = {
    urban = 50,
    rural = 90,
    trunk = 110,
    motorway = 130
  },

  -- List only exceptions
  maxspeed_table = {
    ["ch:rural"] = 80,
    ["ch:trunk"] = 100,
    ["ch:motorway"] = 120,
    ["de:living_street"] = 7,
    ["ru:living_street"] = 20,
    ["ru:urban"] = 60,
    ["ua:urban"] = 60,
    ["at:rural"] = 100,
    ["de:rural"] = 100,
    ["at:trunk"] = 100,
    ["cz:trunk"] = 0,
    ["ro:trunk"] = 100,
    ["cz:motorway"] = 0,
    ["de:motorway"] = 0,
    ["ru:motorway"] = 110,
    ["gb:nsl_single"] = (60*1609)/1000,
    ["gb:nsl_dual"] = (70*1609)/1000,
    ["gb:motorway"] = (70*1609)/1000,
    ["uk:nsl_single"] = (60*1609)/1000,
    ["uk:nsl_dual"] = (70*1609)/1000,
    ["uk:motorway"] = (70*1609)/1000,
    ["nl:rural"] = 80,
    ["nl:trunk"] = 100,
    ["none"] = 140
  }
}

function get_name_suffix_list(vector)
  for index,suffix in ipairs(profile.suffix_list) do
      vector:Add(suffix)
  end
end

speeds_interurban = {
  motorway        = 115,
  motorway_link   =  45,
  trunk           = 100,
  trunk_link      =  40,
  primary         =  85,
  primary_link    =  30,
  secondary       =  77,
  secondary_link  =  25,
  tertiary        =  68,
  tertiary_link   =  20,
  unclassified    =  58,
  residential     =  30,
  living_street   =  20,
  service         =  20,
  pedestrian      =   5,
  track           =   5,
  default         =  20
}

speeds_urban = {
  motorway        = 90,
  motorway_link   = 45,
  trunk           = 75,
  trunk_link      = 37,
  primary         = 33,
  primary_link    = 15,
  secondary       = 28,
  secondary_link  = 14,
  tertiary        = 24,
  tertiary_link   = 12,
  unclassified    = 22,
  residential     = 21,
  living_street   = 13,
  service         = 13,
  pedestrian      =  5,
  track           =  5,
  default         = 13
}

speeds_urban_dense = {
  motorway        = 70,
  motorway_link   = 35,
  trunk           = 58,
  trunk_link      = 27,
  primary         = 15,
  primary_link    =  9,
  secondary       = 12,
  secondary_link  =  7,
  tertiary        = 10,
  tertiary_link   =  5,
  unclassified    =  9,
  residential     =  9,
  living_street   =  8,
  service         =  8,
  pedestrian      =  5,
  track           =  5,
  default         =  8
}

urban_query_ = [[
SELECT
  code AS code,
  SUM(l) / ST_Length((SELECT linestring FROM ways where id = %s)) AS l
FROM (
  SELECT
    code,
    ST_Length(ST_Intersection(geom, (SELECT linestring FROM ways where id = '%s'))) AS l
  FROM
    urban
  WHERE
    geom && (SELECT linestring FROM ways where id = %s) AND
    ST_Intersects(geom, (SELECT linestring FROM ways where id = %s))
) AS t
GROUP BY
  code
;
]]

urban_query = [[
SELECT
  code AS code,
  SUM(l) AS l
FROM (
  SELECT
    code,
    ST_Length(ST_Intersection(geom, linestring)) / ST_Length(linestring) AS l
  FROM
    (SELECT ST_GeomFromText('LINESTRING(%s)', 4326) AS linestring) AS linestrings,
    urban
  WHERE
    ST_Length(linestring) > 0 AND
    ST_Intersects(geom, linestring)
) AS t
GROUP BY
  code
;
]]

function speed_profile(coefs, highway)
  if speeds_interurban[highway] and speeds_urban_dense[highway] and speeds_urban[highway] then
    return
      coefs[1] * speeds_interurban[highway] +
      coefs[2] * speeds_urban[highway] +
      coefs[3] * speeds_urban[highway] +
      coefs[4] * speeds_urban_dense[highway]
  end
end

function speed_coef_sql(way)
  local linestring = {}
  local nodes = way:get_nodes()

  local n = 0
  for _, node in pairs(nodes) do
    if node:location():valid() then
      table.insert(linestring, node:location():lon() .. " " .. node:location():lat())
      n = n + 1
    else
      assert(not("No valid location on NodeRef"))
    end
  end
  if n <= 1 then
    return {0, 0, 0, 0}
  end
  linestring = table.concat(linestring, ",")

  local sql = urban_query:format(linestring)
  local cur = assert(sql_conn:execute(sql))

  local codes = {
    ["1"] = 4, -- Continuous urban
    ["2"] = 3, -- Discontinuous urban & Industrial or commercial
    ["5"] = 2 -- Water bodies
  }
  local speeds = {1, 0, 0, 0}

  row = cur:fetch ({}, "a")
  while row do
    speeds[1] = speeds[1] - row.l
    local c = codes[row.code]
    speeds[c] = row.l

    row = cur:fetch (row, "a")
  end

  return speeds
end

function speed_coef(way)
  assert(way:version() ~= 0)

  local speeds_v = redis_conn:lrange(way:id(), 0, -1)
  if tonumber(speeds_v[5]) == way:version() then
    return {tonumber(speeds_v[1]), tonumber(speeds_v[2]), tonumber(speeds_v[3]), tonumber(speeds_v[4])}
  end

  speeds = speed_coef_sql(way)

  redis_conn:del(way:id())
  local speeds_v = {speeds[1], speeds[2], speeds[3], speeds[4], way:version()}
  redis_conn:rpush(way:id(), unpack(speeds_v))

  return speeds
end

max_speeds = {
  [130] = {115, 90, 90, 70},
  [110] = {100, 75, 75, 58},
  [90] = {85, 60, 60, 43},
  [50] = {47, 33, 33, 15},
  [30] = {29, 19, 19, 9},
  [20] = {20, 13, 13, 8},
  [0] = {0, 0, 0, 0}
}

max_speeds_bounds = {{nil, 130}, {130, 110}, {110, 90}, {90, 50}, {50, 30}, {30, 20}, {20, 0}}

function max_speed_coef(coefs, max_speed)
  local speeds = max_speeds[max_speed]

  if not speeds then
    local bound
    local i = 1
    while max_speeds_bounds[i][1] ~= nil do
      if max_speeds_bounds[i][1] > max_speed and max_speed >= max_speeds_bounds[i][2] then
        bound = max_speeds_bounds[i]
        break
      end
      i = i + 1
    end

    if not bound then
      return max_speed * 0.8
    end

    if bound[1] == nil then
      bound[1] = bound[2]
    end

    speeds = {
      (max_speed - max_speeds[bound[2]][1]) / (max_speeds[bound[1]][1] - max_speeds[bound[2]][1]) + max_speeds[bound[2]][1],
      (max_speed - max_speeds[bound[2]][2]) / (max_speeds[bound[1]][2] - max_speeds[bound[2]][2]) + max_speeds[bound[2]][2],
      (max_speed - max_speeds[bound[2]][3]) / (max_speeds[bound[1]][3] - max_speeds[bound[2]][3]) + max_speeds[bound[2]][3],
      (max_speed - max_speeds[bound[2]][4]) / (max_speeds[bound[1]][4] - max_speeds[bound[2]][4]) + max_speeds[bound[2]][4]
    }
  end

  return
    coefs[1] * speeds[1] +
    coefs[2] * speeds[2] +
    coefs[3] * speeds[3] +
    coefs[4] * speeds[4]
end

-- Load white list of ferries
local ferries_withlist_ids = {}
local file = assert(io.open(debug.getinfo(1).source:sub(2):match("(.*/)") .. "ferries-withlist.csv"))
if file then
  for line in file:lines() do
    if tonumber(line) then
      ferries_withlist_ids[tonumber(line)] = true
    end
  end
end

function Handlers.ferries_withlist(way,result,data,profile)
  if ferries_withlist_ids[way:id()] ~= nil then
    return false
  end
end

-- determine if this way can be used as a start/end point for routing
function Handlers.startpoint_secure(way,result,data,profile)
  local highway = way:get_value_by_key("highway")
  local tunnel = way:get_value_by_key("tunnel")

  if highway ~= "motorway" and (not tunnel or tunnel == "") then
    Handlers.handle_startpoint(way,result,data,profile)
  else
    result.is_startpoint = false
  end
end

function get_restrictions(vector)
  for i,v in ipairs(profile.restrictions) do
    vector:Add(v)
  end
end

function node_function (node, result)
  -- parse access and barrier tags
  local access = find_access_tag(node, profile.access_tags_hierarchy)
  if access then
    if profile.access_tag_blacklist[access] and not profile.restricted_access_tag_list[access] then
      result.barrier = true
    end
  else
    local barrier = node:get_value_by_key("barrier")
    if barrier then
      --  make an exception for rising bollard barriers
      local bollard = node:get_value_by_key("bollard")
      local rising_bollard = bollard and "rising" == bollard

      if not profile.barrier_whitelist[barrier] and not rising_bollard then
        result.barrier = true
      end
    end
  end

  -- check if node is a traffic light
  local tag = node:get_value_by_key("highway")
  if "traffic_signals" == tag then
    result.traffic_lights = true
  end
end

function way_function(way, result)
  -- the intial filtering of ways based on presence of tags
  -- affects processing times significantly, because all ways
  -- have to be checked.
  -- to increase performance, prefetching and intial tag check
  -- is done in directly instead of via a handler.

  -- in general we should  try to abort as soon as
  -- possible if the way is not routable, to avoid doing
  -- unnecessary work. this implies we should check things that
  -- commonly forbids access early, and handle edge cases later.

  -- data table for storing intermediate values during processing
  local data = {
    -- prefetch tags
    highway = way:get_value_by_key('highway'),
    bridge = way:get_value_by_key('bridge'),
    route = way:get_value_by_key('route')
  }

  -- perform an quick initial check and abort if the way is
  -- obviously not routable.
  -- highway or route tags must be in data table, bridge is optional
  if (not data.highway or data.highway == '') and
  (not data.route or data.route == '')
  then
    return
  end

  handlers = Sequence {
    -- set the default mode for this profile. if can be changed later
    -- in case it turns we're e.g. on a ferry
    'handle_default_mode',

    -- check various tags that could indicate that the way is not
    -- routable. this includes things like status=impassable,
    -- toll=yes and oneway=reversible
    'handle_blocked_ways',

    -- determine access status by checking our hierarchy of
    -- access tags, e.g: motorcar, motor_vehicle, vehicle
    'handle_access',

    -- check whether forward/backward directions are routable
    'handle_oneway',

    -- check a road's destination
    'handle_destinations',

    -- check whether we're using a special transport mode
    'ferries_withlist',
    'handle_ferries',
    'handle_movables',

    -- handle service road restrictions
    'handle_service',

    -- handle hov
    'handle_hov',

    -- compute speed taking into account way type, maxspeed tags, etc.
    'handle_speed',
    'handle_surface',
    'handle_maxspeed',
    'handle_penalties',

    -- compute class labels
    'handle_classes',

    -- handle turn lanes and road classification, used for guidance
    'handle_turn_lanes',
    'handle_classification',

    -- handle various other flags
    'handle_roundabouts',
    'handle_startpoint',

    -- set name, ref and pronunciation
    'handle_names',

    -- set weight properties of the way
    'handle_weights'
  }

  Handlers.run(handlers,way,result,data,profile)
end

function turn_function (turn)
  -- Use a sigmoid function to return a penalty that maxes out at turn_penalty
  -- over the space of 0-180 degrees.  Values here were chosen by fitting
  -- the function to some turn penalty samples from real driving.
  local turn_penalty = profile.turn_penalty
  local turn_bias = profile.turn_bias

  if turn.has_traffic_light then
      turn.duration = profile.traffic_light_penalty
  end

  if turn.turn_type ~= turn_type.no_turn then
    if turn.angle >= 0 then
      turn.duration = turn.duration + turn_penalty / (1 + math.exp( -((13 / turn_bias) *  turn.angle/180 - 6.5*turn_bias)))
    else
      turn.duration = turn.duration + turn_penalty / (1 + math.exp( -((13 * turn_bias) * -turn.angle/180 - 6.5/turn_bias)))
    end

    if turn.direction_modifier == direction_modifier.u_turn then
      turn.duration = turn.duration + profile.u_turn_penalty
    end
  end

  -- for distance based routing we don't want to have penalties based on turn angle
  if properties.weight_name == 'distance' then
     turn.weight = 0
  else
     turn.weight = turn.duration
  end

  if properties.weight_name == 'routability' then
      -- penalize turns from non-local access only segments onto local access only tags
      if not turn.source_restricted and turn.target_restricted then
          turn.weight = properties.max_turn_weight;
      end
  end
end
