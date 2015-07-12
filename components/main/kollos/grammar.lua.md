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

# Kollos "mid-level" grammar cod3

This is the code for the "middle layer" of Kollos.
Below it is Libmarpa, a library written in
the C language which contains the actual parse engine.

The interface to this layer from above are a set of
Lua calls, called the PLIF (Pure Lua InterFace).
We expect to add a layer above this,
which will parse from a DSL to the PLIF.

The PLIF will be a documented interface.
while not as convenient as a DSL,
the PLIF can be used for programming.

The mid-level implements the logic

* translates precedences rules to BNF.

* translates sequence rules to BNF.

* performs a set of normalizations on the BNF,
  to allow Libmarpa to be more efficient.

* performs the Libmarpa calls that create a
  Libmarpa grammar.

## Rewriting grammars

Rewriting grammars prior to parsing is a technique
long known and discuesed.
A major obstacle is that parsing is almost always
a means to an end -- the application is parsing
as a first step to applying a semantics,
and that semantics is defined in terms of the
original grammar.
Many of the most tempting rewrites
undo the
relationship between the original grammar
and its semantics, to the extent that
recovering it is so costly that the
rewrite is counter-productive.

Marpa/Kollos uses only "semantics-safe" rewrites --
rewrite which can be undone cheaply.
This approach has been tested in Marpa::R2,
which translates back and forth between an
pre-rewrite grammar and
a post-rewrite grammar.
In Marpa::R2,
"semantics-safe" rewrites can be undone
cheaply not just in post-processing, but also
"on the fly".

### Semantics-safe rewriting

We now proceed to define "semantics-safe".
We consider two grammars.
The *external* grammar is the one before
rewriting.
The *internal* grammar is the one after
rewriting.

A partial function,
call it `brick()`,
maps symbols in the internal
grammar to the external grammar.
Let `isym` be an internal symbol.
`isym` is called a *brick* symbol iff
`brick(isym)` is defined.
`isym` is called a *mortar* symbol iff
`isym` is not a brick symbol.

In a parse tree,
a brick symbol is a terminal iff it has no
brick descendents.
A brick symbol is the brick root iff it has no
brick ancestors.
Note that
a brick terminal may have mortar descendants,
and a brick root may have mortar ancestors.

A brick symbol is a brick interior symbol iff
it is not a brick root symbol
and it is not a brick terminal symbol.
A brick symbol is a brick non-terminal iff
it is not a brick terminal symbol.
A brick non-terminal may be either the brick root
or a brick interior symbol.

In a parse tree using the external grammar,
consider the subtree formed by taking a brick
non-terminal as the root,
and traversing the tree left-to-tree, stopping
at the first brick node encountered.
In the subtree formed by such a traversal,
a node will be a brick
iff it is a terminal of the subtree
or the root node of the subtree.
We say that the terminals of this subtree
are the *brick children* of its root.
The order of the brick children is the order
in which they are encountered in
the left-to-right traversal described above.

Let `i` be an input, whose `n`'th position
we write as `i[n]`.
In a parse tree, each node can also be seen
as an "instance" of a symbol.
We can write the instance as the triple
`<sym,start,length>`,
where `sym` is a symbol of the grammar,
`start` is the location in `i` where the
instance starts,
and `length` is the instance's length.
The first input location of the instnace will therefore
be `i[start]` and the last location will be
`i[start+length-1]`.

Let `i` be an input,
and `itree` be a parse tree that results
from parsing `i` with the internal grammar.
Let `xtree` be a parse tree that results
from parsing `i` with the external grammar.
We say that `itree` and `xtree` are
*brick-consistent*,
if two conditons hold:

The Brick Terminal Condition:
`<xsym,start,length>` is an instance in `xtree`
iff 
`<isym,start,length>` is an brick instance in `itree`,
where `brick(isym) == xsym`.

The Brick Non-terminal Condition:
`<xsym,start,length>` is a non-terminal instance
whose children are

```
    `<xsym1,start1,length1>`, `<xsym2,start2,length2>` ...  `<xsym-n,start-n,length-n>`
```

in
`xtree` iff
`<isym,start,length>` is a non-terminal instance in
`itree`
whose brick children are

```
    `<isym1,start1,length1>`, `<isym2,start2,length2>` ...  `<isym-n,start-n,length-n>`,
```

where 

```
    `brick(isym1) == xsym1`, `brick(isym2) == xsym2` ...  `brick(isym-n) == xsym-n`.
```

We're now in a position to define
a semantically-safe rewrite.
A rewrite is *semantically-safe*
iff, for every application of the rewrite,
and for every input `i`,
when both the external grammar
and internal grammar is used to parse `i`,

* every parse tree produced by the internal grammar
  is brick-consistent
  with some parse tree produced by the external grammar,

* and vice versa,
  every parse tree produced by the external grammar
  is brick-consistent
  with some parse tree produced by the internal grammar.

The previous definition is perhaps clearer
when rephrased so that applies only to
the special case in which both the internal
and external grammars are unambiguous.
A rewrite is *semantically-safe*
iff, for every application of the rewrite,
and for every input `i`,
when both the external grammar
and internal grammar is used to parse `i`,
the parse tree produced by the internal grammar
is brick-consistent with the
parse tree produced by the external grammar.

### Semantically-safe rewrite techniques

Staying semantically-safe limits the kinds of rewrites
that can be applied.
But, with caution,
many simple and highly useful rewrite techniques
be used:

* Rules can be split into alternatives.

* Intermediate rules with mortar symbols can be added.

* Rules can be split up or joined.

* Multiple brick symbols can be mapped
  to the same external
  symbol.

* In particular, rules can be binarized.

In what follows,
many of the rewrites are of non-BNF rules
(sequences and precedenced rules) to BNF.
Others are transformations of the BNF.
All of these techniques find use in the
Kollos code.

## Fields

For development purposes,
after the working grammar is created,
I census the fields in the important
tables.  It's a cheap substitute for
the strictly typed OO Lua does not
have, and which I don't really want in general.

```

        -- luatangle: section census fields
        -- census subalt fields
        -- TODO: remove after development
        local xsubalt_field_census = {}
        local xsubalt_field_census_expected = {
            action = true,
            id = true,
            id_within_top_alternative = true,
            line = true,
            max = true,
            min = true,
            name_base = true,
            name = true,
            nullable = true,
            nulling = true,
            parent_instance = true,
            precedence_level = true,
            productive = true,
            rh_instances = true,
            separation = true,
            separator = true,
            subname = true,
            xprec = true,
        }


```

### Instances

It is useful in Kollos to uniquely identify
each RHS location of every rule.
These are called *RHS instance* objects,
or more often just *instances*.

Instances serve two purposes:
First, not every RHS item is a symbol, and
some object is needed to identify
these non-symbol items.

Second, while semantics is defined in terms
of rules and symbols, knowing the ID of
a symbol
is not always sufficient to
know its semantics, which can vary by
rule and even by position within rule.
We can find the semantics by
going back to the rule, but this will
not always be convenient.
Instances provide a convenient place
to put information about
the role a RHS item
plays in the rule's semantics.

```
        -- luatangle: section+ census fields
        local xinstance_field_census = {}
        local xinstance_field_census_expected = {
            associator = true,
            element = true,
            precedence_level = true,
            rh_ix = true,
            xalt = true,
        }

```

Working instances currently contain nothing
except their `element` (the RHS item)
and, for brick instances,
a `<xalt, rh_ix>` duple that allows their
semantics to be found quickly.
Currently, working instances never change after
creation.

Separators will usually (always?) be
a brick element.
They do not have the
`<xalt, rh_ix>` duple defined.
Instead, the `xalt` is the value of
their `separates` named field.

```
        -- luatangle: section+ census fields
        local winstance_field_census = {}
        local winstance_field_census_expected = {
            element = true,
            separates = true,
            rh_ix = true,
            xalt = true,
        }

```

Since
working instances do not change after creation,
they
can be used to represent what are actually different
instances.
This is tempting when the instance contains only
an `element` field, so that the instance adds 
essentially no information to the underlying `element`.
And the elements
are of course reused at different RHS instances.

This reuse somewhat muddies the idea of instance objects,
but it is convenient, and it
is used in certain places
in the working grammar.

## Some code to implement the census

