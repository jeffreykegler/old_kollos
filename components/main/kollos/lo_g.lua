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

--[[

The Kollos low level grammar logic

--]]

-- luacheck: std lua51
-- luacheck: globals bit

local function here() return -- luacheck: ignore here
    debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
end

local inspect = require "kollos.inspect" -- luacheck: ignore

-- eventually most of this code becomes part of kollos
-- for now we bring the already written part in as a
-- module
local wrap = require "kollos.wrap"
local kollos_c = require "kollos_c"
local matrix = require "kollos.matrix"

local luif_err_none -- luacheck: ignore
= kollos_c.error_code_by_name['LUIF_ERR_NONE'] -- luacheck: ignore
local luif_err_unexpected_token -- luacheck: ignore
= kollos_c.error_code_by_name['LUIF_ERR_UNEXPECTED_TOKEN_ID'] -- luacheck: ignore
local luif_err_duplicate_rule -- luacheck: ignore
= kollos_c.error_code_by_name['LUIF_ERR_DUPLICATE_RULE'] -- luacheck: ignore

-- Create a string of bytes with values from 0 to 255
-- for use in creating a table from byte to charclass
local all_255_chars -- predeclare
do
    local temp_table = {}
    for byte_value = 0, 255 do
        temp_table[byte_value+1] = string.char(byte_value)
    end
    all_255_chars = table.concat(temp_table)
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
every LHS of an empty rule has that property.
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

local function rhs_transitive_closure(symbol_by_name, property)
    local worklist = {}
    for _, symbol_props in pairs(symbol_by_name) do
        if symbol_props[property] == true then
            table.insert(worklist, symbol_props)
        end
    end

    while true do
        local symbol_props = table.remove(worklist)
        if not symbol_props then break end
        for _,irule_props in pairs(symbol_props.irule_by_rhs) do
            -- print("Start of testing rule for propetry ", property);
            local lh_sym_props = symbol_by_name[irule_props.lhs]
            if lh_sym_props[property] ~= true then
                -- print("Rule LHS: ", lh_sym_props.name)
                local rule_has_property = true -- default to true
                for _,rhs_name in pairs(irule_props.rhs) do
                    local rh_sym_props = symbol_by_name[rhs_name]
                    -- print("Rule RHS symbol: ", rh_sym_props.name)
                    if not rh_sym_props[property] then
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

-- We leave the KIR as is, and work with
-- intermediate databases

