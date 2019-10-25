local composer = require("composer")
local utils = require("lib.utils")
local state = require("lib.state")
local tasks = require("lib.tasks")


local scene = composer.newScene()


function scene:create(event)
  state.lvl.lvlTasks, state.lvl.lvlNumbers = tasks.generate(state.lvl.task, state.lvl.limit)
  state.lvl.scheme = tasks.generateScheme(state.lvl.tasksN, state.lvl.tasksType)
  
  local background = display.newRect(
    self.view, display.contentCenterX, display.contentCenterY, 
    display.actualContentWidth, display.actualContentHeight
  )
  background:setFillColor(utils.rgb(255, 255, 255)) 

  local clock = display.newImageRect(self.view, 'assets/images/clock.png', 54, 140)
  clock.x = display.contentCenterX
  clock.y = display.contentCenterY

  transition.to(clock, {time = 1500, rotation = 360, delta = true, iterations = -1})
end


function scene:show(event)
  if event.phase == "will" then
    composer.loadScene("scenes.game", false)
  elseif event.phase == "did" then
    timer.performWithDelay(540, function()
      composer.gotoScene("scenes.game", {time = 500, effect = "crossFade"})
    end)
  end
end


function scene:hide(event) 
  if event.phase == "did" then
    composer.removeScene("scenes.loading")
  end
end


scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")

return scene