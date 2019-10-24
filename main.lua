local composer = require("composer")
local inputReader = require("lib.inputReader")

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())
composer.recycleOnSceneChange = true 
inputReader.start()

composer.gotoScene("scenes.menu")