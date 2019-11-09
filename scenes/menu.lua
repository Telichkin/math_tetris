local composer = require("composer")
local utils = require("lib.utils")
local levels = require("lib.levels")
local sound = require("lib.sound")


local scene = composer.newScene()
local btnsGroup

local buttonsCount = 0
local deltaY = (display.actualContentHeight - display.contentHeight) / 2


local function createBtn(titleStr, callback) 
  local btnGroup = display.newGroup()
  local btn = display.newRect(btnGroup, 0, 0, 134, 40)
  btn:setFillColor(utils.rgb(255, 255, 255))
  btn.strokeWidth = 3
  btn:setStrokeColor(utils.rgb(56, 102, 204))

  local title = display.newText(btnGroup, titleStr, 0, 0, "assets/Neucha-Regular", 25)
  title:setFillColor(utils.rgb(0, 0, 0))

  btnGroup.x = display.contentCenterX
  btnGroup.y = buttonsCount * 80
  btn:addEventListener("tap", function ()
    sound.play("tap")
    callback()
  end)

  buttonsCount = buttonsCount + 1

  btnsGroup:insert(btnGroup)
  btnsGroup.y = display.contentCenterY - (btnsGroup.height / 2)
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
  display.newText(btnGroup, "выход", 0, 0, "assets/Neucha-Regular", 25)

  btnGroup:addEventListener("tap", function ()
    sound.play("tap")
    scene:handleBackBtn()
    return true
  end)

  footerGroup:insert(btnGroup)
  scene.view:insert(footerGroup)
end


function scene:handleBackBtn()
  native.requestExit()
end


function scene:create(event)  
  local background = display.newRect(
    scene.view, display.contentCenterX, display.contentCenterY, 
    display.actualContentWidth, display.actualContentHeight
  )
  background:setFillColor(utils.rgb(255, 255, 255)) 

  btnsGroup = display.newGroup()
  scene.view:insert(btnsGroup)
  createBtn("Играть", function () 
    composer.gotoScene("scenes.levels", {time = 450, effect = "slideLeft"})
  end)
  createBtn("Обучение", function () 
  end)
  createBtn("Рейтинг", function () 
  end)
  createBtn("Вопросы", function () 
  end)
  
  createBackBtn()
end

scene:addEventListener("create")

return scene