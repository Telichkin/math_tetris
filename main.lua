local composer = require("composer")
local inputReader = require("lib.inputReader")
local state = require("lib.state")
require("images")

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())
composer.recycleOnSceneChange = true 
inputReader.start()
state.start()

composer.gotoScene("scenes.menu")