lu = require('luaunit')
tasks = require('lib.tasks')

-- name should start with 'Test'
TestFoo = {}

-- ## Идея для игры
-- соединять цифры и операции, чтобы набрать какое-то итоговое значение
-- 1 + 1 2 5
-- 5 4 * 3 -
-- + 8 1 - 6
-- 

function foo(a, b)
  return a == nil
end


function TestFoo:testTrue()
  local foo, bar = 1, 2
  lu.assertEquals(bar, 2)
end

os.exit(lu.LuaUnit:run())
