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
  if #arr == 0 then return newArr end

  for i = 1, #arr do
    if func(arr[i]) == true then
      newArr[#newArr + 1] = arr[i]
    end
  end

  return newArr
end


-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end


function M.random(tasks, numbers, b1, b2, b3)
  local prob = math.random()
  local blocksOnField = filter({b1, b2, b3}, function (b) return b ~= nil end)
  -- вероятность правильного решения
  local n2probs = {
    [0] = 0, 
    [1] = 0.1, 
    [2] = 0.16, 
    [3] = 0.5,
  }
  local rightProb = n2probs[#blocksOnField]
  tprint(blocksOnField)
  if prob < rightProb then
    -- Случайно выбираем блок под который находим правильное решение
    -- Если блок -- задача, то правильное решение -- число
    -- Если блок -- число, то правильное решение -- задача
    local block = blocksOnField[math.random(#blocksOnField)]
    if block.type ~= "number" then
      return {
        type = "number",
        n = block["?"],
      }
    else
      print("block.n: ", block.n)
      local rightTasks = filter(tasks, function (t) return t["?"] == block.n end)
      return rightTasks[math.random(#rightTasks)]
    end
  elseif prob >= rightProb and prob <= ((rightProb + 1) / 2) then
    -- Если блок -- задача, то неправильно число не должно быть равно полю "?" 
    -- Если блок -- число, то неправильное число не должно быть равно число в блоке
    local wrongNumbers = filter(numbers, function (n)
      if not n then return false end

      for i = 1, #blocksOnField do
        local b = blocksOnField[i]
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
  else  -- [3]
    -- Если блок -- задача, то неправильная задача не должна повторять задачу в блоке
    -- Если блок -- число, то неправильная задача должна иметь поле "?" не равно числу в блоке
    local wrongTasks = filter(tasks, function (t) 
      for i = 1, #blocksOnField do
        local b = blocksOnField[i]
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

function M.isSolved(b1, b2)
  if not b1 or not b2 or b1.type == b2.type then
    return false 
  elseif b1.type == "number" and b2.type ~= "number" then
    return b1.n == b2["?"]
  elseif b2.type == "number" and b1.type ~= "number" then
    return b1["?"] == b2.n
  else
    return false
  end
end

function M.generate(task, limit)
  return generate[task](limit) 
end

return M