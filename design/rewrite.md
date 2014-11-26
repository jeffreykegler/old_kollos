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

