
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
classdef MixColsComputer < handle
    properties
    end
    
    methods
        function obj = MixColsComputer(  )
        end
        
        function [ dstValues ] = Compute( ~, srcValues )
%             plainIDs     = 1:4;
%             keyIDs       = 5:8;
%             addKeyIDs    = 9:12;
%             subBytesIDs  = 13:16;
            shiftRowsIDs = 17:20;
%             x2_IDs = 21:24;
            xt_IDs = 25:28;
            x4_ID   = 29;
            
            computedMixCols = zeros( size( srcValues, 1 ), 4 );
            xor4      = srcValues( :, x4_ID );
            shiftRows = srcValues( :, shiftRowsIDs );
            xtimes    = srcValues( :, xt_IDs );
            
            for rowIdx = 1:4
                computedMixCols( :, rowIdx  ) =                             ...
                                    bitxor( xor4,                           ...
                                            bitxor( shiftRows( :, rowIdx ), ...
                                                    xtimes( :, rowIdx )     ...
                                            )                               ...
                );
            end

            dstValues  = [ srcValues, computedMixCols ];
        end
    end
end

