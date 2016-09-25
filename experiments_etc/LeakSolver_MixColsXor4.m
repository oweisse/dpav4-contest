
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


classdef LeakSolver_MixColsXor4 < LeakSolver
    
    properties
       colIdx;
       xtimesSolver;
       afterShiftRowsApriorPrices;
       mixColsXorApriorPrices;
       mixColsXtimesApriorPrices;
       xor4ApriorPrices;
       possibleXtimesPrices;
       possibleXor4Prices;
       XOR_4_PruneThreshhold;
       
       inputChanged
    end
  
    methods
        function obj = LeakSolver_MixColsXor4( xtimesSolver,                ...
                                               afterShiftRowsApriorPrices,  ...
                                               mixColsXorApriorPrices,      ...
                                               mixColsXtimesApriorPrices,   ...
                                               xor4ApriorPrices             ...
        )
            obj.xtimesSolver                = xtimesSolver;
            obj.afterShiftRowsApriorPrices  = squeeze( afterShiftRowsApriorPrices );
            obj.mixColsXorApriorPrices      = squeeze( mixColsXorApriorPrices );
            obj.mixColsXtimesApriorPrices   = squeeze( mixColsXtimesApriorPrices );
            obj.xor4ApriorPrices            = squeeze( xor4ApriorPrices );
        end

         function [ combination1, combination2, match1 ] = ...
                                CalculateCombinations( obj )
                      
            [ half_0, half_1, half_2, half_3 ] = obj.XorOf4GenerateHalfs();
       
            combination1 = combvec( half_0, half_2 )';
            combination2 = combvec( half_1, half_3 )';
%%%%%%%
            reorder = [];
            halfLength = size( half_0, 1 );
            for j = 1:2:(obj.X2_VALUE_ID - 1)
                reorder = [ reorder, j:(j+1), (j:(j+1)) + halfLength ];%#ok<AGROW>
            end
%             
%             for j = obj.X2_VALUE_ID:obj.X2_PRICE_ID
%                 reorder = [ reorder, j, j + halfLength ];%#ok<AGROW>
%             end
%             
            combination1 = combination1( :, reorder );
            combination2 = combination2( :, reorder );
       %%%%%%%     
            
