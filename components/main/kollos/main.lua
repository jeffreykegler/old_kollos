-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]

local kollos_c = require 'kollos_c'
local location = require 'kollos.location'
local development = require 'kollos.development'
local kollos_util = require 'kollos.util'
local wrap = require 'kollos.wrap'
local lo_g = require 'kollos.lo_g'
local config = require 'kollos.config'

-- local luif_err_none = kollos_c.error_code_by_name['LUIF_ERR_NONE']
local error_object = kollos_c.error_new();
local error_metatable = getmetatable(error_object)
print(__FILE__, __LINE__)
error_metatable.__tostring = function (object)
    if type(object.stringize) == 'function' then
        print(__FILE__, __LINE__)
        return object.stringize(object)
    end
    if type(object.string) == 'string' then
        print(__FILE__, __LINE__)
        return object.string
    end
    if type(code) ~= 'number' then
      local description = kollos_c.error_description(code)
      local name = kollos_c.error_code_by_name(code)
      return name .. '(' .. code .. '): ' .. description
    end
    return "Error code ('" .. code .. "')is not a number"
end

local kollos_error = {
  name = kollos_c.error_name,
  description = kollos_c.error_description,
  code_by_name = kollos_c.error_code_by_name,
  throw = kollos_c.error_throw,
  new = kollos_c.error_new,
}

local kollos_event = {
  name = kollos_c.event_name,
  description = kollos_c.event_description,
  code_by_name = kollos_c.event_code_by_name,
}

return { location = location,
  ["error"] = kollos_error,
  event = kollos_event,
  util = kollos_util,
  lo_g = lo_g,
  wrap = wrap,
  config_new = config.new,
  development_error = development.error
}

-- vim: expandtab shiftwidth=4:
