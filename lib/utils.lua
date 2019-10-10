local M = {}


function M.rgb(r, g, b, o)
  return r / 255, g / 255, b / 255, o or 1
end


return M