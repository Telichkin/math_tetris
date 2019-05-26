local composer = require("composer")
local widget = require("widget")
local utils = require("lib.utils")


local scene = composer.newScene()


local function gotoGame()
  composer.gotoScene("scenes.game")
end


function scene:create(event)
  local sceneGroup = self.view

  local background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  background:setFillColor(unpack(utils.rgb(243, 230, 219)))

  local playBtnGroup = display.newGroup()
  local playBtn = display.newRoundedRect(playBtnGroup, 0, 0, 240, 60, 10)
  playBtn:setFillColor(unpack(utils.rgb(145, 145, 145, 1)))
  local playBtnText = display.newText(playBtnGroup, "Играть", 0, 0, "assets/Roboto-Medium", 32)
  playBtnText:setFillColor(unpack(utils.rgb(255, 255, 255, 1)))
  playBtnGroup.x = display.contentCenterX
  playBtnGroup.y = display.contentCenterY
  sceneGroup:insert(playBtnGroup)

  playBtnGroup:addEventListener("tap", gotoGame)
end

scene:addEventListener("create")

return scene