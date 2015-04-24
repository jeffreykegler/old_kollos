
local kollos_external = require "kollos"
local _khil = kollos_external._khil

g = _khil.grammar()
print(g)
print(g.symbol_new)
print("hello before calls to symbol new")
top = g:symbol_new()
print("hello between calls to symbol new")
a = g:symbol_new()
start_rule = g:rule_new(top, a)
g:start_symbol_set(top)
g:precompute()
print(start_rule)
g = nil
