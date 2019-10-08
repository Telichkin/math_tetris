local composer = require("composer")
local physics = require("physics")
local widget = require("widget")
local tasks = require("lib.tasks")
local utils = require("lib.utils")
local state = require("lib.state")

-- Нужна другая механика
-- Что-то вроде волн: сверху появляется "волна" из трех задач и игрок должен указать в какую задачу
-- он "швырнет" решение.
-- если решение неправильное, то появляется новая волна или снимается жизнь.
-- волны идут с постоянной скоростью
local scene = composer.newScene()
local gameGroup
local mainGroup
local lvlTasks
local lvlNumbers

physics.start()
physics.setGravity(0, 0)


local box
local fieldW = display.contentWidth * 0.92
local fieldH = display.contentHeight * 0.8
local numberOfBoxesW = 3
local numberOfBoxesH = 9
local boxSize = {
  width = fieldW / numberOfBoxesW,
  height = fieldH / numberOfBoxesH - 5,
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
  elseif (index > numberOfBoxesW) then
    index = numberOfBoxesW
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
    -- swipe down
    elseif (yDiff > 30 and box.myMoveFast == false) then
      box.myMoveFast = true
      box:setLinearVelocity(0, 600)
    end
  end
  
  return true
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


local function removeValidBoxes(upBox, lowBox)
  table.remove(lastTasks[lowBox.positionIndex], #lastTasks[lowBox.positionIndex])
  maxPositionY[upBox.positionIndex] = boxLowerY(lowBox)

  transition.to(upBox, {
    alpha = 0,
    time = 200,
  })

  transition.to(lowBox, {
    alpha = 0,
    time = 200,
    onComplete = function () 
      display.remove(upBox)
      display.remove(lowBox)
    end
  })
end


local function createNewBox()
  box = display.newGroup()
  box.y = - (gameGroup.height / 2 + boxSize.height * 0.7)
  gameGroup:insert(box)

  local marginShape = display.newRect(box, 0, 0, boxSize.width, boxSize.height + boxSize.marginX)
  marginShape:setFillColor(0, 0, 0, 0)

  local task = tasks.random(lvlTasks, lvlNumbers, lastTasks[1][#lastTasks[1]], lastTasks[2][#lastTasks[2]], lastTasks[3][#lastTasks[3]])
  local shape = display.newRoundedRect(box, 0, 0, boxSize.width, boxSize.height, boxSize.radius)

  local textContent
  if (task.type == "number") then
    textContent = tostring(task.n)
    shape:setFillColor(unpack(utils.rgb(242, 177, 120)))
  else
    textContent = task.type:gsub("a", task.a):gsub("b", task.b)
    shape:setFillColor(unpack(utils.rgb(254, 218, 65)))
  end

  local text = display.newText(box, textContent, 0, 0, "assets/Roboto-Black", 15)
  text:setFillColor(1, 1, 1)

  updateBoxPosition(math.random(numberOfBoxesW))

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
    
    if tasks.isSolved(this.myTask, other.myTask) then
      removeValidBoxes(this, other)
    else
      table.insert(lastTasks[this.positionIndex], this.myTask)
    end

    -- Box is outside of the screen
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
  lvlTasks, lvlNumbers = tasks.generate(state.task, state.limit)
  lastTasks = {
    {tasks.random(lvlTasks, lvlNumbers)},
    {},
    {},
  }

  for col = 1, #lastTasks do

  end

  physics.pause()

  mainGroup = display.newGroup()
  sceneGroup:insert(mainGroup)
  
  createBackground()

  gameGroup = display.newContainer(fieldW, fieldH)
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


function scene:hide(event) 
  local sceneGroup = self.view
  local phase = event.phase

  if (phase == "did") then
    physics.pause()
    Runtime:removeEventListener("touch", swipeBox)
    composer.removeScene("scenes.game")
  end
end


scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")

return scene