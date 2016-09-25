
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
classdef AESNetworkSolver < handle
 
    properties
        plainXorMask;
        mask;
        
        keyStoreNodes;
        addKeyComputationNodes;
        addKeyStoreNodes;
        
        subBytesComputationNodes;
        subBytesStoreNodes;
        
        shiftRowsComputationNodes;
        shiftRowsStoreNodes;
        
        X2ComputationNodes;
        X2StoreNodes;
        
        XTComputationNodes;
        XTStoreNodes;
        
        XTCostComputationNodes;
        XTCostStoreNodes;
        
        X4ComputationNodes;
        X4StoreNodes;
        
        MergeX4ComputationNodes;
        MergeX4StoreNodes;
        
        mixColsComputationNodes;
        mixColsStoreNodes;
        
        mixColsCostComputationNodes;
        mixColsCostStoreNodes;
        
        addKeyProbabilites;
        subBytesProbabilites;
        shiftRowsProbabilites;
        X2Probabilities;
        XTProbabilities;
        X4Probabilities;
        mixColsProbabilites;
        
        addKeyCount;
        subBytesCount;
        shiftRowsCount;
        addKeySubBytesCount;
        addKeySubBytesShiftRowsCount;
%         X2Count;
%         XTCount;
%         x2Prices;
%         xTPrices;
        
        xtThreshold;
    end
    
    properties(Constant = true)
        shiftRowsMapping = [ 1  6  11 16 ...
                             5  10 15 4  ...
                             9  14 3  8  ...
                             13 2  7  12 ];
                         
        byteHammingWeights = ...
                [  0,  1,  1,  2,  1,  2,  2,  3, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   5,  6,  6,  7,  6,  7,  7,  8 ];  
               
          hwItemCount = [   nchoosek(8,0), ...
                            nchoosek(8,1), ...
                            nchoosek(8,2), ...
                            nchoosek(8,3), ...
                            nchoosek(8,4), ...
                            nchoosek(8,5), ...
                            nchoosek(8,6), ...
                            nchoosek(8,7), ...
                            nchoosek(8,8)];
    end
    
    methods
        function obj = AESNetworkSolver( plainXorMask,      ...
                                         mask,              ...
                                         stateProbabilites, ...
                                         X2Probabilities,   ...
                                         XTProbabilities,   ...
                                         X4Probabilities    ...
        )
            obj.xtThreshold  = 1e-25;
            obj.plainXorMask = plainXorMask;
            obj.mask         = mask;
            
            obj.addKeyProbabilites    = squeeze( stateProbabilites( 1, :, : ) );
            obj.subBytesProbabilites  = squeeze( stateProbabilites( 2, :, : ) );
            obj.shiftRowsProbabilites = squeeze( stateProbabilites( 3, :, : ) );
            obj.mixColsProbabilites   = squeeze( stateProbabilites( 4, :, : ) );
            obj.X2Probabilities       = X2Probabilities;
            obj.XTProbabilities       = XTProbabilities;
            obj.X4Probabilities       = squeeze( X4Probabilities );
 
            obj.setupKeyStoreNodes();
            obj.setupAddKeyStoreNodes();
            obj.setupAddKeyComputationNodes();
            
            obj.setupSubBytesStoreNodes();
            obj.setupSubBytesComputationNodes();
            
            obj.setupShiftRowsStoreNodes();
            obj.setupShiftRowsComputationNodes();
            
            obj.setupX2StoreNodes();
            obj.setupX2ComputationNodes();
            
            obj.setupXTStoreNodes();
            obj.setupXTComputationNodes();
%             
%             obj.setupXTCostStoreNodes();
%             obj.setupXTCostComputationNodes();
%             
            obj.setupX4StoreNodes();
            obj.setupX4ComputationNodes();
            
            obj.setupMergeX4StoreNodes();
            obj.setupMergeX4ComputationNodes();
            
            obj.setupMixColsStoreNodes();
            obj.setupMixColsComputationNodes();
            
            obj.setupMixColsCostStoreNodes();
            obj.setupMixColsCostComputationNodes();
        end 
        
        function ComputeAddKeyLayer( obj )
            for byteIdx = 1:16
                computationNode = obj.addKeyComputationNodes{ byteIdx };
                computationNode.ComputeAndReconcile();
            end
        end
        
        function ComputeSubBytesLayer( obj )
            for byteIdx = 1:16
                computationNode = obj.subBytesComputationNodes{ byteIdx };
                computationNode.ComputeAndReconcile();
            end
        end
        
        function ComputeShiftRowsLayer( obj )
            for byteIdx = 1:16
                computationNode = obj.shiftRowsComputationNodes{ byteIdx };
                computationNode.ComputeAndReconcile();
            end
        end
        
        function ComputeX2Layer( obj )
            for colIdx = 1:4
                for leakIdx = 1:4
                    computationNode = obj.X2ComputationNodes{ colIdx, leakIdx };
                    computationNode.ComputeAndReconcile();
                end
            end
        end
        
        function ComputeX4Layer( obj )
            for colIdx = 1:4
                for takeIdx = 1:2
                    computationNode = obj.X4ComputationNodes{ colIdx, takeIdx };
                    computationNode.ComputeAndReconcile();
                end
            end
        end
        
         function ComputeMergeX4Layer( obj )
            for colIdx = 1:4
                    computationNode = obj.MergeX4ComputationNodes{ colIdx };
                    computationNode.ComputeAndReconcile();
            end
         end
        
         function ComputeMixColsLayer( obj )
            for colIdx = 1:4
                    computationNode = obj.mixColsComputationNodes{ colIdx };
                    computationNode.ComputeAndReconcile();
            end
         end

        function ComputeCostAtMixColsLayer( obj )
            for colIdx = 1:4
                    computationNode = obj.mixColsCostComputationNodes{ colIdx };
                    computationNode.ComputeAndReconcile();
                    
                    storeNode = obj.mixColsCostStoreNodes{ colIdx };
                    storeNode.valuesPrices = storeNode.values( :, end );
            end
        end
        
        function ComputeXTLayer( obj )
            for colIdx = 1:4
                for leakIdx = 1:4
                    computationNode = obj.XTComputationNodes{ colIdx, leakIdx };
                    computationNode.ComputeAndReconcile();
                end
            end
        end
        
        function ComputeCostAtXTLayer( obj )
            sourcesChanged = false;

            for colIdx = 1:4
                for leakIdx = 1:4
                    computationNode = obj.XTCostComputationNodes{ colIdx, leakIdx };
                    computationNode.ComputeAndReconcile();
                    sourcesChanged = sourcesChanged || computationNode.srcStorageChanged;
                end
            end
        end
        
        function Solve( obj )
            %SOURCES_CHANGED = true;
            
            obj.ComputeAddKeyLayer();
            obj.ComputeSubBytesLayer();
            obj.ComputeShiftRowsLayer();
            obj.ComputeX2Layer();
            obj.ComputeXTLayer();