%             obj.combinationShiftRowsIDs =                                   ...
%                             [ obj.XTIMES_SHIFT_ROWS_ID,                     ...
%                               obj.XTIMES_SHIFT_ROWS_ID + size( half_0, 1 )  ...
%             ];
            shiftRowsIDs1  = obj.X4_SHIFT_ROWS_ID;
            shiftRowsIDs2  = circshift( shiftRowsIDs1', 1 )';
            fourRows_take1 = combination1( :, shiftRowsIDs1 );
            fourRows_take2 = combination2( :, shiftRowsIDs2 );

            match1 = ismember( fourRows_take1, fourRows_take2, 'rows' ); 
%             match2 = ismember( fourRows_take2, fourRows_take1, 'rows' ); 
         end
        
        function  Solve( obj )
            obj.possibleXtimesPrices = obj.xtimesSolver.possibleXtimesPrices;
            [ combination1, combination2, match1 ] = obj.CalculateCombinations();
            computedXor4 = obj.ComputeCheapVals( combination1, match1 );
            
            [ validInputsWithPrices, evolvedX4Prices ] =   ...
                    obj.EliminateImpossibleValues_multivar(     ...
                            obj.possibleXor4Prices,             ...
                            obj.PossibleXor4Vals() ,            ...
                            obj.xor4ApriorPrices,               ...
                            computedXor4                        ...
                );
            
            obj.EvolveXtimes( validInputsWithPrices );
            obj.possibleXor4Prices = evolvedX4Prices;
        end
        
        function [ possibleVals ] = PossibleXor4Vals( obj )
            if size( obj.possibleXor4Prices, 1 ) ~= obj.X4_EVOLVED_PRICE_ID 
                nonInfByteIDs = ~isinf( obj.xor4ApriorPrices );
                possibleVals  = find( nonInfByteIDs ) - 1;    
            else
                xor4Result = obj.possibleXor4Prices( obj.X4_RESULT_ID, : );
                possibleVals = unique( xor4Result );
            end    
        end
        
        function [ half_0, half_1, half_2, half_3 ] = ...
                                XorOf4GenerateHalfs( obj )         
            X4_SHIFT_ROWS_0_1_IDS = obj.X4_SHIFT_ROWS_ID( 1:2 );
            X4_SHIFT_ROWS_1_2_IDS = obj.X4_SHIFT_ROWS_ID( 2:3 );
            X4_SHIFT_ROWS_2_3_IDS = obj.X4_SHIFT_ROWS_ID( 3:4 );
            X4_SHIFT_ROWS_3_0_IDS = obj.X4_SHIFT_ROWS_ID( [4,1] );
            half_0 = obj.possibleXtimesPrices{ 0 + 1 };
            half_0 = obj.ReconcileCobinations(                        ...
                    half_0, obj.XTIMES_SHIFT_ROWS_ID,                                ...
                    obj.possibleXor4Prices, X4_SHIFT_ROWS_0_1_IDS   ...
            );
        
            half_1 = obj.possibleXtimesPrices{ 1 + 1 };
            half_1 = obj.ReconcileCobinations(                        ...
                    half_1, obj.XTIMES_SHIFT_ROWS_ID,                                ...
                    obj.possibleXor4Prices, X4_SHIFT_ROWS_1_2_IDS   ...
            );
        
            half_2 = obj.possibleXtimesPrices{ 2 + 1 };
            half_2 = obj.ReconcileCobinations(                        ...
                    half_2, obj.XTIMES_SHIFT_ROWS_ID,                                ...
                    obj.possibleXor4Prices, X4_SHIFT_ROWS_2_3_IDS   ...
            );
        
            half_3 = obj.possibleXtimesPrices{ 3 + 1 };
            half_3 = obj.ReconcileCobinations(                        ...
                    half_3, obj.XTIMES_SHIFT_ROWS_ID,                                ...
                    obj.possibleXor4Prices, X4_SHIFT_ROWS_3_0_IDS   ...
            );                 
        end
        
         function  [ computedXor4 ] = ComputeCheapVals( obj, combination1, match1 )
            xorOf4Candidates = combination1( match1, : )';
            xorOf4Candidates = obj.ReconcileCobinations(                ...
                        xorOf4Candidates, obj.X4_SHIFT_ROWS_ID,         ...
                        obj.possibleXor4Prices, obj.X4_SHIFT_ROWS_ID    ...
            );
            obj.CalculateXor4Prices( xorOf4Candidates );
            [ obj.possibleXor4Prices, ~ ] =                                     ...
                            obj.TakeCheapestCombinatios(                        ...
                                                obj.possibleXor4Prices,         ...
                                                obj.possibleXor4Prices(end,:),  ...            ...
                                                obj.XOR_4_PruneThreshhold       ...
                );
            
            afterShiftRows = obj.possibleXor4Prices( [ obj.X4_SHIFT_ROWS_ID ], : );
            computedXor4 = bitxor( bitxor(   afterShiftRows( 1, : ), ...
                                             afterShiftRows( 2, : )  ...
                                    ),                                     ...
                                    bitxor(  afterShiftRows( 3, : ), ...
                                             afterShiftRows( 4, : )  ...
                                    )                                      ...
            );
         end
        
        function CalculateXor4Prices( obj, xorOf4Candidates )
            afterShiftRowsBytes       = ...
                xorOf4Candidates( obj.X4_SHIFT_ROWS_ID, : );
            [ xorBytes, xtimesBytes ] = ...
                obj.CalcValuesFromShiftRows( afterShiftRowsBytes );

            prices = obj.CalcXor4PriceOfInput(  afterShiftRowsBytes,    ...
                                                xorBytes,               ...
                                                xtimesBytes             ...
            );  
            
           obj.possibleXor4Prices = [ ...
               xorOf4Candidates;
               xorBytes;
               xtimesBytes;
               prices;
           ];
        end
        
        function [ xorBytes, xtimesBytes ] = ....
                    CalcValuesFromShiftRows( ~, afterShiftRowsBytes )
            xorBytes    = zeros( 4, size( afterShiftRowsBytes, 2 ) );
            xtimesBytes = zeros( 4, size( afterShiftRowsBytes, 2 ) );
            for leakIdx = 0:3
                byte_0_idx  = mod( leakIdx, 4 ) + 1;
                byte_1_idx  = mod( leakIdx + 1, 4 ) + 1;
                xorBytes( leakIdx + 1, : ) = bitxor(                        ...
                                    afterShiftRowsBytes( byte_0_idx, : ),   ...
                                    afterShiftRowsBytes( byte_1_idx, : )    ...
                );

                xtimesBytes( leakIdx + 1, : ) = ...
                                aes_xtimes( xorBytes( leakIdx + 1, : ) );
            end 
        end
        
        function [ prices ] = CalcXor4PriceOfInput( obj,                    ...
                                                        afterShiftRowsBytes,    ...
                                                        xorBytes,               ...
                                                        xtimesBytes             ...
        )
            prices = zeros( 1, size( afterShiftRowsBytes, 2 ) );
            for k = 1:4
                prices = prices + ...
                         obj.afterShiftRowsApriorPrices(            ...
                                    k,                              ...
                                    afterShiftRowsBytes( k, : ) + 1 ...
                );
                prices = prices +                                   ...
                         obj.mixColsXorApriorPrices(                ...
                                            k,                      ...
                                            xorBytes( k, : ) + 1    ...
                );

                prices = prices +                               ...
                         obj.mixColsXtimesApriorPrices(         ...
                                        k,                      ...
                                        xtimesBytes( k, : ) + 1 ...
                );
            end
        end
        
        function EvolveXtimes( obj, validInputsWithPrices )
            obj.inputChanged = false;
            validQuartets = validInputsWithPrices( obj.X4_SHIFT_ROWS_ID, : );
            relevantShiftRowsBytes = [ 1, 2;    ...
                                       2, 3;    ...
                                       3, 4;    ...
                                       4, 1;    ...
            ];
        
            for k = 1:4
                origXtimes = obj.possibleXtimesPrices{ k };
                relevantBytes = relevantShiftRowsBytes( k, : );
                validCombination = ismember(                               ...
                                origXtimes( obj.XTIMES_SHIFT_ROWS_ID, : )', ...
                                validQuartets( relevantBytes, : )',        ...
                                'rows'                                     ...
                );
                
                if sum( validCombination ) ~= size( origXtimes, 2 )
                   obj.inputChanged = true;
                end
                obj.xtimesSolver.possibleXtimesPrices( k ) = ...
                                    { origXtimes( :, validCombination ) };
            end
        end
    end
    
end

