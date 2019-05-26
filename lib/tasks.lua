local M = {}
local create = {}


function create.sumRight(range, limit)
  local answer
  if (#range == 1) then
    answer = range[1]
  else
    answer = range[math.random(2, #range)]
  end

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


function M.createTask(type, range, limit)
  return create[type](range, limit)
end


function M.createNumber(types, range, limit)
  local t = {}
  for index, type in pairs(types) do
    t[type] = index
  end

  if t.sumRight ~= nil and t.sumLeft == nil and range[1] == 1 then
    table.remove(range, 1)
  elseif t.sumLeft ~= nil and t.sumRight == nil and range[#range] == limit then
    table.remove(range, #range)
  end

  local number = range[math.random(#range)]
  return {
    type = "number",
    value = tostring(number),
    answer = number,
  }
end


function M.isSolved(task1, task2)
  if (task1.type == task2.type) then
    return false
  elseif ((task1.type == "number" and task2.type ~= "number") or
          (task2.type == "number" and task1.type ~= "number"))
  then
    return task1.answer == task2.answer
  else
    return false
  end
end


return M