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

The algorithm in Loup's tutorial is cubic time (O(s<sup>3</sup>)),
where `s` is the count of symbols in the grammar.
This algorithm can be shown to be quadratic time (O(s<sup>2</sup>)),
based on the following
observations:

* First, no symbol goes on the "work stack" more than once.

* Second, the processing for each symbol popped from the "work stack"
    is constant (`O(s)`).
    It is not linear each RHS symbol of a rule must be scanned,
    that worst-case that is on the order the number of symbols in the 
    grammar.
    Worst-case is realistic, because the time divided among the rules also
    depends on the order the number of symbols in the  grammar.

* The time is taken either in the symbol loop, or as overhead.
    Some of the pre-processing is also linear in the symbol count.

*   The overall cost of this algorithm is
```
    o + c*s,
```
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
