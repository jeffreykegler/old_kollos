<!--

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[ MIT license: http://www.opensource.org/licenses/mit-license.php ]

-->

# Kollos "mid-level" recognizer code

This is the code for the "middle layer" recognizer
of Kollos.
Below it is Libmarpa, a library written in
the C language which contains the actual parse engine.

## Constructor

    -- luatangle: section Constructor

    function new()
    end

## Finish and return the recce class object

    -- luatangle: section Finish return object

    local recce_class = {
        new = new
    }
    return recce_class

## Output file

    -- luatangle: section main
    -- luatangle: insert Constructor
    -- luatangle: insert Finish return object
    -- luatangle: write stdout main

<!--
vim: expandtab shiftwidth=4:
-->
