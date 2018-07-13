WayHandlers = require("lib/way_handlers")

local Startpoint_secure = {}

-- determine if this way can be used as a start/end point for routing
function Startpoint_secure.startpoint_secure(profile,way,result,data)
  local highway = way:get_value_by_key("highway")
  local tunnel = way:get_value_by_key("tunnel")

  if highway ~= "motorway" and highway ~= "motorway_link" and (not tunnel or tunnel == "") then
    WayHandlers.startpoint(way,result,data,profile)
  else
    result.is_startpoint = false
  end
end

return Startpoint_secure
