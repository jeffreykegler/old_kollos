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

luif_err_none = _khil.error.code['LUIF_ERR_NONE']

g = _khil.grammar()
top = g:symbol_new()
main = g:symbol_new()
prefix = g:symbol_new()
body = g:symbol_new()
a = g:symbol_new()
start_rule = g:rule_new(top, main)
main_rule = g:rule_new(main, prefix, body)
body_rule = g:rule_new(body, a, a)
g:start_symbol_set(top)
g:precompute()

print("is top terminal? ", g:symbol_is_terminal(top))
print("is main terminal? ", g:symbol_is_terminal(main))
print("is body terminal? ", g:symbol_is_terminal(body))
print("is prefix terminal? ", g:symbol_is_terminal(prefix))
print("is a terminal? ", g:symbol_is_terminal(a))

r = _khil.recce(g)
r:start_input()

result = r:alternative(a, 1, 1)
if (result ~= luif_err_none) then
    error(_khil.error.name(result))
end

result = r:earleme_complete()
print("result of earleme_complete = ", result)

-- result = r:alternative(a, 1, 1)
-- print("result of alternative = ", result, _khil.error.name(result))
-- result = r:earleme_complete()
-- print("result of earleme_complete = ", result)

-- result = r:alternative(a, 1, 1)
-- print("result of alternative = ", result, _khil.error.name(result))
-- result = r:earleme_complete()
-- print("result of earleme_complete = ", result)

g = nil
r = nil
