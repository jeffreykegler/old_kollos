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
local _klol = kollos_external._klol

-- print (table.tostring(kollos_external))

luif_err_none = _klol.error.code['LUIF_ERR_NONE']
luif_err_unexpected_token = _klol.error.code['LUIF_ERR_UNEXPECTED_TOKEN_ID']

g = _klol.grammar()
top = g:symbol_new()
seq = g:symbol_new()
item = g:symbol_new()
item = g:symbol_new()
prefix = g:symbol_new()
body = g:symbol_new()
a = g:symbol_new()
start_rule = g:rule_new(top, seq)
seq_rule1 = g:rule_new(seq, item)
seq_rule2 = g:rule_new(seq, seq, item)
item_rule = g:rule_new(item, prefix, body)
body_rule = g:rule_new(body, a, a)
g:start_symbol_set(top)
g:precompute()

r = _klol.recce(g)
r:start_input()

pass_count = 0
max_pass = arg[1] or 10000
for pass = 1,max_pass do

  result = r:alternative(prefix, 1, 1)
  result = r:earleme_complete()

  while r:is_exhausted() ~= 1 do
    result = r:alternative(a, 1, 1)
    if (not result) then
      -- print("reached earley set " .. r:latest_earley_set())
      break
    end
    result = r:earleme_complete()
    if (result < 0) then
      error("result of earleme_complete = " .. result)
    end
  end
  pass_count = pass_count + 1;

end

print("completed " .. pass_count .. " passes")


g = nil
r = nil
