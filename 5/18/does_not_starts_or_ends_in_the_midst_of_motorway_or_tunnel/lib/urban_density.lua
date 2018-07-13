local Urban_density = {}

function Urban_density.assert_urban_database()
  -- Assert Urban database exists and contains data
  local cur = assert(sql_conn:execute("SELECT * FROM urban LIMIT 1"))
  assert(cur:fetch())
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

function Urban_density.speed_profile(coefs, highway)
  if speeds_interurban[highway] and speeds_urban_dense[highway] and speeds_urban[highway] then
    return
      coefs[1] * speeds_interurban[highway] +
      coefs[2] * speeds_urban[highway] +
      coefs[3] * speeds_urban[highway] +
      coefs[4] * speeds_urban_dense[highway]
  end
end

function Urban_density.speed_coef_sql(way)
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

function Urban_density.speed_coef(way)
  assert(way:version() ~= 0)

  local speeds_v = redis_conn:lrange(way:id(), 0, -1)
  if tonumber(speeds_v[5]) == way:version() then
    return {tonumber(speeds_v[1]), tonumber(speeds_v[2]), tonumber(speeds_v[3]), tonumber(speeds_v[4])}
  end

  speeds = Urban_density.speed_coef_sql(way)
  speeds[1], speeds[2], speeds[3], speeds[4] = tonumber(speeds[1]), tonumber(speeds[2]), tonumber(speeds[3]), tonumber(speeds[4])

  redis_conn:del(way:id())
  local speeds_v = {speeds[1], speeds[2], speeds[3], speeds[4], way:version()}
  redis_conn:rpush(way:id(), unpack(speeds_v))

  return speeds
end

local max_speeds = {
  [130] = {115, 90, 90, 70},
  [110] = {100, 75, 75, 58},
  [90] = {85, 60, 60, 43},
  [50] = {47, 33, 33, 15},
  [30] = {29, 19, 19, 9},
  [20] = {20, 13, 13, 8},
  [0] = {0, 0, 0, 0}
}

local max_speeds_bounds = {{nil, 130}, {130, 110}, {110, 90}, {90, 50}, {50, 30}, {30, 20}, {20, 0}}

function Urban_density.max_speed_coef(coefs, max_speed)
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

-- Helpers functions

function Urban_density.default_speed(way)
  return Urban_density.speed_profile(Urban_density.speed_coef(way), 'default')
end

function Urban_density.speeds(way)
  return Urban_density.speed_profile(Urban_density.speed_coef(way), way:get_value_by_key('highway'))
end

function Urban_density.maxspeeds(way, max_speed)
  return Urban_density.max_speed_coef(Urban_density.speed_coef(way), max_speed)
end

return Urban_density
