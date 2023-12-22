
local unittest = require 'unittest'

local tests = {}

function tests.test_empty_strings ()

    unittest.assert.equals '' [[]]
    unittest.assert.equals '' [[
]]
    unittest.deny.equals '' [[

]]

end

function tests.test_string_byte ()

    unittest.assert.equals (104, 101, 108, 108, 111) (string.byte ('hello', 1, 5))
    unittest.assert.equals (104, 101, 108, 108, 111) (string.byte ('hello', 1, -1))

end

return tests