```
        -- luatangle: section+ census fields
        for xsubalt_id = 1,#xsubalt_by_id do
            local xsubalt = xsubalt_by_id[xsubalt_id]
            for field,_ in pairs(xsubalt) do
                 if not xsubalt_field_census_expected[field] then
                     xsubalt_field_census[field] = true
                 end
            end
            local rh_instances = xsubalt.rh_instances
            for rh_ix = 1,#rh_instances do
                local rh_instance = rh_instances[rh_ix]
                for field,_ in pairs(rh_instance) do
                     if not xinstance_field_census_expected[field] then
                         xinstance_field_census[field] = true
                     end
                end
            end
        end
        for field,_ in pairs(xsubalt_field_census) do
             print("unexpected xsubalt field:", field)
        end
        for field,_ in pairs(xinstance_field_census) do
             print("unexpected xinstance field:", field)
        end

        -- census xsym fields
        -- TODO: remove after development
        local xsym_field_census = {}
        local xsym_field_census_expected = {
            id = true,
            lhs_xrules = true,
            line = true,
            name_base = true,
            name = true,
            nullable = true,
            nulling = true,
            productive = true,
            rawtype = true,
            semantics = true,
            top_precedence_level = true,
            type = true,
        }
        for xsym_id = 1,#xsym_by_id do
            local xsym = xsym_by_id[xsym_id]
            for field,_ in pairs(xsym) do
                 if not xsym_field_census_expected[field] then
                     xsym_field_census[field] = true
                 end
            end
        end
        for field,_ in pairs(xsym_field_census) do
             print("unexpected xsym field:", field)
        end

        -- census wrule fields
        local wrule_field_census = {}
        local wrule_field_census_expected = {
            brick = true,
            id = true,
            lhs = true,
            max = true,
            min = true,
            rh_instances = true,
            separator = true,
            separation = true,
            source = true,
            xalt = true,
        }

        -- luatangle: section+ census fields

        -- luatangle: section+ census fields
        for rule_id = 1,#wrule_by_id do
            local wrule = wrule_by_id[rule_id]
            if wrule then
                if not wrule.name_base then
                    print("missing 'name_base' in wrule:", wrule.desc)
                end
                if not wrule.line then
                    print("missing 'line' in wrule:", wrule.desc)
                end
                for field,_ in pairs(wrule) do
                    if not wrule_field_census_expected[field] then
                        wrule_field_census[field] = true
                    end
                end
                local rh_instances = wrule.rh_instances
                for rh_ix = 1,#rh_instances do
                    local winstance = rh_instances[rh_ix]
                    if not winstance.name_base then
                        print("missing 'name_base' in winstance:", winstance.name)
                    end
                    if not winstance.line then
                        print("missing 'line' in winstance:", winstance.name)
                    end
                    for field,_ in pairs(winstance) do
                        if not winstance_field_census_expected[field] then
                            winstance_field_census[field] = true
                        end
                    end
                end
            end
        end
        for field,_ in pairs(wrule_field_census) do
            print("unexpected wrule field:", field)
        end
        for field,_ in pairs(winstance_field_census) do
            print("unexpected winstance field:", field)
        end

        -- census wsym fields
        -- TODO: remove after development
        local wsym_field_census = {}
        local wsym_field_census_expected = {
             id = true,
             line = true,
             name = true,
             name_base = true,
             nullable = true,
             precedence_level = true,
             source = true,
             xsym = true,
        }
        for _,wsym in pairs(wsym_by_name) do
            if not wsym.name_base then
                print("missing 'name_base' in wsym:", wsym.name)
            end
            if not wsym.line then
                print("missing 'line' in wsym:", wsym.name)
            end
            for field,_ in pairs(wsym) do
                 if not wsym_field_census_expected[field] then
                     wsym_field_census[field] = true
                 end
            end
        end
        for field,_ in pairs(wsym_field_census) do
             print("unexpected wsym field:", field)
        end

```

## Utilities for wsym, wrule

These wsym and wrule utilities
are internal to the `compile()` method
because they use up-values internal
to the `compile()` method.

Having these function be internal
to `compile()` also makes it easy for the
"working data" to be cleaned up -- it will just be garbage collected
when compile() returns. If these functions were top-level, the data
would have to be top-level as well.

```

    -- luatangle: section wsym,wrule utilities

    -- 2nd return value is true if this is
    -- a new symbol
    local function wsym_ensure(name)
        local wsym_props = wsym_by_name[name]
        if wsym_props then return wsym_props end
        wsym_props = {
            name = name,
        }
        setmetatable(wsym_props, {
                __index = function (table, key)
                    if key == 'type' then return 'wsym'
                    elseif key == 'rawtype' then return 'wsym'
                    elseif key == 'line' then return table.source.line
                    elseif key == 'name_base' then return table.source.name_base
                    elseif key == 'source' then return table.xsym
                    elseif key == 'xsym' then return nil
                    else
                        local xsym = table.xsym
                        if xsym then return xsym[key] end
                        return nil
                    end
                end
            }
        )

        wsym_by_name[name] = wsym_props
        return wsym_props,true
    end

    -- Create a new *internal* lhs for this
    -- alt
    local function lh_wsym_ensure(alt)
        local alt_name = alt.name
        local name = 'lhs!' .. alt_name
        local wsym_props,is_new = wsym_ensure(name)
        if is_new then
            wsym_props.nullable = alt.nullable
            wsym_props.line = alt.line
            wsym_props.name_base = alt.name_base
        end
        return wsym_props
    end

    -- Create a new *internal* lhs for this
    -- alt
    local function lh_of_wrule_new(name, wrule)
        local new_wsym,is_new = wsym_ensure(name)
        -- TODO: remove after development
        assert(is_new)
        new_wsym.nullable = wrule.nullable
        new_wsym.line = wrule.line
        new_wsym.name_base = wrule.name_base
        return new_wsym
    end

    -- Create a unique new internal symbol
    -- given the line & name_base data
    local internal_wsym_ensure
    do
        local unique_number = 0
        internal_wsym_ensure =
            function(name_base, line)
                local name = 'int!' .. unique_number
                unique_number = unique_number + 1
                local new_wsym = wsym_ensure(name)
                new_wsym.name_base = name_base
                new_wsym.line = line
                return new_wsym
            end
    end

    local function precedenced_wsym_ensure(base_wsym, precedence)
        local name = base_wsym.name .. '!prec' .. precedence
        local new_wsym,is_new = wsym_ensure(name)
        if is_new then
            new_wsym.nullable = false
            new_wsym.line = base_wsym.line
            new_wsym.name_base = base_wsym.name_base
        end
        return new_wsym
    end

    local function cloned_wsym_ensure(xsym)
        local name = xsym.name
        local new_wsym,is_new = wsym_ensure(name)
        if is_new then
            new_wsym.nullable = xsym.nullable
            new_wsym.line = xsym.line
            new_wsym.name_base = xsym.name_base
        end
        return new_wsym
    end

    local function wrule_desc(wrule)
        local desc_table = {
            wrule.lhs.name,
            '::=',
        }
        local rh_instances = wrule.rh_instances
        for rh_ix = 1,#rh_instances do
            local rh_instance = rh_instances[rh_ix]
            desc_table[#desc_table+1] = rh_instance.name
        end
        return table.concat(desc_table, ' ')
    end

    local function wrule_ensure(rule_args)
        local max = rule_args.max or 1
        local min = rule_args.min or 1
        local separator = rule_args.separator
        local separator_id = separator and separator.id or -1
        local lhs = rule_args.lhs
        local rh_instances = rule_args.rh_instances
        wrule = {
            brick = rule_args.brick,
            lhs = lhs,
            max = max,
            min = min,
            rh_instances = rh_instances,
            separation = rule_args.separation,
            separator = separator,
            source = rule_args.source,
            xalt = rule_args.xalt,
        }
        setmetatable(wrule, {
                __index = function (table, key)
                    if key == 'type' then return 'wrule'
                    elseif key == 'rawtype' then return 'wrule'
                    elseif key == 'source' then return xalt or lhs
                    elseif key == 'line' then return table.source.line
                    elseif key == 'name_base' then return table.source.name_base
                    elseif key == 'nullable' then return lhs.nullable
                    elseif key == 'desc' then return wrule_desc(table)
                    else return end
                end
            })
        wrule_by_id[#wrule_by_id+1] = wrule
        wrule.id = #wrule_by_id
        return wrule
    end

```

Given a hacked wrule, replace the original with the hacked version.
This routine exists because it is often convenient,
instead of carefully custom-cloning a rule,
and then deleting it.
to "hack" its fields.

```
    -- luatangle: section+ wsym,wrule utilities

    local function wrule_replace(hacked_wrule)
        wrule_by_id[hacked_wrule.id] = false
        return wrule_ensure(hacked_wrule)
    end

```

## Rewrite the sequence counts

This code rewrites sequences rules to
eliminate the counts -- that is,
so that, in effect,
`min = 1` and `max = 1`.
The `min` and `max` fields are not actually changed
but will no longer be meaningful.

It is assumed at this point that

* previous rewrites have eliminated `liberal`
  and `terminating` separation, so that only
  `proper` separation sequences and unseparated
  sequences remain.

* `min > 0`.

* the sequence rule's RHS has length of exactly 1.

* the sequence is non-trivial, that either
  `min ~= 1` or `max ~= 1`.

## Create the repetend instance

Per the above assumptions, there is exactly one
RHS symbol.
The RHS symbol is called the *repetend*.
It is the first (and only) symbol in `working_rule`.

```
    -- luatangle: section Create the repetend instance

    local repetend_instance = working_wrule.rh_instances[1]

```

## Create the separator instance

For separators,
we reuse the same instance object for
for multiple RHS instances.
Working instances are never changed,
and the same semantic information can be
used in every case,
so we can get away with this.

```
    -- luatangle: section Create the separator instance if needed

    local separator_instance
    if separator then
        separator_instance = winstance_new(separator)
        assert( working_wrule.xalt )
        separator_instance.separates = working_wrule.xalt
    end

```

I call a *block* a sequence of fixed length.
I call a *block* a sequence of fixed length.
I call any other sequence a *range*.
If a range has no maximum length, I call it *open*.
If a range is not open, then it is *closed*.
If, in a sequence, `min == 1`, then I say the
sequence is *1-based*.

The following code works first dividing the
sequence into one or two 1-based sequences.
If there is only one,
the sequece may be a block or a range.
If there are two, the block always comes first.
If there is a range, it may be either open
or closed.

The next code
performs the rewrite for a block of size `n`,
without separation.
Assumed to be available as an upvalue are

* `working_wrule`, the current sequence rule.

* `repetend_instance`, the instance for the repetend.

```

    -- luatangle: section Rewrite block function

    -- For memoizing blocks by cont
    local blocks = {}

    local function blk_lhs(n)
        local lhs = blocks[n]
        if lhs then return lhs end

        if n == 1 then
            rhs = { repetend_instance }
        elseif n == 2 then
            if separator_instance then
                rhs = { repetend_instance, separator_instance,
                    repetend_instance }
            else
                rhs = { repetend_instance, repetend_instance }
            end
        else
            local n1 = pow2(n)
            local n2 = n - n1
            local lhs1 = blk_lhs(n1)
            local lhs2 = blk_lhs(n2)
            if separator_instance then
                rhs = { winstance_new(lhs1), separator_instance,
                    winstance_new(lhs2) }
            else
                rhs = { winstance_new(lhs1), winstance_new(lhs2) }
            end
        end
        local lhs_name = 'blk' .. n .. '!' .. repetend_instance.name
        local is_new
        lhs, is_new = wsym_ensure(lhs_name)
        assert(is_new) -- TODO: remove after development
        lhs.source = working_wrule.source
        wrule_ensure(
            {
                lhs = lhs,
                rh_instances = rhs
            }
        )
        blocks[n] = lhs
        return lhs
    end

```

The next code
performs the rewrite for a range of size `n`.
Assumed to be available as an upvalue are

* `working_wrule`, the current sequence rule.

* `repetend_instance`, the instance for the repetend.

```

    -- luatangle: section Rewrite range functions

    -- For memoizing ranges by cont
    local ranges = {}

    local function range_lhs(n)
        local lhs = ranges[n]
        if lhs then return lhs end
        local short_rhs, long_rhs

        local lhs_name = 'rng' .. n .. '!' .. repetend_instance.name
        local is_new
        lhs, is_new = wsym_ensure(lhs_name)
        assert(is_new) -- TODO: remove after development
        lhs.source = working_wrule.source

        if n == -1 then
            short_rhs = { repetend_instance }
            if separator_instance then
                long_rhs = { winstance_new(lhs), separator_instance,
                    repetend_instance }
            else
                long_rhs = { winstance_new(lhs), repetend_instance }
            end
        elseif n == 1 then
            lhs = blk_lhs(1)
            ranges[n] = lhs
            return lhs
        elseif n == 2 then
            short_rhs = { repetend_instance }
            if separator_instance then
                long_rhs = { repetend_instance, separator_instance,
                    repetend_instance }
            else
                long_rhs = { repetend_instance, repetend_instance }
            end
        else
            local n1 = pow2(n)
            local n2 = n - n1
            local range_lhs1 = range_lhs(n1)
            local block_lhs1 = blk_lhs(n1)
            local lhs2 = range_lhs(n2)
            short_rhs = { winstance_new(range_lhs1) }
            if separator_instance then
                long_rhs = { winstance_new(block_lhs1), separator_instance,
                    winstance_new(lhs2) }
            else
                long_rhs = { winstance_new(block_lhs1), winstance_new(lhs2) }
            end
        end
        wrule_ensure(
            {
                lhs = lhs,
                rh_instances = short_rhs
            }
        )
        wrule_ensure(
            {
                lhs = lhs,
                rh_instances = long_rhs
            }
        )
        ranges[n] = lhs
        return lhs
    end

```


We start by determining what sequences we have:

```

    -- luatangle: section Rewrite the sequence counts

    local block_size
    local range_size
    if min == max then
        block_size = max
    elseif min == 1 then
        range_size = max
    else
        block_size = min-1
        range_size = max == -1 and -1 or max-block_size
    end

```

```
    -- luatangle: section+ Rewrite the sequence counts
    -- luatangle: insert Rewrite block function
    -- luatangle: insert Rewrite range functions

    local new_rhs = {}
    if block_size then
        local block_lhs = blk_lhs(block_size)
        new_rhs[#new_rhs+1] = winstance_new(block_lhs)
    end

    if range_size then
        local range_lhs = range_lhs(range_size)
        if #new_rhs > 0 and separator_instance then
            new_rhs[#new_rhs+1] = separator_instance
        end
        new_rhs[#new_rhs+1] = winstance_new(range_lhs)
    end

    working_wrule.rh_instances = new_rhs
    working_wrule = wrule_replace(working_wrule)

```

```

    -- luatangle: section Binarize the working grammar

    for rule_id = 1,#wrule_by_id do
        local working_wrule = wrule_by_id[rule_id]
        -- TODO finish this
    end

```

## Disallow nulling separator

```

    -- luatangle: section disallow nulling separator
    if separator and separator.nulling then
        grammar:development_error(
            who
            .. 'Separator ' .. separator.name .. ' is nulling\n'
            .. ' That is not allowed\n',
            working_wrule.name_base,
            working_wrule.line
        )
    end

```

## Allow only singleton RHS

We force a singleton RHS,
by creating a new rule.
Since we want a new, unique, symbol for the
repetend,
we do this *even* if the rule is already an singleton.
Each sequence has a unique semantics,
and we will use the repetend symbol name as a
unique ID for this sequence.

```

    -- luatangle: section force singleton RHS in working_rule

    local new_sym
        = lh_of_wrule_new('rh1!' .. unique_number, working_wrule)
    unique_number = unique_number + 1
    local new_winstance = winstance_new(new_sym)
    working_wrule.rh_instances = {new_winstance}
    working_wrule = wrule_replace(working_wrule)
    wrule_ensure{
        lhs = new_sym,
        rh_instances = rh_instances,
    }

```

## Normalize separation

Elminate `terminating` and `liberal` separation
by rewriting them in terms of `proper` separation.
After this rewrite all rules will either have no
separator, or `proper` separation.

```

    -- luatangle: section Normalize separation

    if separation == 'terminating' or
        separation == 'liberal'
    then
        local middle_sym
            = lh_of_wrule_new('term!' .. unique_number, working_wrule)
        unique_number = unique_number + 1
        local middle_winstance = winstance_new(middle_sym)
        assert(separator)
        unique_number = unique_number + 1
        -- The old LHS of the wrule with the actual sequence,
        -- which we are going to replace
        local previous_lhs = working_wrule.lhs
        wrule_ensure{
            lhs = previous_lhs,
            rh_instances = {
                middle_winstance,
                separator_instance,
            }
        }
        working_wrule.lhs = middle_sym
        working_wrule = wrule_replace(working_wrule)
        -- If liberal separation, also add an
        -- unterminated variant
        if separation == 'liberal' then
            wrule_ensure{
                lhs = previous_lhs,
                rh_instances = {
                    middle_winstance,
                }
            }
        end
    end

```

## Main code

The main code follows

