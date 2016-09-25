
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


classdef ComputationNode < handle
     properties
        srcStorage;
        dstStorage;
        computer;
        srcStorageChanged;
        fanIn;
    end
    
    methods
        function obj = ComputationNode( srcStorage, dstStorage, computer )
            obj.srcStorage = srcStorage;
            obj.dstStorage = dstStorage;
            obj.computer   = computer;
            
            if iscell( srcStorage )
                obj.fanIn = length( srcStorage );
            else
                obj.fanIn = 1;
            end
        end
        
        function ComputeAndReconcile( obj )
            if obj.fanIn == 1
                obj.computeAndReconcile_singleInput();
            else
                obj.computeAndReconcile_multipleInput();
            end 
        end
        
        function computeAndReconcile_singleInput( obj )
            srcWitnesses          = obj.srcStorage.values;
            srcWitnessesPrices    = obj.srcStorage.valuesPrices;
            computedDstWitnesses  = obj.computer.Compute( srcWitnesses );
            
            obj.dstStorage.SetValues(  computedDstWitnesses, ...
                                       srcWitnessesPrices    ...
            );
        end
        
        function computeAndReconcile_multipleInput( obj )
            obj.srcStorageChanged = false;
            
            [ srcWitnesses,         ...
              srcWitnessesPrices ] = ...
                                    obj.GetSrcWitnessesForMultipleInput();
            computedDstWitnesses  = obj.computer.Compute( srcWitnesses );
            
            obj.dstStorage.SetValues( computedDstWitnesses, ...
                                      srcWitnessesPrices'   ...
            );
        end
        
        function [ srcWitnessesCombination, combinationPrices ] = ...
                                        GetSrcWitnessesForMultipleInput( obj )
                                    
            srcWitnessesWithPrices = cell( 1, length( obj.srcStorage ) );
            priceColIDs            = zeros( 1, length( obj.srcStorage ) );
            prevPriceColID         = 0;
            
            for srcIdx = 1:length( obj.srcStorage )
                currentSrcValues      = obj.srcStorage{ srcIdx }.values;
                currentSrcPrices      = obj.srcStorage{ srcIdx }.valuesPrices;
                valuesWithPrices      = [ currentSrcValues, currentSrcPrices' ];
                priceColIDs( srcIdx ) = prevPriceColID + ...
                                        size( currentSrcValues, 2 ) + 1;
                prevPriceColID        = priceColIDs( srcIdx );
                
                srcWitnessesWithPrices( srcIdx ) = { valuesWithPrices' }; 
            end

            srcWitnessesCombination = ...
                obj.computer.GetValidCombinations( srcWitnessesWithPrices );
            
            srcPrices = srcWitnessesCombination( :, priceColIDs );
            combinationPrices = prod( srcPrices, 2 );
            combinationPrices = combinationPrices / sum( combinationPrices );
            
            allColumnIDs            = 1:size( srcWitnessesCombination, 2 );
            valuesColIDs            = ~ismember( allColumnIDs, priceColIDs );
            srcWitnessesCombination = srcWitnessesCombination( :, valuesColIDs );
        end
        
        function [ srcStorageChanged ] = PruneSrcStoragesForMultipleInput(  ...
                                                        obj,                ...
                                                        srcWitnesses,       ...
                                                        validWitnesses      ...
        )
            srcStorageChanged = false;
            startIdx          = 1;
            for srcIdx = 1:length( obj.srcStorage )
                currentSrcStorage = obj.srcStorage{ srcIdx };
                srcWitnessLength  = size( currentSrcStorage.values, 2 );
                endIdx            = startIdx + srcWitnessLength - 1;
                
                currentSrcValidWitnesses = srcWitnesses( ...
                                                    validWitnesses, ...
                                                    startIdx:endIdx ...
                );
                currentStorageChanged    = currentSrcStorage.PruneStorage( ...
                                unique( currentSrcValidWitnesses, 'rows' ) ...
                );
                
                srcStorageChanged = srcStorageChanged || currentStorageChanged;
                startIdx          = startIdx + srcWitnessLength;
            end
        end
        
    end
    
end