%             obj.ComputeCostAtXTLayer();
            obj.ComputeX4Layer();
            obj.ComputeMergeX4Layer();
            obj.ComputeMixColsLayer();
            obj.ComputeCostAtMixColsLayer();
        end
        
%         function [ xtChanged ] = PruneXT( obj )
%             xtChanged = false;
%             for colIdx = 1:4
%                 for leakIdx = 1:4
%                     storeNode  = obj.XTStoreNodes{ colIdx ,leakIdx };
%                     prices     = obj.xTPrices{ colIdx ,leakIdx };
% %                     [ ~, ids ] = sort( prices, 'descend' );
% %                     
% %                     thresholdPriceID = ids( obj.xtThresholdRank );
% %                     validIDs        = prices > prices( thresholdPriceID );
%                     validIDs        = prices > obj.xtThreshold;
%                     if sum( validIDs ) < size( storeNode.values, 1 )
%                         xtChanged = true;
%                     end
%                     storeNode.values = storeNode.values( validIDs, : );
%                 end
%             end    
%         end
        
%         function CalcX2Prices( obj, colIdx, leakIdx )
%             storeNode       = obj.X2StoreNodes{ colIdx, leakIdx };
%             AK_SB_SR_X2_IDS = 5:11;
%             X2HW_COL_ID         = 7;
%             
%             hwVals      = obj.byteHammingWeights(                          ...
%                                 storeNode.values( :, AK_SB_SR_X2_IDS ) + 1 ...
%             );
%             obj.CalcX2Count( colIdx, leakIdx, hwVals( :, X2HW_COL_ID ) );
%             
%             byte_0_idx  = ( colIdx - 1 ) * 4 + mod( leakIdx -1  , 4 ) + 1;
%             byte_1_idx  = ( colIdx - 1 ) * 4 + mod( leakIdx -1 +1, 4 ) + 1;
%             byte0SrcIdx = obj.shiftRowsMapping( byte_0_idx );
%             byte1SrcIdx = obj.shiftRowsMapping( byte_1_idx );
%             
%             obj.x2Prices{ colIdx, leakIdx } = zeros( 1, size( hwVals, 1 ) );
%             
%             byte0HWsIDs  = hwVals( :, 1:2:5 ) + 1;
%             byte1HWsIDs  = hwVals( :, 2:2:6 ) + 1;
%             x2HW_ID      = hwVals( :, X2HW_COL_ID ) + 1;
% 
%             addKey0Probs    = obj.addKeyProbabilites( byte0SrcIdx, byte0HWsIDs( :, 1 ) ) .* ...
%                               ( obj.addKeyCount( byte0SrcIdx, byte0HWsIDs( :, 1 ) ) ).^(-1);
% 
%             subBytes0Probs  = obj.subBytesProbabilites( byte0SrcIdx, byte0HWsIDs( :, 2 ) ) .* ...
%                               ( obj.subBytesCount( byte0SrcIdx, byte0HWsIDs( :, 2 ) ) ).^(-1);
% 
%             shiftRows0Probs = obj.shiftRowsProbabilites( byte_0_idx, byte0HWsIDs( :, 3 ) ) .* ...
%                               ( obj.shiftRowsCount( byte_0_idx, byte0HWsIDs( :, 3 ) ) ).^(-1);
%             
%             addKey1Probs    = obj.addKeyProbabilites( byte1SrcIdx, byte1HWsIDs( :, 1 ) ) .* ...
%                               ( obj.addKeyCount( byte1SrcIdx, byte1HWsIDs( :, 1 ) ) ).^(-1);
%                           
%             subBytes1Probs  = obj.subBytesProbabilites( byte1SrcIdx, byte1HWsIDs( :, 2 ) ) .* ...
%                               ( obj.subBytesCount( byte1SrcIdx, byte1HWsIDs( :, 2 ) ) ).^(-1);
%                           
%             shiftRows1Probs = obj.shiftRowsProbabilites( byte_1_idx, byte1HWsIDs( :, 3 ) ) .* ...
%                               ( obj.shiftRowsCount( byte_1_idx, byte1HWsIDs( :, 3 ) ) ).^(-1);
%             
% 
% %             CountOf3Classes_0 = ...
% %                 arrayfun(  @(b,c1,c2,c3) obj.addKeySubBytesShiftRowsCount(b,c1,c2,c3), ...
% %                             byte_0_idx * ones( size( byte0HWsIDs, 1 ), 1 ),...
% %                             byte0HWsIDs( :, 1 ), ...
% %                             byte0HWsIDs( :, 2 ), ...
% %                             byte0HWsIDs( :, 3 ) );
% %             CountOf3Classes_1 = ...
% %                 arrayfun(  @(b,c1,c2,c3) obj.addKeySubBytesShiftRowsCount(b,c1,c2,c3), ...
% %                             byte_1_idx * ones( size( byte1HWsIDs, 1 ), 1 ),...
% %                             byte1HWsIDs( :, 1 ), ...
% %                             byte1HWsIDs( :, 2 ), ...
% %                             byte1HWsIDs( :, 3 ) );
% %             
% %             CountOf2Classes_0 = ...
% %                 arrayfun(  @(b,c1,c2) obj.addKeySubBytesCount(b,c1,c2), ...
% %                             byte0SrcIdx * ones( size( byte0HWsIDs, 1 ), 1 ),...
% %                             byte0HWsIDs( :, 1 ), ...
% %                             byte0HWsIDs( :, 2 ));
% %             CountOf2Classes_1 = ...
% %                 arrayfun(  @(b,c1,c2) obj.addKeySubBytesCount(b,c1,c2), ...
% %                             byte1SrcIdx * ones( size( byte1HWsIDs, 1 ), 1 ),...
% %                             byte1HWsIDs( :, 1 ), ...
% %                             byte1HWsIDs( :, 2 ) );
%                        
%             x2Probs         = obj.X2Probabilities( colIdx, leakIdx, x2HW_ID ).* ...
%                               obj.X2Count( colIdx, leakIdx, x2HW_ID ).^(-1) ;
%             x2Probs         = squeeze( x2Probs )';
%             
% %             x2Probs = x2Probs .* CountOf3Classes_0';
% %             x2Probs = x2Probs .* CountOf3Classes_1';
% %             x2Probs = x2Probs .* CountOf2Classes_0';
% %             x2Probs = x2Probs .* CountOf2Classes_1';
%             
%             prices = addKey0Probs .* subBytes0Probs .* shiftRows0Probs .* ...
%                      addKey1Probs .* subBytes1Probs .* shiftRows1Probs .* ...
%                      x2Probs;
%             obj.x2Prices{ colIdx, leakIdx } = prices;                    
%         end
%         
%         function CalcXTPrices( obj, colIdx, leakIdx )
%             storeNode       = obj.XTStoreNodes{ colIdx, leakIdx };
%             AK_SB_SR_X2_XT_IDS = 5:12;
%             XTHW_COL_ID            = 8;
%             
%             hwVals      = obj.byteHammingWeights(                             ...
%                                 storeNode.values( :, AK_SB_SR_X2_XT_IDS ) + 1 ...
%             );
%             obj.CalcXTCount( colIdx, leakIdx, hwVals( :, XTHW_COL_ID ) );
%             
%             obj.xTPrices{ colIdx, leakIdx } = zeros( 1, size( hwVals, 1 ) );
%             x2PricesP = obj.x2Prices{ colIdx, leakIdx }; %make short name
%             
%             xTHW_ID = hwVals( :, XTHW_COL_ID );
%             
%             xtprobs = obj.XTProbabilities( colIdx, leakIdx, xTHW_ID + 1 );
%             xtprobs = xtprobs .* ...
%                         obj.XTCount( colIdx, leakIdx, xTHW_ID + 1 ).^(-1);
%             xtprobs = squeeze( xtprobs )';   
% 
%             prices = x2PricesP.*xtprobs;
%             prices = prices / sum(prices);
%             obj.xTPrices{ colIdx, leakIdx } = prices;
%         end
        
