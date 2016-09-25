
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


% 31 Dec 2013

%% load traces and leaks
NUM_TRACES = 1000;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();
%%
load( 'classifiers-2013_11_12_16-10-35.mat' );

powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = 50:149; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers       = classifiers;

%%
TRACES = 401:999;
KEY_PART_MAX_PRICE = 400;
FIRST_TRACE = TRACES(1);

prices = zeros(1, length( TRACES ) ); 
for traceIdx = TRACES
    postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );
    stateProbabilites   = OPBCreator.ExtractStateProbabilites( postriors );
    mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( postriors );

    solver              = Solver( rsm.masks( traceIdx, : ),         ...
                              rsm.plainXORMask( traceIdx, : ),  ...
                              stateProbabilites,                ...
                              mixColsProbabilites               ...
    );
    solver.XORLeakPruneThreshhold = 3e2;
    solver.XOR_4_PruneThreshhold  = 5e2;
    price = solver.CalcXor2CorrectPrice( rsm, traceIdx );
    
    prices( 1, traceIdx - FIRST_TRACE + 1 ) = price;
    fprintf( 'Trace %d: price for Xor 2: %.1f\n', traceIdx, price );
    save( 'pricesX2.mat', 'prices' );
end


%%
failursExplained    = cell( 1, size(totalInfo, 1 ) );
X2_PRUNE_THRESHOLD  = 2;
TRACE_IDX           = 1;
KEY_PRICE           = 8;
KEY_PARTS_PRICES_IDS= 12:15;

numX2Errors           = 0;
numKeyThresholdErrors = 0;
totalErrors           = 0;
for idx = 1:size( totalInfo, 1 )
   traceIdx = totalInfo( idx, TRACE_IDX );
   if isinf( totalInfo( idx, KEY_PRICE ) )
       totalErrors             = totalErrors + 1;
       failursExplained( idx ) = cellstr( sprintf( 'Trace %d faild', traceIdx ) );
   end
   
   x2Threshold = totalInfo( idx, X2_PRUNE_THRESHOLD );
   x2Price = prices( idx );
   if x2Price > x2Threshold
       numX2Errors             = numX2Errors + 1;
       failursExplained( idx ) = cellstr( sprintf(                   ...
           'Trace %d faild due x2 prune. Threshold: %d, actual: %d', ...
           traceIdx, x2Threshold, x2Price                            ...
       ) );
   end
   
   keyPartMaxPrice = max( totalInfo( idx, KEY_PARTS_PRICES_IDS ) );
   if ~isinf(keyPartMaxPrice) && keyPartMaxPrice > KEY_PART_MAX_PRICE
       numKeyThresholdErrors    = numKeyThresholdErrors + 1;
        failursExplained( idx ) = cellstr( sprintf(                   ...
           'Trace %d faild key part threshold. Threshold: %d, actual: %d', ...
           traceIdx, KEY_PART_MAX_PRICE, keyPartMaxPrice                            ...
       ) );
   end
end

%%
f = fopen( 'failurs.txt', 'w' );
for idx = 1:length( failursExplained )
    fprintf(  f, '%s\n', cell2mat( failursExplained(idx) ) );
end
fclose( f );







