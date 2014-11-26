# Kollos: the grammar rewrite

Marpa follows, and greatly expands on,
Aycock & Horspool's use of semantics-friendly
rewrites for implementing
the Earley algorithm.
Eventually, I intend to expand the rewriting even
further.

Intuitively,
"Semantics-friendly" means that you can very quickly
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

### Restrictions on sequence rules

The RHS symbol and,
if there is one, the separator of a sequence rule
cannot be nullable.

### Restrictions on multi-precedence symbols

Multi-precedence symbols have several restrictions.
A multi-precedence symbol is one with more than one PKS.
Equivalently, it is a symbol on the LHS of a rule with a double
bar operator (`||`) ].
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
by a completely different semantics
when the rule happens to be nulled.  In the SLIF, there's a third possibility.  A nullable LHS is OK if all rules have the same semantics.
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
 The only semantics active symbols are the KPSs
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

  
