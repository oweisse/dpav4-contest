
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


function [ entropies ] = CalcEntropyEvolution( solver )
                    
                    
    entropies = zeros( 4, 8 ); 
    for colIdx = 0:3
       singleByteEntropies         = zeros( 4, 4 );
       singleByteEntropies( :, 1 ) = 8;
       for rowIdx = 0:3
          byteIdx     = colIdx * 4 + rowIdx + 1;
          srcByteIdx  = solver.shiftRowsMapping( byteIdx );
          addKeyProbs = solver.addKeyStoreNodes{ srcByteIdx }.valuesPrices;
          entropyTemp = addKeyProbs.*log2( addKeyProbs );
          notNANIDs   = ~isnan( entropyTemp );
          singleByteEntropies( rowIdx + 1, 2 ) = -sum( entropyTemp( notNANIDs ) );
          
          subBytesProbs = solver.subBytesStoreNodes{ srcByteIdx }.valuesPrices;
          entropyTemp   = subBytesProbs.*log2( subBytesProbs );
          notNANIDs     = ~isnan( entropyTemp );
          singleByteEntropies( rowIdx + 1, 3 ) = -sum( entropyTemp( notNANIDs ) );
          
          shiftRowsProbs = solver.shiftRowsStoreNodes{ byteIdx }.valuesPrices;
          entropyTemp    = shiftRowsProbs.*log2( shiftRowsProbs);
          notNANIDs      = ~isnan( entropyTemp );
          singleByteEntropies( rowIdx + 1, 4 ) = -sum( entropyTemp( notNANIDs ) );
       end
       entropies( colIdx + 1, 1:4 ) = sum( singleByteEntropies);
       
       x2Entropy = zeros( 1, 4 );
       xTEntropy = zeros( 1, 4 );
       for leakIdx = 1:4
            x2LeakProbs = solver.X2StoreNodes{ colIdx + 1, leakIdx }.valuesPrices;
            entropyTemp = x2LeakProbs.*log2( x2LeakProbs);
            notNANIDs   = ~isnan( entropyTemp );
            x2Entropy( leakIdx ) = -sum( entropyTemp( notNANIDs ) );
           
            xTLeakProbs = solver.XTStoreNodes{ colIdx + 1, leakIdx }.valuesPrices;
            entropyTemp = xTLeakProbs.*log2( xTLeakProbs);
            notNANIDs   = ~isnan( entropyTemp );
            xTEntropy( leakIdx ) = -sum( entropyTemp( notNANIDs ) );
       end
       %%
       x2Entropy_take1 = x2Entropy( 1 ) + x2Entropy( 3 );
       x2Entropy_take2 = x2Entropy( 2 ) + x2Entropy( 4 );
       entropies( colIdx + 1, 5 ) = min( x2Entropy_take1, x2Entropy_take2 );
       
       xTEntropy_take1 = xTEntropy( 1 ) + xTEntropy( 3 );
       xTEntropy_take2 = xTEntropy( 2 ) + xTEntropy( 4 );
       entropies( colIdx + 1, 6 ) = min( xTEntropy_take1, xTEntropy_take2 );
       %%
       x4Probs1         = solver.X4StoreNodes{ colIdx + 1, 1 }.valuesPrices;
       entropyTemp      = x4Probs1.*log2( x4Probs1 );
       notNANIDs        = ~isnan( entropyTemp );
       x4Entropy_take1  = -sum( entropyTemp( notNANIDs ) );
       
       x4Probs2         = solver.X4StoreNodes{ colIdx + 1, 2 }.valuesPrices;
       entropyTemp      = x4Probs2.*log2( x4Probs2 );
       notNANIDs        = ~isnan( entropyTemp );
       x4Entropy_take2  = -sum( entropyTemp( notNANIDs ) );
       
       entropies( colIdx + 1, 7 ) = min( x4Entropy_take1, x4Entropy_take2  );
       
       %%
       x4MergedProbs   = solver.MergeX4StoreNodes{ colIdx + 1 }.valuesPrices;
       entropyTemp     = x4MergedProbs.*log2( x4MergedProbs );
       notNANIDs       = ~isnan( entropyTemp );
       entropies( colIdx + 1, 8 ) = -sum( entropyTemp( notNANIDs ) );
       
       %%
       mixColsProbs   = solver.mixColsCostStoreNodes{ colIdx + 1 }.valuesPrices;
       entropyTemp     = mixColsProbs.*log2( mixColsProbs );
       notNANIDs       = ~isnan( entropyTemp );
       entropies( colIdx + 1, 9 ) = -sum( entropyTemp( notNANIDs ) );
    end
end


