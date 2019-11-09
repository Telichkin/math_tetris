local levels = require("lib.levels")
local tasks = require("lib.tasks")


-- В глобальные переменные не стоит писать напрямую, это поможет избежать глупых ошибок
local M = {
  selectedLvl = nil,
  lastUnlockedLvlIndex = 1,
}


local function lvlIndex(lvl)
  for i, otherLvl in pairs(levels) do
    if (otherLvl.level == lvl.level) and (otherLvl.name == lvl.name) then
      return i
    end
  end
  return 1
end


local function nextLvlIndex(lvl)
  local i = lvlIndex(lvl)
  if i >= #levels then
    return 1
  else
    return i + 1
  end
end


function M.start()
  local path = system.pathForFile("lvl.txt", system.DocumentsDirectory)
  local file = io.open(path, "r")
  if file then
    M.lastUnlockedLvlIndex = tonumber(file:read("*a")) or 1
    io.close(file)
    file = nil
  end
end


function M.unlockNextLvl()
  local i = nextLvlIndex(M.selectedLvl)
  if i > M.lastUnlockedLvlIndex then
    M.lastUnlockedLvlIndex = i
    local path = system.pathForFile("lvl.txt", system.DocumentsDirectory)
    local file = io.open(path, "w")
    file:write(tostring(i))
    io.close(file)
    file = nil
  end
end


function M.initSelectedLvl()
  local lvl = M.selectedLvl
  if (lvl.lvlTasks == nil) or (lvl.lvlNumbers == nil) then
    lvl.lvlTasks, lvl.lvlNumbers = tasks.generate(lvl.task, lvl.limit)
  end
  lvl.scheme = tasks.generateScheme(lvl.tasksN, lvl.tasksType)
end


-- Эта функция защищает от случайного выбора заблокированного уровня
function M.selectLvl(lvl) 
  local i = lvlIndex(lvl)
  if i <= M.lastUnlockedLvlIndex then
    M.selectedLvl = levels[i]
  end
end


function M.selectNextLvl()
  M.selectLvl(levels[nextLvlIndex(M.selectedLvl)])
end


return M