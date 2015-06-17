--[[

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[ MIT license: http://www.opensource.org/licenses/mit-license.php ]

--]]

-- Kollos top level grammar routines

-- luacheck: std lua51
-- luacheck: globals bit

local inspect = require "kollos.inspect" -- luacheck: ignore
local development = require "kollos.development"

local function here() return -- luacheck: ignore here
    debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
end

local grammar_class = { }

function grammar_class.file_set(config, file_name)
    config.file = file_name or debug.getinfo(2,'S').source
end

function grammar_class.line_set(config, line_number)
    config.line = line_number or debug.getinfo(2, 'l').currentline
end

-- process the named arguments common to most grammar methods
-- these are line, file and throw
local function common_args_process(who, grammar, args)
    if type(args) ~= 'table' then
        return nil, development.error(who .. [[ must be called with a table of named arguments]], grammar.throw)
    end
    if args.throw == nil then
        throw = grammar.throw
    else
        throw = args.throw
        args.throw = nil
    end

    local file = args.file
    if file == nil then
        file = grammar.file
    end
    if type(file) ~= 'string' then
        return nil,
            development.error(
                who .. [[ 'file' named argument is ']]
                    .. type(file) .. [['; it should be 'string']],
                throw)
    end
    grammar.file = file
    args.file = nil

    local line = args.line
    if line == nil then
        if type(grammar.line) ~= 'number' then
            return nil,
                development.error(
                    who .. [[ line is not numeric for grammar ']]
                        .. grammar.name
                        .. [['; a numeric line number is required]],
                    throw)
        end
        line = grammar.line + 1
    end
    grammar.line = line
    args.line = nil

    return line, file, throw
end

-- the *internal* version of the method for
-- creating *external* symbols.
local function _symbol_new(args)
    local name = args.name
    if not name then
        return nil, [[symbol must have a name]]
    end
    if type(name) ~= 'string' then
        return nil, [[symbol 'name' must be a string]]
    end
    -- decimal 055 is hyphen (or minus sign)
    -- strip initial angle bracket and whitespace
    name = name:gsub('^[<]%s*', '')
    -- strip find angle bracket and whitespace
    name = name:gsub('%s*[>]$', '')

    local charclass = '[^a-zA-Z0-9_%s\055]'
    if name:find(charclass) then
        return nil, [[symbol 'name' characters must be in ]] .. charclass
    end

    -- normalize internal whitespace
    name = name:gsub('%s+', ' ')
    if name:sub(1, 1):find('[_\055]') then
        return nil, [[symbol 'name' first character may not be '-' or '_']]
    end
    return { name = name }
end

function grammar_class.rule_new(grammar, args)
    local line, file, throw = common_args_process('rule_new()', grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    print(inspect(args))
    local lhs = args.lhs
    if not lhs then
        return nil, development.error([[rule must have a lhs]], throw)
    end
    args.lhs = nil

    for field_name,value in pairs(args) do
        return nil, development.error([[grammar_new(): unacceptable named argument ]] .. field_name, throw)
    end

    local symbol_props, error = _symbol_new{ name = lhs }
    if not symbol_props then
        return nil, development.error(error, throw)
    end

    local xsym = grammar.xsym
    local xrule = grammar.xrule
    local xprec = grammar.xprec
    xsym[#xsym+1] = symbol_props
    symbol_props.id = #xsym
    current_xprec = { level = 0 }
    xprec[#xprec+1] = current_xprec
    xrule[#xrule+1] = { lhs = symbol_props, current_xprec = current_xprec }
    xrule.id = #xrule
end

-- this will actually become a method of the config object
local function grammar_new(config, args)
    local grammar_object = {
        throw = true,
        name = '[NEW]',
        xrule = {},
        xprec = {},
        xalt = {},
        xsym = {},
    }
    local line, file, throw
        = common_args_process('grammar_new()', grammar_object, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local name = args.name
    if not name then
        return nil, development.error([[grammar must have a name]], throw)
    end
    if type(name) ~= 'string' then
        return nil, development.error([[grammar 'name' must be a string]], throw)
    end
    if name:find('[^a-zA-Z0-9_]') then
        return nil, development.error([[grammar 'name' characters must be ASCII-7 alphanumeric plus '_']], throw)
    end
    if name:byte(1) == '_' then
        return nil, development.error([[grammar 'name' first character may not be '_']], throw)
    end
    args.name = nil

    for field_name,value in pairs(args) do
        return nil, development.error([[grammar_new(): unacceptable named argument ]] .. field_name, throw)
    end

    setmetatable(grammar_object, {
            __index = grammar_class,
        })
    return grammar_object
end

return {
    new = grammar_new,
}

-- vim: expandtab shiftwidth=4:
