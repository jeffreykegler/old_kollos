# Notes on Loup's tutorials #2: Finding nullables

This is the second in my series of notes on Loup's tutorial series
on Earley parsing.
Loup is doing an excellent job not only of presenting the basics,
but of pointing the way toward more advanced approaches.
This note is on Loup's
[tutorial on the handling of empty rules]
(http://loup-vaillant.fr/tutorials/earley-parsing/empty-rules).

This note will be about the code at the end of the tutorial.
There Loup describes a way

1.  to find the set of nullable symbols in a grammar; and
2.  to use this set while parsing.

This note will present an alternative way to find the set
of nullables.  Here it is, in pseudo-code:

* Create a table of lists of rules, indexed by LHS

* Create a table of lists of rules, indexed by RHS symbol.

* Create a list of empty rules.

*   Create an `nullable[symid]` array:
    an array of booleans, indexed by symbol ID.
    The boolean is `ON`, if the symbol has been marked
    "nullable", `OFF` otherwise.

*   Initialize the `nullable` array, by marking
    as nullable the LHS of every empty rule.

*   Create a "work stack", which will contain 
    those symbols which still need to be worked on
    in order to find all nullable symbols.
    Initialize it by pushing all the symbols initially
    marked as nullable in the `nullable` array.

*   Symbol loop: While symbols remain on the "work stack", do the following:

    + Pop a symbol -- we'll call it the work symbol.

    + Rule loop: For every rule with the work symbol on its RHS, call it the "work rule"

        *   If the LHS of the work rule is already marked nullable,
            we do not need to look at this rule --
            continue with the next rule of the rule loop.

        *   For every RHS symbol of the work rule,
            if it is not marked nullable, 
            continue with the next rule of the rule loop.

        *   If we reach this point, the LHS of the work rule is nullable,
            but is not marked nullable.

        * Mark the LHS of the work rule nullable.

        * Push the LHS of the work rule onto the "work stack".

        * Continue with the next rule of the rule loop.

    + Continue with the next symbol of the symbol loop.

* When there are no symbols left in the "work stack",
    all the nullable symbols will have been marked in the `nullable`
    array.

This algorithm is implemented in Marpa.
The above pseudo-code is a stream-lined version of the C code,
which can be found in the
[latest Marpa source]
(https://drive.google.com/file/d/0B9_mR_M2zOc4WjI1dU02QnhVQVU/view?usp=sharing),
on pages 293-295, sections 1120-1124.

The C code in the Marpa listing does not refer
to nullables directly, but instead speaks
of the "RHS closure" of some property.
This is because the identical logic also works for determining
whether a symbol is productive or not.
Therefore the code abstracts the logic into an
algorithm to find "the RHS closure" of a bit vector,
where the an `ON` bit can mean "nullable" or "productive",
as required.

## Possible improvement

It won't change the time complexity, but using a "work queue" instead
of a "work stack" -- that is a FIFO instead of a LIFO -- might be
faster in practice.
Note that since no symbol is pushed more than
once,
the stack (or queue) will never be larger than the number of symbols,
and may therefore be of fixed size.

## Proof of correctness

Folks who don't care about proofs can stop reading here.
They are in fact very helpful for coming up with, understanding
and improving the algorithm,
but they are certainly not necessary if you only want to implement it.

### The "nulling height" of rules and symbols

First we define *nulling height* for rules and for symbols.
The definition is inductive.

* The nulling height of an empty rule is -1.

* The nulling height of a rule is `n + 1`,
    where `n` is the highest nulling height of any of its RHS symbols.
    The nulling height of a rule is not defined if the nulling height of any symbol
    on its RHS is not defined. 

* The nulling height of a symbol is `n + 1` where `n`
    is the lowest nulling height of a rule with that symbol on its LHS.
    The nulling height of a symbol is not defined if it is not on the LHS
    of at any rule.

Note that these definition imply that the nulling height of any symbol
that is on the LHS of an empty rule is 0.
It can be seen by induction on this definition that nulling height
is defined for a symbol if and only if it derives the empty string
in a finite number of derivation steps.
In other words, the nulling height of a symbol is defined
if and only if it is nullable.

### If a symbol is marked nullable, it has a nulling height

By examining the pseudo-code,
it is straightforward to confirm that
no symbol is marked nullable unless

* it is initialized nullable, or

* it is on the LHS of a rule all of whose RHS symbols are marked nullable.

It is easy to show that by induction that
no symbol will be marked nullable unless it has a nulling height.
Less obvious is the converse, which we will show next.

### If a symbol has a nulling height, our algorithm marks it nullable.

The proof is by strong induction on the nulling height of symbols.
The basis of the induction
is that all symbols of nulling height 0 are marked nullable.
The basis is given by the initialiation of the "work stack",
as can be confirmed by examining the pseudo code.

For the step of the induction, we assume that
all nullables of nulling height `n` or less are marked
nullable, and seek to show that
our algorithm will mark as nullable
any nullable symbol `x` of nulling height `n + 1`.

First, from the definition of nulling height,
we can see that symbol `x` is on the LHS
of at least one rule,
call it `rule_n`
all of whose RHS symbols have a nulling height of
`n` or less.
Let `rule_n` be
```
     <x> ::= <rhs1> <rhs2> ... <rhs_n>
```
By the assumption for the step,
we can see that
all of the symbols
`rhs1`, `rhs2`, ... `rhs_n`,
will have been marked nullable,
and from inspection of the pseudo-code,
we can see that when they were marked nullable,
they were also pushed onto the "work stack".

Of the symbols `rhs1`, `rhs2`, ... `rhs_n`,
one of them,
call it `rhs_last`,
will be the last to be popped off the "work stack".
Since `rhs_last` is the last symbol
in the series `rhs1`, `rhs2`, ... `rhs_n`
to be popped,
all the symbols in that series
will already have been popped from the work stack,
and, since they were marked nullable when they were
put on the work stack,
all the symbols in the series
will have been marked nullable.

From inspection of the pseudo-code,
this means that the LHS of `rule_n` will be marked nullable
and put onto "work stack",
if it has not been already.
The LHS of `rule_n` is the symbol `x`,
and showing that 
this will be marked nullable is what was needed to
show the step of the strong induction.

### Concluding the correctness proof

Showing the strong induction shows that all symbols with
a defined nulling height are marked nullable by our algorithm.
Earlier we showed that only symbols with a defined nulling height
are marked nullable by our algorithm.
So we know that our algorithm marks a symbol nullable if
and only if it has a nulling height.
We saw, when defining nulling height,
that having a defined nulling height is equivalent
to being nullable.
This concludes our proof of correctness.
QED.

## Proof of time complexity

The algorithm in Loup's tutorial is cubic time (O(s<sup>3</sup>)),
where `s` is the count of symbols in the grammar.
This algorithm can be shown to be quadratic time (O(s<sup>2</sup>)),
based on the following
observations:

* First, no symbol goes on the "work stack" more than once.

* Second, the processing for each symbol popped from the "work stack"
    is linear in the number of symbols -- `O(s)`.
    This is because each symbol on the RHS of a rule must be looked at,
    and worst-case is
    that this is on the order the number of symbols in the 
    grammar.

* The time is taken either in the symbol loop, or as overhead.
    Some of the pre-processing is also linear in the symbol count.

*   The overall cost of this algorithm is ` o + c*s`,
    where `o` is the overhead
    outside the symbol loop, `c` is a constant which bounds the time consumed
    on each pass through the symbol loop,
    and `s` is the number of symbols,
    so that the time complexity is
    
    `o + c*s = O(s) + O(s)*O(s) = O(`s<sup>2</sup>`)`

For more about
[Marpa](http://savage.net.au/Marpa.html),
see its web site.

<!---
vim: expandtab shiftwidth=4
-->
