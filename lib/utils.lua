local levels = require("lib.levels")

local M = {}


function M.rgb(r, g, b, o)
  return r / 255, g / 255, b / 255, o or 1
end


function M.nextLvlIndex(lvl)
  for i, otherLvl in pairs(levels) do
    if (otherLvl.level == lvl.level) and (otherLvl.name == lvl.name) then
      if i == #levels then
        return 1
      else
        return i + 1
      end
    end
  end

  return 1
end


function M.nextLvl(lvl)
  return levels[M.nextLvlIndex(lvl)]
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


-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function M.tprint(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      M.tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end


return M