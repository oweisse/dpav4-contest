
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
classdef FilterStorageNode < handle 
    
    properties
        apriorValsPrices;
        
        origValues;
        origValuesPrices;
        values;
        valuesPrices;
        
        threshold;
    end
    
    methods
        function obj = FilterStorageNode( valsPrices, threshold )
            obj.apriorValsPrices = valsPrices;
            obj.threshold        = threshold;
        end

        function SetValues( obj, values, previousPrices )
            obj.origValues       = values;
            newPrices            = obj.apriorValsPrices( values( :, end ) + 1 );
            obj.origValuesPrices = previousPrices .* newPrices;
            obj.origValuesPrices = obj.origValuesPrices / sum( obj.origValuesPrices );
            
            higestValsIDs    = obj.origValuesPrices > obj.threshold;
            obj.values       = obj.origValues( higestValsIDs, : );
            obj.valuesPrices = obj.origValuesPrices( higestValsIDs );
            obj.valuesPrices = obj.valuesPrices / sum( obj.valuesPrices );
        end
    end
end

