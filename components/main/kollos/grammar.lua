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
local matrix = require "kollos.matrix"

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
-- returns the previous throw value
function grammar_class.throw_set(grammar, throw_flag)
    local throw = true -- default is true
    local old_throw_value = grammar.throw
    if throw_flag == false then throw = false end
    grammar.throw = throw
    return old_throw_value
end

local function development_error_stringize(error_object)
    return
    "Grammar error at line "
    .. error_object.line
    .. " of "
    .. error_object.file
    .. ":\n "
    .. error_object.string
end

function grammar_class.development_error(grammar, string, file, line)
    local error_object
    = kollos_c.error_new{
        stringize = development_error_stringize,
        code = luif_err_development,
        string = string,
        file = file or grammar.file,
        line = line or grammar.line,
    }
    if grammar.throw then error(tostring(error_object)) end
    return error_object
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
            .. [['; it should be 'string']]
            )
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
                .. [['; a numeric line number is required]]
            )
        end
        line = grammar.line + 1
    end
    grammar.line = line
    args.line = nil

    return line, file
end

-- the *internal* version of the method for
-- creating *external* symbols.
local function _symbol_new(grammar, args)
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

    local xsym_by_name = grammar.xsym_by_name
    local props = xsym_by_name[name]
    if props then return props end

    props = { name = name, type = 'xsym', lhs_xrules = {} }
    xsym_by_name[name] = props

    local xsym = grammar.xsym
    xsym[#xsym+1] = props
    props.id = #xsym

    return props
end

-- create a RHS instance of type 'xstring'
-- throw is always set by the caller, which catches
-- any error
function grammar_class.string(grammar, string)
    if type(string) ~= 'string' then
        grammar:development_error(
         [[string in alternate is type ']]
        .. type(string)
        .. [['; it must be a string]])
    end
    return {
        string = string,
        type = 'xstring',
        productive = true,
        nullable = false
        }
end

-- create a RHS instance of type 'xstring'
-- throw is always set by the caller, which catches
-- any error
function grammar_class.cc(grammar, cc)
    if type(cc) ~= 'string' then
        grammar:development_error(
        [[charclass in alternate is type ']]
        .. type(cc)
        .. [['; it must be a string]])
    end
    if not cc:match('^%[.+%]$') then
        grammar:development_error(
         [[charclass in alternate must be in square brackets]])
    end

    return {
        cc = cc,
        type = 'xcc',
        productive = true,
        nullable = false
    }
end

function grammar_class.rule_new(grammar, args)
    local who = 'rule_new()'
    local line, file = common_args_process(who, grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local lhs = args[1]
    args[1] = nil
    if not lhs then
        return nil, grammar:development_error([[rule must have a lhs]])
    end

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar:development_error(who .. [[: unacceptable named argument ]] .. field_name)
    end

    local symbol_props, symbol_error = _symbol_new(grammar, { name = lhs })
    if not symbol_props then
        return nil, grammar:development_error(symbol_error)
    end

    local xrule = grammar.xrule
    local xprec = grammar.xprec
    local new_xrule = { lhs = symbol_props }
    xrule[#xrule+1] = new_xrule
    new_xrule.id = #xrule

    local xrules_of_lhs = symbol_props.lhs_xrules
    xrules_of_lhs[#xrules_of_lhs+1] = new_xrule

    local current_xprec = { level = 0, xrule = new_xrule }
    xprec[#xprec+1] = current_xprec
    grammar.current_xprec = current_xprec
end

function grammar_class.precedence_new(grammar, args)
    local who = 'precedence_new()'
    local line, file = common_args_process(who, grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar:development_error(who .. [[: unacceptable named argument ]] .. field_name)
    end

    local xrule = grammar.xrule
    if #xrule < 1 then
        return nil, grammar:development_error(who .. [[ called, but no current rule]])
    end

    local current_xrule = xrule[#xrule]
    local last_xprec = grammar.current_xprec
    local new_level = last_xprec.level + 1
    local new_xprec = { level = new_level, xrule = current_xrule }
    local xprec = grammar.xprec
    xprec[#xprec+1] = new_xprec
end

-- throw is always set for this method
-- the error is caught by the caller and re-thrown or not,
-- as needed
local function subalternative_new(grammar, subalternative)

    -- use name of caller
    local who = 'alternative_new()'

    local new_rhs = {}

    local current_xprec = grammar.current_xprec
    local current_xrule = current_xprec.xrule
    local xlhs_by_rhs = grammar.xlhs_by_rhs

    for rhs_ix = 1, table.maxn(subalternative) do
        local rhs_instance = subalternative[rhs_ix]
        local new_rhs_instance
        if type(rhs_instance) == 'table' then
            local instance_type = rhs_instance.type
            if not instance_type then
                new_rhs_instance = subalternative_new(grammar, rhs_instance)
            elseif instance_type == 'xstring' then
                new_rhs_instance = rhs_instance
            elseif instance_type == 'xcc' then
                new_rhs_instance = rhs_instance
            else
                grammar:development_error(
                    [[Problem with rule rhs item #]] .. rhs_ix
                    .. ' unexpected type: ' .. instance_type
                )
            end
        else
            local error_string
            print(inspect(rhs_instance))
            new_rhs_instance, error_string = _symbol_new(grammar, { name = rhs_instance })
            if not new_rhs_instance then
                -- using return statements even for thrown errors is the
                -- standard idiom, but in this case, I think it is clearer
                -- without the return
                grammar:development_error(
                    [[Problem with rule rhs item #]] .. rhs_ix .. ' ' .. error_string
                )
            end
            xlhs_by_rhs[new_rhs_instance.id] = current_xrule.lhs.id
        end
        new_rhs[#new_rhs+1] = new_rhs_instance
    end

    local new_subalternative = { rhs = new_rhs, type = 'xalt' }
    local action = subalternative.action
    if action then
        if type(action) ~= 'function' then
            grammar:development_error(
                who
                .. [[: action must be of type function; actual type is ']]
                .. type(action)
                .. [[']]
            )
        end
        new_subalternative.action = action
        subalternative.action = nil
    end

    local min = subalternative.min
    local max = subalternative.max
    if min ~= nil and type(min) ~= 'number' then
        grammar:development_error(
            who
            .. [[: min must be of type 'number'; actual type is ']]
            .. type(min)
            .. [[']]
        )
    end
    if max ~= nil and type(max) ~= 'number' then
        grammar:development_error(
            who
            .. [[: max must be of type 'number'; actual type is ']]
            .. type(min)
            .. [[']]
        )
    end
    if min == nil then
        min = 1
        if max == nil then max = 1 end
    elseif max == nil then max = -1 end

    new_subalternative.min = min subalternative.min = nil
    new_subalternative.max = max subalternative.max = nil

    if min == 0 then
        new_subalternative.productive = true
        new_subalternative.nullable = true
    end

    for field_name,_ in pairs(subalternative) do
        if type(field_name) ~= 'number' then
            grammar:development_error(who .. [[: unacceptable named argument ]] .. field_name)
        end
    end

    return new_subalternative

end

function grammar_class.alternative_new(grammar, args)
    local who = 'alternative_new()'
    local line, file = common_args_process(who, grammar, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local old_throw_value = grammar:throw_set(true)
    local ok, new_alternative = pcall(function () return subalternative_new(grammar, args) end)
    -- if ok is false, then new_alterative is actually an error object
    if not ok then
        if old_throw_value then error(new_alternative)
        else return nil, new_alternative end
    end
    grammar:throw_set(old_throw_value)
    new_alternative.prec = grammar.current_xprec

    local xalt = grammar.xalt
    xalt[#xalt+1] = new_alternative

end

--[[

The RHS transitive closure is Jeffrey's coinage, to describe
a kind of property useful in Marpa.

Let `P` be a symbol property.
We will write `P(sym)` if symbol `sym`
has property P.

We say that the symbol property holds of a rule `r`,
or `P(r)`,
if `r` is of the form
`LHS ::= RHS`,
where `RHS` is is a series
of zero or more RHS symbols,
and `P(Rsym)` for every `Rsym` in `RHS`.

A property `P` is *RHS transitive* if and only if
when `r = LHS ::= RHS` and `P(r)`,
then `P(LHS)`.

Note that the definition of a RHS transitive property implies that
every LHS of an empty rule hss that property.
This is because, in the case of an empty rule, it is vacuously
true that all the RHS symbols have the RHS transitive property.

Also note the definition only describes the transitivity of the
property, not which symbols have it.
That is, while `P` is a RHS transitive property,
a symbol must have property `P`
if it appears on the LHS
of a rule with property `P`.
the converse is not necessarily true:
A symbol may have property `P`
even if it never appears on the LHS
of a rule with property `P`.

In Marpa, "being productive" and
"being nullable" are RHS transitive properties
--]]

local function rhs_transitive_closure(grammar, property)
    local worklist = {}
    for _, symbol_props in pairs(grammar.xsym) do
        if symbol_props[property] == true then
            table.insert(worklist, symbol_props)
        end
    end

    while true do
        local symbol_props = table.remove(worklist)
        if not symbol_props then break end
        for _,xrule_props in pairs(symbol_props.lhs_xrules) do
            -- print("Start of testing rule for property ", property);
            local lh_sym_props = xrule_props.lhs
            if lh_sym_props[property] ~= true then
                -- print("Rule LHS: ", lh_sym_props.name)
                local rule_has_property = true -- default to true
                for _,rhs_instance in pairs(xrule_props.rhs) do
                    if not rhs_instance[property] then
                        rule_has_property = false
                        break
                    end
                end
                -- print("End of testing rule, result = ", rule_has_property);
                if rule_has_property then
                    -- we don't get here if the LHS symbol already
                    -- has the property, so no symbol is ever
                    -- put on worklist twice
                    lh_sym_props[property] = true
                    -- print("Setting property ", property, " true for symbol ", lh_sym_props.name, " from ", symbol_props.name)
                    table.insert(worklist, lh_sym_props)
                end
            end

        end
    end
end

function grammar_class.compile(grammar, args)
    local who = 'grammar.compile()'
    common_args_process(who, grammar, args)
    local at_top = false
    local at_bottom = false
    local start_symbol = nil
    if args.seamless then
         at_top = true
         at_bottom = true
         local start_symbol_name = args.seamless
         args.seamless = nil
         start_symbol
             = grammar.xsym_by_name[start_symbol_name]
         if not start_symbol then
            return nil, grammar:development_error(
                who
                .. [[ value of 'seamless' named argument must be the start symbol]]
                )
         end
    elseif args.start then
        at_top = true
        local start_symbol_name = args.start
        args.start = nil
        return nil, grammar:development_error(
            who
            .. [[ 'start' named argument not yet implemented]]
            )
    elseif args.lexer then
        at_bottom = true
        args.lexer = nil
        return nil, grammar:development_error(
            who
            .. [[ 'lexer' named argument not yet implemented]]
            )
    else
        return nil, grammar:development_error(
            who
            .. [[ must have 'seamless', 'start' or 'lexer' named argument]]
            )
    end

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar:development_error(who .. [[: unacceptable named argument ]] .. field_name)
    end

    local xsym = grammar.xsym
    local matrix_size = #xsym+2

    -- Not the real augment symbol, but a temporary that
    -- "fakes" it
    local augment_symbol_id = #xsym + 1

    local terminal_sink_id = #xsym + 2
    local reach_matrix = matrix.init(matrix_size)
    if at_top then
        matrix.bit_set(reach_matrix, augment_symbol_id, start_symbol.id)
    end

    local xlhs_by_rhs = grammar.xlhs_by_rhs
    for symbol_id = 1,#xsym do
        local symbol_props = xsym[symbol_id]
        -- every symbol reaches itself
        matrix.bit_set(reach_matrix, symbol_id, symbol_id)
        for _,lhs_id in pairs(xlhs_by_rhs) do
            matrix.bit_set(reach_matrix, lhs_id, symbol_id)
        end

        if #symbol_props.lhs_xrules <= 0 then
            matrix.bit_set(reach_matrix, symbol_id, terminal_sink_id)
            symbol_props.productive = true
        end

        if symbol_props.lexeme then
            matrix.bit_set(reach_matrix, augment_symbol_id, symbol_id)
        end
    end

    matrix.transitive_closure(reach_matrix)

    rhs_transitive_closure(grammar, 'nullable')
    rhs_transitive_closure(grammar, 'productive')

    -- Hygene, to do next
    -- LHS of sequence rule is unique
    -- LHS of precedenced rule is unique

    -- Hygene, to do at some point
    -- Start symbol is productive and a LHS
    -- All symbols are accessible from start symbol
    --    Later, make it so some symbols can be set to be "inaccessilbe ok"
    -- Lowest precedence must have no precedenced symbol

end

-- this will actually become a method of the config object
local function grammar_new(config, args) -- luacheck: ignore config
    local who = 'grammar_new()'
    local grammar_object = {
        throw = true,
        name = '[NEW]',
        xrule = {},
        xprec = {},
        xalt = {},

        xsym = {},
        xsym_by_name = {},

        -- maps LHS id to RHS id
        xlhs_by_rhs = {},
    }
    setmetatable(grammar_object, {
            __index = grammar_class,
        })

    if not args.file then
        return nil, grammar_object:development_error(who .. [[ requires 'file' named argument]],
     debug.getinfo(2,'S').source,
     debug.getinfo(2, 'l').currentline) end

    if not args.line then
        return nil, grammar_object:development_error(who .. [[ requires 'line' named argument]],
     debug.getinfo(2,'S').source,
     debug.getinfo(2, 'l').currentline) end

    local line, file
    = common_args_process('grammar_new()', grammar_object, args)
    -- if line is nil, the "file" is actually an error object
    if line == nil then return line, file end

    local name = args.name
    if not name then
        return nil, grammar_object:development_error([[grammar must have a name]])
    end
    if type(name) ~= 'string' then
        return nil, grammar_object:development_error([[grammar 'name' must be a string]])
    end
    if name:find('[^a-zA-Z0-9_]') then
        return nil, grammar_object:development_error(
            [[grammar 'name' characters must be ASCII-7 alphanumeric plus '_']]
        )
    end
    if name:byte(1) == '_' then
        return nil, grammar_object:development_error([[grammar 'name' first character may not be '_']])
    end
    args.name = nil
    grammar_object.name = name

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar_object:development_error([[grammar_new(): unacceptable named argument ]] .. field_name)
    end

    return grammar_object
end

grammar_class.new = grammar_new
return grammar_class

-- vim: expandtab shiftwidth=4:
