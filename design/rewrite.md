# Kollos: the grammar rewrite

Marpa follows, and greatly expands on,
Aycock & Horspool's use of semantics-friendly
rewrites for implementing
the Earley algorithm.
Eventually, I intend to expand the rewriting even
further.

Intuitively,
"semantics-friendly" means that you can very quickly
go from the "rewritten" symbols and rules
back to the "original" symbols and rules.
And that you can do this, not only after
the parse is over, but during it,
to allow "on the fly" examination of
and changes to the parse,
made in terms of the "original"
symbols.

TO DO: Show how to do this.
[ It will be along the lines of Libmarpa,
and the SLIF, which already do *a lot* of grammar
rewriting. ]

## Kinds of symbols

For Kollos, we will need several "layers" of symbols.

### Kollos symbols

These are symbols represented in the original DSL.
Their name is their literal LUIF representation,
where feasible.
For character classes,
a name is dummied up of the form `[cc-42]`,
where 42 is some non-negative integer.
For quoted strings,
a name is dummied up of the form `[qs-42]`,
where 42 is some non-negative integer.

### Precedenced Kollos symbols

Precedenced Kollos symbols (PKSs)
are Kollos symbols with a precedence added.
Their names are of the form `base@43`,
where `base` is a Kollos symbol
and `43` is an integer.
The integers show precedence as follows:

+ 0 means tightest precedence
+ 1 means 2nd tightest precedence
+ -2 means 2nd loosest precedence
+ -1 means loosest precedence

FUTURE: In future, we may allow PKSs
to appear explicitly in the DSL.

Every Kollos symbol has at least one precedenced
counterpart.
For the Kollos symbol `base`, it would be `base@0`.

### Intermediate symbols

Intermediate symbols are created at the beginning of
the rewrite, and destroyed after it.
They have names in
some internal form to be determined.

### Libmarpa symbols

These symbols are the result of the rewrite,
and are the ones used when creating the Libmarpa grammar.
They have names in
some internal form to be determined.

## Guidelines for rewrites

All rewrites must follow certain principles 
in order to guarantee they can be reversed efficiently.
When a rule is rewritten, it is rewritten into
one or more other rules.
using "brick" symbols and "mortar" symbols.
Intuitively, the brick symbols represent symbols
from the original rule, and the "mortar" symbols
glue them together.

There is a total function from the set of
brick symbols to the set of original symbols,
and it is a surjection.
In other words, every brick symbols maps to
an original symbol;
and every original symbol has one or more
brick symbols which map to it.
The mortar symbols do *not* map to the original
symbols.

In every parse or partial parse of any input
that uses
the rewritten rules,
every instance of a rewritten rule must be
part of a subtree that obeys the following rules:

+ The top symbol of the subtree must be
  a brick symbol mapping to the original rule's LHS.

+ The terminals of the subtree
  must be brick symbols mapping to one of the original rule's RHS
  symbols.

+ When the subtree is traversed
  left-to-right, bottom-to-top,
  the order in which the brick symbols of the subtree
  are encountered as follows:

  * For BNF rules,
    first, exactly one brick symbol mapping
    to each RHS symbol in the
    order in which it occurs
    on the rule's RHS;
    and then a brick symbol
    mapping to the original LHS symbol.

  * For sequence rules,
    zero or more brick symbols mapping to
    the original RHS symbol;
    then a brick symbol mapping
    to the original LHS symbol.

  * For alternatives and precedented rules,
    brick symbols as required
    for one of the rule alternatives,
    as described above for BNF rules.

Each rewrite must track which brick symbols are
"hidden" in their original rules.
A rewritten rule whose LHS is a brick symbol
mapping to the original rule's LHS is
called a *semantically active rule*.
A rule is semantically inactive
if it is not a semantically active rule.
Semantically inactive rules are
also called intermediate rules.

## Prohibitions

For reasons that I think will become clear
as we do the writing,
some possibilities are forbidden.

FUTURE: A few of these prohibitions might be eased,
or eliminated.
In doing so we should consider whether we're not
giving the user too much freedom to shoot himself
in the foot.

