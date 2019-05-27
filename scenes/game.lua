local composer = require("composer")
local physics = require("physics")
local widget = require("widget")
local tasks = require("lib.tasks")
local utils = require("lib.utils")


local scene = composer.newScene()
local gameGroup
local mainGroup

physics.start()
physics.setGravity(0, 0)


local box
local numberOfBoxes = 3
local boxSize = {
  width = display.contentWidth * 0.92 / numberOfBoxes,
  height = display.contentWidth / (numberOfBoxes * 2) - 5,
  marginY = 6,
  marginX = 4,
  radius = 10,
}
boxSize.width = boxSize.width - 2 * boxSize.marginX

local boxXPositions = {
  - (boxSize.marginX * 1.5 + boxSize.width),
  0,
    (boxSize.marginX * 1.5 + boxSize.width)
}
local floorSize = {
  width = display.contentWidth,
  height = 10,
}
local maxPositionY = {
  display.contentHeight,
  display.contentHeight,
  display.contentHeight
}
local lastTasks = {{}, {}, {}}


local function gotoMenu()
  composer.gotoScene("scenes.menu")
end


local function boxUpperY(aBox) 
  return aBox.y - boxSize.height / 2
end

local function boxLowerY(aBox)
  return aBox.y + boxSize.height / 2
end


local function updateBoxPosition(index) 
  if (index < 1) then
    index = 1
  elseif (index > numberOfBoxes) then
    index = numberOfBoxes
  end

  if (boxLowerY(box) < maxPositionY[index]) then 
    box.positionIndex = index
    box.x = boxXPositions[index]
  end

  if (box.positionIndex == nil) then 
    box.x = -boxSize.width
  end
end


local function swipeBox(event)
  if (box == nil) then
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
      box:setLinearVelocity(0, 600)
    end
  end
  
  return true
end


