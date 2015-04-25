
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
r = _khil.recce(g)
r:start_input()
result = r:alternative(a, 1, 1)
print("result of alternative = ", result)
result = r:earleme_complete()
print("result of earleme_complete = ", result)
g = nil
r = nil
