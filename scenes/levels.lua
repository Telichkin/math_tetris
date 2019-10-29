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
  composer.gotoScene("scenes.loading", {time = 450, effect = "slideLeft"})
end


local function createBackBtn()
  local footerGroup = display.newGroup()
  footerGroup.x = display.contentCenterX
  footerGroup.y = display.contentCenterY + ((display.actualContentHeight - 45) / 2)
  footerGroup:addEventListener("tap", function () return true end)  -- blocks events propagation

  local bkg = display.newRect(footerGroup, 0, 0, display.actualContentWidth, 45)
  bkg:setFillColor(utils.rgb(50, 97, 215, 0.75))

  local btnGroup = display.newGroup()
  local btn = display.newRect(btnGroup, 0, 0, 100, 30)
  btn:setFillColor(utils.rgb(97, 134, 232, 1))
  btn.strokeWidth = 2
  btn:setStrokeColor(1, 1, 1, 1)
  display.newText(btnGroup, "назад", 0, 0, "assets/Neucha-Regular", 25)

  btnGroup:addEventListener("tap", function ()
    sound.play("tap")
    composer.gotoScene("scenes.menu", {time = 450, effect = "slideRight"})
    return true
  end)

  footerGroup:insert(btnGroup)
  scene.view:insert(footerGroup)
end


local function createLvlBtn(lvl, unlocked) 
  local playBtnGroup = display.newGroup()
  local img = "assets/images/lvl-" .. (unlocked and "unlocked" or "locked") .. ".png"
  local playBtn = display.newImageRect(playBtnGroup, img, 138, 114)

  if unlocked then
    local playBtnTitle = display.newText(playBtnGroup, lvl.name, 0, 0, "assets/Neucha-Regular", 20)
    playBtnTitle:setFillColor(utils.rgb(0, 0, 0, 1))
    playBtnTitle.y = -15

    local playBtnSubtitle = display.newText(playBtnGroup, "Уровень " .. tostring(lvl.level), 0, 0, "assets/Neucha-Regular", 20)
    playBtnSubtitle:setFillColor(utils.rgb(0, 0, 0, 1))  
    playBtnSubtitle.y = 15
  else
    local lockImg = display.newImage(playBtnGroup, "assets/images/lock-icon.png", 0, 0)
    lockImg.height = 72
    lockImg.width = 72
  end

  if math.fmod((buttonsCount + 1), 2) ~= 0 then  -- Левый блок
    playBtnGroup.x = deltaX + display.contentCenterX - 75
  else  -- Правый блок
    playBtnGroup.x = deltaX + display.contentCenterX + 75
  end
  playBtnGroup.y = deltaY + (math.floor(buttonsCount / 2) * 125) + 70

  scrollView:insert(playBtnGroup)
  playBtn:addEventListener("tap", function ()
    if unlocked then
      state.selectLvl(lvl)
      gotoGame()
    end
    sound.play("tap")
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

  createBackBtn()
  for i, lvl in pairs(levels) do
    createLvlBtn(lvl, i <= state.lastUnlockedLvlIndex)
  end

  scrollView:setScrollHeight(deltaY + (math.ceil(buttonsCount / 2) * 135))
end

scene:addEventListener("create")

return scene