
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
classdef XTCostComputer < handle
    properties
        colIdx;
        leakIdx;
        addKeyProbabilites;
        subBytesProbabilites;
        shiftRowsProbabilites;
        X2Probabilities;
        XTProbabilities;
        
        addKey0Probs;
        subBytes0Probs;
        shiftRows0Probs;
        addKey1Probs;
        subBytes1Probs;
        shiftRows1Probs;
        x2Probs;
        xtProbs;
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
               
               
       
        hwItemCount = [ nchoosek(8,0), ...
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
        function obj = XTCostComputer( colIdx, leakIdx,        ...
                                       addKeyProbabilites,     ...
                                       subBytesProbabilites,   ...
                                       shiftRowsProbabilites,  ...
                                       X2Probabilities,        ...
                                       XTProbabilities         ...
                    )
            obj.colIdx                  = colIdx;
            obj.leakIdx                 = leakIdx;
            obj.addKeyProbabilites      = addKeyProbabilites;
            obj.subBytesProbabilites    = subBytesProbabilites;
            obj.shiftRowsProbabilites   = shiftRowsProbabilites;
            obj.X2Probabilities         = X2Probabilities;
            obj.XTProbabilities         = XTProbabilities;
        end
        
        function [ dstValues ] = Compute( obj, srcValues )
            AK_SB_SR_X2_XT_IDS = 5:12;
            ADDKEY0_ID      = 1;
            ADDKEY1_ID      = 2;
            SUBBYTES0_ID    = 3;
            SUBBYTES1_ID    = 4;
            SHIFTROWS0_ID   = 5;
            SHIFTROWS1_ID   = 6;
            X2_ID           = 7;
            XT_ID           = 8;
            
            hwVals      = obj.byteHammingWeights(                      ...
                                srcValues( :, AK_SB_SR_X2_XT_IDS ) + 1 ...
            );          
            
            byte_0_idx  = obj.colIdx * 4 + obj.leakIdx + 1;
            byte_1_idx  = obj.colIdx * 4 + mod( obj.leakIdx + 1, 4 ) + 1;
            byte0SrcIdx = obj.shiftRowsMapping( byte_0_idx );
            byte1SrcIdx = obj.shiftRowsMapping( byte_1_idx );
            
            
            addKey0HWs      = hwVals( :, ADDKEY0_ID );
            addKey1HWs      = hwVals( :, ADDKEY1_ID );
            subBytes0HWs    = hwVals( :, SUBBYTES0_ID );
            subBytes1HWs    = hwVals( :, SUBBYTES1_ID );
            shiftRows0HWs   = hwVals( :, SHIFTROWS0_ID );
            shiftRows1HWs   = hwVals( :, SHIFTROWS1_ID );
            x2HWs           = hwVals( :, X2_ID );
            xtHWs           = hwVals( :, XT_ID );
            
%             addKey0ClassCount       = obj.CountClasses( addKey0HWs );
%             addKey1ClassCount       = obj.CountClasses( addKey1HWs );
%             subBytes0ClassCount     = obj.CountClasses( subBytes0HWs );
%             subBytes1ClassCount     = obj.CountClasses( subBytes1HWs );
%             shiftRows0ClassCount    = obj.CountClasses( shiftRows0HSs );
%             shiftRows1ClassCount    = obj.CountClasses( shiftRows1HSs );
%             x2HWsClassCount         = obj.CountClasses( x2HWs );
%             xtHWsClassCount         = obj.CountClasses( xtHWs );
                        
            obj.addKey0Probs    = obj.addKeyProbabilites( byte0SrcIdx, addKey0HWs + 1 ) ./ ...
                                  obj.hwItemCount( addKey0HWs + 1 );

            obj.subBytes0Probs  = obj.subBytesProbabilites( byte0SrcIdx, subBytes0HWs + 1) ./ ...
                                  obj.hwItemCount( subBytes0HWs + 1 );

            obj.shiftRows0Probs = obj.shiftRowsProbabilites( byte_0_idx, shiftRows0HWs + 1 ) ./ ...
                                  obj.hwItemCount( shiftRows0HWs + 1 );
            
            obj.addKey1Probs    = obj.addKeyProbabilites( byte1SrcIdx, addKey1HWs + 1 ) ./ ...
                                  obj.hwItemCount( addKey1HWs + 1 );
                          
            obj.subBytes1Probs  = obj.subBytesProbabilites( byte1SrcIdx, subBytes1HWs + 1 ) ./ ...
                                  obj.hwItemCount( subBytes1HWs + 1 );
                          
            obj.shiftRows1Probs = obj.shiftRowsProbabilites( byte_1_idx, shiftRows1HWs + 1 ) ./ ...
                                  obj.hwItemCount( shiftRows1HWs + 1 );
            
            obj.x2Probs = obj.X2Probabilities( obj.colIdx + 1, obj.leakIdx + 1, x2HWs + 1 );
            obj.x2Probs = squeeze( obj.x2Probs )';
            obj.x2Probs = obj.x2Probs ./ obj.hwItemCount( x2HWs + 1 ); 
            
            obj.xtProbs = obj.XTProbabilities( obj.colIdx + 1, obj.leakIdx + 1, xtHWs + 1 );
            obj.xtProbs = squeeze( obj.xtProbs )';
            obj.xtProbs = obj.xtProbs ./ obj.hwItemCount( xtHWs + 1 ); 
            
            prices = obj.addKey0Probs .* obj.addKey1Probs .*        ...
                     obj.subBytes0Probs .* obj.subBytes1Probs .*    ...
                     obj.shiftRows0Probs .* obj.shiftRows1Probs .*  ...
                     obj.x2Probs .* obj.xtProbs;
            
%             prices = prices / sum( prices );
%             prices = prices.^8;
            prices = prices / sum( prices );
            dstValues  = [ srcValues, prices' ];
        end
        
%         function [ classCount ] = CountClasses( ~, allClasses )
%             classCount = zeros( 1, 9 );
%             for hwID = 1:9
%                classCount( hwID ) = sum( allClasses + 1 == hwID );
%             end
%         end
    end
    
end



