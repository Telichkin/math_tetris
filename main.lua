local composer = require("composer")
local inputReader = require("lib.inputReader")
local saver = require("lib.saver")

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())
composer.recycleOnSceneChange = true 
inputReader.start()
saver.start()

composer.gotoScene("scenes.menu")