%         function CalcX2Count( obj, colIdx, leakIdx, hws )
%             for hwID = 1:9
%                obj.X2Count( colIdx, leakIdx, hwID ) = sum( hws + 1 == hwID );
%             end
%         end
%         
%         function CalcXTCount( obj, colIdx, leakIdx, hws )
%             for hwID = 1:9
%                obj.XTCount( colIdx, leakIdx, hwID ) = sum( hws + 1 == hwID );
%             end
%         end
        
%         function CountSingleByteStatistics( obj )
%             NUM_HW_CLASSES                   = 9;
%             obj.addKeyCount                  = zeros( 16, NUM_HW_CLASSES );
%             obj.subBytesCount                = zeros( 16, NUM_HW_CLASSES );
%             obj.shiftRowsCount               = zeros( 16, NUM_HW_CLASSES );
%             obj.addKeySubBytesCount          = zeros( 16, NUM_HW_CLASSES, NUM_HW_CLASSES );
%             obj.addKeySubBytesShiftRowsCount = zeros( 16, NUM_HW_CLASSES, NUM_HW_CLASSES, NUM_HW_CLASSES );
%             
%             for byteIdx = 1:16
%                 storeNode = obj.shiftRowsStoreNodes{ byteIdx };
%                 hwValues = obj.byteHammingWeights( storeNode.values + 1 );
%                 
%                 obj.CountSingleByteStatistics_forByte( byteIdx, hwValues );
%             end
%         end
        
