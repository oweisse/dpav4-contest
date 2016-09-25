
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


classdef Pricer < handle

    properties
        plainXorMask;
        mask;
        
        probabilites;
        groupSizes;
        
        addKeyProbabilites;
        subBytesProbabilites;
        shiftRowsProbabilites;
        X2Probabilities;
        
        %the network nodes:
        addKeyStorageNode;
        subBytesStorageNode;
        shiftRowsStorageNode;
        addKeyComputationNode;
        subBytesComputationNode;
        shiftRowsComputationNode;
    end
    
    
    properties (Constant = true)
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
               
        shiftRowsMapping = [ 1  6  11 16 ...
                             5  10 15 4  ...
                             9  14 3  8  ...
                             13 2  7  12 ];
    end
    
    methods
        function obj = Pricer( plainXorMask, mask, stateProbabilites, X2Probabilities )
            obj.plainXorMask = plainXorMask;
            obj.mask         = mask;
            
            obj.addKeyProbabilites    = stateProbabilites( 1, : );
            obj.subBytesProbabilites  = stateProbabilites( 2, : );
            obj.shiftRowsProbabilites = stateProbabilites( 3, : );
            obj.X2Probabilities       = X2Probabilities;
            
            obj.probabilites = containers.Map();
            obj.groupSizes   = containers.Map();
        end
        
        function [ result ] = GetProbability( obj, colIdx, leakIdx, x2ComputationTrace )
            % colIdx in 1..4, leakIdx in 1..4
            x2Result = x2ComputationTrace( end );
            x2HW     = obj.byteHammingWeights( x2Result + 1 );
            result   = ( obj.SingleClassSize( x2HW ) )^(-1);
            result   = result* obj.X2Probabilities( colIdx, leakIdx, x2HW + 1 );
            
            src1Bytes = x2ComputationTrace( 1:2:9 );
            src2Bytes = x2ComputationTrace( 2:2:10 );
            byte0Idx  = ( colIdx - 1 ) * 4 + mod( leakIdx - 1   , 4 ) + 1;
            byte1Idx  = ( colIdx - 1 ) * 4 + mod( leakIdx - 1 +1, 4 ) + 1;
            result    = result * ...
                        obj.Get3ClassProbability(  byte0Idx, src1Bytes );
            result    = result * ...
                        obj.Get3ClassProbability(  byte1Idx, src2Bytes );
        end
        
        function [ result ] = Get3ClassProbability( obj, byteIdx, computationTrace )
            [ hashKey, hws ] = obj.GenerateHashKey( byteIdx, computationTrace );
            if obj.probabilites.isKey( hashKey )
                result = obj.probabilites( hashKey );
                return;
            end
            
            groupSize = obj.GetGroupSize( hashKey, byteIdx, hws );
            resultHW  = hws( end );
            result    = groupSize;
            result    = result / ( obj.SingleClassSize( resultHW ) );
            result    = result * obj.shiftRowsProbabilites( byteIdx, resultHW + 1);
            
            origByteIdx = obj.shiftRowsMapping( byteIdx );
            result      = result * Get2ClassProbability(             ...
                                        origByteIdx,                 ...
                                        computationTrace( 1:(end-1)) ...
            );
        
            obj.probabilites( hashKey ) = result;
        end
        
        function [ result ] = Get2ClassProbability( obj, byteIdx, computationTrace )
            [ hashKey, hws ] = obj.GenerateHashKey( byteIdx, computationTrace );
            if obj.probabilites.isKey( hashKey )
                result = obj.probabilites( hashKey );
                return;
            end
            
            groupSize = obj.groupSizes( hashKey );
            resultHW  = hws( end );
            result    = groupSize;
            result    = result / ( obj.SingleClassSize( resultHW ) );
            result    = result * obj.subBytesProbabilites( byteIdx, resultHW + 1);
            
            addKeyHw  = hws( end - 1 );
            result    = result * obj.addKeyProbabilites( byteIdx, addKeyHw + 1 );
        
            obj.probabilites( hashKey ) = result;
        end
         
        function [ groupSize ] = GetGroupSize( obj, hashKey, byteIdx, hws )
            if obj.groupSizes.isKey( hashKey )
                groupSize = obj.groupSizes( hashKey );
            else
                groupSize = obj.CalcClassesIntersectionSize( byteIdx, hws );
            end
        end
        
        function [ groupSize ] = CalcClassesIntersectionSize( obj, byteIdx, hws )
           %byteIdx in 1..16
           if length( hws ) ~= 3  
              error( 'Can calc class intersection sizes only when given 3 hw classes for addkey, subbytes and shiftrows') ;
           end
           
           origByteIdx =  obj.shiftRowsMapping( byteIdx );
           obj.InitNetwork( origByteIdx, hws );
           
           obj.SolveUntilAddKey( hws( 1 ) );
           hashKey1 = obj.GenerateHashKeyFromHW( byteIdx, hws( 1 ) );
           obj.groupSizes( hashKey1 ) = size( obj.addKeyStorage.values, 1 );
           
           obj.SolveUntilSubBytes( hws( 2 ));
           hashKey2 = obj.GenerateHashKeyFromHW( byteIdx, hws( 1:2 ) );
           obj.groupSizes( hashKey2 ) = size( obj.subBytesStorage.values, 1 );
           
           obj.SolveUntilShiftRows( hws( 3 ) );
           hashKey3                   = obj.GenerateHashKeyFromHW( byteIdx, hws( 1:3 ) );
           groupSize                  = size( obj.shiftRowsStorage.values, 1 );
           obj.groupSizes( hashKey3 ) = groupSize;
        end
        
        function obj.InitNetwork( obj, byteIdx )
            obj.InitKeyStorage( byteIdx );
            obj.addKeyStorageNode     = StorageNode();
            obj.subBytesStorageNode   = StorageNode();
            obj.shiftRowsStorageNode  = StorageNode();
            
            obj.addKeyComputationNode =  ComputationNode(         ...
                                            obj.keyStorageNode,   ...
                                            obj.addKeyStorageNode,...
                                            AddKeyComputer()      ...
            );
            
            subBytesComputer = SubBytesComputer( byteIdx - 1, obj.mask );
            obj.subBytesComputationNode = ComputationNode(          ...                     ...
                                            obj.addKeyStorageNode,  ...
                                            obj.subBytesStorageNode,...
                                            subBytesComputer        ...
            ) ;
            obj.shiftRowsComputationNodes  =                           ...
                                ComputationNode(                       ...
                                            obj.subBytesStorageNode,   ...
                                            obj.shiftRowsStorageNode,  ...
                                            shiftRowsComputer          ...
            );     
        end
        
        function InitKeyStorage( obj, byteIdx )
            obj.keyStorageNode = StorageNode();
            initVals           = zeros( 256, 2 );
            initVals( :, 1 )   = obj.plainXorMask( byteIdx );
            initVals( :, 2 )   = ( 0:255 )';

            obj.keyStorageNode.ReconcileValues( initVals ); %setup initial values
        end
        
        function SolveUntilAddKey( obj, addKeyHW )
           obj.addKeyComputationNode.ComputeAndReconcile();
           obj.addKeyStorageNode.values = ...
                obj.TakeSingleHWResults( obj.addKeyStorageNode.values, addKeyHW );
        end
        
        function SolveUntilSubBytes( obj, subBytesHW )
           obj.subBytesComputationNode.ComputeAndReconcile();
           obj.subBytesStorageNode.values = ...
                obj.TakeSingleHWResults( obj.subBytesStorageNode.values, subBytesHW );
        end
        
        function SolveUntilShiftRows( obj, shiftRowsHW )
           obj.shiftRowsComputationNodes.ComputeAndReconcile();
           obj.shiftRowsStorageNode.values = ...
                obj.TakeSingleHWResults( obj.shiftRowsStorageNode.values, shiftRowsHW );
        end

        function [ filteredValues ] = TakeSingleHWResults( origValues, allowedHW )
           resultValues     =  origValues( :, end );
           resultHW         = obj.byteHammingWeights( resultValues + 1 );
           validResults     = ( resultHW == allowedHW );
           filteredValues   = origValues( validResults, : );
        end
        
%         function ComputeClassSizelX2( obj, x2ComputationTrace )
%             src1Bytes = x2ComputationTrace( 1:2:9 );
%             src2Bytes = x2ComputationTrace( 2:2:10 );
%             x2Byte = x2ComputationTrace( 9 );
%             x2ByteHW = byteHammingWeight( x2Byte + 1 );
%             possibleSrc1Bytes = obj.GetClassSizeUpToShiftRows( ...
%                                                         srcPlainBytes( 1 ), ...
%                                                         src1Bytes ...
%             );
%             possibleSrc2Bytes = obj.GetClassSizeUpToShiftRows( ...
%                                                         srcPlainBytes( 2 ), ...
%                                                         src2Bytes ...
%             );
%         
%             combinations = combvec( possibleSrc1Bytes, possibleSrc2Bytes );
%             xorResult = bitxor( combinations(1,:), combinations(2,:) );
%             uniqueResults = unique( xorResult );
%             resultsHW = byteHammingWeight( uniqueResults + 1 );
%             groupSize = sum( resultsHW == x2ByteHW );
%             
%             
%         end
    end
    
end

