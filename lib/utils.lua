local levels = require("lib.levels")

local M = {}


function M.rgb(r, g, b, o)
  return r / 255, g / 255, b / 255, o or 1
end


function M.nextLvl(lvl)
  for i, otherLvl in pairs(levels) do
    if (otherLvl.level == lvl.level) and (otherLvl.name == lvl.name) then
      return levels[i + 1]
    end
  end

  return levels[1]
end


function M.deepCopy(obj)
  if type(obj) ~= "table" then
    return obj
  end

  local copy = {}
  for k, v in pairs(obj) do
    copy[k] = M.deepCopy(v)
  end
  return copy
end


return M