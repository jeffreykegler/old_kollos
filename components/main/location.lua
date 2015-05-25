--[[
  location object prototype for the Kollos project
  according to
  https://github.com/rns/kollos-luif-doc/blob/master/etc/internals.md
--]]

--[[

-- the blob name. Required. Archetypally a file name, but not all locations will be in files.
Blob name must be suitable for appearing in messages.

start() and end() -- start and end positions. Length of the text will be end - start.

range() -- start and end positions as a two-element array.

text() -- the text from start to end. LUIF source follows Lua restrictions, which means no Unicode.

line_column(pos) -- given a position, of the sort returned by start() and end(), returns the position in a more convenient representation. What is "more convenient" depends on the class of the blob, but typically this will be line and column.

sublocation() -- the current location within the blob in form suitable for an error message.

location() -- the current location, including the blob name.

--]]

-- namespace
local location_class = {}

-- methods to go to prototype
function location_class.location (location_object)
  return location_object.blob .. ': ' .. location_object.line
end

-- prototype with default values and methods
location_class.prototype = {
  _type = "location", blob = "", text = "", line = "",
  location = location_class.location,
}

-- constructor
function location_class.new (location_object)
  setmetatable(location_object, location_class.mt)
  return location_object
end

-- metatable
location_class.mt = {}

-- the __index metamethod points to prototype
location_class.mt.__tostring = location_class.location
location_class.mt.__index = location_class.prototype

return location_class
