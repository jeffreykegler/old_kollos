Principles of the project
=========================

I hope it's OK if I pontificate a bit, but I think neglect of
these guidelines has caused a *lot* of skilled time and effort
to be simply wasted, and that there's not enough concern about that.

A project should be specifically targeted
=========================================

The target has to be specific, but it does not have to be interesting,
or have a future.  This sounds preposterous and, as if it's sure to
hobble the vision behind a project, but the record shows otherwise.
UNIX was targeted at a long-forgotten game.
Perl was targeted at a long-forgotten database (was it bug tracking?).
Linux was targeted at Linus's desire to have a terminal server so he
could dial into the university.

The Linux goal is an especially good example -- how does a terminal server turn into
an industrial quality OS?  Well, if you want it to be able to print from it,
you need multi-tasking and I/O, so you in fact have a nice running start.

All of the target apps I mention are long forgotten, but they kept their
projects focused.

Get user base as soon as reasonable, and be loyal to it
=======================================================

Marpa::R2 bug fixes (mercifully rare) are not my first love,
but they are my first priority.
Because Marpa::R2's users are the ones who were there when I needed
a community.
Kollos is going to be much more cool, and it's more fun to work on,
but it has to take second priority.

Similarly, within Kollos, we will have to stay alpha, but we want to
produce something we can stabilize as soon as reasonable,
and make that reliable.
The best way I've found to do this is by freezing old versions as soon
as the cost of new features to their base begins to approach the benefit,
and move development over to new ones.

Perl was always difficult in this respect, because both
its culture and its infra-structure tended to force upgrades.
It was genuinely hard in Perl to freeze your setup,
and the desire to do so sometimes ridiculed as Ruby-ish thinking.
I'm no expert on Ruby-ish thinking, but if that's it, I'm for it.

Lua's model is more reasonable.  Each new minor version does not
try to be compatible with the previous one.
But there's no pressure to upgrade -- in fact at this point
most of the Lua community seems to be one, going on two,
releases behind, and in no hurry to do anything about that.
For bug fixes, Lua does new micro-numbered versions within
each minor version.

