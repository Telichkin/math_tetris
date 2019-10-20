local composer = require("composer")

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())
composer.recycleOnSceneChange = true 

composer.gotoScene("scenes.menu")