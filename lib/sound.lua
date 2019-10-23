local M = {}

audio.reserveChannels(2)

local loadedSounds = {}
local sounds = {
  tap = "assets/sounds/tap.wav",
  swipe_1 = "assets/sounds/swipe.wav",
  swipe_2 = "assets/sounds/poof.wav",
  impact = "assets/sounds/impact.wav",
  lose = "assets/sounds/lose.wav",
  win = "assets/sounds/win_2.wav",
}


function loadSound(name)
  if loadedSounds[name] == nil then
    loadedSounds[name] = audio.loadSound(sounds[name])
  end
  return loadedSounds[name]
end


function M.play(name) 
  audio.play(loadSound(name))
end


return M
