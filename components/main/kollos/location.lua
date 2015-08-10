--[[
  location object prototype for the Kollos project
  according to
  https://github.com/rns/kollos-luif-doc/blob/master/etc/internals.md
--]]

--[[

The blob name. Required. Archetypally a file name, but not all locations
will be in files.  Blob name must be suitable for appearing in messages.

start() and end() -- start and end positions. Length of the text will
be end - start.

range() -- start and end positions as a two-element array.

text() -- the text from start to end. LUIF source follows Lua
restrictions, which means no Unicode.

line_column(pos) -- given a position, of the sort returned by start() and
end(), returns the position in a more convenient representation. What is
"more convenient" depends on the class of the blob, but typically this
will be line and column.

sublocation() -- the current location within the blob in form suitable
for an error message.

location() -- the current location, including the blob name.

--]]

-- namespace
local location_class = {}

-- methods to go to prototype
local function location_method (location_object)
  return location_object._blob .. ': ' .. location_object._line
end

-- Only for errors -- it does a lot of checking which
-- usually should be unnecessary.
-- We query subtype often and do
-- not even want call a function every time we do it
local function trace_subtype(location_object)
   local metatable = getmetatable(location_object)
   if not metatable then
     error("Bad location object: no metatable")
   end
   local prototype = metatable.__index
   if not prototype then
     error("Bad location object: metatable has no __index prototype")
   end
   if not prototype._type or prototype._type ~= 'location' then
     error("Bad location object: prototype is not for location object")
   end
   return location_object._subtype
end

local function cursor_set(self, new_cursor)
    if self._subtype ~= 'reader' then
        error("cursor_set() called, but object is ", trace_subtype(self))
    end
    self.cursor = new_cursor
end

local function cursor(self)
    if self._subtype ~= 'reader' then
        error("cursor() called, but object is ", trace_subtype(self))
    end
    return self.cursor
end

--[[
This is for optimized reading of long strings, so that we don't have to
call a function for each character
--]]
local function fixed_string(self)
    if self._subtype ~= 'reader' then
        error("fixed_string() called, but object is " .. trace_subtype(self))
    end
    return self._string, self.cursor
end

-- Some day we may do dynamic strings, and this method may
-- be less efficient than fixed_string(), but will
-- work with them.
local function string_method(self) -- luacheck: ignore self
    error('location.string() is not yet implemented')
end

local default_prototype = {
    _type = 'location',
    _fixed = true, -- for now, all strings fixed for the
                  -- life of the prototype
    _blob = '[No file]',
    _line = '[No line data]',
    location = location_method,
    cursor_set = cursor_set,
    cursor = cursor,
    fixed_string = fixed_string,
    string = string_method
}

-- metatable
location_class.mt = {}

-- the __index metamethod points to prototype

-- Basic constructor, creates a location from a string.
-- It creates a dedicated metatable and prototype.
-- Other locator objects referring to this same string will
-- be created from this one, and share the same metatable
-- and prototype
function location_class.new_from_string (string)
    local location_object = { _subtype = 'reader', cursor = 1 }
    local prototype = {}
    for field,default_value in pairs(default_prototype) do
         prototype[field] = default_value
    end
    prototype._string = string
    local metatable = {}
    metatable.__index = prototype
    metatable.__tostring = prototype.location
    setmetatable(location_object, metatable)
    return location_object
end

return location_class
