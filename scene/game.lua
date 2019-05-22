local composer = require("composer")
local physics = require("physics")


local scene = composer.newScene()

physics.start()
physics.setGravity(0, 0)


local box
local boxSize = {
  width = math.floor(display.contentWidth / 3),
  height = 40,
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
  display.contentHeight - floorSize.height,
  display.contentHeight - floorSize.height,
  display.contentHeight - floorSize.height,
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
end


local function swipeBox(event)
  if (box.myStatic == true) then
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
    elseif (yDiff > 30) then
      box:setLinearVelocity(0, 500)
    end
  end
  
  return true
end


local function createNewBox()
  local startY = boxSize.margin + boxSize.height / 2
  box = display.newRect(mainGroup, 0, startY, boxSize.width, boxSize.height)
  updateBoxPosition(math.random(1, #boxPositionsX))

  physics.addBody(box, "dynamic", {
    bounce = 0,
  })

  box.isBullet = true
  box.myName = "box"
  box.myStatic = false
  box:setLinearVelocity(0, 50)

  function box:collision(event)
    box.isBullet = false
    box.myStatic = true
    box.bodyType = "static"
    box:removeEventListener("collision")
    box:setLinearVelocity(0, 0)
    maxPositionY[box.positionIndex] = boxUpperY()
    timer.performWithDelay(500, createNewBox)
  end

  box:addEventListener("collision")
end


local function createFloor()
  local floor = display.newRect(
    mainGroup, 
    display.contentCenterX, 
    display.contentHeight - floorSize.height, 
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