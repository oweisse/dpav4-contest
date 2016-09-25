
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


%Author: Ofir Weisse, www.ofirweisse.com, OfirWeisse@gmail.com
classdef X2Computer < handle
   
    properties
        
    end
    
    methods
        function obj = X2Computer()
        end
        
        function [ dstValues ] = Compute( ~, srcValues )
            EXPECTED_HALF_SIZE = 5;
            plainIDs     = [1, 1 + EXPECTED_HALF_SIZE];
            keyIDs       = [2, 2 + EXPECTED_HALF_SIZE];
            addKeyIDs    = [3, 3 + EXPECTED_HALF_SIZE];
            subBytesIDs  = [4, 4 + EXPECTED_HALF_SIZE];
            shiftRowsIDs = [5, 5 + EXPECTED_HALF_SIZE];
            
            idsReordered = [ plainIDs, keyIDs, addKeyIDs, subBytesIDs, shiftRowsIDs];
            reorderedSrc = srcValues(:, idsReordered );
            src1ShiftRowsID = 7;
            src2ShiftRowsID = 8;
            
            computedValues      = bitxor( reorderedSrc( :, src1ShiftRowsID ),   ...
                                          reorderedSrc( :, src2ShiftRowsID )    ...
            );
            dstValues           = [ reorderedSrc, computedValues ];
        end
        
        function [ validCombinations ] = GetValidCombinations(    ...
                                                ~,                ...
                                                srcValues         ...
        )
            validCombinations = combvec( srcValues{:} )'; %note '
        end
    end
    
end

