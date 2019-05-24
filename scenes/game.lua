local composer = require("composer")
local physics = require("physics")


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


local function getBoxX(n) 
  local xList = {
    - (boxSize.marginX * 1.5 + boxSize.width),
    0,
      (boxSize.marginX * 1.5 + boxSize.width),
  }
  return xList[n]
end

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


local function rgb(r, g, b, o)
  return {r / 255, g / 255, b / 255, o or 1}
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
    box.x = getBoxX(index)
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


local function findValidAnswersForLastTasks() 
  local answers = {}
  for i = #lastTasks, 1, -1 do
    local task = lastTasks[i][#lastTasks[i]]
    if (task and task.type ~= "number") then
      table.insert(answers, task.answer)
    end
  end
  return answers
end


local function findInvalidAnswersForLastTasks(limit)
  local answers = {}
  for i = 1, limit do
    table.insert(answers, i)
  end

  for i = #lastTasks, 1, -1 do
    local task = lastTasks[i][#lastTasks[i]]
    if (task and task.type ~= "number") then
      table.remove(answers, task.answer)
    end
  end
  return answers
end


local function findValidNumbersForLastTasks() 
  local numbers = {}
  for i = #lastTasks, 1, -1 do
    local task = lastTasks[i][#lastTasks[i]]
    if (task and task.type == "number") then
      table.insert(numbers, task.answer)
    end
  end
  return numbers
end


local function findInvalidNumbersForLastTasks(limit)
  local answers = {}
  for i = 1, limit do
    table.insert(answers, i)
  end

  for i = #lastTasks, 1, -1 do
    local task = lastTasks[i][#lastTasks[i]]
    if (task and task.type == "number") then
      table.remove(answers, task.answer)
    end
  end
  return answers
end


local function generateTask(type, range, limit) 
  if (type == "number") then
    local number = range[math.random(#range)]
    return {
      type = type, 
      value = tostring(number),
      answer = number,
    }
  elseif (type == "sum right") then
    if (#range == 1 and range[1] == 1) then
      return generateTask("sum left", range, limit)
    end

    local answer
    if (#range == 1) then
      answer = range[1]
    else
      answer = range[math.random(2, #range)]
    end

    local pairs = {}
    if (answer == 2) then 
      table.insert(pairs, {1, answer - 1})
    end
    for i = 1, answer - 1 do
      table.insert(pairs, {i, answer - i})
    end
    local firstAndSecond = pairs[math.random(1, #pairs)]

    return {
      type = type,
      value = tostring(firstAndSecond[1]) .. " + " .. tostring(firstAndSecond[2]) .. " = ?",
      answer = answer,
    }
  elseif (type == "sum left") then
    local maxIndex = #range
    if (range[maxIndex] == limit) then
      maxIndex = maxIndex - 1
    end

    if (maxIndex == 0) then
      return generateTask("sum right", range, limit)
    end

    local answer = range[math.random(1, maxIndex)]

    local pairs = {}
    for i = 1, limit - answer do
      table.insert(pairs, {i, answer + i})
    end
    local firstAndSum = pairs[math.random(1, #pairs)]

    return {
      type = type,
      value = tostring(firstAndSum[1]) .. " + ? = " .. tostring(firstAndSum[2]),
      answer = answer,
    }
  else
    return {
      type = type,
      value = "?",
      answer = 0,
    }
  end
end


local function generateRandomTask(types, limit)
  local validAnswers = findValidAnswersForLastTasks()
  local invalidAnswers = findInvalidAnswersForLastTasks(limit)
  local validNumbers = findValidNumbersForLastTasks()
  local invalidNumbers = findInvalidNumbersForLastTasks(limit)
  local taskType = types[math.random(#types)]

  local shouldBeValid = (math.random() > 0.54) and (#validAnswers > 0 or #validNumbers > 0)
  if (shouldBeValid) then
    if (#validAnswers == 0 and #validNumbers > 0) then
      return generateTask(taskType, validNumbers, limit)
    elseif (#validNumbers == 0 and #validAnswers > 0) then
      return generateTask("number", validAnswers, limit)
    else
      if (math.random() > 0.5) then
        return generateTask(taskType, validNumbers, limit)
      else
        return generateTask("number", validAnswers, limit)
      end
    end
  else
    if (#invalidAnswers == 0 and #invalidNumbers > 0) then
      return generateTask(taskType, invalidNumbers, limit)
    elseif (#invalidNumbers == 0 and #invalidAnswers > 0) then
      return generateTask("number", invalidAnswers, limit)
    else
      if (math.random() > 0.5) then
        return generateTask(taskType, invalidNumbers, limit)
      else
        return generateTask("number", invalidAnswers, limit)
      end
    end
  end
end


local function isSolved(task1, task2)
  if (task1.type == task2.type) then
    return false
  elseif ((task1.type == "number" and task2.type ~= "number") or
          (task2.type == "number" and task1.type ~= "number"))
  then
    return task1.answer == task2.answer
  else
    return false
  end
end


local function createBackground()
  local background = display.newRect(mainGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  background:setFillColor(unpack(rgb(243, 230, 219)))
end


local function createNewBox()
  box = display.newGroup()
  box.y = - (gameGroup.height / 2 + boxSize.height * 0.7)
  gameGroup:insert(box)

  local task = generateRandomTask({"sum right", "sum left"}, 100)
  local shape = display.newRoundedRect(box, 0, 0, boxSize.width, boxSize.height, boxSize.radius)
  if (task.type == "number") then
    shape:setFillColor(unpack(rgb(242, 177, 120)))
  else
    shape:setFillColor(unpack(rgb(254, 218, 65)))
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

    if (upperY > - (gameGroup.height / 2 - boxSize.height * 0.1)) then
      this:setLinearVelocity(0, 0)
      this.isBullet = false
      this.bodyType = "static"
      this:removeEventListener("collision")
      maxPositionY[this.positionIndex] = upperY
      
      if (other.myName == "box") then
        if (isSolved(this.myTask, other.myTask)) then
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