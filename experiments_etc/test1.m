
% Author: Ofir Weisse, mail: oweisse (at) umich.edu, www.ofirweisse.com
%
% MIT License
%
% Copyright (c) 2016 oweisse
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.


f = fopen( 'c:/dev/DPA/Repo/DPA/Contest/Z1Trace00000.trc' );
fread(f, 357);
d = fread( f, 435002 , 'int8' )
size(d)
fclose(f);

key = sscanf( '6cecc67f287d083deb8766f0738b36cf164ed9b246951090869d08285d2e193b', ...
    '%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x'...
);
plain = sscanf( '448ff4f8eae2cea393553e15fd00eca1', '%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x' );
cipher = sscanf( 'f71e9995e754e9f711b4027106a72788', '%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x' );

M_str = '0x00; 0x0f; 0x36; 0x39; 0x53; 0x5c; 0x65; 0x6a; 0x95; 0x9a; 0xa3; 0xac; 0xc6; 0xc9; 0xf0; 0xff';
M = sscanf( M_str, '0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; ' )

%%
f = fopen( 'c:/dev/DPA/Repo/DPA/Contest/leaks.txt', 'w' );
fprintf(  f, '%s', rsm.leaksDescryptions(1) );
fclose( f );