Implementation of these will require
a lot of transitive closures.
For these we should use Warshall's algorithm,
already implemented within Libmarpa.

### Cycles

Cycles are prohibited, for now.
This will change in favor of a rewrite at some point.
The rewrite will write the grammar into a form which uses
the rules involved in the cycle,
but does not actually allow a cycle.
(This idea is that this rewrites grammars with
unintended cycles into a form which is cycle-free
and perhaps what the grammar author intended.)

### Restrictions on sequence rules

The RHS symbol cannot be nullable.
The separator of a sequence rule,
if there is one, cannot be nullable.

### Restrictions on multi-precedence symbols

Multi-precedence symbols have several restrictions.
A multi-precedence symbol is one with more than one PKS.
Equivalently, it is a symbol on the LHS of a rule with a double
bar operator (`||`).
Such a rule is said to be a *home rule*
of the multi-precedence symbol.

  + A multi-precedence symbol cannot be nullable.
  + A multi-precedence symbol cannot be on the LHS of more than one rule.
    This implies that a multi-precedence symbol
    can have only one home rule.
  + A multi-precedence symbol cannot be on the RHS of any rule,
   unless
      * that rule is its home rule, or
      * that rule's LHS cannot be derived
        from the multi-precedence symbol.

Intuitively, the last restriction say that a multi-precedence symbol cannot
be "downstream" from its home rule.

### Restrictions on nullable rules

The LHS of a nullable rule must
  * be the LHS of only one nullable rule; or
  * be the LHS of an empty rule.

This is in order for the semantics to be unambiguous,
and to prevent the user from being surprised
by a sudden change to a completely different semantics
when the rule happens to be nulled.
In the SLIF, there's a third possibility.
A nullable LHS is OK if all rules have the same semantics.
But figuring out whether two semantics are "identical" is tricky,
and I think this simpler way makes more sense.

## Pseudo-code

* Get the Kollos symbols and rules from the LUIF DSL script.

* Convert all character classes and single-quoted strings to Kollos symbols.

* Create the precedenced Kollos symbols.  [ I need to describe how to do
  this for multi-precedenced rules. ]

* Expand the multi-precedenced rules into single-precedenced rules.
  [ TO DO: I need to describe how to do this.  It's already done in
  the SLIF. ]

* Expand all rules into rules with a single alternative.

* For rules which have one or more sequences on their RHS, expand the
  sequences into rules
  whose RHS is a single symbol.

* Expand all explicitly counted sequences (`a{7,42}`)
  into ordinary BNF rules and
  star (`*`) or plus (`+`) sequences.
  [ TO DO: I need to explain how to do this.  Numbered sequences should
  not be implemented with long RHS's.
  Instead they should be binary-factored.
  I actually wrote up the logic for this and posted it to the
  Google group some months ago. ]

* Copy the intermediate symbols and rules to Libmarpa rules and symbols.
  When copying,
  do not include inaccessible and unproductive rules and symbols.

* Create the Libmarpa grammar.

## Notes

### External semantics by LHS symbol

TO DO:
I need to describe how to do this.  Hint:
The only semantically active symbols are the PKSs
which appear on a LHS.
The semantics can be done with dual stacks
(one for rules, one for symbols),
and tracking which symbols are "virtual" and
which are "physical" in the sense they are directly
equivalent to a Kollos symbol.
This is the mechanism currently used by the SLIF.
I'm thinking of changing this method to take account
of hidden symbols,
in addition to virtual ones.

### History

The Libmarpa symbols should contain a "history"
of their creation, in some compact form.

### Mapping symbols

PKSs are a partial function of Libmarpa symbols --
every Libmarpa symbol maps to zero or one PKS.
(Many Libmarpa symbols will be "virtual" in the
sense they do not correspond directly to any PKS.)

A PKS maps to one or more Libmarpa symbols,
unless the PKS is inaccessible or unproductive.

There is a total function from the set of
PKSs to the set of Kollos symbols.
Every PKS maps to exactly one Kollos symbol.

Every Kollos symbol maps to one or more PKS.

  
