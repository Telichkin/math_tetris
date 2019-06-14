local composer = require("composer")
local widget = require("widget")
local utils = require("lib.utils")
local state = require("lib.state")


local scene = composer.newScene()
local buttonsCount = 0


local function gotoSubMenu()
  composer.gotoScene("scenes.subMenu")
end


local function createLvlBtn(text) 
  local playBtnGroup = display.newGroup()
  local playBtn = display.newRoundedRect(playBtnGroup, 0, 0, 240, 60, 10)
  playBtn:setFillColor(unpack(utils.rgb(145, 145, 145, 1)))
  local playBtnText = display.newText(playBtnGroup, text, 0, 0, "assets/Roboto-Medium", 32)
  playBtnText:setFillColor(unpack(utils.rgb(255, 255, 255, 1)))

  playBtnGroup.x = display.contentCenterX
  playBtnGroup.y = (buttonsCount + 1) * (60 + 15)

  scene.view:insert(playBtnGroup)
  playBtn:addEventListener("tap", function ()
    state.task = text
    gotoSubMenu()
  end)

  buttonsCount = buttonsCount + 1
end


function scene:create(event)
  local sceneGroup = self.view

  local background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  background:setFillColor(unpack(utils.rgb(243, 230, 219)))

  createLvlBtn("a + b = ?")
  createLvlBtn("a + ? = b")
  createLvlBtn("a - b = ?")
  createLvlBtn("? - a = b")
  createLvlBtn("a - ? = b")
end

scene:addEventListener("create")

return scene