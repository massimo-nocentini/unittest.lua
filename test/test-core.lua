
local unittest = require 'unittest'

local tests = {}

function tests.setup (recv) recv.result = unittest.new_result () end
    
function tests.test_template_method (recv)
    local test = unittest.wasrun 'test_method'
    test:run (recv.result)
    unittest.assert.equals (test:logstring (), 'setup test_method teardown')
end

function tests.test_result (recv)

    local test = unittest.wasrun 'test_method'
    test:run (recv.result)
    unittest.assert.equals ('1 run, 0 failed.', recv.result:summary ())

end

function tests.test_failed_result (recv)

    local test = unittest.wasrun 'test_broken_method'
    test:run (recv.result)
    
    unittest.assert.equals (recv.result:summary (), [[
1 run, 1 failed.
test_broken_method: /usr/local/share/lua/5.4/unittest.lua:85: explicitly raised.]])

end

function tests.test_failedresultformatting (recv)

    local not_seen = recv.result:started (recv)
    assert (not_seen)

    recv.result:failed ({name = 'test_dummy'}, 'no reason.')
    
    unittest.assert.equals (recv.result:summary (), [[
1 run, 1 failed.
test_dummy: no reason.]])

end

function tests.test_cases (recv)

    local cases = unittest.cases ()
    cases:append (unittest.wasrun 'test_method')
    cases:append (unittest.wasrun 'test_broken_method')
    
    cases:run (recv.result)

    unittest.assert.equals (recv.result:summary (), [[
2 run, 1 failed.
test_broken_method: /usr/local/share/lua/5.4/unittest.lua:85: explicitly raised.]])

end

function tests.test_suite (recv, result)

    local suite = unittest.suite (tests)
    suite:run (result)
    unittest.assert.equals (result:summary (), '8 run, 0 failed.')

end


function tests.test_api_run (recv, result)

    unittest.run (tests, result)
    unittest.assert.equals (result:summary (), '8 run, 0 failed.')

end


function tests.test_api_files (recv)
    unittest.files {'test/test-assert.lua'} (recv.result)
    unittest.assert.equals (recv.result:summary (), '5 run, 0 failed.')
end

local result = unittest.run (tests)
print (result:summary ())

return tests