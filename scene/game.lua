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
  display.contentHeight
}
local lastTasks = {nil, nil, nil}


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

  print(boxLowerY(), maxPositionY[index])
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


local function findValidAnswersForLastTasks() 
  local answers = {}
  for i = #lastTasks, 1, -1 do
    local task = lastTasks[i]
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
    local task = lastTasks[i]
    if (task and task.type ~= "number") then
      table.remove(answers, task.answer)
    end
  end
  return answers
end


local function findValidNumbersForLastTasks() 
  local numbers = {}
  for i = #lastTasks, 1, -1 do
    local task = lastTasks[i]
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
    local task = lastTasks[i]
    if (task and task.type == "number") then
      table.remove(answers, task.answer)
    end
  end
  return answers
end


local function generateTask(type, range, limit) 
  print(#range, type)
  
  if (type == "number") then
    local number = range[math.random(1, #range)]
    return {
      type = type, 
      value = tostring(number),
      answer = number,
    }
  elseif (type == "sum right") then
    if (#range == 1 and range[1] == 1) then
      return generateTask("sum left", range, limit)
    end

    local answer = range[math.random(2, #range)]

    local pairs = {}
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
  local tasks = {}

  local validAnswers = findValidAnswersForLastTasks()
  if (#validAnswers > 0) then
    local task = generateTask("number", validAnswers, limit)
    table.insert(tasks, task)
  end

  local invalidAnswers = findInvalidAnswersForLastTasks(limit)
  if (#invalidAnswers > 0) then
    local task = generateTask("number", invalidAnswers, limit)
    table.insert(tasks, task)
  end

  local validTaskType = types[math.random(1, #types)]
  local validNumbers = findValidNumbersForLastTasks()
  if (#validNumbers > 0) then
    local task = generateTask(validTaskType, validNumbers, limit)
    table.insert(tasks, task)
  end

  local invalidTaskType = types[math.random(1, #types)]
  local invalidNumbers = findInvalidNumbersForLastTasks(limit)
  if (#invalidNumbers > 0) then
    local task = generateTask(invalidTaskType, invalidNumbers, limit)
    table.insert(tasks, task)
  end
  
  return tasks[math.random(1, #tasks)]
end


local function isSolved(task1, task2)
  if (task1.type == task2.type) then
    return false
  elseif ((task1.type == "number" and task2.type ~= "number") or
          (task2.type == "number" and task1.type ~= "number"))
  then
    print(task1.answer, task2.answer)
    return task1.answer == task2.answer
  else
    return false
  end
end


local function createNewBox()
  box = display.newGroup()
  box.y = -boxSize.height * 0.7
  mainGroup:insert(box)

  local task = generateRandomTask({"sum right", "sum left"}, 10)
  local shape = display.newRect(box, 0, 0, boxSize.width, boxSize.height)
  shape:setFillColor(174 / 255, 227 / 255, 250 / 255)
  local text = display.newText(box, task.value, 0, 0, native.systemFont, 15)
  text:setFillColor(0, 0, 0)

  updateBoxPosition(math.random(1, #boxPositionsX))

  physics.addBody(box, "dynamic", {bounce = 0})

  box.isBullet = true
  box.myName = "box"
  box.myTask = task
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
        if (isSolved(box.myTask, other.myTask)) then
          display.remove(box)
          display.remove(other)
        else
          lastTasks[box.positionIndex] = box.myTask
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