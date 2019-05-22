local composer = require("composer")
local physics = require("physics")


local scene = composer.newScene()

physics.start()
physics.setGravity(0, 0)


local box
local boxSize = {
  width = math.floor(display.contentWidth / 3),
  height = display.contentHeight / 10,
  margin = 1,
}
local boxPositionsX = {
  boxSize.margin + boxSize.width * 0.5,
  boxSize.margin * 2 + boxSize.width * 1.5,
  boxSize.margin * 3 + boxSize.width * 2.5,
}
local floorSize = {
  width = display.contentWidth,
  height = 10,
}
local maxPositionY = {
  display.contentHeight,
  display.contentHeight,
  display.contentHeight,
}


local function boxUpperY() 
  return  box.y - boxSize.height / 2
end

local function boxLowerY()
  return box.y + boxSize.height / 2
end


local function updateBoxPosition(index) 
  if (index < 1) then
    index = 1
  elseif (index > #boxPositionsX) then
    index = #boxPositionsX
  end

  if (boxLowerY() < maxPositionY[index]) then 
    box.positionIndex = index
    box.x = boxPositionsX[index]
  end

  if (box.positionIndex == nil) then 
    box.x = -boxSize.width
  end
end


local function swipeBox(event)
  if (box.bodyType == "static") then
    return true
  end

  local phase = event.phase
  local xDiff = event.x - event.xStart
  local yDiff = event.y - event.yStart

  if ((phase == "ended" or phase == "cancelled")) then
    if (math.abs(xDiff) > 30) then
      -- swipe left
      if (xDiff < 0) then
        updateBoxPosition(box.positionIndex - 1)
      -- swipe right
      elseif (xDiff > 0) then
        updateBoxPosition(box.positionIndex + 1)
      end
    elseif (yDiff > 30 and box.myMoveFast == false) then
      box.myMoveFast = true
      box:setLinearVelocity(0, 500)
    end
  end
  
  return true
end


local function generateTask(description, limit)
  if (description == "number") then
    return tostring(math.random(1, limit))
  elseif (description == "sum right") then
    local first = math.random(1, limit - 1)
    local second = math.random(1, limit - first)
    return tostring(first) .. " + " .. tostring(second) .. " = ?"
  elseif (description == "sum left") then
    local first = math.random(1, limit - 1)
    local sum = math.random(first + 1, limit)
    return tostring(first) .. " + ? = " .. tostring(sum)  
  end
  return "?"
end


local function isSolved(value1, value2)
  local questionIndex1 = string.find(value1, '?')
  local questionIndex2 = string.find(value2, '?')

  if ((questionIndex1 and questionIndex2) or (questionIndex1 == nil and questionIndex2 == nil)) then
    return false
  end

  local task = questionIndex1 and value1 or value2
  local answer = questionIndex2 and value1 or value2
  local questionIndex = questionIndex1 or questionIndex2

  local solution = string.sub(task, 1, questionIndex - 1) .. answer .. string.sub(task, questionIndex + 1)
  local equalIndex = string.find(solution, '=')
  solution = string.sub(solution, 1, equalIndex - 1) .. "==" .. string.sub(solution, equalIndex + 1)
  local solved = loadstring("return " .. solution)
  return solved()
end


local function createNewBox()
  box = display.newGroup()
  box.y = -boxSize.height * 0.7
  mainGroup:insert(box)

  local taskTypes = {"number", "sum right", "sum left", "number"}

  local task = generateTask(taskTypes[math.random(1, #taskTypes)], 10)
  local shape = display.newRect(box, 0, 0, boxSize.width, boxSize.height)
  shape:setFillColor(174 / 255, 227 / 255, 250 / 255)
  local text = display.newText(box, task, 0, 0, native.systemFont, 15)
  text:setFillColor(0, 0, 0)

  updateBoxPosition(math.random(1, #boxPositionsX))

  physics.addBody(box, "dynamic", {bounce = 0})

  box.isBullet = true
  box.myName = "box"
  box.myValue = task
  box.myMoveFast = false
  box:setLinearVelocity(0, 50)

  function box:collision(event)
    local upperY = boxUpperY()
    local other = event.other

    if (upperY > -boxSize.height * 0.1) then
      box:setLinearVelocity(0, 0)
      box.isBullet = false
      box.bodyType = "static"
      box:removeEventListener("collision")
      maxPositionY[box.positionIndex] = upperY
      
      if (other.myName == "box") then
        if (isSolved(box.myValue, other.myValue)) then
          display.remove(box)
          display.remove(other)
        end
      end

      timer.performWithDelay(300, createNewBox)
    else
      print("game over")
      physics.pause()
    end
  end

  box:addEventListener("collision")
end


local function createFloor()
  local floor = display.newRect(
    mainGroup, 
    display.contentCenterX, 
    display.contentHeight + floorSize.height, 
    floorSize.width, 
    floorSize.height
  )

  physics.addBody(floor, "static", {
    bounce = 0,
  })
  floor.myName = "floor"
end


function scene:create(event)
  local sceneGroup = self.view

  physics.pause()

  mainGroup = display.newGroup()
  sceneGroup:insert(mainGroup)

  createFloor()
  createNewBox()
end


function scene:show(event)
  local phase = event.phase

  if (phase == "did") then
    physics.start()
    Runtime:addEventListener("touch", swipeBox)
  end
end


scene:addEventListener("create")
scene:addEventListener("show")

return scene