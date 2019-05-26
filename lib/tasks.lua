local M = {}
local create = {}


function create.number(range, limit)
  local number = range[math.random(#range)]
  return {
    type = "number", 
    value = tostring(number),
    answer = number,
  }
end


function create.sumRight(range, limit)
  local answer
  if (#range == 1) then
    answer = range[1]
  else
    answer = range[math.random(2, #range)]
  end

  -- Такой пример: 0 + ? = 1 не должен быть сгенерирован
  if answer == 1 then 
    return create.sumLeft(range, limit) 
  end

  local pairs = {}
  if (answer == 2) then 
    table.insert(pairs, {1, 1})
  end
  for i = 1, answer - 1 do
    table.insert(pairs, {i, answer - i})
  end
  local firstAndSecond = pairs[math.random(1, #pairs)]

  return {
    type = "sumRight",
    value = tostring(firstAndSecond[1]) .. " + " .. tostring(firstAndSecond[2]) .. " = ?",
    answer = answer,
  }
end


function create.sumLeft(range, limit) 
  local maxIndex = #range
  if (range[maxIndex] == limit) then
    maxIndex = maxIndex - 1
  end

  if (maxIndex == 0) then 
    return create.sumRight(range, limit)
  end

  local answer = range[math.random(1, maxIndex)]

  local pairs = {}
  for i = 1, limit - answer do
    table.insert(pairs, {i, answer + i})
  end
  local firstAndSum = pairs[math.random(1, #pairs)]

  return {
    type = "sumLeft",
    value = tostring(firstAndSum[1]) .. " + ? = " .. tostring(firstAndSum[2]),
    answer = answer,
  }
end


function M.create(type, range, limit)
  return create[type](range, limit)
end


return M