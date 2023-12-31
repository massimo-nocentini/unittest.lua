
local unittest = {}

unittest.traits = {

    testcase = {
        run = function (recv, result)

            if not result:started (recv) then return end

            recv:setup ()

            local succeed, msg = pcall (recv[recv.name], recv, result)   -- ignore returned values, just keep the succeed flag.

            if not succeed then result:failed (recv, msg) end
            
            recv:teardown ()
        end,
        setup = function (recv) end,
        teardown = function (recv) end,
    },

    testresult = {

        summary = function (recv)
            local totals = string.format ('%d run, %d failed.', recv.runcount, recv.failedcount)
            local reasons = {}
            for name, msg in pairs (recv.reasons) do table.insert (reasons, name .. ': ' .. msg) end
            if #reasons > 0 then totals = totals .. '\n' .. table.concat (reasons, '\n') end
            return totals
        end,

        started = function (recv, case)
            if recv.seen[case.name] then return false end
            recv.runcount = recv.runcount + 1
            recv.seen[case.name] = true
            return true
        end,

        failed = function (recv, case, msg) 
            recv.failedcount = recv.failedcount + 1 
            recv.reasons[case.name] = msg
        end

    },

    testcases = {

        append = function (recv, test) table.insert (recv.tests, test) end,
        run = function (recv, result)
            for k, test in pairs (recv.tests) do
                test:run (result)
            end
        end

    },

}

function unittest.case (name) 

    local t = { name = name }

    setmetatable (t, {

        __index = function (recv, key) return unittest.traits.testcase[key] end

    })

    return t

end

function unittest.wasrun (name)
    
    local t = unittest.case (name)

    t.log = {}

    function t.test_method (recv) 
        table.insert (recv.log, 'test_method')
    end

    function t.test_broken_method (recv) 
        error 'explicitly raised.'
    end

    function t.logstring (recv) return table.concat (recv.log, ' ') end

    function t.setup (recv)
        table.insert (recv.log, 'setup')
    end

    function t.teardown (recv)
        table.insert (recv.log, 'teardown')
    end

    return t
end

function unittest.new_result ()
    local o = { 
        runcount = 0, 
        failedcount = 0, 
        reasons = {},
        seen = {},
    }

    setmetatable(o, {
        __index = function (recv, key) return unittest.traits.testresult[key] end
    })

    return o
end

function unittest.cases ()

    local o = { tests = {} }

    setmetatable (o, {
        __index = function (recv, key) return unittest.traits.testcases[key] end
    })

    return o

end


function unittest.suite (trait)


    local function case_trait (name)
        local c = unittest.case (name)

        local __index = getmetatable (c).__index

        setmetatable (c, {

            __index = function (recv, key) 
                return trait[key] or __index (recv, key) 
            end

        })

        return c
    end


    local cases = unittest.cases ()

    for name, test_f in pairs (trait) do 
        if (type(name) == 'string' and string.sub(name, 1, 4) == 'test') then
            cases:append (case_trait (name))
        end
    end

    return cases

end

function unittest.run (tests, result)

    result = result or unittest.new_result ()
    unittest.suite (tests):run (result)
    return result
end

function unittest.files (files)
    return function (result)
        result = result or unittest.new_result ()

        for i, filename in ipairs (files) do
            local spec = dofile (filename)
            unittest.suite (spec):run (result)
        end

        return result
    end
end

unittest.assert = {}

local eq_functions = {}

function eq_functions.same (a, b) return a == b end

function eq_functions.equals (a, b)
    local atype = type(a)
    if atype == 'table' and atype == type(b) then return eq_functions.eq_tbls (a, b)
    else return eq_functions.same (a, b) end
end

function eq_functions.eq_tbls (r, s)

    local used = {}

    for k, v in pairs (r) do

        local missing = true

        for kk, vv in pairs (s) do

            if (not used[kk]) and eq_functions.equals (k, kk) then 

                if eq_functions.equals (v, vv) then missing = false; used[kk] = true end

            end

        end

        if missing then return false end

    end

    for k, v in pairs (s) do if not used[k] then return false end end

    return true

end

local function tostring_recursive (obj, indent)

    indent = indent or ''

    if type(obj) == 'table' then
        local s = indent
        s = s .. '{\n'
        for k, v in pairs (obj) do 
            indent = indent .. '  '
            s = s .. indent .. tostring(k) .. ': \n'
            indent = indent .. '  '
            s = s .. tostring_recursive (v, indent)
        end
        s = s .. '\n}'
        return s
    elseif type(obj) == 'string' then return indent .. "'" .. obj .. "'"
    else return indent .. tostring (obj) end

end

function unittest.assert.same (a)
    return function (b)
        return assert (eq_functions.same (a, b), string.format([[
Expected:
%s
Actual:
%s]], tostring_recursive(b), tostring_recursive(a))) 
    end
end

function unittest.assert.equals (...) 
    local b = table.pack (...)
    return function (...) 
        local a = table.pack (...) 
        return assert (eq_functions.eq_tbls (a, b),  string.format([[
Expected:
%s
Actual:
%s]], tostring_recursive(b), tostring_recursive(a))) 
    end
end

unittest.assert.istrue = unittest.assert.equals (true)
unittest.assert.isfalse = unittest.assert.equals (false)

unittest.deny = {}

function unittest.deny.same (a)
    return function (b)
        return assert (not eq_functions.same (a, b), string.format([[
Expected:
%s
Actual:
%s]], tostring_recursive(b), tostring_recursive(a))) 
    end
end

function unittest.deny.equals (...) 
    local b = table.pack (...)
    return function (...) 
        local a = table.pack (...) 
        return assert (not eq_functions.eq_tbls (a, b),  string.format([[
Expected:
%s
Actual:
%s]], tostring_recursive(b), tostring_recursive(a))) 
    end
end

return unittest