local function findInLastTasks(limit, fn) 
  local valid, invalid = {}, {}
  for i = 1, limit do table.insert(invalid, i) end

  for i = 1, #lastTasks do
    local task = lastTasks[i][#lastTasks[i]]
    if (task and fn(task)) then
      table.insert(valid, task.answer)
      table.remove(invalid, task.answer)
    end
  end
  return {valid = valid, invalid = invalid}
end


local function generateRandomTask(types, limit)
  local answers = findInLastTasks(limit, function (task) return task.type ~= "number" end)
  local numbers = findInLastTasks(limit, function (task) return task.type == "number" end)
  local taskType = types[math.random(#types)]

  local shouldBeValid = (math.random() > 0.5) and (#answers.valid > 0 or #numbers.valid > 0)
  if shouldBeValid then
    if #answers.valid == 0 and #numbers.valid > 0 then
      return tasks.createTask(taskType, numbers.valid, limit)
    elseif #numbers.valid == 0 and #answers.valid > 0 then
      return tasks.createNumber(types, answers.valid, limit)
    else
      if math.random() > 0.5 then
        return tasks.createTask(taskType, numbers.valid, limit)
      else
        return tasks.createNumber(types, answers.valid, limit)
      end
    end
  else
    if #answers.invalid == 0 and #numbers.invalid > 0 then
      return tasks.createTask(taskType, numbers.invalid, limit)
    elseif (#numbers.invalid == 0 and #answers.invalid > 0) then
      return tasks.createNumber(types, answers.invalid, limit)
    else
      if math.random() > 0.5 then
        return tasks.createTask(taskType, numbers.invalid, limit)
      else
        return tasks.createNumber(types, answers.invalid, limit)
      end
    end
  end
end


local function createBackground()
  local background = display.newRect(mainGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  background:setFillColor(unpack(utils.rgb(243, 230, 219)))
end


local function createGameOverBackground()
  local background = display.newRoundedRect(gameGroup, 0, 0, gameGroup.width, gameGroup.height, 10)
  background:setFillColor(unpack(utils.rgb(240, 240, 240, 0.6)))

  local btnGroup = display.newGroup()
  local btn = display.newRoundedRect(btnGroup, 0, 0, 240, 60, 10)
  btn:setFillColor(unpack(utils.rgb(145, 145, 145, 1)))
  local btnText = display.newText(btnGroup, "В меню", 0, 0, "assets/Roboto-Medium", 32)
  btnText:setFillColor(unpack(utils.rgb(255, 255, 255, 1)))
  btnGroup.x = 0
  btnGroup.y = 0
  gameGroup:insert(btnGroup)

  btnGroup:addEventListener("tap", gotoMenu)
end


local function createNewBox()
  box = display.newGroup()
  box.y = - (gameGroup.height / 2 + boxSize.height * 0.7)
  gameGroup:insert(box)

  local task = generateRandomTask({"a - b = ?", "? - a = b", "a - ? = b"}, 5)
  local shape = display.newRoundedRect(box, 0, 0, boxSize.width, boxSize.height, boxSize.radius)
  if (task.type == "number") then
    shape:setFillColor(unpack(utils.rgb(242, 177, 120)))
  else
    shape:setFillColor(unpack(utils.rgb(254, 218, 65)))
  end
  local marginShape = display.newRect(box, 0, 0, boxSize.width, boxSize.height + boxSize.marginX)
  marginShape:setFillColor(0, 0, 0, 0)

  local text = display.newText(box, task.value, 0, 0, "assets/Roboto-Black", 15)
  text:setFillColor(1, 1, 1)

  updateBoxPosition(math.random(numberOfBoxes))

  physics.addBody(box, "dynamic", {bounce = 0})

  box.isBullet = true
  box.myName = "box"
  box.myTask = task
  box.myMoveFast = false
  box:setLinearVelocity(0, 30)

  function box:collision(event)
    local upperY = boxUpperY(box)
    local other = event.other
    local this = box
    box = nil

    this:setLinearVelocity(0, 0)
    this.isBullet = false
    this.bodyType = "static"
    this:removeEventListener("collision")
    maxPositionY[this.positionIndex] = upperY
    
    if (other.myName == "box") then
      if (tasks.isSolved(this.myTask, other.myTask)) then
        display.remove(this)
        display.remove(other)
        table.remove(lastTasks[other.positionIndex], #lastTasks[other.positionIndex])
        maxPositionY[this.positionIndex] = boxLowerY(other)
      else
        table.insert(lastTasks[this.positionIndex], this.myTask)
      end
    else
      table.insert(lastTasks[this.positionIndex], this.myTask)
    end

    if maxPositionY[this.positionIndex] > - (gameGroup.height / 2 - boxSize.height * 0.1) then 
      timer.performWithDelay(300, createNewBox)
    else
      createGameOverBackground()
      physics.pause()
    end
  end

  box:addEventListener("collision")
end


local function createFloor()
  local floor = display.newRect(
    gameGroup, 
    0, 
    gameGroup.height / 2 + floorSize.height / 2 - boxSize.marginY / 2, 
    floorSize.width,
    floorSize.height
  )
  floor:setFillColor(0, 0, 0, 0)

  physics.addBody(floor, "static", {
    bounce = 0,
  })
  floor.myName = "floor"
end


local function createGameBackground()
  local background = display.newRoundedRect(gameGroup, 0, 0, gameGroup.width, gameGroup.height, 10)
  background:setFillColor(1, 1, 1)
end


function scene:create(event)
  local sceneGroup = self.view

  physics.pause()

  mainGroup = display.newGroup()
  sceneGroup:insert(mainGroup)
  
  createBackground()

  gameGroup = display.newContainer(display.contentWidth * 0.92, display.contentWidth)
  gameGroup.x = display.contentCenterX
  gameGroup.y = display.contentCenterY
  sceneGroup:insert(gameGroup)

  createGameBackground()
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