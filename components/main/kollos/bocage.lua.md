<!--

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

-->

# Kollos "mid-level" bocage code

This is the code for the "middle layer" bocage
of Kollos.
Below it is Libmarpa, a library written in
the C language which contains the actual parse engine.

## Constructor

    -- luatangle: section Constructor

    local function bocage_new(recce)
        local grammar = recce.grammar
        local bocage = {
            _type = "bocage",
            grammar = grammar,
            throw = recce.throw,
        }

        bocage = kollos_c.bocage_new(bocage,
            recce,
            symbol,
            start_loc,
            end_loc
        )
        setmetatable(bocage, {
                __index = bocage_class,
            })
        return bocage
    end

## Declare the bocage class

    -- luatangle: section declare bocage_class
    local bocage_class = {}

## Declare the bocage show() method

    -- luatangle: section declare bocage show() method

    local function or_node_tag(bocage, or_node_id)
        local irl_id = bocage:__or_node_irl(or_node_id)
        local position = bocage:__or_node_position(or_node_id)
        local or_origin = bocage:__or_node_origin(or_node_id)
        local or_set = bocage:__or_node_set(or_node_id)
        return 'R' .. irl_id .. ':' .. position .. '@' .. or_origin .. '-' .. or_set
    end

    function bocage_class.show(bocage)
        local or_node_id = 0
        local data = {}
        local tags = {}
        while true do
            local irl_id = bocage:__or_node_irl(or_node_id)
            if not irl_id then break end
            local first_and_node_id
            = bocage:__or_node_first_and(or_node_id)
            local last_and_node_id
            = bocage:__or_node_last_and(or_node_id)
            for and_node_id = first_and_node_id, last_and_node_id do
                local symbol = bocage:__and_node_symbol(and_node_id)
                local cause_tag
                if symbol then cause_tag = 'S' .. symbol end
                local cause_id = bocage:__and_node_cause(and_node_id)
                if cause_id then
                    cause_tag = or_node_tag(bocage, cause_id)
                end
                local parent_tag = or_node_tag(bocage, or_node_id)
                local predecessor_id = bocage:__and_node_predecessor(or_node_id)
                local predecessor_tag = '-'
                if predecessor_id then
                    predecessor_tag = or_node_tag(bocage, predecessor_id)
                end
                local tag =
                and_node_id .. ':'
                .. ' ' .. or_node_id .. '=' .. parent_tag
                .. ' ' .. predecessor_tag
                .. ' ' .. cause_tag
                tags[and_node_id] = tag
                data[#data+1] = and_node_id
            end
            or_node_id = or_node_id + 1
        end
        table.sort(data)
        for data_ix = 1, #data do
            local and_node_id = data[data_ix]
            data[data_ix] = tags[and_node_id]
        end
        return table.concat(data, '\n') .. '\n'
    end

## To do

    sub Marpa::R2::Recognizer::and_node_tag {
        my ( $recce, $and_node_id ) = @_;
        my $bocage            = $recce->[Marpa::R2::Internal::Recognizer::B_C];
        my $recce_c           = $recce->[Marpa::R2::Internal::Recognizer::C];
        my $parent_or_node_id = $bocage->_marpa_b_and_node_parent($and_node_id);
        my $origin         = $bocage->_marpa_b_or_node_origin($parent_or_node_id);
        my $origin_earleme = $recce_c->earleme($origin);
        my $current_earley_set =
            $bocage->_marpa_b_or_node_set($parent_or_node_id);
        my $current_earleme = $recce_c->earleme($current_earley_set);
        my $cause_id        = $bocage->_marpa_b_and_node_cause($and_node_id);
        my $predecessor_id = $bocage->_marpa_b_and_node_predecessor($and_node_id);

        my $middle_earley_set = $bocage->_marpa_b_and_node_middle($and_node_id);
        my $middle_earleme    = $recce_c->earleme($middle_earley_set);

        my $position = $bocage->_marpa_b_or_node_position($parent_or_node_id);
        my $irl_id   = $bocage->_marpa_b_or_node_irl($parent_or_node_id);

    #<<<  perltidy introduces trailing space on this
        my $tag =
              'R'
            . $irl_id . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
    #>>>
        if ( defined $cause_id ) {
            my $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause_id);
            $tag .= 'C' . $cause_irl_id;
        }
        else {
            my $symbol = $bocage->_marpa_b_and_node_symbol($and_node_id);
            $tag .= 'S' . $symbol;
        }
        $tag .= q{@} . $middle_earleme;
        return $tag;
    } ## end sub Marpa::R2::Recognizer::and_node_tag

    sub Marpa::R2::Recognizer::show_and_nodes {
        my ($recce) = @_;
        my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
        my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
        my $text;
        my @data = ();
        AND_NODE: for ( my $id = 0;; $id++ ) {
            my $parent      = $bocage->_marpa_b_and_node_parent($id);
            my $predecessor = $bocage->_marpa_b_and_node_predecessor($id);
            my $cause       = $bocage->_marpa_b_and_node_cause($id);
            my $symbol      = $bocage->_marpa_b_and_node_symbol($id);
            last AND_NODE if not defined $parent;
            my $origin            = $bocage->_marpa_b_or_node_origin($parent);
            my $set               = $bocage->_marpa_b_or_node_set($parent);
            my $irl_id            = $bocage->_marpa_b_or_node_irl($parent);
            my $position          = $bocage->_marpa_b_or_node_position($parent);
            my $origin_earleme    = $recce_c->earleme($origin);
            my $current_earleme   = $recce_c->earleme($set);
            my $middle_earley_set = $bocage->_marpa_b_and_node_middle($id);
            my $middle_earleme    = $recce_c->earleme($middle_earley_set);

    #<<<  perltidy introduces trailing space on this
            my $desc =
                  "And-node #$id: R"
                . $irl_id . q{:}
                . $position . q{@}
                . $origin_earleme . q{-}
                . $current_earleme;
    #>>>
            my $cause_rule = -1;
            if ( defined $cause ) {
                my $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause);
                $desc .= 'C' . $cause_irl_id;
            }
            else {
                $desc .= 'S' . $symbol;
            }
            $desc .= q{@} . $middle_earleme;
            push @data,
                [
                $origin_earleme, $current_earleme, $irl_id,
                $position,       $middle_earleme,  $cause_rule,
                ( $symbol // -1 ), $desc
                ];
        } ## end AND_NODE: for ( my $id = 0;; $id++ )
        my @sorted_data = map { $_->[-1] } sort {
                   $a->[0] <=> $b->[0]
                or $a->[1] <=> $b->[1]
                or $a->[2] <=> $b->[2]
                or $a->[3] <=> $b->[3]
                or $a->[4] <=> $b->[4]
                or $a->[5] <=> $b->[5]
                or $a->[6] <=> $b->[6]
        } @data;
        return ( join "\n", @sorted_data ) . "\n";
    } ## end sub Marpa::R2::Recognizer::show_and_nodes

    sub Marpa::R2::Recognizer::show_or_nodes {
        my ( $recce, $verbose ) = @_;
        my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
        my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
        my $text;
        my @data = ();
        my $id   = 0;
        OR_NODE: for ( ;; ) {
            my $origin   = $bocage->_marpa_b_or_node_origin($id);
            my $set      = $bocage->_marpa_b_or_node_set($id);
            my $irl_id   = $bocage->_marpa_b_or_node_irl($id);
            my $position = $bocage->_marpa_b_or_node_position($id);
            $id++;
            last OR_NODE if not defined $origin;
            my $origin_earleme  = $recce_c->earleme($origin);
            my $current_earleme = $recce_c->earleme($set);

    #<<<  perltidy introduces trailing space on this
            my $desc =
                  'R'
                . $irl_id . q{:}
                . $position . q{@}
                . $origin_earleme . q{-}
                . $current_earleme;
    #>>>
            push @data,
                [ $origin_earleme, $current_earleme, $irl_id, $position, $desc ];
        } ## end OR_NODE: for ( ;; )
        my @sorted_data = map { $_->[-1] } sort {
                   $a->[0] <=> $b->[0]
                or $a->[1] <=> $b->[1]
                or $a->[2] <=> $b->[2]
                or $a->[3] <=> $b->[3]
        } @data;
        return ( join "\n", @sorted_data ) . "\n";
    } ## end sub Marpa::R2::Recognizer::show_or_nodes

