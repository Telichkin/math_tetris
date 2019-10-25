local M = {}
local lastLvlIndex = 1


function M.start()
  local path = system.pathForFile("lvl.txt", system.DocumentsDirectory)
  local file = io.open(path, "r")
  if file then
    lastLvlIndex = tonumber(file:read("*a")) or 1
    io.close(file)
    file = nil
  end
end


function M.lastLvlIndex()
  return lastLvlIndex
end


function M.saveLvl(lvlIndex)
  if lvlIndex > lastLvlIndex then
    lastLvlIndex = lvlIndex
    local path = system.pathForFile("lvl.txt", system.DocumentsDirectory)
    local file = io.open(path, "w")
    file:write(tostring(lvlIndex))
    io.close(file)
    file = nil
  end
end


return M