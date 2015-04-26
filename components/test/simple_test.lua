function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

local kollos_external = require "kollos"
local _khil = kollos_external._khil

-- print (table.tostring(kollos_external))

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
print("result of alternative = ", result, _khil.error.name(result))
result = r:earleme_complete()
print("result of earleme_complete = ", result)
g = nil
r = nil
