local M = {}
local generate = {}


generate["a + b = ?"] = function (limit)
  local tasks = {}
  for a = 1, limit do
    for b = 1, limit do
      tasks[#tasks + 1] = {
        type = "a + b = ?",
        a = a,
        b = b,
        ["?"] = a + b,
      }
    end
  end

  local numbers = {}
  for n = 2, limit + limit do
    numbers[n] = {
      type = "number",
      n = n,
    }
  end

  return tasks, numbers
end


generate["a + ? = b"] = function (limit)
  local tasks = {}
  for a = 1, limit do
    for q = 1, limit do
      tasks[#tasks + 1] = {
        type = "a + ? = b",
        a = a,
        b = a + q,
        ["?"] = q,
      }
    end
  end

  local numbers = {}
  for n = 1, limit do
    numbers[#numbers + 1] = {
      type = "number",
      n = n,
    }
  end

  return tasks, numbers
end


generate["a - b = ?"] = function (limit)
  local tasks = {}
  for a = 2, limit do
    for b = 1, a - 1 do
      tasks[#tasks + 1] = {
        type = "a - b = ?",
        a = a,
        b = b,
        ["?"] = a - b,
      }
    end
  end

  local numbers = {}
  for n = 2, limit - 1 do
    numbers[#numbers + 1] = {
      type = "number",
      n = n,
    }
  end

  return tasks, numbers
end


generate["? - a = b"] = function (limit)
  local tasks = {}
  for q = 2, limit do
    for a = 1, q - 1 do
      tasks[#tasks + 1] = {
        type = "? - a = b",
        a = a,
        b = q - a,
        ["?"] = q,
      }
    end
  end

  local numbers = {}
  for n = 2, limit do
    number[#numbers + 1] = {
      type = "number",
      n = n,
    }
  end

  return tasks, numbers
end


generate["a - ? = b"] = function (limit)
  local tasks = {}
  for a = 2, limit do
    for q = 1, a - 1 do
      tasks[#tasks + 1] = {
        type = "a - ? = b",
        a = a,
        b = a - q,
        ["?"] = q,
      }
    end
  end

  local numbers = {}
  for n = 1, limit - 1 do
    numbers[#numbers + 1] = {
      type = "number",
      n = n,
    }
  end

  return tasks, numbers
end


generate["a * b = ?"] = function (limit)
  local tasks = {}
  for a = 2, limit do
    for b = 2, limit do
      tasks[#tasks + 1] = {
        type = "a * b = ?",
        a = a,
        b = b,
        ["?"] = a * b,
      }
    end
  end


  local numbers = {}
  for a = 2, limit do
    for b = 2, limit do
      numbers[#numbers + 1] = {
        type = "number",
        n = a * b,
      }
    end
  end

  return tasks, numbers
end


generate["a * ? = b"] = function (limit)
  local tasks = {}
  for a = 1, limit do
    for q = 1, limit do
      tasks[#tasks + 1] = {
        type = "a * ? = b",
        a = a,
        b = a * q,
        ["?"] = q,
      }
    end
  end

  local numbers = {}
  for n = 1, limit do
    numbers[#numbers + 1] = {
      type = "number",
      n = n,
    }
  end

  return tasks, numbers
end


function filter(arr, func)
  local newArr = {}

  for i, item in pairs(arr) do
    if func(item) == true then
      newArr[#newArr + 1] = item
    end
  end

  return newArr
end


function M.createOne(tasks, numbers, isRight, wantType, b1, b2, b3)
  local prob = math.random()
  local blocksOnField = filter({b1, b2, b3}, function (b) return b ~= nil end)
  -- Случайно выбираем блок под который находим решение
  local block = (#blocksOnField > 0) and blocksOnField[math.random(#blocksOnField)] or nil
  isRight = isRight and (math.random() <= (#blocksOnField / 3))

  if isRight and block then
    -- Если блок -- задача, то правильное решение -- число
    -- Если блок -- число, то правильное решение -- задача
    if block.task.type ~= "number" then
      return {
        type = "number",
        n = block.task["?"],
        text = block.task["?"],
      }
    else
      local rightTasks = filter(tasks, function (t) return t["?"] == block.task.n end)
      return rightTasks[math.random(#rightTasks)]
    end
  else
    local calcNumber = false
    if wantType then
      calcNumber = wantType == "number"
    elseif block then
      calcNumber = block.task.type ~= "number"
    else
      calcNumber = prob < 0.5
    end

    if calcNumber then
      local wrongNumbers = filter(numbers, function (n)
        for i, b in pairs(blocksOnField) do
          if b.type ~= "number" then
            if n.n == b["?"] then
              return false
            end
          else
            if n.n == b.n then
              return false
            end
          end
        end
        return true
      end)
      return wrongNumbers[math.random(#wrongNumbers)]
    else
      local wrongTasks = filter(tasks, function (t) 
        for i, b in pairs(blocksOnField) do
          if b.type ~= "number" then
            if t["?"] == b["?"] and t.a == b.a and t.b == b.b then
              return false
            end
          else
            if t["?"] == b.n then
              return false
            end
          end
        end
        return true
      end)
      return wrongTasks[math.random(#wrongTasks)]
    end
  end
end

function M.isSolved(b1, b2)
  if not b1 or not b2 or b1.task.type == b2.task.type then
    return false 
  elseif b1.task.type == "number" and b2.task.type ~= "number" then
    return b1.task.n == b2.task["?"]
  elseif b2.task.type == "number" and b1.task.type ~= "number" then
    return b1.task["?"] == b2.task.n
  else
    return false
  end
end

local function init(tasks, numbers)
  for i, task in pairs(tasks) do
    task.text = task.type:gsub("a", task.a):gsub("b", task.b)
  end

  for i, num in pairs(numbers) do
    num.text = tostring(num.n)
  end

  return tasks, numbers
end

function M.generate(task, limit)
  return init(generate[task](limit))
end

function M.generateScheme(tasksN, tasksType)
  local scheme = {{}, {}, {}}
  for i = 1, tasksN do
    local col = math.random(#scheme)
    -- Не должно быть перепада по высоте больше, чем на 2 блока
    while ((#scheme[col] - #scheme[1]) >= 2) or ((#scheme[col] - #scheme[2]) >= 2) or ((#scheme[col] - #scheme[3]) >= 2) do
      col = col + 1
      if col > 3 then
        col = 1
      end
    end
    table.insert(scheme[col], tasksType)
  end
  return scheme
end

return M