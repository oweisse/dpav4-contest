
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


classdef X4Computer < handle

    properties
        x2Reorder;
    end
    
    methods
        function obj = X4Computer( x2Reorder )
            obj.x2Reorder = x2Reorder;
        end
        
        function [ dstValues ] = Compute( obj, srcValues )
            EXPECTED_HALF_SIZE = 12;
            plainIDs     = [1:2,   (1:2)  + EXPECTED_HALF_SIZE];
            keyIDs       = [3:4,   (3:4)  + EXPECTED_HALF_SIZE];
            addKeyIDs    = [5:6,   (5:6)  + EXPECTED_HALF_SIZE];
            subBytesIDs  = [7:8,   (7:8)  + EXPECTED_HALF_SIZE];
            shiftRowsIDs = [9:10,  (9:10) + EXPECTED_HALF_SIZE];
            x2IDs        = [11,    11     + EXPECTED_HALF_SIZE];
            xTIDs        = [12,    12     + EXPECTED_HALF_SIZE];
            
            
            idsReordered = [ plainIDs, keyIDs, addKeyIDs, ...
                             subBytesIDs, shiftRowsIDs, x2IDs, xTIDs ];
            reorderedSrc = srcValues(:, idsReordered );
            
            reorderByByteIdx = [ obj.x2Reorder,     ... %plains
                                 obj.x2Reorder + 4, ... %keys
                                 obj.x2Reorder + 8, ... %addKey
                                 obj.x2Reorder + 12,... %subBytes
                                 obj.x2Reorder + 16,... %shiftrows
                                 21:22,             ... %x2 vals
                                 23:24              ... %xt vals
            ];
            reorderedSrc     = reorderedSrc( :, reorderByByteIdx );
            reorderedX2Ids   = 21:22;
            
            computedValues      = bitxor( reorderedSrc( :, reorderedX2Ids(1) ),   ...
                                          reorderedSrc( :, reorderedX2Ids(2) )    ...
            );
            dstValues           = [ reorderedSrc, computedValues ];
        end
        
        function [ validCombinations ] = GetValidCombinations(  ...
                                                ~,              ...
                                                srcValues       ...  
        )
             validCombinations = combvec( srcValues{:} )'; %note '
        end
    end
    
end