%         function CountSingleByteStatistics_forByte( obj, byteIdx, hwValues )
%             ADD_KEY_ID        = 3;
%             SUBBYTES_ID       = 4;
%             SHIFT_ROWS_ID     = 5;
%             
%             srcByteIdx        = obj.shiftRowsMapping( byteIdx );
%             for addKeyHwIdx = 1:9
%                 obj.addKeyCount( srcByteIdx, addKeyHwIdx ) = ...
%                     sum( hwValues( :, ADD_KEY_ID ) == ( addKeyHwIdx - 1 ) );
%                 
%                 subBytesHwIdx_singleByte = addKeyHwIdx;
%                 obj.subBytesCount( srcByteIdx, subBytesHwIdx_singleByte ) = ...  
%                     sum( hwValues( :, SUBBYTES_ID ) == ( addKeyHwIdx - 1 ) );
%                 
%                 shiftRowsHwIdx_singleByte = addKeyHwIdx;
%                 obj.shiftRowsCount( byteIdx, shiftRowsHwIdx_singleByte ) = ...
%                     sum( hwValues( :, SHIFT_ROWS_ID ) == ( addKeyHwIdx - 1 ) );
% 
% %                 for subBytesHwIdx = 1:9
% %                     obj.CountSingleByteStatistics_subBytesShiftRows(    ...
% %                                                         byteIdx,        ...
% %                                                         hwValues,       ...
% %                                                         addKeyHwIdx,    ...
% %                                                         subBytesHwIdx   ...
% %                     );
% %                 end
%             end           
%         end
        
%         function CountSingleByteStatistics_subBytesShiftRows(           ...
%                                                         obj,            ...
%                                                         byteIdx,        ...
%                                                         hwValues,       ...
%                                                         addKeyHwIdx,    ...
%                                                         subBytesHwIdx   ...
%         )
%             ADD_KEY_ID        = 3;
%             SUBBYTES_ID       = 4;
%             SHIFT_ROWS_ID     = 5;
%             srcByteIdx        = obj.shiftRowsMapping( byteIdx );
%             
%             searchedHWs = [ addKeyHwIdx - 1, subBytesHwIdx - 1 ];
%             obj.addKeySubBytesCount( srcByteIdx,                   ...
%                                      addKeyHwIdx,                  ... 
%                                      subBytesHwIdx ) =             ...
%                 sum( ismember( ...
%                         hwValues( :, [ ADD_KEY_ID, SUBBYTES_ID ] ),...
%                         searchedHWs, ...
%                         'rows' ...
%                         ) ...
%             );
% 
%             for shiftRowsHWIdx = 1:9
%                 relevantMatrixIDs = [ ADD_KEY_ID,  ...
%                                       SUBBYTES_ID, ...
%                                       SHIFT_ROWS_ID ];
%                 searchedHWs = [ addKeyHwIdx - 1,    ...
%                                 subBytesHwIdx - 1,  ...
%                                 shiftRowsHWIdx - 1 ];
% 
%                 obj.addKeySubBytesShiftRowsCount( byteIdx,          ...
%                                                   addKeyHwIdx,      ... 
%                                                   subBytesHwIdx,    ...
%                                                   shiftRowsHWIdx) = ...
%                     sum( ismember( ...
%                             hwValues( :, relevantMatrixIDs ),...
%                             searchedHWs, ...
%                             'rows' ...
%                             ) ...
%                 );
%             end
%         end
        function setupKeyStoreNodes( obj )
            EQUAL_CHANCE_PRICES = (1/256) * ones(1,256);
            obj.keyStoreNodes   = cell( 1, 16 );
            
            for byteIdx = 1:16
                
                node             = StorageNode( EQUAL_CHANCE_PRICES );
                initVals         = zeros( 256, 2 );
                initVals( :, 1 ) = obj.plainXorMask( byteIdx );
                initVals( :, 2 ) = ( 0:255 )';
                
                node.SetValues( initVals, EQUAL_CHANCE_PRICES ); %setup initial values
                obj.keyStoreNodes( byteIdx ) = { node };
            end
        end
        
        function setupAddKeyStoreNodes( obj )
            obj.addKeyStoreNodes = cell( 1, 16 );

            for byteIdx = 1:16
                hammingWeightPrices = obj.addKeyProbabilites( byteIdx, : );
                valsPrices = hammingWeightPrices( obj.byteHammingWeights + 1 );
                valsPrices = valsPrices ./ ...
                             obj.hwItemCount( obj.byteHammingWeights + 1 );
                obj.addKeyStoreNodes( byteIdx ) = { StorageNode( valsPrices ) };
            end
        end
        
        function setupSubBytesStoreNodes( obj )
            obj.subBytesStoreNodes = cell( 1, 16 );
            
            for byteIdx = 1:16
                hammingWeightPrices = obj.subBytesProbabilites( byteIdx, : );
                valsPrices = hammingWeightPrices( obj.byteHammingWeights + 1 );
                valsPrices = valsPrices ./ ...
                             obj.hwItemCount( obj.byteHammingWeights + 1 );
                obj.subBytesStoreNodes( byteIdx ) = { StorageNode( valsPrices ) };
            end
        end
        
        function setupShiftRowsStoreNodes( obj )
            obj.shiftRowsStoreNodes = cell( 1, 16 );
            
            for byteIdx = 1:16
                hammingWeightPrices = obj.shiftRowsProbabilites( byteIdx, : );
                valsPrices = hammingWeightPrices( obj.byteHammingWeights + 1 );
                valsPrices = valsPrices ./ ...
                             obj.hwItemCount( obj.byteHammingWeights + 1 );
                         
                obj.shiftRowsStoreNodes( byteIdx ) = { StorageNode( valsPrices ) };
            end
        end
        
        function setupX2StoreNodes( obj )
            obj.X2StoreNodes = cell( 4, 4 );
            
            for colIDx = 1:4
                for leakIdx = 1:4
                    hammingWeightPrices = obj.X2Probabilities ( colIDx, leakIdx, : );
                    hammingWeightPrices = squeeze( hammingWeightPrices )';
                    valsPrices = hammingWeightPrices( obj.byteHammingWeights + 1 );
                    valsPrices = valsPrices ./ ...
                                 obj.hwItemCount( obj.byteHammingWeights + 1 );

                    obj.X2StoreNodes( colIDx, leakIdx ) = { StorageNode( valsPrices ) };
                end
            end
        end
        
        function setupXTStoreNodes( obj )
            obj.XTStoreNodes = cell( 4, 4 );
            
            for colIDx = 1:4
                for leakIdx = 1:4
                    hammingWeightPrices = obj.XTProbabilities ( colIDx, leakIdx, : );
                    hammingWeightPrices = squeeze( hammingWeightPrices )';
                    valsPrices = hammingWeightPrices( obj.byteHammingWeights + 1 );
                    valsPrices = valsPrices ./ ...
                                 obj.hwItemCount( obj.byteHammingWeights + 1 );

                    obj.XTStoreNodes( colIDx, leakIdx ) = ...
                        { FilterStorageNode( valsPrices, obj.xtThreshold ) };
                end
            end
        end
        
