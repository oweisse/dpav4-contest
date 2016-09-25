
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


function [ masks ] = Moffset( offsets )
%Moffset calulate Moffset
%In:
%   offsets - vetor of offsets
%Out:
%   masks - matrix of dimensions length( offsets ) X 16
%           each row k is 16 byte values of mask with offset == offsets( k )
   
    if min( offsets ) < 0 || max( offsets ) > 15
        error( 'offset must be in range [0, 15]' );
    end

    M_str = '0x00; 0x0f; 0x36; 0x39; 0x53; 0x5c; 0x65; 0x6a; 0x95; 0x9a; 0xa3; 0xac; 0xc6; 0xc9; 0xf0; 0xff';
    M = sscanf( M_str, '0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; 0x%2x; ' );
    M = M';
    MASK_SIZE = 16;

    masks = zeros( length( offsets ), MASK_SIZE );
    for offsetIndex = 1 : length( offsets )
        masks( offsetIndex, : ) = circshift( M, [ 0, -offsets( offsetIndex ) ] );
    end
end

