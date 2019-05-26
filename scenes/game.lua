local composer = require("composer")
local physics = require("physics")
local tasks = require("lib.tasks")


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
      return tasks.create(taskType, numbers.valid, limit)
    elseif #numbers.valid == 0 and #answers.valid > 0 then
      return tasks.create("number", answers.valid, limit)
    else
      if math.random() > 0.5 then
        return tasks.create(taskType, numbers.valid, limit)
      else
        return tasks.create("number", answers.valid, limit)
      end
    end
  else
    if #answers.invalid == 0 and #numbers.invalid > 0 then
      return tasks.create(taskType, numbers.invalid, limit)
    elseif (#numbers.invalid == 0 and #answers.invalid > 0) then
      return tasks.create("number", answers.invalid, limit)
    else
      if math.random() > 0.5 then
        return tasks.create(taskType, numbers.invalid, limit)
      else
        return tasks.create("number", answers.invalid, limit)
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

  -- Вот эти моменты нужно как-то отлавливать:
  --  - Если пример типа: a + b = ?, то единица вообще не должна генерироваться
  --    среди всех чисел
  --  - Если пример типа: a + ? = b, и все числа не должны быть больше 10,
  --    то 10 вообще не должна генерироваться среди всех чисел
  local task = generateRandomTask({"sumRight"}, 10)
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