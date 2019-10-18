local composer = require("composer")


local scene = composer.newScene()


function scene:show(event)
  if (event.phase == "did") then
    composer.removeScene("scenes.game")
    composer.gotoScene("scenes.game")
  end
end


function scene:hide(event) 
  if (event.phase == "did") then
    composer.removeScene("scenes.toGame")
  end
end


scene:addEventListener("show")
scene:addEventListener("hide")

return scene