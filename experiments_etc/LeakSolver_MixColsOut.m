
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


classdef LeakSolver_MixColsOut < LeakSolver
    
    properties
        x4Solver;
        outputApriorPrices;
        mixColsPrices;
        
        inputChanged
    end
    
    methods
        function obj = LeakSolver_MixColsOut(  ...
                            x4Solver,          ...
                            outputApriorPrices ...
        )
            obj.x4Solver           = x4Solver;
            obj.outputApriorPrices = outputApriorPrices;
        end
        
        function Solve( obj )
            obj.inputChanged = false;
            inputs           = obj.x4Solver.possibleXor4Prices;
            addedPrices      = zeros( 4, size( inputs, 2 ) );
            validValues      = zeros( 4, size( inputs, 2 ) );
            
            computedMixCols = obj.ComputeMixColsOut( inputs );
            for rowIdx = 0:3
                possibleValues               = obj.PossibleMixColsVals( rowIdx );
                validValues( rowIdx + 1, : ) = ismember(               ...
                                    computedMixCols( rowIdx + 1, : ) , ...
                                    possibleValues                     ...
                );
                addedPrices( rowIdx + 1, : ) = obj.outputApriorPrices(   ...
                                    rowIdx + 1,                          ...
                                    computedMixCols( rowIdx + 1, : ) + 1 ...
                ); 
            end
            
            totalValidInputs  = logical( prod( validValues ) );
            totalAddedPrices  = sum( addedPrices );
            totalPrices       = inputs( end, : ) + totalAddedPrices;
            obj.mixColsPrices = [   inputs( 1:(end-1), totalValidInputs );...
                                    computedMixCols( :,  totalValidInputs );...
                                    totalPrices( totalValidInputs );...
            ];
            
            if sum( totalValidInputs ) ~= size( inputs, 2 )
                   obj.inputChanged = true;
            end
            obj.x4Solver.possibleXor4Prices = ...
                obj.x4Solver.possibleXor4Prices( :, totalValidInputs ); 

        end
        
        function [ computedMixCols ] = ComputeMixColsOut( obj, inputs )
%             % k - key bytes
%             % ak - add round key
%             % sb - sub bytes
%             % sr - shift rows
%             % x2 - xor 2 bytes
%             % xt - xtimes
%             % x4 - xor 4 bytes
%             % mc - mix cols
%             %                       k   ak  sb  sr  x2  xt  x4  mc price
%             X4_RESULT_ID          = 4 + 4 + 4 + 4 + 4 + 4 + 1;
%             SHIFT_ROWS_RESULT_ID  = 4 + 4 + 4 + 0;
%             XTIMES_RESULT_ID      = 4 + 4 + 4 + 4 + 4 + 0;
            
            computedMixCols = zeros( 4, size( inputs, 2 ) );
            xor4      = inputs( obj.X4_RESULT_ID, : );
            shiftRows = inputs( obj.X4_SHIFT_ROWS_ID, : );
            xtimes    = inputs( obj.X4_XTIMES_ID, : );
            
            for rowIdx = 0:3
                computedMixCols( rowIdx + 1, : ) =                                  ...
                                    bitxor( xor4,                               ...
                                            bitxor( shiftRows( rowIdx + 1, : ), ...
                                                    xtimes( rowIdx + 1, : )     ...
                                            )                                   ...
                );
            end
        end
        
        function [ possibleVals ] = PossibleMixColsVals( obj, rowIdx )
            % k - key bytes
            % ak - add round key
            % sb - sub bytes
            % sr - shift rows
            % x2 - xor 2 bytes
            % xt - xtimes
            % x4 - xor 4 bytes
            % mc - mix cols
            %                     k   ak  sb  sr  x2  xt  x4  mc price
            MIX_COLS_RESULT_ID  = 4 + 4 + 4 + 4 + 4 + 4 + 1 + 0;
            EVOLVED_PRICE_ID    = 4 + 4 + 4 + 4 + 4 + 4 + 4 + 4 +1;
            if size( obj.mixColsPrices, 1 ) ~= EVOLVED_PRICE_ID 
                nonInfByteIDs = ~isinf( obj.outputApriorPrices( rowIdx + 1, :  ) );
                possibleVals  = find( nonInfByteIDs ) - 1;    
            else
                idx = MIX_COLS_RESULT_ID + rowIdx + 1;
                mixColsResult = obj.mixColsPrices( idx, : );
                possibleVals  = unique( mixColsResult );
            end    
        end
    end
    
end

