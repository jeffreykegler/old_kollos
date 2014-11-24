# About Kollos

## What is Kollos?

Kollos is the next phase of Marpa.  Today, Marpa's main implementation consist of these pieces:

+ a C library, called Libmarpa, which implements the core parse engine.  It's very low-level --
for example, there are no strings.  Rules, symbols, error messages, etc. are all integers.

+ a Perl/XS wrapper, also in C, which provides the necessary upper layer for Libmarpa.

+ pure Perl logic, which combined with the previous two becomes Marpa::R2, a Perl module

Kollos will replace the Perl/XS wrapper with Lua.
In the process Lua will become the language for Marpa's semantics --
that is, you'll be able to specify custom logic in Lua.
Lua is extremely minimal and lightweight, and is perfect for this purpose.

## What are the advantages foreseen for Kollos?

First, currently several of Marpa's nicest featurs rely on Perl callbacks
for their custom logic, which is costly.
To a certain extent, Marpa lets you bypass this, and in doing so, it has evolved its
own virtual machine.
Kollos will replace this "evolved" virtual machine with Lua, which will be much more
powerful, no bigger, and (I expect) faster.

Second, the current Marpa implementation, which has to support
a number of deprecated interfaces and features, is a bit of a morass.
This makes it difficult to add new features from being added to Marpa::R2,
especially now that it is seeing major usage,
and stability and backward compatibility is important.
With Kollos, I will freeze Marpa::R2.
New features will go into Kollos.

## Will Kollos be compatible with Marpa::R2

No.  Old features will only be kept based on their merits.
Behavior won't be changed capriciously, but it will be
changed if there is any good reason to do so.

## What will happen to the SLIF?

Kollos will have a new interface langauge, the LUIF.
It will look like Lua, except that it will also have BNF
statements which declare rules.
The design of the LUIF is in progress.

## Which version of Lua will you use?

Lua 5.1.  Because it is compatible with the LuaJit.
Also because it is the most heavily supported in Perl.
