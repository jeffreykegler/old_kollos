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
local kollos_c = require "kollos_c"
local luif_err_development = kollos_c.error_code_by_name['LUIF_ERR_DEVELOPMENT']

local function here() return -- luacheck: ignore here
    debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
end

local grammar_class = { }

function grammar_class.file_set(grammar, file_name)
    grammar.file = file_name or debug.getinfo(2,'S').source
end

function grammar_class.line_set(grammar, line_number)
    grammar.line = line_number or debug.getinfo(2, 'l').currentline
end

-- note that a throw_flag of nil sets throw to *true*
function grammar_class.throw_set(grammar, throw_flag)
    local throw = true -- default is true
    if throw_flag == false then throw = false end
    grammar.throw = throw
    return throw
end

-- process the named arguments common to most grammar methods
-- these are line, file and throw
local function common_args_process(who, grammar, args)
    if type(args) ~= 'table' then
        return nil, grammar:development_error(who .. [[ must be called with a table of named arguments]])
    end

    local file = args.file
    if file == nil then
        file = grammar.file
    end
    if type(file) ~= 'string' then
        return nil,
        grammar:development_error(
            who .. [[ 'file' named argument is ']]
            .. type(file)
            .. [['; it should be 'string']],
            grammar.throw)
    end
    grammar.file = file
    args.file = nil

    local line = args.line
    if line == nil then
        if type(grammar.line) ~= 'number' then
            return nil,
            grammar:development_error(
                who .. [[ line is not numeric for grammar ']]
                .. grammar.name
                .. [['; a numeric line number is required]],
                grammar.throw)
        end
        line = grammar.line + 1
    end
    grammar.line = line
    args.line = nil

    return line, file
end

-- the *internal* version of the method for
-- creating *external* symbols.
local function _symbol_new(args)
    local name = args.name
    if not name then
        return nil, [[symbol must have a name]]
    end
    if type(name) ~= 'string' then
        return nil, [[symbol 'name' is type ']]
        .. type(name)
        .. [['; it must be a string]]
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
    local my_name = 'rule_new()'
    local line, file = common_args_process(my_name, grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local lhs = args[1]
    args[1] = nil
    if not lhs then
        return nil, grammar:development_error([[rule must have a lhs]])
    end

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar:development_error(my_name .. [[: unacceptable named argument ]] .. field_name)
    end

    local symbol_props, symbol_error = _symbol_new{ name = lhs }
    if not symbol_props then
        return nil, grammar:development_error(symbol_error)
    end

    local xsym = grammar.xsym
    local xrule = grammar.xrule
    local xprec = grammar.xprec
    xsym[#xsym+1] = symbol_props
    symbol_props.id = #xsym
    local new_xrule = { lhs = symbol_props }
    xrule[#xrule+1] = new_xrule
    new_xrule.id = #xrule
    local current_xprec = { level = 0, xrule = new_xrule }
    xprec[#xprec+1] = current_xprec
    grammar.current_xprec = current_xprec
end

function grammar_class.precedence_new(grammar, args)
    local my_name = 'precedence_new()'
    local line, file = common_args_process(my_name, grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar:development_error(my_name .. [[: unacceptable named argument ]] .. field_name)
    end

    local xrule = grammar.xrule
    if #xrule < 1 then
        return nil, grammar:development_error(my_name .. [[ called, but no current rule]])
    end

    local current_xrule = xrule[#xrule]
    local last_xprec = grammar.current_xprec
    local new_level = last_xprec.level + 1
    local new_xprec = { level = new_level, xrule = current_xrule }
    local xprec = grammar.xprec
    xprec[#xprec+1] = new_xprec
end

local function subalternative_new(grammar, subalternative)

    -- use name of caller
    local my_name = 'alternative_new()'

    local xsym = grammar.xsym
    local new_rhs = {}

    for rhs_ix = 1, table.maxn(subalternative) do
        local rhs_instance = subalternative[rhs_ix]
        local new_rhs_instance
        if type(rhs_instance) == 'table' then
            new_rhs_instance = subalternative(grammar, rhs_instance)
        else
            local error_string
            new_rhs_instance, error_string = _symbol_new{ name = rhs_instance }
            if not new_rhs_instance then
                return nil,
                grammar:development_error(
                    [[Problem with rule rhs item #]] .. rhs_ix .. ' ' .. error_string,
                    grammar.throw)
            end
            xsym[#xsym+1] = new_rhs_instance
            new_rhs_instance.id = #xsym
        end
        new_rhs[#new_rhs+1] = new_rhs_instance
    end

    local new_subalternative = { rhs = new_rhs }
    if subalternative.exp then
        new_subalternative.exp = subalternative.exp
        subalternative.exp = nil
    end

    for field_name,_ in pairs(subalternative) do
        if type(field_name) ~= 'number' then
        return nil, grammar:development_error(my_name .. [[: unacceptable named argument ]] .. field_name)
        end
    end

    return new_subalternative

end

function grammar_class.alternative_new(grammar, args)
    local my_name = 'alternative_new()'
    local line, file = common_args_process(my_name, grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local new_alternative, error_object = subalternative_new(grammar, args)
    if not new_alternative then
        -- subroutine did not throw error, so we do not
        return nil, error_object
    end
    new_alternative.prec = grammar.current_xprec

    local xalt = grammar.xalt
    xalt[#xalt+1] = new_alternative

end

function grammar_class.development_error(grammar, string)
    local error_object
    = kollos_c.error_new{
        code = luif_err_development,
        string =
        "Grammar error at line "
        .. grammar.line
        ..  " of "
        .. grammar.file
        .. ":\n    "
        .. string,
        file = grammar.file,
        line = grammar.line
    }
    if grammar.throw then error(tostring(error_object)) end
    return error_object
end

-- this will actually become a method of the config object
local function grammar_new(config, args) -- luacheck: ignore config
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
        return nil, grammar_object:development_error([[grammar must have a name]])
    end
    if type(name) ~= 'string' then
        return nil, grammar_object:development_error([[grammar 'name' must be a string]], throw)
    end
    if name:find('[^a-zA-Z0-9_]') then
        return nil, grammar_object:development_error(
            [[grammar 'name' characters must be ASCII-7 alphanumeric plus '_']],
            throw)
    end
    if name:byte(1) == '_' then
        return nil, grammar_object:development_error([[grammar 'name' first character may not be '_']], throw)
    end
    args.name = nil
    grammar_object.name = name

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar_object:development_error([[grammar_new(): unacceptable named argument ]] .. field_name, throw)
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
