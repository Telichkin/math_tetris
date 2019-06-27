local M = {}
local create = {}


create["a + b = ?"] = function (range, limit)
  local answer
  if #range == 1 then
    answer = range[1]
  else
    answer = range[math.random(2, #range)]
  end

  if answer == 1 then 
    return create["a + ? = b"](range, limit) 
  end

  local pairs = {}
  if (answer == 2) then 
    table.insert(pairs, {1, 1})
  end
  for i = 1, answer - 1 do
    table.insert(pairs, {i, answer - i})
  end
  local firstAndSecond = pairs[math.random(#pairs)]

  return {
    type = "a + b = ?",
    answer = answer,
    args = pairs[math.random(#pairs)],
  }
end


create["a + ? = b"] = function (range, limit) 
  local maxIndex = #range
  if range[maxIndex] == limit then
    maxIndex = maxIndex - 1
  end

  if maxIndex == 0 then 
    return create["a + b = ?"](range, limit)
  end

  local answer = range[math.random(maxIndex)]

  local pairs = {}
  if limit - answer == 1 then
    table.insert(pairs, {1, answer + 1})
  else
    for i = 1, limit - answer do
      table.insert(pairs, {i, answer + i})
    end
  end
  local firstAndSum = pairs[math.random(#pairs)]

  return {
    type = "a + ? = b",
    answer = answer,
    args = pairs[math.random(#pairs)],
  }
end


create["a - b = ?"] = function (range, limit)
  local maxIndex = #range
  if range[maxIndex] == limit then
    maxIndex = maxIndex - 1
  end

  if maxIndex == 0 then
    return create["? - a = b"](range, limit)
  end

  local answer = range[math.random(maxIndex)]

  local pairs = {}

  if limit - answer == 1 then
    table.insert(pairs, {answer + 1, 1})
  else
    for i = 1, limit - answer do
      table.insert(pairs, {answer + i, i})
    end
  end
  local firstAndSecond = pairs[math.random(#pairs)]

  return {
    type = "a - b = ?",
    answer = answer,
    args = pairs[math.random(#pairs)],
  }
end


create["? - a = b"] = function (range, limit) 
  local answer
  if #range == 1 then
    answer = range[1]
  else
    answer = range[math.random(2, #range)]
  end

  if answer == 1 then 
    return create["a - b = ?"](range, limit) 
  end

  local pairs = {}
  if (answer == 2) then 
    table.insert(pairs, {1, 1})
  end
  for i = 1, answer - 1 do
    table.insert(pairs, {answer - i, i})
  end
  local secondAndAnswer = pairs[math.random(#pairs)]

  return {
    type = "? - a = b",
    answer = answer,
    args = pairs[math.random(#pairs)],
  }
end


create["a - ? = b"] = function (range, limit)
  local maxIndex = #range
  if range[maxIndex] == limit then
    maxIndex = maxIndex - 1
  end

  if maxIndex == 0 then
    return create["? - a = b"](range, limit)
  end

  local answer = range[math.random(maxIndex)]

  local pairs = {}
  if limit - answer == 1 then
    table.insert(pairs, {answer + 1, 1})
  else
    for i = 1, limit - answer do
      table.insert(pairs, {answer + i, i})
    end
  end
  local firstAndAnswer = pairs[math.random(#pairs)]

  return {
    type = "a - ? = b",
    answer = answer,
    args = pairs[math.random(#pairs)],
  }
end

-- Генерируется много простых чисел, из-за этого
-- примеры получаются неинтересными: 61 * 1 = ?, 1 * 67 = ? и т.д.
-- Чтобы примеры были интересными, нужно как-то связать генерацию 
-- чисел с генерацией примеров. А еще нужно решить, что значит
-- задача "умножение с лимитом 10". Лимит в левой или в правой части?
create["a * b = ?"] = function (range, limit)
  local answer
  if #range == 1 then
    answer = range[1]
  else
    answer = range[math.random(2, #range)]
  end

  if answer == 1 then
    return create["a * ? = b"](range, limit)
  end

  local pairs = {}
  if (answer == 2) then
    local pairsFor2 = {{1, 2}, {2, 1}}
    table.insert(pairs, {pairsFor2[math.random(2)]})
  end
  for i = 1, answer - 1 do
    if answer % i == 0 then
      table.insert(pairs, {i, math.floor(answer / i)})
    end
  end
  local firstAndSecond = pairs[math.random(#pairs)]
  return {
    type = "a * b = ?",
    answer = answer,
    args = pairs[math.random(#pairs)],
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

  local maxIsForbidden = t["a + ? = b"] or t["a - b = ?"] or t["a - ? = b"]
  local oneIsForbidden = t["a + b = ?"] or t["? - a = b"]

  if oneIsForbidden and not maxIsForbidden and range[1] == 1 then
    table.remove(range, 1)
  elseif maxIsForbidden and not oneIsForbidden and range[#range] == limit then
    table.remove(range, #range)
  end

  local number = range[math.random(#range)]
  return {
    type = "number",
    answer = number,
  }
end


function M.isSolved(task1, task2)
  if not task1 or not task2 or task1.type == task2.type then
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