```
    -- luatangle: section main

    -- Kollos top level grammar routines

    -- luacheck: std lua51
    -- luacheck: globals bit
    -- luacheck: globals __FILE__ __LINE__

    local inspect = require "kollos.inspect" -- luacheck: ignore
    local kollos_c = require "kollos_c"
    local luif_err_development = kollos_c.error_code_by_name['LUIF_ERR_DEVELOPMENT']
    local matrix = require "kollos.matrix"

    local function here() return -- luacheck: ignore here
        debug.getinfo(2,'S').source .. debug.getinfo(2, 'l').currentline
    end

    local rshift = bit.rshift
    local lshift = bit.lshift

    -- Return highest power of 2 less than its argument
    -- Valid only for n>=2
    local function pow2(n)
        local pow = 1
        while pow < n do
            pow = lshift(pow, 1)
        end
        return rshift(pow, 1)
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

        props = {
            name = name,
            type = 'xsym',
            rawtype = 'xsym',
            lhs_xrules = {},
            -- am not trying to be very accurate about the line
            -- it should be the line of an alternative containing that symbol
            name_base = grammar.name_base,
            line = grammar.line,
        }
        xsym_by_name[name] = props

        local xsym_by_id = grammar.xsym_by_id
        xsym_by_id[#xsym_by_id+1] = props
        props.id = #xsym_by_id

        return props
    end

    -- Create a RHS instance of type 'xstring'
    -- Should be called only inside of a call to
    -- the alternative_new() method.
    -- 'throw' is always set by the caller, which catches
    -- any error
    function grammar_class.string(grammar, string)
        if type(string) ~= 'string' then
            grammar:development_error(
                [[string in alternate is type ']]
                .. type(string)
                .. [['; it must be a string]])
        end

        local current_xprec = grammar.current_xprec

        -- used to form the name of the string
        local id_within_top_alternative = grammar.string_id_within_top_alternative
        id_within_top_alternative = id_within_top_alternative + 1
        grammar.string_id_within_top_alternative = id_within_top_alternative

        local new_string = {
            string = string,
            productive = true,
            nullable = false,
            id_within_top_alternative =
            id_within_top_alternative,
            xprec = current_xprec,
            line = grammar.line,
            name_base = grammar.name_base
        }
        setmetatable(new_string, {
                __index = function (table, key)
                    if key == 'type' then return 'xstring'
                    elseif key == 'rawtype' then return 'xstring'
                    elseif key == 'subname' then
                        local subname =
                        'str'
                        .. table.id_within_top_alternative
                        .. table.xprec.subname
                        table.subname = subname
                        return subname
                    elseif key == 'name' then
                        local name =
                        table.name_base
                        .. ':'
                        .. table.line
                        .. table.subname
                        table.name = name
                        return name
                    end
                    return nil
                end
            })
        return new_string
    end

    -- Create a RHS instance of type 'xcc'
    -- Should be called only inside of a call to
    -- the alternative_new() method.
    -- 'throw' is always set by the caller, which catches
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

        local current_xprec = grammar.current_xprec

        -- used to form the name of the cc
        local id_within_top_alternative = grammar.cc_id_within_top_alternative
        id_within_top_alternative = id_within_top_alternative + 1
        grammar.cc_id_within_top_alternative = id_within_top_alternative

        local new_cc = {
            cc = cc,
            productive = true,
            nullable = false,
            id_within_top_alternative =
            id_within_top_alternative,
            xprec = current_xprec,
            line = grammar.line,
            name_base = grammar.name_base
        }
        setmetatable(new_cc, {
                __index = function (table, key)
                    if key == 'type' then return 'xcc'
                    elseif key == 'rawtype' then return 'xcc'
                    elseif key == 'subname' then
                        local subname =
                        'cc'
                        .. table.id_within_top_alternative
                        .. table.xprec.subname
                        table.subname = subname
                        return subname
                    elseif key == 'name' then
                        local name =
                        table.name_base
                        .. ':'
                        .. table.line
                        .. table.subname
                        table.name = name
                        return name
                    end
                    return nil
                end
            })
        return new_cc

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

        local xrule_by_id = grammar.xrule_by_id
        local new_xrule_id = #xrule_by_id + 1
        local new_xrule = {
            id = new_xrule_id,
            line = grammar.line,
            name_base = grammar.name_base,
        }

        setmetatable(new_xrule, {
                __index = function (table, key)
                    if key == 'type' then return 'xrule'
                    elseif key == 'rawtype' then return 'xrule'
                        -- 'name' and 'subname' are computed "just in time"
                        -- and then memoized
                    elseif key == 'subname' then
                        local subname =
                        'r'
                        .. table.id
                        table.subname = subname
                        return subname
                    elseif key == 'name' then
                        local name =
                        table.name_base
                        .. ':'
                        .. table.line
                        .. table.subname
                        table.name = name
                        return name
                    end
                    return nil
                end
            })

        xrule_by_id[new_xrule_id] = new_xrule
        new_xrule.id = new_xrule_id

        local symbol_props, symbol_error = _symbol_new(grammar, { name = lhs })
        if not symbol_props then
            return nil, grammar:development_error(symbol_error)
        end
        new_xrule.lhs = symbol_props

        local lhs_xrules = symbol_props.lhs_xrules
        lhs_xrules[#lhs_xrules+1] = new_xrule

        local current_xprec = {
            level = 0,
            xrule = new_xrule,
            top_alternatives = {},
            line = grammar.line,
            name_base = grammar.name_base,
        }
        setmetatable(current_xprec, {
                __index = function (table, key)
                    if key == 'type' then return 'xprec'
                        -- 'name' and 'subname' are computed "just in time"
                        -- and then memoized
                    elseif key == 'rawtype' then return 'xprec'
                    elseif key == 'subname' then
                        local subname =
                        'p'
                        .. table.level
                        .. table.xrule.subname
                        table.subname = subname
                        return subname
                    elseif key == 'name' then
                        local name =
                        table.name_base
                        .. ':'
                        .. table.line
                        .. table.subname
                        table.name = name
                        return name
                    end
                    return nil
                end
            })

        local xprec_by_id = grammar.xprec_by_id
        xprec_by_id[#xprec_by_id+1] = current_xprec
        grammar.current_xprec = current_xprec

        new_xrule.precedences = { current_xprec }
    end

    function grammar_class.precedence_new(grammar, args)
        local who = 'precedence_new()'
        local line, file = common_args_process(who, grammar, args)
        -- if line is nil, the "file" is actually an error object
        if line == nil then return line, file end

        local xrule_by_id = grammar.xrule_by_id
        if #xrule_by_id < 1 then
            return nil, grammar:development_error(who .. [[ called, but no current rule]])
        end

        local last_xprec = grammar.current_xprec
        local new_level = last_xprec.level + 1

        local current_xrule = xrule_by_id[#xrule_by_id]
        local xrule_precedences = current_xrule.precedences
        local new_xprec = {
            xrule = current_xrule,
            top_alternatives = {},
            line = grammar.line,
            name_base = grammar.name_base,
            level = new_level,
        }
        setmetatable(new_xprec, getmetatable(last_xprec))

        xrule_precedences[#xrule_precedences+1] = new_xprec

        local field_name = next(args)
        if field_name ~= nil then
            return nil, grammar:development_error(who .. [[: unacceptable named argument ]] .. field_name)
        end

        if #xrule_by_id < 1 then
            return nil, grammar:development_error(who .. [[ called, but no current rule]])
        end

        local xprec_by_id = grammar.xprec_by_id
        xprec_by_id[#xprec_by_id+1] = new_xprec
        grammar.current_xprec = new_xprec

    end

    local function xinstance_new(element, xalt, rh_ix)
        local new_instance = {
            xalt = xalt,
            rh_ix = rh_ix,
            element = element
        }
        setmetatable(new_instance, {
                __index = function (table, key)
                    if key == 'rawtype' then return 'xinstance'
                    elseif key == 'line' then return element.line
                    elseif key == 'name_base' then return element.name_base
                    else return table.element[key] end
                end
            })
        return new_instance
    end

    local function winstance_new(element, xalt, rh_ix)
        local new_instance = {
            xalt = xalt,
            rh_ix = rh_ix,
            element = element
        }
        setmetatable(new_instance, {
                __index = function (table, key)
                    if key == 'rawtype' then return 'winstance'
                    elseif key == 'line' then return element.line
                    elseif key == 'name_base' then return element.name_base
                    elseif key == 'element' then return nil
                    else return table.element[key] end
                end
            })
        return new_instance
    end

    local function _top_xalt_lhs(top_xalt)
        local xprec = top_xalt.xprec
        local xrule = xprec.xrule
        return xrule.lhs
    end

    local function _xalt_lhs(xalt)
        -- parent_instance field is only defined
        -- when the xalt is the child of *exactly*
        -- one instance.
        local parent = xalt
        while true do
            local grandparent = parent.parent_instance
            if not grandparent then break end
            parent = grandparent.xalt
        end
        return _top_xalt_lhs(parent)
    end

    -- throw is always set for this method
    -- the error is caught by the caller and re-thrown or not,
    -- as needed
    local function subalternative_new(grammar, src_subalternative)

        -- use name of caller
        local who = 'alternative_new()'

        local new_rh_instances = {}

        local current_xprec = grammar.current_xprec
        local current_xrule = current_xprec.xrule
        local xlhs_by_rhs = grammar.xlhs_by_rhs

        -- used to form the name of the subalternative
        local id_within_top_alternative = grammar.alt_id_within_top_alternative
        id_within_top_alternative = id_within_top_alternative + 1
        grammar.alt_id_within_top_alternative = id_within_top_alternative

        local new_subalternative = {
            xprec = current_xprec,
            line = grammar.line,
            id_within_top_alternative =
            id_within_top_alternative,
            name_base = grammar.name_base
        }

        setmetatable(new_subalternative, {
                __index = function (table, key)
                    if key == 'type' then return 'xalt'
                    elseif key == 'rawtype' then return 'xalt'
                    elseif key == 'lhs' then return _xalt_lhs(table)
                    elseif key == 'is_top' then return not table.parent_instance
                    elseif key == 'lhs_of_top' then
                        return _top_xalt_lhs(table)
                    elseif key == 'subname' then
                        local subname =
                        'a'
                        .. table.id_within_top_alternative
                        .. table.xprec.subname
                        table.subname = subname
                        return subname
                    elseif key == 'name' then
                        local name =
                        table.name_base
                        .. ':'
                        .. table.line
                        .. table.subname
                        table.name = name
                        return name
                    end
                    return nil
                end
            })

        local xsubalt_by_id = grammar.xsubalt_by_id
        xsubalt_by_id[#xsubalt_by_id+1] = new_subalternative
        local new_subalternative_id = #xsubalt_by_id
        new_subalternative.id = new_subalternative_id

        -- maxn() is used, because the src_alternative's are 
        -- part of a user interface, so that there might be nil's
        -- mixed in the series anywhere.
        -- These are fatal errors, and we have to make sure
        -- we can detect them.
        for rh_ix = 1, table.maxn(src_subalternative) do
            local src_rh_instance = src_subalternative[rh_ix]
            if not src_rh_instance then
                    grammar:development_error(
                        [[Problem with rule rhs item #]] .. rh_ix .. ' '
                        .. "wrong type: "
                        .. type(src_rh_instance)
                    )
            end
            local new_rh_instance

            if type(src_rh_instance) == 'table' then
                local instance_type = src_rh_instance.type
                if not instance_type then
                    local new_rhs_xalt = subalternative_new(grammar, src_rh_instance)
                    new_rh_instance = xinstance_new(new_rhs_xalt, new_subalternative, rh_ix)
                    new_rhs_xalt.parent_instance = new_rh_instance
                else
                    new_rh_instance = xinstance_new(src_rh_instance, new_subalternative, rh_ix)
                end
            else
                local error_string
                local new_rhs_sym
                new_rhs_sym, error_string = _symbol_new(grammar, { name = src_rh_instance })
                if not new_rhs_sym then
                    -- using return statements even for thrown errors is the
                    -- standard idiom, but in this case, I think it is clearer
                    -- without the return
                    grammar:development_error(
                        [[Problem with rule rhs item #]] .. rh_ix .. ' ' .. error_string
                    )
                end
                new_rh_instance = xinstance_new(new_rhs_sym, new_subalternative, rh_ix)
                xlhs_by_rhs[new_rhs_sym.id] = current_xrule.lhs.id
            end
            new_rh_instances[#new_rh_instances+1] = new_rh_instance
        end

        new_subalternative.rh_instances = new_rh_instances
        local action = src_subalternative.action
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
            src_subalternative.action = nil
        end


        local min = src_subalternative.min
        local max = src_subalternative.max
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

        new_subalternative.min = min
        src_subalternative.min = nil
        new_subalternative.max = max
        src_subalternative.max = nil

        local is_sequence = min ~= 1 or max ~= 1

        local separator_symbol
        local separator = src_subalternative.separator
        if separator ~= nil then
            if not is_sequence then
                grammar:development_error(
                    who
                    .. ': separator specified, but alternative is not sequence\n'
                )
            end
            local separator_type = type(separator)
            if separator_type ~= 'string' then
                grammar:development_error(
                    who
                    .. ': separator is type "'
                    .. separator_type
                    .. '"; it needs to be a string'
                )
            end
            local symbol_error
            separator_symbol, symbol_error
                = _symbol_new(grammar, { name = separator })
            if not separator_symbol then
                grammar:development_error(symbol_error)
            end
            new_subalternative.separator = separator_symbol
            src_subalternative.separator = nil
        end

        local separation = src_subalternative.separation
        if separation ~= nil then
            if not separator_symbol then
                grammar:development_error(
                    who
                    .. ': separation style '
                    .. [["]] .. separation .. [["]]
                    .. ' specified, but no separator\n'
                )
            end
            if separation == 'liberal' then -- luacheck: ignore
            elseif separation == 'proper' then
               separation = nil -- 'proper' is the default
            elseif separation == 'terminating' then -- luacheck: ignore
            else
                grammar:development_error(
                    who
                    .. ': unknown separation style '
                    .. [["]] .. separation .. [["]]
                    .. ' specified\n'
                )
            end
            new_subalternative.separation = separation
            src_subalternative.separation = nil
        end

        assert(not new_subalternative.separation or
            new_subalternative.separator)

        if min == 0 then
            if max == 0 then
                grammar:development_error(
                    who
                    .. [[: a nulling sequence, where min == max == 0, is not allowed ]]
                )
            end
            new_subalternative.productive = true
            new_subalternative.nullable = true
        end

        for field_name,_ in pairs(src_subalternative) do
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

        grammar.alt_id_within_top_alternative = 0
        grammar.cc_id_within_top_alternative = 0
        grammar.string_id_within_top_alternative = 0

        local old_throw_value = grammar:throw_set(true)
        local ok, new_alternative = pcall(function () return subalternative_new(grammar, args) end)
        -- if ok is false, then new_alterative is actually an error object
        if not ok then
            if old_throw_value then error(new_alternative, 2)
            else return nil, new_alternative end
        end
        grammar:throw_set(old_throw_value)
        new_alternative.xprec = grammar.current_xprec
        local xprec_top_alternatives = grammar.current_xprec.top_alternatives
        xprec_top_alternatives[#xprec_top_alternatives+1] = new_alternative

        local xtopalt_by_ix = grammar.xtopalt_by_ix
        xtopalt_by_ix[#xtopalt_by_ix+1] = new_alternative

    end

```


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

