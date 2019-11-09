local composer = require("composer")
local inputReader = require("lib.inputReader")
local state = require("lib.state")
require("images")

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())
composer.recycleOnSceneChange = true 
inputReader.start()
state.start()

if system.getInfo("platformName") == "Android" then
	Runtime:addEventListener("key", function (event)
		if event.phase == "down" and event.keyName == "back" then
			local scene = composer.getScene(composer.getSceneName("current"))
			if scene and scene.handleBackBtn then
				scene:handleBackBtn()
			end
		end
		return true
	end)
end

composer.gotoScene("scenes.menu")