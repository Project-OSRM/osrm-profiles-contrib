-- Bus profile
-- Note : for a 'standard' bus
-- weight=19 (if maxweight < 19 then mode.inaccessible)
-- width=2.55 (if maxwidth < 2.55 then mode.inaccessible)
-- height=3.5 (if maxheight < 3.5 then mode.inaccessible)


api_version = 1

local find_access_tag = require("lib/access").find_access_tag
local Set = require('lib/set')
local Sequence = require('lib/sequence')
local Handlers = require("lib/handlers")
local next = next       -- bind to local for speed

local Tags = require('lib/tags')

penalty_table = {
  ["service"] = 0.5,
}




-- set profile properties
properties.max_speed_for_map_matching      = 180/3.6 -- 180kmph -> m/s
properties.use_turn_restrictions           = true
properties.continue_straight_at_waypoint   = true
properties.left_hand_driving               = false
-- For routing based on duration, but weighted for preferring certain roads
properties.weight_name                     = 'routability'
-- For shortest duration without penalties for accessibility
--properties.weight_name                     = 'duration'
-- For shortest distance without penalties for accessibility
--properties.weight_name                     = 'distance'

local profile = {
  default_mode      = mode.driving,
  default_speed     = 10,
  oneway_handling   = true,

  side_road_multiplier       = 0.8,
  turn_penalty               = 7.5,
  speed_reduction            = 0.8,
  traffic_light_penalty      = 2,
  u_turn_penalty             = 20,
  restricted_penalty         = 3000,
  -- Note^: abstract value but in seconds correlates approximately to 50 min
  -- meaning that a route through a local access way is > 50 min faster than around

  -- Note: this biases right-side driving.
  -- Should be inverted for left-driving countries.
  turn_bias   = properties.left_hand_driving and 1/1.075 or 1.075,


-- set "bus" properties
  maxweight=19
  maxwidth=2.55
  maxheight=3.5



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
    'entrance',
    'bus_trap' --bus_trap is not a trap for busses!
  },

  access_tag_whitelist = Set {
    'yes',
--    'motorcar', --removed
    'motor_vehicle',
    'vehicle',
    'permissive',
    'designated',
--    'hov'
    'psv', --added
    'bus' --added
  },

  access_tag_blacklist = Set {
    'no',
    'agricultural',
    'forestry',
    'emergency' --,
--    'psv' --removed
  },

  restricted_access_tag_list = Set {
    'private',
    'delivery',
    'destination'
  },

  access_tags_hierarchy = Sequence {
--    'motorcar',
    'bus', --added
    'psv', --added
    'motor_vehicle',
    'vehicle',
    'access'
  },

  service_tag_forbidden = Set {
    'emergency_access'
  },

  restrictions = Sequence {
--    'motorcar',
    'bus', --added
    'psv', --added
    'motor_vehicle',
    'vehicle'
  },


  avoid = Set {
    --'area', removed
    -- 'toll',    -- uncomment this to avoid tolls
    'reversible',
    'impassable',
    'hov_lanes',
    'steps'
  },

  speeds = Sequence {
    highway = {
      motorway        = 90,
      motorway_link   = 45,
      trunk           = 85,
      trunk_link      = 40,
      primary         = 65,
      primary_link    = 30,
      secondary       = 55,
      secondary_link  = 25,
      tertiary        = 40,
      tertiary_link   = 20,
      unclassified    = 25,
      residential     = 25,
      living_street   = 10,
      service         = 15
    }
  },

  service_penalties = {
    alley             = 0.5,
    parking           = 0.5,
    parking_aisle     = 0.5,
    driveway          = 0.5,
    ["drive-through"] = 0.5,
    ["drive-thru"] = 0.5
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

function get_restrictions(vector)
  for i,v in ipairs(profile.restrictions) do
    vector:Add(v)
  end
end

-- node analysis
-- result.barrier = true means that this node is impassable
-- result.traffic_light = true indicates a traffic light on this node


function node_function (node, result)
  -- parse access and barrier tags
  local access = find_access_tag(node, profile.access_tags_hierarchy)
  if access then
    if profile.access_tag_blacklist[access] then
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


  -- check if node is a maxweight/height/width limit
  local tag = node:get_value_by_key("maxweight")
  if tag then
    local tagN = tonumber(tag:match("%d+%.?%d*"))
    if tagN and tagN < profile.maxweight then
      result.barrier = true
    end
  end

  local tag = node:get_value_by_key("maxwidth")
  if tag then
    local tagN = tonumber(tag:match("%d+%.?%d*"))
    if tagN and tagN < profile.maxwidth then
      result.barrier = true
    end
  end

  local tag = node:get_value_by_key("maxheight")
  if tag then
    local tagN = tonumber(tag:match("%d+%.?%d*"))
    if tagN and tagN < profile.maxheight then
      result.barrier = true
    end
  end


  -- check if node is a traffic light
  local tag = node:get_value_by_key("highway")
  if "traffic_signals" == tag then
    result.traffic_lights = true
  end
end

-- way analysis
-- result.forward_mode = mode for this way in forward direction (mode.driving, mode.inaccessible)
-- result.forward_rate = (analogous to m/weight unit, for example m/s, greater is better)
-- result.forward_speed = speed in km/h for this way in forward direction (used for ETA calculation)
-- result.duration = s, used for ETA (independant of routing)
-- result.weight = depends on weight_name, for example s, lesser is better, used for routing
-- weight_name can be 'routability','distance','steps','duration'
-- routability is like duration but weighted for prefering certain roads

-- result.name, result.ref, result.pronunciation = name of the way
-- result.roundabout, result.circular = true indicates a roundabout or circular (no priority for circular)
-- result.is_startpoint = true
-- result.destinations
-- result.turn_lanes_forward
-- result.forward_restricted


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
--    'handle_oneway',
    'handle_bus_oneway',

    -- check whether forward/backward directions are routable
    'handle_destinations',

    -- check whether we're using a special transport mode
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


  local tag = way:get_value_by_key("maxweight")
  if tag then
    local tagN = tonumber(tag:match("%d+%.?%d*"))
    if tagN and tagN < profile.maxweight then
      result.forward_mode = mode.inaccessible
      result.backward_mode = mode.inaccessible
    end
  end
  local tag = way:get_value_by_key("maxwidth")
  if tag then
    local tagN = tonumber(tag:match("%d+%.?%d*"))
    if tagN and tagN < profile.maxwidth then
      result.forward_mode = mode.inaccessible
      result.backward_mode = mode.inaccessible
    end
  end
  local tag = way:get_value_by_key("maxheight")
  if tag then
      local tagN = tonumber(tag:match("%d+%.?%d*"))
      if tagN and tagN < profile.maxheight then
        result.forward_mode = mode.inaccessible
        result.backward_mode = mode.inaccessible
      end
  end



end

function turn_function (turn)
  -- Use a sigmoid function to return a penalty that maxes out at turn_penalty
  -- over the space of 0-180 degrees.  Values here were chosen by fitting
  -- the function to some turn penalty samples from real driving.
  local turn_penalty = profile.turn_penalty
  local turn_bias = profile.turn_bias

  if turn.turn_type ~= turn_type.no_turn then
    if turn.angle >= 0 then
      turn.duration = turn_penalty / (1 + math.exp( -((13 / turn_bias) *  turn.angle/180 - 6.5*turn_bias)))
    else
      turn.duration = turn_penalty / (1 + math.exp( -((13 * turn_bias) * -turn.angle/180 - 6.5/turn_bias)))
    end

    if turn.direction_modifier == direction_modifier.u_turn then
      turn.duration = turn.duration + profile.u_turn_penalty
    end

    if turn.has_traffic_light then
       turn.duration = turn.duration + profile.traffic_light_penalty
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
            turn.weight = turn.weight + profile.restricted_penalty
        end
    end
  end
end





-- handle oneways tags
function Handlers.handle_bus_oneway(way,result,data,profile)
  if not profile.oneway_handling then
    return
  end

  local oneway
  if profile.oneway_handling == true then
    oneway = Tags.get_value_by_prefixed_sequence(way,profile.restrictions,'oneway') or way:get_value_by_key("oneway")
  elseif profile.oneway_handling == 'specific' then
    oneway = Tags.get_value_by_prefixed_sequence(way,profile.restrictions,'oneway')
  elseif profile.oneway_handling == 'conditional' then
    -- Following code assumes that `oneway` and `oneway:conditional` tags have opposite values and takes weakest (always `no`).
    -- So if we will have:
    -- oneway=yes, oneway:conditional=no @ (condition1)
    -- oneway=no, oneway:conditional=yes @ (condition2)
    -- condition1 will be always true and condition2 will be always false.
    if way:get_value_by_key("oneway:conditional") then
        oneway = "no"
    else
        oneway = Tags.get_value_by_prefixed_sequence(way,profile.restrictions,'oneway') or way:get_value_by_key("oneway")
    end
  end



local busway = way:get_value_by_key("busway")
local bus = way:get_value_by_key("bus")
local psv = way:get_value_by_key("psv")

-- if psv or bus*=opposite*
if (busway and string.find(busway, "opposite") == 1) or (bus and string.find(bus, "opposite") == 1) or (psv and string.find(psv, "opposite") == 1) then
   bus_opposite = true
else
   bus_opposite = false
end


  data.oneway = oneway

  if oneway == "-1" then
    if not bus_opposite then
      data.is_reverse_oneway = true
      result.forward_mode = mode.inaccessible
    end


  elseif oneway == "yes" or
         oneway == "1" or
         oneway == "true" then
    if not bus_opposite then
      data.is_forward_oneway = true
      result.backward_mode = mode.inaccessible
    end



  elseif profile.oneway_handling == true then
    local junction = way:get_value_by_key("junction")
    if data.highway == "motorway" or
       junction == "roundabout" or
       junction == "circular" then
      if oneway ~= "no" then
        -- implied oneway
        data.is_forward_oneway = true
        result.backward_mode = mode.inaccessible
      end
    end
  end
end

