# Kollos: sequence rule rewrite

This document describes how the LUIF rewrites
sequence rules.

[ Lots and lots to be added here. ]

A naive approach to
a rewrite of rules of the form `A ::= B{min,max}`
would rewrite `A ::= B{42,1041}` into
1000 BNF rules.
We will try to do better than this,
with a binarized approach.
There is
[a Perl script in a Github
gist](https://gist.github.com/jeffreykegler/2324781#file-minmax_to_bnf-pl)
implementing an algorithm for doing this.

<!---
vim: expandtab shiftwidth=4
-->
