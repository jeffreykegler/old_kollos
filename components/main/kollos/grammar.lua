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

-- this will actually become a method of the config object
local function _config_grammar_new(config, args)
    local file = config.file
    local line
    local name
    local throw = config.throw
    if type(args) == 'table' then
        if args.throw ~= nil then throw = args.throw end
        for field_name,value in pairs(args) do
            if field_name == 'file' then
                if type(value) ~= 'string' then
                    development.error([[grammar 'file' named argument must be a string]], throw)
                end
                file = value
            elseif field_name == 'line' then
                local arg_line = tonumber(value)
                if arg_line == nil then
                    development.error([[grammar 'line' named argument must be a number]], throw)
                end
                line = arg_line
            elseif field_name == 'name' then
                -- We check if value is OK below, not here
                name = value
            elseif field_name == 'throw' then -- anything is OK
            else
                development.error([[grammar_new(): unacceptable named argument ]] .. field_name, throw)
            end
        end
    else
        name = args
        args = {}
    end
    if not file then
        development.error([[grammar must a 'file' set]], throw)
    end
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
    if not line then
        line = config.line + 1
        config.line = line
    end
    return {
        line = line,
        file = file,
        config = config,
        xrule = {},
        xsym = {},
        xalt = {},
        wsym = {},
        wrule = {},
    }
end

local function alternative(grammar, args)
end

return {
    alternative = alternative,
}

-- vim: expandtab shiftwidth=4:
