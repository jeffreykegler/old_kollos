--[[
Copyright 2015 Jeffrey Kegler
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
--]]

-- Prototype the LUIF parser

-- local inspect = require 'kollos.inspect'
require 'Test.More'
-- luacheck: globals ok plan
plan(1)

-- luacheck: globals __LINE__ __FILE__

local K = require 'kollos'

local kollos = K.config_new{interface = 'alpha'}

ok(kollos, 'config_new() returned')

local l0 = kollos:grammar_new{ line = __LINE__, file = __FILE__,  name = 'l0' }
l0:line_set(__LINE__)
l0:rule_new{'top'}
l0:alternative_new{'a', 'a', 'a', 'a'}
l0:line_set(__LINE__)
l0:rule_new{'a'}
l0:alternative_new{l0:string'a'}
l0:alternative_new{}
l0:compile{ seamless = 'top', line = __LINE__}

local r0 = l0:recce_new()
r0:start()
local lexer_factory = l0.default_lexer_factory
local input = 'aaaa'
local lexer = lexer_factory(r0, 'aaaa', input)
r0:lexer_set(lexer)
r0:read()
print(r0:progress_report())

local b0 = r0:bocage_new()
print(b0:show())
print(b0:_verbose_or_nodes())

-- vim: expandtab shiftwidth=4:
