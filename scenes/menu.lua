local composer = require("composer")
local widget = require("widget")
local utils = require("lib.utils")
local state = require("lib.state")
local levels = require("lib.levels")
local sound = require("lib.sound")


local scene = composer.newScene()
local buttonsCount = 0
local deltaY = (display.actualContentHeight - display.contentHeight) / 2
local deltaX = (display.actualContentWidth - display.contentWidth) / 2
local scrollView


local function gotoGame()
  composer.gotoScene("scenes.toGame", {time = 450, effect = "fromRight"})
end


local function createLvlBtn(lvl) 
  local playBtnGroup = display.newGroup()
  local playBtn = display.newImageRect(playBtnGroup, "assets/images/lvl-unlocked.png", 138, 114)

  local playBtnTitle = display.newText(playBtnGroup, lvl.name, 0, 0, "assets/Neucha-Regular", 20)
  playBtnTitle:setFillColor(utils.rgb(0, 0, 0, 1))
  playBtnTitle.y = -15

  local playBtnSubtitle = display.newText(playBtnGroup, "Уровень " .. tostring(lvl.level), 0, 0, "assets/Neucha-Regular", 20)
  playBtnSubtitle:setFillColor(utils.rgb(0, 0, 0, 1))  
  playBtnSubtitle.y = 15

  if math.fmod((buttonsCount + 1), 2) ~= 0 then  -- Левый блок
    playBtnGroup.x = deltaX + display.contentCenterX - 75
  else  -- Правый блок
    playBtnGroup.x = deltaX + display.contentCenterX + 75
  end
  playBtnGroup.y = deltaY + (math.floor(buttonsCount / 2) * 125) + 70

  scrollView:insert(playBtnGroup)
  playBtn:addEventListener("tap", function ()
    state.lvl = lvl
    sound.play("tap")
    gotoGame()
  end)

  buttonsCount = buttonsCount + 1
end


function scene:create(event)
  local sceneGroup = self.view

  scrollView = widget.newScrollView({
    x = display.contentCenterX,
    y = display.contentCenterY,
    width = display.actualContentWidth,
    height = display.actualContentHeight,
    horizontalScrollDisabled = true,
  })
  sceneGroup:insert(scrollView)

  for i, lvl in pairs(levels) do
    createLvlBtn(lvl)
  end

  scrollView:setScrollHeight(deltaY + (math.ceil(buttonsCount / 2) * 135) - 30)
end

scene:addEventListener("create")

return scene