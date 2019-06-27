lu = require('luaunit')

-- name should start with 'Test'
TestFoo = {}

function TestFoo:testTrue()
  lu.assertEquals(1, 1)
end

os.exit(lu.LuaUnit:run())