-- currently grammar is unused, but someday we may need the grammar name
local function do_grammar(grammar, properties) -- luacheck: ignore grammar

    -- I expect to handle cycles eventually, so this logic must be
    -- cycle-safe.

    local g_is_structural = properties.structural

    -- while developing we do all the "hygenic" tests to
    -- make sure the KIR is sane

    -- In production, the KIR will be produced by Kollos's
    -- own logic, so this boolean should only be set
    -- for debugging
    local hygenic = true -- luacheck: ignore hygenic

    -- Next we start the database of intermediate KLOL symbols
    local symbol_by_name = {} -- create an symbol to integer index
    local symbol_by_id = {} -- create an integer to symbol index
    local klol_rules = {} -- an array of the KLOL rules

    local function klol_symbol_new(props)
        props.lhs_by_rhs = {}
        props.rhs_by_lhs = {}
        props.irule_by_rhs = {}
        props.irule_by_lhs = {}
        if symbol_by_name[props.name] then
            error('Internal error: Attempt to create duplicate symbol : "' .. props.name .. '"')
        end
        symbol_by_name[props.name] = props
        local symbol_id = #symbol_by_id+1
        props.id = symbol_id
        symbol_by_id[symbol_id] = props
        return props
    end

    local function klol_rule_new(rule_props)
        klol_rules[ #klol_rules + 1 ] = rule_props

        --[[ COMMENTED OUT
        -- print(debug.getinfo(2,'S').source, debug.getinfo(2, 'l').currentline)
        local rule_desc = rule_props.lhs.symbol.name .. ' ::='
        for dot_ix = 1,#rule_props.rhs do
            rule_desc = rule_desc .. ' ' .. rule_props.rhs[dot_ix].symbol.name
        end
        print("KLOL rule:", rule_desc)
        --]]

    end

    local top_symbol -- will be RHS of augmented start rule

    -- a pseudo-symbol "reached" by all terminals
    -- for convenience in determinal if a symbol reaches any terminal
    local sink_terminal = klol_symbol_new{ name = '?sink_terminal', productive = true}
    local augment_symbol = klol_symbol_new{ name = '?augment'}

    if (not g_is_structural) then
        top_symbol = klol_symbol_new{ name = '?top'}
    end

    for symbol_name,isym_props in pairs(properties.isym) do
        local symbol_props = klol_symbol_new{ isym_props = isym_props, name = symbol_name,
            is_khil = true -- true if a KHIL symbol
        }
        if (isym_props.charclass) then
            symbol_props.productive = true;
            symbol_props.terminal = true;
            symbol_props.nullable = false;
        end
        if (isym_props.lexeme) then
            if (g_is_structural) then
                error('Internal error: Lexeme "' .. symbol_name .. '" declared in structural grammar')
            end
            symbol_props.lexeme = true;
        end
        if (isym_props.start) then
            if (not g_is_structural) then
                error('Internal error: Start symbol "' .. symbol_name '" declared in lexical grammar')
            end
            top_symbol = symbol_props
        end
    end

    if (not top_symbol) then
        error('Internal error: No start symbol found in grammar')
    end

    for rule_ix,irule_props in ipairs(properties.irule) do
        local lhs_name = irule_props.lhs
        local lhs_props = symbol_by_name[lhs_name]
        if (not lhs_props) then
            error("Internal error: Symbol " .. lhs_name .. " is lhs of irule but not in isym")
        end
        lhs_props.irule_by_lhs[#lhs_props.irule_by_lhs+1] = irule_props
        local rhs_names = irule_props.rhs
        if (#rhs_names == 0) then
            lhs_props.nullable = true
            lhs_props.productive = true
        end
        for _,rhs_name in ipairs(rhs_names) do
            local rhs_props = symbol_by_name[rhs_name]
            if (not rhs_props) then
                error("Internal error: Symbol " .. rhs_name .. " is rhs of irule but not in isym")
            end

            -- built different from irule_by_lhs, because symbols
            -- may occur several times on the RHS
            rhs_props.irule_by_rhs[rule_ix] = irule_props

            rhs_props.lhs_by_rhs[lhs_name] = lhs_props
            lhs_props.rhs_by_lhs[rhs_name] = rhs_props
        end
    end

    for symbol_name,symbol_props in pairs(symbol_by_name) do
        if (not symbol_props.lhs_by_rhs and not symbol_props.rhs_by_lhs and symbol_props.is_khil) then
            error("Internal error: Symbol " .. symbol_name .. " is in isym but not in irule")
        end
        if (symbol_props.charclass and #symbol_props.irule_by_lhs > 0) then
            error("Internal error: Symbol " .. symbol_name .. " has charclass but is on LHS of irule")
        end
    end

    -- now set up the reach matrix
    local reach_matrix = matrix.init(#symbol_by_id)
    if not g_is_structural then
        matrix.bit_set(reach_matrix, augment_symbol.id, top_symbol.id)
    end

    for symbol_id = 1,#symbol_by_id do
        local symbol_props = symbol_by_id[symbol_id]
        local isym_props = symbol_props.isym_props
        -- every symbol reaches itself
        matrix.bit_set(reach_matrix, symbol_id, symbol_id)
        if isym_props then
            for _,lhs_props in pairs(symbol_props.lhs_by_rhs) do
                matrix.bit_set(reach_matrix, lhs_props.id, symbol_id)
            end
            if symbol_props.terminal then
                matrix.bit_set(reach_matrix, symbol_id, sink_terminal.id)
            end
            if symbol_props.lexeme then
                matrix.bit_set(reach_matrix, top_symbol.id, symbol_id)
            end
        end
    end

    matrix.transitive_closure(reach_matrix)

    rhs_transitive_closure(symbol_by_name, 'nullable')
    rhs_transitive_closure(symbol_by_name, 'productive')

    --[[
    I don't want to get into adding the KLOL rules until later, so for
    a lexical grammar we mark the top symbol productive to silence the
    error message. We will test that all the lexemes were productive,
    and that is sufficient.
    --]]

    if not g_is_structural then
        top_symbol.productive = true
    end

    for symbol_id = 1,#symbol_by_id do
        local symbol_props = symbol_by_id[symbol_id]
        if not matrix.bit_test(reach_matrix, augment_symbol.id, symbol_id) then
            print("Symbol " .. symbol_props.name .. " is not accessible")
        end
        if not symbol_props.productive then
            print("Symbol " .. symbol_props.name .. " is not productive")
        end
        if symbol_props.nullable and
        not matrix.bit_test(reach_matrix, symbol_id, sink_terminal.id)
        then symbol_props.nulling = true end
        if symbol_props.lexeme then
            if symbol_props.nulling then
                print("Symbol " .. symbol_props.name .. " is a nulling lexeme -- A FATAL ERROR")
            end
            if not symbol_props.productive then
                print("Symbol " .. symbol_props.name .. " is an unproductive lexeme -- A FATAL ERROR")
            end
        end

    end

    --[[ COMMENTED OUT
    for from_symbol_id,from_symbol_props in ipairs(symbol_by_id) do
        for to_symbol_id,to_symbol_props in ipairs(symbol_by_id) do
            if matrix.bit_test(reach_matrix, from_symbol_id, to_symbol_id) then
                print( from_symbol_props.name, "reaches", to_symbol_props.name)
            end
        end
    end
    --]]

    if top_symbol.nulling then
        print("Start symbol " .. top_symbol.name .. " is nulling -- NOT YET IMPLEMENTED SPECIAL CASE")
    end

    local unique_number = 1 -- used in forming names of symbols

    for _,irule_props in ipairs(properties.irule) do
        local lh_sym_name = irule_props.lhs
        local lh_sym_props = symbol_by_name[lh_sym_name]
        local rhs_names = irule_props.rhs
        local instance_stack = {}

        -- print(here())
        -- print('LHS:', lh_sym_name)

        for dot_ix,rhs_name in ipairs(rhs_names) do
            local rh_sym_props = symbol_by_name[rhs_name]

            -- print('RHS:', rhs_name)

            -- skip nulling symbols
            -- the span and dot info is a prototype of the kind
            -- of information about location in the xrule that
            -- I will need to reconstruct the external rule,
            -- and to do the semantics
            if not rh_sym_props.nulling then
                local instance = {
                    kir_dot = dot_ix,
                    symbol = rh_sym_props
                }
                instance_stack[#instance_stack + 1] = instance
            end
        end

        -- print(here())

        local start_of_nullable_suffix = #instance_stack+1
        for i=#instance_stack,1,-1 do
            if not instance_stack[i].symbol.nullable then break end
            start_of_nullable_suffix = i
        end

        -- first LHS is that of the original rule
        local lh_sides = {}
        lh_sides[1] = {
            irule = irule_props,
            kir_dot = 1,
            symbol = lh_sym_props
        }
        -- we need a new LHS for the length of the original
        -- RHS, less 2
        for instance_ix=2,#instance_stack-1 do
            local new_lhs_name =
            irule_props.lhs .. '?' .. unique_number .. '@' .. instance_ix
            unique_number = unique_number + 1
            local new_lh_symbol = klol_symbol_new{ name = new_lhs_name }
            lh_sides[#lh_sides+1] = {
                irule = irule_props,
                kir_dot = instance_stack[instance_ix].kir_dot,
                symbol = new_lh_symbol
            }
        end

        -- if the rule is empty (zero length) it will
        -- "fall through" the following logic
        local next_rule_base = 1
        while #instance_stack - next_rule_base >= 2 do
            local new_rule_lhs = lh_sides[next_rule_base]
            local rhs_instance_1 = instance_stack[next_rule_base]
            local next_lhs = lh_sides[next_rule_base+1]
            klol_rule_new{
                lhs = new_rule_lhs,
                rhs = { rhs_instance_1, next_lhs }
            }
            if start_of_nullable_suffix <= next_rule_base+1 then
                klol_rule_new{
                    lhs = new_rule_lhs,
                    rhs = { rhs_instance_1 }
                }
            end
            if rhs_instance_1.symbol.nullable then
                klol_rule_new{
                    lhs = new_rule_lhs,
                    rhs = { next_lhs }
                }
            end
            next_rule_base = next_rule_base+1
        end

        -- print(here())

        -- If two RHS instances remain ...
        if #instance_stack - next_rule_base == 1 then
            local new_rule_lhs = lh_sides[next_rule_base]
            local rhs_instance_1 = instance_stack[next_rule_base]
            local rhs_instance_2 = instance_stack[next_rule_base+1]
            -- print(here())
            klol_rule_new{
                lhs = new_rule_lhs,
                rhs = { rhs_instance_1, rhs_instance_2 }
            }

            -- order by symbol used on the RHS,
            -- not by symbol tested so that
            -- the output is easier to read
            -- print(here())
            if rhs_instance_2.symbol.nullable then
                klol_rule_new{
                    lhs = new_rule_lhs,
                    rhs = { rhs_instance_1 }
                }
            end

            -- print(here())
            if rhs_instance_1.symbol.nullable then
                klol_rule_new{
                    lhs = new_rule_lhs,
                    rhs = { rhs_instance_2 }
                }
            end
        end

        -- print(here())
        -- If one RHS instance remains ...
        if #instance_stack - next_rule_base == 0 then
            local new_rule_lhs = lh_sides[next_rule_base]
            local rhs_instance_1 = instance_stack[next_rule_base]
            klol_rule_new{
                lhs = new_rule_lhs, rhs = { rhs_instance_1 }
            }
        end

    end -- of for _,irule_props in ipairs(properties.irule)

    -- now create additional rules ...
    -- first the augment rule
    -- do not yet know what to do about location information
    -- for instances
    klol_rule_new{
        lhs = { symbol = augment_symbol },
        rhs = { { symbol = top_symbol } }
    }

    if not g_is_structural then

        -- and now deal with the lexemes ...
        -- which will only be present in a lexical grammar ...
        -- we need to create the "lexeme prefix symbols"
        -- and to add rules which connect them to the
        -- top symbol
        for symbol_id = 1,#symbol_by_id do
            local symbol_props = symbol_by_id[symbol_id]
            if symbol_props.lexeme then
                -- print("Creating prelex for ", symbol_props.name)
                local lexeme_prefix = klol_symbol_new{ name = symbol_props.name .. '?prelex' }
                symbol_props.lexeme_prefix = lexeme_prefix
                klol_rule_new{
                    lhs = { symbol = top_symbol },
                    rhs = {
                        { symbol = lexeme_prefix },
                        { symbol = symbol_props },
                    }
                }
            end
        end

    end -- if not g_is_structural

    local g = wrap.grammar()
    local symbol_by_libmarpa_id = {}
    for symbol_id = 1,#symbol_by_id do
        local symbol_props = symbol_by_id[symbol_id]
        local libmarpa_id = g:symbol_new()
        if symbol_props.lexeme then
             -- print("Creating completion event for ", libmarpa_id, symbol_props.name)
             g:symbol_is_completion_event_set(libmarpa_id, 1)
        end
        symbol_by_libmarpa_id[libmarpa_id] = symbol_props
        symbol_props.libmarpa_id = libmarpa_id
    end

    local rule_by_libmarpa_id = {}
    g.throw = false
    for _,rule_props in pairs(klol_rules) do
        local lhs_libmarpa_id = rule_props.lhs.symbol.libmarpa_id
        local rhs1_libmarpa_id = rule_props.rhs[1].symbol.libmarpa_id
        local rhs2_libmarpa_id = rule_props.rhs[2] and
        rule_props.rhs[2].symbol.libmarpa_id
        local libmarpa_rule_id = g:rule_new( lhs_libmarpa_id,
            rhs1_libmarpa_id, rhs2_libmarpa_id)
        if libmarpa_rule_id < 0 then
            local error_code = g:error()
            print('Problem with rule',
                symbol_by_libmarpa_id[lhs_libmarpa_id].name,
                ' ::= ',
                symbol_by_libmarpa_id[rhs1_libmarpa_id].name,
                ((rhs2_libmarpa_id and
                        symbol_by_libmarpa_id[rhs2_libmarpa_id].name
                ) or '')
            )
            if error_code == luif_err_duplicate_rule then
                print('Duplicate rule -- non-fatal')
            else
                kollos_c.error_throw(error_code, 'problem with rule_new()')
            end
        end
        rule_by_libmarpa_id[libmarpa_rule_id] = rule_props
        rule_props.libmarpa_rule_id = libmarpa_rule_id
    end
    g.throw = true

    g:start_symbol_set(augment_symbol.libmarpa_id)
    g:precompute()

    local lexeme_prefixes = {}
    local tokens_by_char = {}
    for i = 0,255 do
        tokens_by_char[i] = {}
    end

    for symbol_id = 1,#symbol_by_id do
        local symbol_props = symbol_by_id[symbol_id]
        if symbol_props.lexeme then
            -- print(symbol_props.name, symbol_props.lexeme_prefix.name, symbol_props.lexeme_prefix.libmarpa_id)
            lexeme_prefixes[#lexeme_prefixes + 1] = symbol_props.lexeme_prefix
        end

        -- When we do Unicode, we switch to (add?) a method for
        -- lazy computation of the tokens for each character
        -- with a value greater than 255
        if symbol_props.terminal then
            local charclass = symbol_props.isym_props.charclass
            local initial_char = 1
            while true do
                local found_char = all_255_chars:find(charclass, initial_char)
                if not found_char then break end
                local token_list = tokens_by_char[found_char-1] -- 0-based indexing
                token_list[#token_list + 1] = symbol_props.libmarpa_id
                initial_char = found_char + 1
            end
        end

    end

    return { libmarpa_g = g,
        tokens_by_char = tokens_by_char, -- 0-based index
        lexeme_prefixes = lexeme_prefixes,
        symbol_by_libmarpa_id = symbol_by_libmarpa_id,
        rule_by_libmarpa_id = rule_by_libmarpa_id,
    }

end

local function kir_compile(kir)
    local compiled = {}
    for grammar,grammar_props in pairs(kir) do
        print ("Compiling grammar ", grammar)
        compiled[grammar] = do_grammar(grammar, grammar_props)
    end
    return compiled
end

return { kir_compile = kir_compile }

-- vim: expandtab shiftwidth=4:
