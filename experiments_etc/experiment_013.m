
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


 % 30 Dec 2013

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
KEY_PART_MAX_PRICE = 400;
TRACES              = 401:999;
FIRST_TRACE         = TRACES( 1 );
KEYS_BYTES          = 1:4;
PRICE_ID            = 30;
X2_THRESHOLD        = 3e2;
X4_THRESHOLD        = 1e3;

totalInfo = [];
solutions = cell( length( TRACES ), 4 );
for traceIdx = TRACES
    fprintf( 'Trace %d ', traceIdx );
    postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );
    stateProbabilites   = OPBCreator.ExtractStateProbabilites( postriors );
    mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( postriors );

    solver              = Solver( rsm.masks( traceIdx, : ),         ...
                              rsm.plainXORMask( traceIdx, : ),  ...
                              stateProbabilites,                ...
                              mixColsProbabilites               ...
    );
    solver.XORLeakPruneThreshhold = X2_THRESHOLD;
    solver.XOR_4_PruneThreshhold  = X4_THRESHOLD;
    
    tic;
    solver.Solve();
    solvingTime = toc;
    fprintf( 'Solving took %.1f sec, ', solvingTime );
    
    for colIdx = 1:4
        solutions( traceIdx - FIRST_TRACE + 1, colIdx ) = ...
            { solver.mixColsSolvers{ colIdx }.mixColsPrices( [ KEYS_BYTES, PRICE_ID ], : ) };
    end
    save( 'solutions.mat', 'solutions' );
    
    tic;
    ranksOfKeysParts = solver.CalcRanksOfKeyParts( rsm.AES_KEY );
    possibleKeys     = solver.GetPossibleKeys( KEY_PART_MAX_PRICE );
    location         = find(ismember( possibleKeys(1:16,:)', rsm.AES_KEY(1:16)', 'rows' ));
    [prices,ids]     = sort( possibleKeys( 17, : ), 'ascend' );
    if isempty( location )
        rank  = Inf;
        price = Inf;
    else
        rank  = find( ids == location );
        price = prices( rank );
    end
    resolvingTime = toc;
    fprintf( 'resolving took %.1f sec, ', resolvingTime );
    info = [ traceIdx,                      ...
             solver.XORLeakPruneThreshhold, ...
             solver.XOR_4_PruneThreshhold,  ...
             solvingTime,                   ...
             resolvingTime,                 ...
             size( possibleKeys, 2 ),       ...
             rank,                          ...
             price,                ...
             ranksOfKeysParts(1, 1:4),      ...
             ranksOfKeysParts(2, 1:4) ];
         
    fprintf( 'key candidates: %d, rank: %d, price: %d\n', ...
             size( possibleKeys, 2), rank, price );
    totalInfo = [ totalInfo; info ];%#ok<AGROW>
    save( 'totalInfo.mat' , 'totalInfo' );
    clear solver;
    clear possibleKeys;
    clear ids;
    clear prices;
end









