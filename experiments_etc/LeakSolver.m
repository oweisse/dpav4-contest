
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


classdef LeakSolver < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties(Constant = true)
        % k - key bytes
        % ak - add round key
        % sb - sub bytes
        % sr - shift rows
        % x2 - xor 2 bytes
        % xt - xtimes
        % x4 - xor 4 bytes
        %For x2Prices:     k   ak  sb  sr     x2  price
        X2_SHIFT_ROWS_ID = 2 + 2 + 2 + (1:2);
        X2_VALUE_ID      = 2 + 2 + 2 + 2    + 1 ;
        X2_PRICE_ID      = 2 + 2 + 2 + 2    + 1 + 1;
        
        %For xtimes:           k   ak  sb  sr     x2  xt      price
        XTIMES_SHIFT_ROWS_ID = 2 + 2 + 2 + (1:2);
        XTIMES_RESULT_ID     = 2 + 2 + 2 + 2    + 1 + 1; 
        XTIMES_PRICE_ID      = 2 + 2 + 2 + 2    + 1 + 1     + 1; 
        
        %For xor 4            k   ak  sb  sr     x2  xt     x4  price
        X4_RESULT_ID        = 4 + 4 + 4 + 4    + 4 + 4    + 1;
        X4_EVOLVED_PRICE_ID = 4 + 4 + 4 + 4    + 4 + 4    + 1 + 1; 
        X4_SHIFT_ROWS_ID    = 4 + 4 + 4 + (1:4); 
        X4_XTIMES_ID        = 4 + 4 + 4 + +4   + 4 + (1:4); 
    end
    
    methods (Static = true)
         function [ reconciledCombinations ] = ReconcileCobinations(                              ...
                    sourceArray, sourceRowsToMatch,                 ...
                    constraintCombinations, constraintRowsToMatch   ...
         )
            if isempty( constraintCombinations )
                reconciledCombinations = sourceArray;
                return;
            end
            
            rowsToTake = ismember(                                      ...
                    sourceArray( sourceRowsToMatch, : )',               ...
                    constraintCombinations( constraintRowsToMatch, : )',...
                    'rows'                                              ...
            );
            reconciledCombinations = sourceArray( :, rowsToTake );
         end
        
         function [ validInputsWithPrices, evolvedDest ] =                  ...
                 EliminateImpossibleValues_multivar(                    ...
                               sourceValuesAndPrices,                   ...
                               possibleDestValues, apriorDestPrices,    ... 
                               calculatedDestValues                     ...
           )
            validDestValues       = intersect( possibleDestValues, calculatedDestValues );
            validSourceIDs        = ismember( calculatedDestValues, validDestValues );
            validInputsWithPrices = sourceValuesAndPrices( : , validSourceIDs );
            validDestBytes        = calculatedDestValues( validSourceIDs );
            
            validInputsPrices = sourceValuesAndPrices( end, validSourceIDs );
            validDestPrices   = apriorDestPrices( validDestBytes + 1 ) + ...
                                validInputsPrices;
            validInputs       = validInputsWithPrices( 1:(end-1), : );
            evolvedDest       = [  validInputs;    ...
                                   validDestBytes; ...
                                   validDestPrices ];
         end
         
        function [ affordableCombinations, affordablePrices ] =         ...
                                    TakeCheapestCombinatios(            ...                         ...
                                          allCombinations,              ...
                                          allPrices,                    ...
                                          threshhold                    ...
            )
            [ sortedPrices, rankedCombinations ] = sort( allPrices( end, : ) );
            affordableCombinationsIDs = ...
                    rankedCombinations( sortedPrices <= threshhold );
            
            affordableCombinations = allCombinations( :, affordableCombinationsIDs );
            affordablePrices       = allPrices( :, affordableCombinationsIDs );   
        end
 
        function [ isDifferentLengths ] = DifferentLengths( prices1, prices2 )
            isDifferentLengths = false;
            if( size( prices1, 2 ) ~= size( prices2, 2 ) )
                isDifferentLengths = true;
            end
        end
    end
    
end