%         function setupXTCostStoreNodes( obj )
%             obj.XTCostStoreNodes = cell( 4, 4 );
%             
%             for colIDx = 1:4
%                 for leakIdx = 1:4
%                     obj.XTCostStoreNodes( colIDx, leakIdx ) = ...
%                         { FilterStorageNode( obj.xtThreshold ) };
%                 end
%             end
%         end
        
        function setupX4StoreNodes( obj )
            NUM_COLS  = 4;
            NUM_TAKES = 2;
            obj.X4StoreNodes = cell( NUM_COLS, NUM_TAKES );
            
            for colIDx = 1:NUM_COLS
                hammingWeightPrices = obj.X4Probabilities ( colIDx, : );
                valsPrices = hammingWeightPrices( obj.byteHammingWeights + 1 );
                valsPrices = valsPrices ./ ...
                             obj.hwItemCount( obj.byteHammingWeights + 1 );
                         
                for takeIdx = 1:NUM_TAKES    
                    obj.X4StoreNodes( colIDx, takeIdx ) = { StorageNode( valsPrices ) };
                end
            end
        end
        
        function setupMergeX4StoreNodes( obj )
            NUM_COLS  = 4;
            obj.MergeX4StoreNodes = cell( 1, NUM_COLS );
            NO_PRICES = [];
            
            for colIDx = 1:NUM_COLS
                obj.MergeX4StoreNodes( colIDx ) = { StorageNode( NO_PRICES ) };
            end
        end
        
        function setupMixColsStoreNodes( obj )
            NUM_COLS  = 4;
            obj.mixColsStoreNodes = cell( 1, NUM_COLS );
            NO_PRICES = [];
             
            for colIDx = 1:NUM_COLS
                obj.mixColsStoreNodes( colIDx ) = { StorageNode( NO_PRICES ) };
            end
        end
        
        function setupMixColsCostStoreNodes( obj )
            NUM_COLS  = 4;
            obj.mixColsCostStoreNodes = cell( 1, NUM_COLS );
            NO_PRICES = [];
            
            for colIDx = 1:NUM_COLS
                obj.mixColsCostStoreNodes( colIDx ) = { StorageNode( NO_PRICES ) };
            end
        end
        
        function setupAddKeyComputationNodes( obj )
            obj.addKeyComputationNodes = cell( 1, 16 );
            for byteIdx = 1:16
                addKeyComputer = AddKeyComputer();
                obj.addKeyComputationNodes( byteIdx ) = {                   ...
                                ComputationNode(                            ...
                                            obj.keyStoreNodes{ byteIdx },   ...
                                            obj.addKeyStoreNodes{ byteIdx },...
                                            addKeyComputer                  ...
                                ) } ;                          
            end
        end
        
        function setupSubBytesComputationNodes( obj )
            obj.subBytesComputationNodes = cell( 1, 16 );
            for byteIdx = 1:16
                subBytesComputer = SubBytesComputer( byteIdx - 1, obj.mask );
                obj.subBytesComputationNodes( byteIdx ) = {                   ...
                                ComputationNode(                              ...
                                            obj.addKeyStoreNodes{ byteIdx },  ...
                                            obj.subBytesStoreNodes{ byteIdx },...
                                            subBytesComputer                  ...
                                ) } ;                          
            end
        end
        
        function setupShiftRowsComputationNodes( obj )
            obj.shiftRowsComputationNodes = cell( 1, 16 );
            for byteIdx = 1:16
                shiftRowsComputer = NullComputer();
                srcByteIdx        = obj.shiftRowsMapping( byteIdx );
                obj.shiftRowsComputationNodes( byteIdx )   = {                   ...
                                ComputationNode(                                 ...
                                            obj.subBytesStoreNodes{ srcByteIdx },...
                                            obj.shiftRowsStoreNodes{ byteIdx },  ...
                                            shiftRowsComputer                    ...
                                ) } ;                          
            end
        end
        
        function setupX2ComputationNodes( obj )
            obj.X2ComputationNodes = cell( 4, 4 );
            for colIdx = 0:3
                for leakIdx = 0:3
                    x2Computer = X2Computer();
                    
                    byte_0_idx  = colIdx * 4 + mod( leakIdx   , 4 ) + 1;
                    byte_1_idx  = colIdx * 4 + mod( leakIdx +1, 4 ) + 1;
                    srcStorages = cell( 1, 2 );
                    srcStorages( 1 ) = obj.shiftRowsStoreNodes( byte_0_idx );
                    srcStorages( 2 ) = obj.shiftRowsStoreNodes( byte_1_idx );
                    
                    obj.X2ComputationNodes( colIdx + 1, leakIdx + 1  )   = {         ...
                        ComputationNode(                                     ...
                                srcStorages,                                 ...
                                obj.X2StoreNodes{ colIdx + 1, leakIdx + 1 }, ...
                                x2Computer                                   ...
                    ) } ;                          
                end
            end
        end
        
        function setupXTComputationNodes( obj )
            obj.XTComputationNodes = cell( 4, 4 );
            for colIdx = 0:3
                for leakIdx = 0:3
                    xTComputer = XTComputer();
                    obj.XTComputationNodes( colIdx + 1, leakIdx + 1  )   = { ...
                        ComputationNode(                                     ...
                                obj.X2StoreNodes{ colIdx + 1, leakIdx + 1 }, ...
                                obj.XTStoreNodes{ colIdx + 1, leakIdx + 1 }, ...
                                xTComputer                                   ...
                    ) } ;                          
                end
            end
        end
        
