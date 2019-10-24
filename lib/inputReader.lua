local M = {}
local lastEvent


function readInput(event)
  local phase = event.phase
  local xDiff = event.x - event.xStart
  local yDiff = event.y - event.yStart

  if phase == "ended" or phase == "cancelled" then
    if xDiff < -30 then 
      lastEvent = "Swipe Left"
    elseif xDiff > 30 then 
      lastEvent = "Swipe Right" 
    elseif yDiff > 30 then
      lastEvent = "Swipe Down"
    elseif yDiff < -30 then
      lastEvent = "Swipe Up"
    end
  end

  return true
end


function M.getLastEvent()
  local e = lastEvent
  lastEvent = nil
  return e
end


function M.start()
  Runtime:addEventListener("touch", readInput)
end


function M.stop()
  lastEvent = nil
  Runtime:removeEventListener("touch", readInput)  
end


return M