```

    -- luatangle: section+ main

    local function xrhs_transitive_closure(grammar, property)

        local changes_made

        -- ok to shadow upvalue property, I think
        local function property_of_instance_element(element,
                property) -- luacheck: ignore property

            -- print('Calling poie()', element.rawtype, element.type, element.name, property)
            if element[property] ~= nil then
                -- print('Already has', property, element[property])
                return element[property]
            end
            if element.type == 'xsym' then
                -- If a symbol with the property still not set,
                -- return nil and the symbol id
                return nil, element.id
            end

            -- If we are here, the element must be an xalt
            local rh_instances = element.rh_instances
            -- assume true, unless found false
            local element_has_property = true
            -- print('#rh_instances', #rh_instances)
            for rh_ix = 0,#rh_instances do
                -- print('rh_ix', rh_ix)
                local child_element
                -- As a bit of a hack,
                -- An rh_ix of 0 has a special meaning:
                -- check the separator
                if rh_ix == 0 then
                    -- Check only if the separator is always used
                    -- by this sequence. There is always an internal
                    -- separator is min>2; and there is always a
                    -- terminating separator, if the separation
                    -- type is 'terminating'
                    if element.separation == 'terminating' or element.min>2 then
                        child_element = element.separator
                    end
                else
                    local rh_instance = rh_instances[rh_ix]
                    child_element = rh_instance.element
                end

                -- Child element may be nil, if rh_ix==0 and we did not have
                -- or are not checking the separator
                if child_element then
                    -- print("Checking", child_element.rawtype, child_element.type,
                        -- child_element.name, "for", property)
                    local has_property = property_of_instance_element(child_element, property)
                    if has_property == nil then
                        return nil
                    elseif has_property == false then
                        element_has_property = false
                        break
                    end
                end
            end
            element[property] = element_has_property
            -- print("Setting" .. element.name .. " " .. property .. " to", element_has_property)
            changes_made = true
            -- If instance is top level
            if element.is_top then
                local lhs = element.lhs_of_top
                -- print("Setting " .. lhs.name .. " " .. property .. " to ", element_has_property)
                lhs[property] = element_has_property
            end
            return element_has_property
        end

        local xsubalt_by_id = grammar.xsubalt_by_id

        -- Make LHS symbols consist with subalternatives
        for xsubalt_id = 1,#xsubalt_by_id do
            local xsubalt = xsubalt_by_id[xsubalt_id]
            if xsubalt.is_top then
                local has_property = xsubalt[property]
                if has_property ~= nil then
                    local lhs = xsubalt.lhs_of_top
                    lhs[property] = has_property
                end
            end
        end

        changes_made = true
        while changes_made do
            changes_made = false
            for xsubalt_id = 1,#xsubalt_by_id do
                local xsubalt = xsubalt_by_id[xsubalt_id]
                property_of_instance_element(xsubalt, property)
            end
        end

    end

    local function report_nullable_precedenced_xrule(grammar, xrule)
        local precedences = xrule.precedences
        local nullable_alternatives = {}
        for prec_ix = 1, #precedences do
            local xprec = precedences[prec_ix]
            local alternatives = xprec.top_alternatives
            for alt_ix = 1, #alternatives do
                local alternative = alternatives[alt_ix]
                nullable_alternatives[#nullable_alternatives+1] = alternative
                if #nullable_alternatives >= 3 then break end
            end
            if #nullable_alternatives >= 3 then break end
        end
        local error_table = {
            'grammar_new():' .. 'precedenced rule is nullable',
            ' That is not allowed',
            [[ The rule is ]] .. xrule.name
        }
        for ix = 1, #nullable_alternatives do
            error_table[#error_table+1]
            = ' Alternative ' .. nullable_alternatives[ix].name .. " is nullable"
        end

        -- For now, report just the rule.
        -- At some point, find one of the alternatives
        -- which was nullable, and report that
        return nil,
        grammar:development_error(
            table.concat(error_table, '\n'),
            xrule.name_base,
            xrule.line
        )
    end

    local function report_nullable_repetend(grammar, xsubalt)
        local error_table = {
            'grammar.compile():' .. 'sequence repetend is nullable',
            ' That is not allowed',
            [[ The sequence is ]] .. xsubalt.name
        }

        return nil,
        grammar:development_error(
            table.concat(error_table, '\n'),
            xsubalt.name_base,
            xsubalt.line
        )
    end

    local function report_shared_precedenced_lhs(grammar, precedenced_xrule, lhs)

        local error_table = {
            'grammar.compile():' .. 'precedenced rule shares LHS with another rule',
            ' That is not allowed: a precedenced rule must have a dedicated LHS',
            [[ The precedenced rule is ]] .. precedenced_xrule.name,
            [[ The LHS is ]] .. lhs.name,
            [[ This LHS is shared with the rule ]] .. lhs.name,
        }

        -- just show at most 3 other rules
        local xrules = lhs.xrules
        local shown_count = 0
        while shown_count >= 3 do
            local other_xrule = xrules[shown_count+1]
            if other_xrule == nil then break end
            if other_xrule ~= precedenced_xrule then
                error_table[#error_table+1] =
                [[ This LHS is shared with the rule ]] .. other_xrule.name
                shown_count = shown_count + 1
            end
        end

        return nil,
        grammar:development_error(
            table.concat(error_table, '\n'),
            precedenced_xrule.name_base,
            precedenced_xrule.line
        )
    end

    -- Right now empty table indicates default semantics
    -- Maybe do something more explicit?
    local default_nullable_semantics = { }

    -- Use the alternative, which the caller has ensured is
    -- nullable, as the source of a nullable semantics
    local function nullable_semantics_create(alternative)
        local action = alternative.action
        if action then
            return { action = action }
        end
        -- return default semantics
        return default_nullable_semantics
    end

    --[[
    -- 
    -- Find and return the nullable semantics of <symbol>.
    -- On error, return nil and the error object, or else
    -- throw the error, as specified by the grammar
    -- 
    -- Semantics are
    -- 
    -- 1) Those of the only nullable alternative, when there 
    -- is only one.
    -- 
    -- 2) Those of the explicit empty rule, if there is one
    -- 
    -- 3) The default semantics, if that is the semantics of
    -- all the nullable alternatives
    -- 
    -- If none of the above are true, it is a fatal error
    -- 
    --]]

    local function find_nullable_semantics(grammar, symbol)
        local xrules = symbol.lhs_xrules
        local nullable_alternatives = {}
        local has_only_default_semantics = true
        for xrule_ix = 1, #xrules do
            local precedences = xrules[xrule_ix].precedences
            for prec_ix = 1, #precedences do
                local alternatives = precedences[prec_ix].top_alternatives
                for alt_ix = 1, #alternatives do
                    local alternative = alternatives[alt_ix]
                    if alternative.nullable then
                        local rhs = alternative.rh_instances
                        if #rhs <= 0 then
                            return nullable_semantics_create(grammar, alternative)
                        end
                        nullable_alternatives[#nullable_alternatives+1] = alternative
                        if alternative.action then
                            has_only_default_semantics = false
                        end
                    end
                end
            end
        end
        if #nullable_alternatives == 1 then
            return nullable_semantics_create(grammar, nullable_alternatives[1])
        end
        if has_only_default_semantics then
            return default_nullable_semantics
        end

        -- If here, we consider the semantics ambiguous, and report
        -- an error

        local error_table = {
            'grammar_new():' .. 'Ambiguous nullable semantics',
            ' That is not allowed',
            ' An explicit empty rule is one solution ...',
            ' The nullable semantics of an empty rule override all other choices.',
            ' The symbol with ambiguous semantics was <' .. symbol.name .. '>',
        }
        error_table[#error_table+1]
        = ' Nullable alternative #1 is ' .. nullable_alternatives[1].name
        error_table[#error_table+1]
        = ' Nullable alternative #2 is ' .. nullable_alternatives[2].name
        if #nullable_alternatives > 2 then
            error_table[#error_table+1]
            = ' Nullable alternative #'
            .. #nullable_alternatives
            .. ' is '
            .. nullable_alternatives[#nullable_alternatives].name
        end

        -- For now, report just the rule.
        -- At some point, find one of the alternatives
        -- which was nullable, and report that
        return nil,
        grammar:development_error(
            table.concat(error_table, '\n'),
            nullable_alternatives[1].name_base,
            nullable_alternatives[1].line
        )
    end

    function grammar_class.compile(grammar, args)
        local who = 'grammar.compile()'
        common_args_process(who, grammar, args)
        local at_top = false
        local at_bottom = false
        local start_symbol
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

        local xtopalt_by_ix = grammar.xtopalt_by_ix

        -- Check for duplicate topalt's
        -- ignore min,max,action, etc.
        do
            local sorted_table = {}
            for ix = 1,#xtopalt_by_ix do
                sorted_table[ix] = xtopalt_by_ix[ix]
            end

            -- return true if alt1 < alt2, nil if ==, otherwise true
            local function comparator(alt1, alt2)
                local type = alt1.type
                if type ~= alt2.type then
                    return type < alt2.type
                end
                if type == 'xcc' then
                    if alt1.cc == alt2.cc then return nil end
                    return alt1.cc < alt2.cc
                elseif type == 'xstring' then
                    if alt1.string == alt2.string then return nil end
                    return alt1.string < alt2.string
                elseif type == 'xsym' then
                    if alt1.name == alt2.name then return nil end
                    return alt1.name < alt2.name
                elseif type == 'xalt' then
                    -- Only an xalt can be the top, so only here do we
                    -- worry about the LHS
                    local lhs_name1 = alt1.xprec.xrule.lhs.name
                    local lhs_name2 = alt2.xprec.xrule.lhs.name
                    if lhs_name1 ~= lhs_name2 then
                        return lhs_name1 < lhs_name2
                    end

                    local rh_instance1 = alt1.rh_instances
                    local rh_instance2 = alt2.rh_instances
                    local rhs_length = #rh_instance1
                    if rhs_length ~= #rh_instance2 then
                        return rhs_length < #rh_instance2
                    end
                    for rh_ix = 1, rhs_length do
                        local result = comparator(
                            rh_instance1[rh_ix].element,
                            rh_instance2[rh_ix].element
                        )
                        if result ~= nil then return result end
                    end
                    return nil
                else
                    -- Should never happen
                    error("Unknown type " .. type .. " in table.sort comparator")
                end
            end
            table.sort(sorted_table, comparator)
            for ix = 1, #sorted_table-1 do
                if comparator(sorted_table[ix], sorted_table[ix+1]) == nil then
                    return nil,
                    grammar:development_error(
                        who
                        .. [[ Duplicate alternatives: ]]
                        .. sorted_table[ix].name
                        .. ' and '
                        .. sorted_table[ix+1].name
                        .. '\n'
                    )
                end
            end
        end

        local xsym_by_id = grammar.xsym_by_id
        local matrix_size = #xsym_by_id+2

        -- Not the real augment symbol, but a temporary that
        -- "fakes" it
        local augment_symbol_id = #xsym_by_id + 1

        local terminal_sink_id = #xsym_by_id + 2
        local reach_matrix = matrix.init(matrix_size)
        if at_top then
            matrix.bit_set(reach_matrix, augment_symbol_id, start_symbol.id)
        end

        xrhs_transitive_closure(grammar, 'nullable')
        xrhs_transitive_closure(grammar, 'productive')

        -- Start symbol must be a LHS
        if #start_symbol.lhs_xrules <= 0 then
            return nil,
            grammar:development_error(
                who
                .. [[ start symbol must be LHS]] .. '\n'
                .. [[ start symbol is <]] .. start_symbol.name '>\n'
            )
        end

        -- Ban unproductive symbols (and therefore rules)
        -- If we allow them, we must make sure that they, all
        -- all symbols and rule they recursively make
        -- unproductive are not used in what follows.
        -- Much of the logic requires that all symbols be
        -- productive
        --
        -- Also, we must always make sure that the start symbol
        -- is productive
        for symbol_id = 1,#xsym_by_id do
            local symbol_props = xsym_by_id[symbol_id]
            if not symbol_props.productive then
                return nil,
                grammar:development_error(
                    who
                    .. [[ unproductive symbol: ]]
                    .. symbol_props.name
                )
            end
        end

        -- Ban nullable precedenced rules.
        -- They are just too confusing. Tf the user
        -- *really* is sure they want it, and that she
        -- knows what she is doing, she can write it out
        -- in BNF.

        -- Also, ensure that precedenced LHS is not shared
        -- with any other rule. Again, this reduces confusion.
        -- There is no loss of generality. Any grammar which
        -- breaks this rule can be rewritten
        -- by adding a dedicated LHS symbol for the
        -- precedenced rule.
        -- This can be done while preserving the semantics.

        -- Also, this loop labels all precedenced alternatives
        -- with their precedence level, in preparation for later
        -- processing

        local xrule_by_id = grammar.xrule_by_id
        for xrule_id = 1,#xrule_by_id do
            local xrule = xrule_by_id[xrule_id]
            local precedences = xrule.precedences
            -- If it is a rule with multiple precedences
            if #precedences > 1 then
                local lhs = xrule.lhs
                if lhs.nullable then
                    return report_nullable_precedenced_xrule(grammar, xrule)
                end
                if #lhs.lhs_xrules > 1 then
                    return report_shared_precedenced_lhs(grammar, xrule, lhs)
                end
            end
        end

        -- Note -- use the nullability
        -- of the subalternative is not very useful,
        -- even as a clue, because the subalternative
        -- may be nullable because min=0, or
        -- non-nullable because of the separator
        --
        -- If the user really wants sequences with nullable
        -- repetends, and knows what she is doing,
        -- then she can write them out in BNF.

        local xsubalt_by_id = grammar.xsubalt_by_id
        for subalt_id = 1,#xsubalt_by_id do
            local xsubalt = xsubalt_by_id[subalt_id]
            if xsubalt.min ~= 1 or xsubalt.max ~= 1
            then

                -- Check to see if there are any
                -- indelible (= non-nullable) elements in the
                -- repetend
                local item_is_indelible = false
                local rh_instances = xsubalt.rh_instances
                for rh_ix = 1,#rh_instances do
                    local rhs_instance = rh_instances[rh_ix]
                    if not rhs_instance.element.nullable then
                        item_is_indelible = true
                        break
                    end
                end
                if not item_is_indelible then
                    return report_nullable_repetend(grammar, xsubalt)
                end
            end
        end

        -- Nullable semantics is unique
        for symbol_id = 1,#xsym_by_id do
            local symbol_props = xsym_by_id[symbol_id]
            if symbol_props.nullable then
                local semantics, error_object
                = find_nullable_semantics(grammar, symbol_props)
                if not semantics then
                    -- the lower level did not throw the error, so it
                    -- should not be thrown
                    return nil, error_object
                end
                symbol_props.semantics = semantics
            end
        end

        local xlhs_by_rhs = grammar.xlhs_by_rhs
        for symbol_id = 1,#xsym_by_id do
            local symbol_props = xsym_by_id[symbol_id]
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

    --[[

    All symbols are assumed to be productive, so if any reaches an indelible
    element, then we mark it as reaching a terminal.  This means no symbol
    which derives it can be nulling.  Indelible (or terminal) elements
    include not just non-LHS symbols, but also charclasses and strings --

    --]]

        for xsubalt_id = 1,#xsubalt_by_id do
            local xsubalt = xsubalt_by_id[xsubalt_id]
            local separator = xsubalt.separator
            local lhs_reaches_terminal = false
            if separator and not separator.nullable then
                lhs_reaches_terminal = true
            else
                local rh_instances = xsubalt.rh_instances
                for rh_ix = 1,#rh_instances do
                    local rhs_instance = rh_instances[rh_ix]
                    if not rhs_instance.element.nullable then
                        lhs_reaches_terminal = true
                        break
                    end
                end
            end
            if lhs_reaches_terminal then
                local lhs = xsubalt.lhs
                matrix.bit_set(reach_matrix, lhs.id, terminal_sink_id)
                lhs.productive = true
            end
        end

        matrix.transitive_closure(reach_matrix)

        for symbol_id = 1,#xsym_by_id do
            local symbol_props = xsym_by_id[symbol_id]

            -- Later, make it so some symbols can be set to be "inaccessible ok"
            if not matrix.bit_test(reach_matrix, augment_symbol_id, symbol_id) then
                grammar:development_error(
                    who
                    .. "Symbol " .. symbol_props.name .. " is not accessible",
                    symbol_props.name_base,
                    symbol_props.line
                )
            end

            -- Since all symbols are now productive, a symbol is nulling iff
            -- it is nullable and does NOT reach a terminal
            if symbol_props.nullable and
            not matrix.bit_test(reach_matrix, symbol_id, terminal_sink_id)
            then symbol_props.nulling = true end

            -- A nulling lexeme is a fatal error
            if #symbol_props.lhs_xrules <= 0 and symbol_props.nulling then
                grammar:development_error(
                    who
                    "Symbol " .. symbol_props.name .. " is a nulling lexeme",
                    symbol_props.name_base,
                    symbol_props.line
                )
            end
        end

        --[[ COMMENTED OUT
        for from_symbol_id,from_symbol_props in ipairs(xsym_by_id) do
            for to_symbol_id,to_symbol_props in ipairs(xsym_by_id) do
                if matrix.bit_test(reach_matrix, from_symbol_id, to_symbol_id) then
                    print( from_symbol_props.name, "reaches", to_symbol_props.name)
                end
            end
        end
        --]]

        if start_symbol.nulling then
            print(inspect(start_symbol))
            grammar:development_error(
                who
                .. "Start symbol " .. start_symbol.name .. " is nulling\n"
                .. " This is not yet implemented",
                start_symbol.name_base,
                start_symbol.line
            )
        end

        local wrule_by_id = {}
        local wsym_by_name = {}
```

    -- luatangle: section+ main

        -- luatangle: insert wsym,wrule utilities

        local function alt_to_work_data_add(xalt)
            -- at top, use brick from xrule.lhs
            -- otherwise, new internal lhs
            local new_lhs
            local precedence_level = xalt.precedence_level
            if xalt.parent_instance then
                new_lhs = lh_wsym_ensure(xalt)
            else
                local old_lhs = xalt.xprec.xrule.lhs
                if xalt.precedence_level then
                    new_lhs =
                    precedenced_wsym_ensure(old_lhs, precedence_level)
                else
                    new_lhs = cloned_wsym_ensure(old_lhs)
                end
            end

            local rh_instances = xalt.rh_instances
            -- just skip empty alternatives
            if #rh_instances == 0 then return end
            -- for now don't process precedences
            local work_rh_instances = {}
            -- print("compiling RHS ", new_lhs.name, #rh_instances)
            for rh_ix = 1,#rh_instances do
                local x_rh_instance = rh_instances[rh_ix]
                local x_element = x_rh_instance.element
                local element_type = x_element.type

                -- print("RHS element", rh_ix, x_element.name, x_element.nulling)
                -- Do nothing for a nulling instance
                if not x_element.nulling then
                    if element_type == 'xalt' then
                        -- This is always a wsym, because an xsym
                        -- LHS occurs only for a top level alternative,
                        -- and, if we are here, we are dealing with
                        -- a subalternative

                        -- Skip a nulling rh instance.
                        -- While the xalt cannot be nulling, a subalt
                        -- can be.

                        -- Because of these skips, a working rule may have
                        -- a right side shorter than the external alternative
                        -- from which it is derived.
                        -- But it will *never* be zero length, because the caller
                        -- made sure the external alternative is not nulling
                        if not x_rh_instance.nulling then
                            local subalt_wrule = alt_to_work_data_add(x_element)
                            local subalt_lhs = subalt_wrule.lhs
                            local new_work_instance = winstance_new(subalt_lhs, xalt, rh_ix)
                            work_rh_instances[#work_rh_instances+1] = new_work_instance
                        end
                    else
                        local new_element
                        local level = x_rh_instance.precedence_level
                        if element_type == 'xsym' and level ~= nil then
                            new_element =
                                precedenced_wsym_ensure(x_element, level)
                        else
                            new_element = cloned_wsym_ensure(x_element)
                        end
                        local new_work_instance = winstance_new(new_element, xalt, rh_ix)
                        work_rh_instances[#work_rh_instances+1] = new_work_instance
                    end
                end

            end

            -- I don't think it's possible for there to be an empty
            -- RHS, because the caller has ensured that the xalt is
            -- not nulling
            if #work_rh_instances <= 0 then
               error("zero length RHS " .. new_lhs.name)
            end
            assert( #work_rh_instances > 0 ) -- TODO remove after development
            local separator_xsym = xalt.separator
            local separator_wsym
            if separator_xsym then
                separator_wsym = cloned_wsym_ensure(separator_xsym)
                separator_wsym.xsym = separator_xsym
            end
            assert(not xalt.separation or separator_wsym)
            local new_wrule = wrule_ensure{
                lhs = new_lhs,
                rh_instances = work_rh_instances,
                min = xalt.min,
                max = xalt.max,
                separator = separator_wsym,
                separation = xalt.separation,
                xalt = xalt,
            }
            return new_wrule
        end

        local precedenced_instances = {}
        local function gather_precedenced_instances(xalt, lhs_id, in_seq)
            local rh_instances = xalt.rh_instances
            for rh_ix = 1,#rh_instances do
                local rh_instance = rh_instances[rh_ix]
                local element = rh_instance.element
                local type = element.type
                if type == 'xsym' then
                    if element.id == lhs_id then
                        if in_seq then rh_instance.in_seq = true end
                        precedenced_instances[#precedenced_instances+1] = rh_instance
                    end
                elseif type == 'xalt' then
                    local element_is_seq = element.min ~= 1 or element.max ~= 1
                    gather_precedenced_instances(element, lhs_id, in_seq or element_is_seq)
                end
            end
        end

        -- This logic
        -- relies on a precedenced xrule having a dedicated LHS
        for xrule_id = 1,#xrule_by_id do
            local xrule = xrule_by_id[xrule_id]
            local precedences = xrule.precedences
            local lhs = xrule.lhs
            -- If it is a rule with multiple precedences
            -- Create "precedence ladder" of wrules,
            -- and precedenced symbols
            if #precedences > 1 then
                local top_precedence_level = precedences[#precedences].level
                lhs.top_precedence_level = top_precedence_level
                for prec_ix = 1, #precedences do
                    local xprec = precedences[prec_ix]
                    local level = xprec.level
                    local alternatives = xprec.top_alternatives
                    for alt_ix = 1, #alternatives do
                        local alternative = alternatives[alt_ix]
                        alternative.precedence_level = level
                        precedenced_instances = {}
                        gather_precedenced_instances(
                            alternative, lhs.id,
                            false)
                        if #precedenced_instances > 0 then
                            if level == 0 then
                                -- Need a more precise explanation of what kind of
                                -- this *is* OK at precedence 0
                                grammar:development_error(
                                    who
                                    .. "Recursive alternative " .. alternative.name .. " at precedence 0\n"
                                    .. " That is not allowed\n"
                                    .. " Precedence 0 is the bottom level\n",
                                    alternative.name_base,
                                    alternative.line
                                )
                            end
                            local assoc = alternative.assoc or 'left'
                            -- First set them all to the next lower precedence
                            local associator_ix
                            -- Default is top level, so we do nothing for 'group' precedence
                            if assoc == 'left' then associator_ix = 1
                            elseif assoc == 'right' then associator_ix = #precedenced_instances
                            end
                            -- Second, check, correct and mark the associator
                            if associator_ix then
                                --
                                for ix = 1,#precedenced_instances do
                                    precedenced_instances[ix].precedence_level = level-1
                                end
                                local associator_instance = precedenced_instances[associator_ix]

                                if associator_instance.in_seq then
                                    -- At some point, I might add logic to allow associators
                                    -- in sequences with min>=1, automatically rewriting to
                                    -- break out the singleton. But the automatic
                                    -- rewrite would be complicated, what with the various
                                    -- sequence-separation and -termination options,
                                    -- and it is quite possible the user is writing the rule
                                    -- that way because he has not thought the matter through.
                                    -- If the user does know what he is doing,
                                    -- it may be best to require him to write out explicitly what
                                    -- he wants.
                                    grammar:development_error(
                                        who
                                        .. 'Precedence ' .. assoc .. '-associator is inside a sequence\n'
                                        .. ' That is not allowed\n'
                                        .. ' Marpa must be able to find a unique '
                                        .. assoc
                                        .. '-associator\n'
                                        .. ' Possible solution: rewrite so that an unique '
                                        .. assoc
                                        .. ' is outside the sequence\n',
                                        associator_instance.name_base,
                                        associator_instance.line
                                    )
                                end
                                associator_instance.precedence_level = level
                                associator_instance.associator = assoc
                            end
                        end
                    end
                end

                local next_ladder_lhs = cloned_wsym_ensure(lhs)
                do
                    -- We need a symbol for the top precedence level
                    -- in addition to the original symbol
                    local wsym_props = wsym_ensure(lhs.name)
                    wsym_props.xsym = lhs
                    wsym_props.precedence_level = top_precedence_level
                    for level = top_precedence_level,0,-1 do
                        wsym_props = precedenced_wsym_ensure(lhs, level)
                        wsym_props.xsym = lhs
                        wsym_props.precedence_level = level
                        wrule_ensure{lhs = next_ladder_lhs,
                            rh_instances = {winstance_new(wsym_props)},
                            }
                        next_ladder_lhs = wsym_props
                    end
                end

            end
        end

        for topalt_ix = 1,#xtopalt_by_ix do
            local xtopalt = xtopalt_by_ix[topalt_ix]
            local brick_wrule = alt_to_work_data_add(xtopalt)
            brick_wrule.brick = true
        end

        -- will be used to ensure names are unique
        local unique_number = 0

        -- We change wrule_by_id as we proceed, and
        -- so do cannot use ipairs
        for rule_id = 1,#wrule_by_id do
            local working_wrule = wrule_by_id[rule_id]

            -- As of this writing, no wrules should be
            -- deleted at this point,
            -- but we are being careful

            if working_wrule then

                -- TODO -- split rules with internal nulling
                --     events, and convert that event to
                --     a completion event

                local min = working_wrule.min
                local separator = working_wrule.separator
                local max = working_wrule.max

                -- luatangle: insert disallow nulling separator

                if min <= 0 then min = 1 end
                -- Do not need to fix working_wrule value
                -- of min because we will no longer use it

                -- Rewrite sequence rules
                if min ~= 1 or max ~= 1 then
                    local rh_instances = working_wrule.rh_instances
                    local separation = working_wrule.separation
                    -- luatangle: insert force singleton RHS in working_rule
                    -- luatangle: insert Create the repetend instance
                    -- luatangle: insert Create the separator instance if needed
                    -- luatangle: insert Normalize separation
                    -- luatangle: insert Rewrite the sequence counts
                end
            end
        end

        -- luatangle: insert Binarize the working grammar

        for rule_id = 1,#wrule_by_id do
            local wrule = wrule_by_id[rule_id]
            if wrule then print(wrule.desc) end
        end

        -- luatangle: insert census fields

    end

    -- this will actually become a method of the config object
    local function grammar_new(config, args) -- luacheck: ignore config
        local who = 'grammar_new()'
        local grammar_object = {
            throw = true,
            name = '[NEW]',
            name_base = '[NEW]',
            xrule_by_id = {},
            xprec_by_id = {},
            xtopalt_by_ix = {},
            xsubalt_by_id = {},

            xsym_by_id = {},
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
    -- This is used to name child objects of the grammar
    -- For now, it is just the name of the grammar.
    -- Someday I may create a method that allows it to be changed.
    grammar_object.name_base = name

    local field_name = next(args)
    if field_name ~= nil then
        return nil, grammar_object:development_error([[grammar_new(): unacceptable named argument ]] .. field_name)
    end

    return grammar_object
    end

    grammar_class.new = grammar_new
    return grammar_class

    --luatangle: write stdout main

```


<!--
vim: expandtab shiftwidth=4:
-->
