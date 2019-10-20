local composer = require("composer")
local utils = require("lib.utils")


local scene = composer.newScene()


function scene:create()
  local background = display.newRect(self.view, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  background:setFillColor(utils.rgb(255, 255, 255)) 

  local ball = display.newImageRect(self.view, 'assets/images/clock.png', 54, 140)
  ball.x = display.contentCenterX
  ball.y = display.contentCenterY

  transition.to(ball, {time = 1500, rotation = 360, delta = true, iterations = -1})
end


function scene:show(event)
  if event.phase == "will" then
    composer.removeScene("scenes.game")
    -- composer.loadScene("scenes.game")
  elseif (event.phase == "did") then
    timer.performWithDelay(540, function()
      composer.gotoScene("scenes.game", {time = 350, effect = "crossFade"})
    end)
  end
end


function scene:hide(event) 
  if (event.phase == "did") then
    composer.removeScene("scenes.toGame")
  end
end


scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")

return scene