# Kollos: the grammar rewrite

Marpa, and greatly expands on,
follows Aycock & Horspool in making a semantics-friendly
grammar rewrite a major part of the algorithm.
Eventually, I intend to expand the rewriting even
further.

Intuitively,
"Semantics-friendly" means that you can very quickly
go from the "rewritten" symbols and rules
back to the "original" symbols and rules.
And that you can do this, not only after
the parse is over, but during it
to allow "on the fly" examination of
and changes to the parse,
made in terms of the "original"
symbols.
TO DO: Show how to do this.
[ It will be along the lines of Libmarpa,
and the SLIF, which already do *a lot* of this. ]

## Kinds of symbols

For Kollos, we will need several "layers" of symbols.

### Kollos symbols

These are symbols represented in the original DSL.
Their name is their literal LUIF representation,
where feasible.
For character classes,
a name is dummied up of the form `[CC-42]`,
where 42 is some non-negative integer.
For quoted strings,
a name is dummied up of the form `[QS-42]`,
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

Every Kollos symbol has at least once precedenced
counter part.
For the Kollos symbol `base`, it would be `base@0`.

### Intermediate symbols

Intermediate symbols are used in the rewrite, and exist
only during the rewrite.  They has names in
some internal form to be determined.

### Libmarpa symbols

These symbols are the result of the rewrite,
and are the ones used in creating the Libmarpa grammar.
They has names in
some internal form to be determined.

## Prohibitions

For reasons that I think will become clear
as we do the writing,
some possibilities are forbidden.

FUTURE: Some of these prohibitions might be eased,
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

### Restrictions on sequence rules

The RHS symbol and,
if there is one, the separator of a sequence rule
cannot be nullable.

### Restrictions on multi-precedence symbols

Multi-precedence symbols have several restrictions.
A multi-precedence symbol is one with more than one PKS.
Equivalently, it is a symbol on the LHS of a rule with a double
bar operator (`||`) ].
Such a rule is said to the multi-precedence's symbol's home
rule.

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

### Restrictions on nullabe rules

The LHS of a nullable rule must
  * be the LHS of only one rule; or
  * be the LHS of an empty rule.

This is in order for the semantics to be unambiguous,
and to prevent the user from being surprised
by a completely different semantics
when the rule happens to be nulled.  In the SLIF, there's a third possibility.  A nullable LHS is OK if all rules have the same semantics.
But figuring out whether two semantics are "identical" is tricky,
and I think this simpler way makes more sense.
