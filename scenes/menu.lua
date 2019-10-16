local composer = require("composer")
local widget = require("widget")
local utils = require("lib.utils")
local state = require("lib.state")
local levels = require("lib.levels")


local scene = composer.newScene()
local buttonsCount = 0
local scrollView


local function gotoGame()
  composer.gotoScene("scenes.game")
end


local function createLvlBtn(lvl) 
  local playBtnGroup = display.newGroup()
  local playBtn = display.newRect(playBtnGroup, 0, 0, 240, 60)
  playBtn:setFillColor(utils.rgb(255, 255, 255, 1))
  playBtn.strokeWidth = 4
  playBtn:setStrokeColor(utils.rgb(149, 175, 237))

  local playBtnText = display.newText(playBtnGroup, lvl.name .. " " .. tostring(lvl.level), 0, 0, "assets/Neucha-Regular", 20)
  playBtnText:setFillColor(utils.rgb(0, 0, 0, 1))

  playBtnGroup.x = display.contentCenterX
  playBtnGroup.y = (buttonsCount + 1) * (60 + 15)

  scrollView:insert(playBtnGroup)
  playBtn:addEventListener("tap", function ()
    state.lvl = lvl
    gotoGame()
  end)

  buttonsCount = buttonsCount + 1
end


function scene:create(event)
  local sceneGroup = self.view

  scrollView = widget.newScrollView({
    x = display.contentCenterX,
    y = display.contentCenterY,
    width = display.contentWidth,
    height = display.contentHeight,
  })

  sceneGroup:insert(scrollView)

  for i, lvl in pairs(levels) do
    createLvlBtn(lvl)
  end

  scrollView:setScrollHeight(10 + (buttonsCount * 80))
end

scene:addEventListener("create")

return scene