```

# The bocage _or_nodes_show() method

The nodes are not sorted and therefore the
output is not suitable for use in a test suite.

    -- luatangle: section declare bocage _or_nodes_show() method

    local function or_node_show(bocage, or_node_id, verbose)
        local origin = bocage:__or_node_origin(or_node_id)
        local grammar = bocage.grammar
        if not origin then return end
        local current_set_id = bocage:__or_node_set(or_node_id)
        local irl_id = bocage:__or_node_irl(or_node_id)
        local position = bocage:__or_node_position(or_node_id)
        local text =
              "OR-node #" .. or_node_id .. ': R' .. irl_id .. ':'
            .. position .. '@'
            .. origin .. '-'
            .. current_set_id .. "\n"
        if verbose then
            text = text .. "    "
            .. grammar:show_dotted_irl(irl_id, position)
            .. '\n'
        end
        return text
    end

    function bocage_class._or_nodes_show(bocage, verbose)
        local or_node_data = {}
        local or_node_id = 0
        while true do
            local origin = bocage:__or_node_origin(or_node_id)
            if not origin then break end
            local schwartzian = { or_node_id, origin,
                bocage:__or_node_set(or_node_id),
                bocage:__or_node_irl(or_node_id),
                bocage:__or_node_position(or_node_id) }
            or_node_id = or_node_id+1
            -- array index of or_node_id is or_node_id+1
            -- so we use or_node_id *post-increment*
            or_node_data[or_node_id] = schwartzian
        end
        table.sort(or_node_data, schwartz_cmp)
        local pieces = {}
        for ix = 1, #or_node_data do
            pieces[ix] = or_node_show(bocage, or_node_data[ix][1], verbose)
        end
        return table.concat(pieces)
    end

## Finish and return the bocage static class

    -- luatangle: section Finish return object

    local bocage_static_class = {
        new = bocage_new
    }
    return bocage_static_class

## Development errors

    -- luatangle: section Development error methods

    local function development_error_stringize(error_object)
        return
        "bocage error at line "
        .. error_object.line
        .. " of "
        .. error_object.file
        .. ":\n "
        .. error_object.string
    end

    local function development_error(bocage, string)
        local error_object
        = kollos_c.error_new{
            stringize = development_error_stringize,
            code = luif_err_development,
            line = debug.getinfo(2, 'l').short_src,
            line = debug.getinfo(2, 'l').currentline,
            string = string
        }
        if bocage.throw then error(tostring(error_object)) end
        return error_object
    end

## Output file

    -- luatangle: section main

    -- luacheck: std lua51
    -- luacheck: globals bit
    -- luacheck: globals __FILE__ __LINE__

    -- local inspect = require "kollos.inspect"
    local kollos_c = require "kollos_c"
    local util = require "kollos.util"
    local schwartz_cmp = util.schwartz_cmp
    local luif_err_development = kollos_c.error_code_by_name['LUIF_ERR_DEVELOPMENT']

    -- luatangle: insert declare bocage_class

    for k,v in pairs(kollos_c) do
         if k:match('^[_]?bocage') then
             local c_wrapper_name = k:gsub('bocage', '', 1)
             bocage_class[c_wrapper_name] = v
         end
    end

    -- luatangle: insert Development error methods
    -- luatangle: insert Constructor
    -- luatangle: insert declare bocage show() method
    -- luatangle: insert declare bocage _or_nodes_show() method
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
