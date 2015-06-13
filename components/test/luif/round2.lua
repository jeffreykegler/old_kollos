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

K = require 'kollos'

kollos.if('alpha')

l0 = K:grammar_new()

l0:alternative{'E', 'number', exp = 'number'}
l0:precedence{}
l0:alternative{'E',
   'E',
   l0:seq{'ws', min = 0, max = 1 },
   l0:string'*',
   l0:seq{'ws', min = 0, max = 1 },
   'E',
   exp = 'E*E'}
l0:precedence{}
l0:alternative{'E',
   'E',
   l0:seq{'ws', min = 0, max = 1 },
   l0:string'+',
   l0:seq{'ws', min = 0, max = 1 },
   'E',
   exp = 'E+E'}
l0:token{'ws', '[\009\010\013\032]', exp = 'nil' }
l0:token{'number', l0:seq{l0:token'[%d]', min = 1}}

-- vim: expandtab shiftwidth=4:
