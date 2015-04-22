
local kollos_external = require "kollos"
local _khil = kollos_external._khil

g = k.grammar()
top = g:symbol_new()
a = g:symbol_new()
start_rule = g:rule_new(top, a)
print(start_rule)
g = nil