%         function setupXTCostComputationNodes( obj )
%             obj.XTCostComputationNodes = cell( 4, 4 );
%             for colIdx = 0:3
%                 for leakIdx = 0:3
%                     xtCostComputer = XTCostComputer(                        ...
%                                                 colIdx, leakIdx,            ...
%                                                 obj.addKeyProbabilites,     ...
%                                                 obj.subBytesProbabilites,   ...
%                                                 obj.shiftRowsProbabilites,  ...
%                                                 obj.X2Probabilities,        ...
%                                                 obj.XTProbabilities         ...
%                     );
%                     obj.XTCostComputationNodes( colIdx + 1, leakIdx + 1  )   = {...
%                         ComputationNode(                                        ...                            ...
%                                 obj.XTStoreNodes{ colIdx + 1, leakIdx + 1 },    ...
%                                 obj.XTCostStoreNodes{ colIdx + 1, leakIdx + 1 },...
%                                 xtCostComputer                                      ...
%                     ) } ;                          
%                 end
%             end
%         end
        
        function setupX4ComputationNodes( obj )
            NUM_COLS  = 4;
            NUM_TAKES = 2;
            obj.X4ComputationNodes = cell( NUM_COLS, NUM_TAKES );           
            
            x2ReorderByTakeIdx = [ 1 2 3 4;   ... %when taking leak 1,3 the bytes are oredered 1 2 3 4
                                   4 1 2 3 ]; ... %when taking leaks 2,4 the 
                                                  %bytes are ordered 2 3 4 1, 
                                                  %thus we need to take the
                                                  %4th byte first, then 1 2
                                                  %3
                                    
            
            for colIdx = 1:NUM_COLS
                for takeIdx = 1:NUM_TAKES
                    x4Computer = X4Computer( x2ReorderByTakeIdx( takeIdx, : ) );
                    srcStorages = cell( 1, 2 );
                    srcStorages( 1 ) = obj.XTStoreNodes( colIdx , takeIdx );
                    srcStorages( 2 ) = obj.XTStoreNodes( colIdx , takeIdx + 2 );
                    obj.X4ComputationNodes( colIdx, takeIdx  )   = {         ...
                        ComputationNode(                                     ...                              
                                srcStorages,                                 ...
                                obj.X4StoreNodes{ colIdx, takeIdx }, ...
                                x4Computer                                   ...
                    ) } ;                          
                end
            end
        end
        
        function setupMergeX4ComputationNodes( obj )
            NUM_COLS  = 4;
            obj.MergeX4ComputationNodes = cell( 1, NUM_COLS );           
            
            for colIdx = 1:NUM_COLS
                mergeX4Computer = MergeX4Computer();
                srcStorages = cell( 1, 2 );
                srcStorages( 1 )      = obj.X4StoreNodes( colIdx , 1 );
                srcStorages( 2 )      = obj.X4StoreNodes( colIdx , 2 );

                obj.MergeX4ComputationNodes( colIdx  )   = {        ...
                    ComputationNode(                                ...                              
                            srcStorages,                            ...
                            obj.MergeX4StoreNodes{ colIdx },        ...
                            mergeX4Computer                         ...
                ) } ;                          
            end
        end
        
        function setupMixColsComputationNodes( obj )
            NUM_COLS  = 4;
            obj.mixColsComputationNodes = cell( 1, NUM_COLS );           
            
            for colIdx = 1:NUM_COLS
                mixColsComputer = MixColsComputer();
                obj.mixColsComputationNodes( colIdx  )   = {        ...
                    ComputationNode(                                ...                              
                            obj.MergeX4StoreNodes{ colIdx },        ...
                            obj.mixColsStoreNodes{ colIdx },        ...
                            mixColsComputer                         ...
                ) } ;                          
            end
        end
        
         function setupMixColsCostComputationNodes( obj )
            NUM_COLS  = 4;
            obj.mixColsCostComputationNodes = cell( 1, NUM_COLS );           
            
            for colIdx = 0:( NUM_COLS -1 )
                mixColsCostComputer = MixColsCostComputer(                  ...
                                        colIdx,                             ...
                                        obj.mixColsStoreNodes{ colIdx + 1}, ...              
                                        obj.mixColsProbabilites             ...
                );
                obj.mixColsCostComputationNodes( colIdx + 1 )   = { ...
                    ComputationNode(                                ...                              
                            obj.mixColsStoreNodes{ colIdx + 1},     ...
                            obj.mixColsCostStoreNodes{ colIdx + 1 },...
                            mixColsCostComputer                     ...
                ) } ;                          
            end
        end
        
        function [ x2Statistics, mcStatistics ] = CalcCorrectKeyPrices( obj, correctKey )
            x2Statistics = zeros( 4, 4, 2 );
            mcStatistics = zeros( 4, 2 );
            
            for colIdx = 0:3
                for leakIdx = 0:3
                    byte_0_idx  = colIdx * 4 + mod( leakIdx   , 4 ) + 1;
                    byte_1_idx  = colIdx * 4 + mod( leakIdx +1, 4 ) + 1;
                    srcByte0Idx = obj.shiftRowsMapping( byte_0_idx );
                    srcByte1Idx = obj.shiftRowsMapping( byte_1_idx );
                    
                    keyBytes  = correctKey( [ srcByte0Idx, srcByte1Idx ] );
                    storeNode = obj.XTStoreNodes{colIdx + 1,leakIdx + 1};
                    location  = ismember( storeNode.origValues( :, 3:4 ), keyBytes, 'rows' ) ;
                    
                    prices       = storeNode.origValuesPrices;
                    correctPrice = prices( location );
                    rank         = sum( prices > correctPrice );
                    
                    x2Statistics( colIdx + 1, leakIdx + 1, 1 ) = correctPrice;
                    x2Statistics( colIdx + 1, leakIdx + 1, 2 ) = rank;
                end
            end
            
            for colIdx = 0:3
                colIDs = colIdx * 4 + (1:4);
                keyBytes = correctKey( obj.shiftRowsMapping( colIDs ) );
                
                storeNode = obj.mixColsCostStoreNodes{colIdx + 1};
                location  = ismember( storeNode.values( :, 5:8 ), keyBytes, 'rows' ) ;

                if sum( location ) == 0
                    mcStatistics( colIdx + 1, 1 ) = -Inf;
                    mcStatistics( colIdx + 1, 2 ) = Inf;
                else
                    prices       = storeNode.valuesPrices;
                    correctPrice = prices( location );
                    rank         = sum( prices > correctPrice );

                    mcStatistics( colIdx + 1, 1 ) = correctPrice;
                    mcStatistics( colIdx + 1, 2 ) = rank;
                end
            end
        end
    end
    
    
     methods (Static = true)
       function [ estimatedOffset ] = EsitimateOffset( plainXorMaskPosteriors, ...
                                                         plain                   ...
         )
            NUM_POSSIBLE_MASKS    = 16;
            candidatePlainXORMask = zeros( NUM_POSSIBLE_MASKS, length( plain ) );
            for offset = 0:15
                candidateMask = Moffset( offset );
                for byteIdx = 1:16
                    candidatePlainXORMask( offset + 1, byteIdx ) =          ...
                                        bitxor( plain( :, byteIdx ),        ...
                                                candidateMask( :, byteIdx ) ...
                    );
                end
            end

            %%            
            plainXorMaskHW = AESNetworkSolver.byteHammingWeights( candidatePlainXORMask + 1 );
            probabilites   = zeros( size( candidatePlainXORMask ) );

            %%
            for byteIdx = 0:15
                byteHW                         = plainXorMaskHW( :, byteIdx + 1 );
                probabilites( :, byteIdx + 1 ) =                         ...
                                    plainXorMaskPosteriors( byteIdx + 1, ...
                                               byteHW + 1                ...
                );
            end
            
            candidateProbabilites     = prod( probabilites, 2 );
            [ ~, estimatedOffsetIdx ] = max( candidateProbabilites );
            estimatedOffset           = estimatedOffsetIdx - 1;
       end 
         
       function [ stateProbabilites ] = ExtractStateProbabilites( rawPostriorProbs )
            % In:  rawPostriorProbs - 245 leaks X 9 HammingWeights
            %        probabilities
            % Out: stateProbabilities - 4 states X 16 bytes  X 9 Hamming Weights 
            %                       probabilites matrix
            % state 1 - after add round key
            % state 2 - after sub bytes
            % state 3 - after shift rows
            % state 4 - after mix cols
            
            stateProbabilites = zeros( 4, 16, 9 );
            rawPostriorProbs  = squeeze( rawPostriorProbs );
            %see leaks.txt for details on leak indices
            %state s_2:
            LEAK_START_IDX_AFTER_ROUND_KEY = 50; %see leaks.txt
            for byteIdx = 0:15
                stateProbabilites( 1, byteIdx + 1, : ) =                        ...
                    rawPostriorProbs( LEAK_START_IDX_AFTER_ROUND_KEY + byteIdx, ...
                                      :                                         ...
                );
            end
            
            
            %state s_3:
            LEAK_START_IDX_SUBBYTES = 66; %see leaks.txt
            for byteIdx = 0:15
                stateProbabilites( 2, byteIdx + 1, : ) =                        ...
                    rawPostriorProbs( LEAK_START_IDX_SUBBYTES + byteIdx,        ...
                                      :                                         ...
                );
            end
            
            %state s_4:
            LEAK_START_IDX_SHIFT_ROWS = 82; %see leaks.txt
            for byteIdx = 0:15
                stateProbabilites( 3, byteIdx + 1, : ) =                        ...
                    rawPostriorProbs( LEAK_START_IDX_SHIFT_ROWS + byteIdx,      ...
                                      :                                         ...
                );
            end
            
            %state s_5:
            LEAK_START_IDX_MIX_COLS = 98; %see leaks.txt
            for byteIdx = 0:15
                stateProbabilites( 4, byteIdx + 1, : ) =                        ...
                    rawPostriorProbs( LEAK_START_IDX_MIX_COLS + byteIdx,        ...
                                      :                                         ...
                );
            end
       end
        
       function [ mixColsProbabilities ] = ExtractMixColsProbabilites( rawPostriorProbs )
            % In:  rawPostriorProbs - 245 leaks X 9 HammingWeights
            %        probabilities
            % Out: stateProbabilities - 4 colums X 9 Mix Cols leaks X 9 Hamming Weights 
            %        probabilites matrix
            
            rawPostriorProbs  = squeeze( rawPostriorProbs );
            mixColsProbabilities = zeros( 4, 9, 9 );
            LEAK_START_IDX_MIX_COLS = 114; %see leaks.txt
            for coloumnIdx = 0:3
               for leakIdx = 0:8
                   mixColsProbabilities( coloumnIdx + 1, leakIdx + 1, : ) = ...
                        rawPostriorProbs( LEAK_START_IDX_MIX_COLS + ...
                                                coloumnIdx * 9    + ...
                                                leakIdx,            ...
                                          :                         ...
                   );
               end
            end
       end
        
        function [ results ] = GenerateResults( columsCandidateKeys )
            results           = zeros( 256, 16 ); 
            COST_COLUMN_ID    = 34;
            KEYS_START_ID     = 5;
            
            for colIdx = 0:3
              colResults   = columsCandidateKeys{ colIdx + 1 }.values;
              [ ~, ranks ] = sort( colResults( :, COST_COLUMN_ID ), 'descend' );
              
                for rowIdx = 0:3
                    byteIdx           = colIdx * 4 + rowIdx + 1;
                    srcByteIdx        = AESNetworkSolver.shiftRowsMapping( byteIdx );
                    lastRankedByteIdx = 0;
                    for keyIdx = ranks'
                       valueIsInColumn = KEYS_START_ID + rowIdx;
                       keyByte =  colResults( keyIdx, valueIsInColumn);
                       if sum( results( :, srcByteIdx ) == keyByte ) > 0
                           %if keyByte already in list - skip it!
                           continue;
                       else
                           %put keyByte in list
                           results( lastRankedByteIdx + 1, srcByteIdx ) = keyByte;
                           lastRankedByteIdx = lastRankedByteIdx + 1;
                       end
                       
                       if lastRankedByteIdx >= 256
                           %if all 256 key bytes were ranked - go to next
                           %byte
                           break;
                       end 
                    end           
                end
           end
        end
       
        function [ intersectionSolution ] = IntersectSolutions( multipleSolutions )
            KEY_COL_IDS = 5:8;
            
            if size( multipleSolutions, 1 ) == 1
                intersectionSolution = multipleSolutions;
                return;
            end
            
            intersectionSolution = cell( 1, 4 );
            NO_PRICES = [];
            for colIdx = 1:4
                intersectionSolution( colIdx ) = { StorageNode( NO_PRICES ) };
            end
            
            for colIdx = 1:4
                firstSolution   = multipleSolutions{ 1, colIdx };
                validCandidates = true( 1, size( firstSolution.values, 1 ) );
                
                for solIdx = 2:size( multipleSolutions, 1 )
                    currentSolution = multipleSolutions{ solIdx, colIdx };
                    intersetion     = ismember(                          ...
                                firstSolution.values( :, KEY_COL_IDS ),  ...
                                currentSolution.values( :, KEY_COL_IDS ),...
                                'rows'                                   ...
                    );
                    
                    validCandidates = logical( validCandidates.*intersetion' );
                end
                
                if sum( validCandidates ) == 0
                    intersectionSolution = [];
                    return; %intersection is EMPTY!
                end
                
                intersectionSolution{ colIdx }.values = ...
                                firstSolution.values( validCandidates, : );
            end

        end
    end
    
end

