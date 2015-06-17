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

local function here() return -- luacheck: ignore here
    debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
end

local inspect = require "kollos.inspect" -- luacheck: ignore
local development = require "kollos.development"

-- process the named arguments common to most grammar methods
-- these are line, file and throw

-- process the named arguments common to most grammar methods
-- these are line, file and throw
local function common_args_process(who, config, throw, args)
    if type(args) ~= 'table' then
        return nil, development.error(who .. [[ must be called with a table of named arguments]], throw)
    end
    if args.throw ~= nil then throw = args.throw end
    args.throw = nil

    local file = args.file
    if file == nil then
        file = config.file
    end
    if type(file) ~= 'string' then
        return nil, development.error(who .. [[ 'file' named argument must be a string]], throw)
    end
    config.file = file
    args.file = nil

    local line = args.line
    if line == nil then
        line = config.line + 1
    else
        line = tonumber(line)
        if line == nil then
            return nil, development.error(who .. [['line' named argument must be a number]], throw)
        end
    end
    config.line = line
    args.line = nil

    return line, file, throw
end

-- this will actually become a method of the config object
local function _config_grammar_new(config, args)
    local line, file, throw = common_args_process('grammar_new()', config, config.throw, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local name = args.name
    if not name then
        development.error([[grammar must have a name]], throw)
    end
    if type(name) ~= 'string' then
        development.error([[grammar 'name' must be a string]], throw)
    end
    if name:find('[^a-zA-Z0-9_]') then
        development.error([[grammar 'name' characters must be ASCII-7 alphanumeric plus '_']], throw)
    end
    if name:byte(1) == '_' then
        development.error([[grammar 'name' first character may not be '_']], throw)
    end
    args.name = nil

    for field_name,value in pairs(args) do
        development.error([[grammar_new(): unacceptable named argument ]] .. field_name, throw)
    end

    return {
        line = line,
        file = file,
        config = config,
        xrule = {},
        xprec = {},
        xalt = {},
        xsym = {},
    }
end

local function rule_new(grammar, args)
    if type(args) ~= 'table' then
        development.error([[rule_new must be called with a table of named arguments]], grammar.throw)
    end
    local line, file, throw = common_args_process(grammar.config, args)
    -- if line is nil, the file is an error object
    if line == nil then return line, file end
end

return {
    alternative = alternative,
    _config_grammar_new = _config_grammar_new,
}

-- vim: expandtab shiftwidth=4:
