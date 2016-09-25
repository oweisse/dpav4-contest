
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


%3 Dec 2013
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
traceIdx   = 406;
postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );


%%

[ idealPostrios, idealProbaility ] = GenerateIdealPostrios(         ...
                                       postriors,                   ...
                                       leaksToLearn,                ...
                                       rsm.leaks( traceIdx, : )     ...
);

%%

stateProbabilites   = OPBCreator.ExtractStateProbabilites( idealPostrios );
mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( idealPostrios );

% %%
% % stateProbabilites = stateProbabilites > 0.5;
% solver              = Solver( rsm.masks( traceIdx, : ),         ...
%                               rsm.plainXORMask( traceIdx, : ),  ...
%                               stateProbabilites,                ...
%                               mixColsProbabilites               ...
% );

%%
stateProbabilites   = OPBCreator.ExtractStateProbabilites( postriors );
mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( postriors );

%%
% numLeaks = size( postriors, 1 );
% thinPostriors = zeros( size( postriors ) );
% for leakIdx = 1:numLeaks
%     [ ~ ,ranks ] = sort( postriors( leakIdx, : ), 'descend'  );
%     thinPostriors( leakIdx, ranks( 1:5 ) ) = postriors( leakIdx, ranks( 1:5 ) );
% end
% %%
% stateProbabilites   = OPBCreator.ExtractStateProbabilites( thinPostriors );
% mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( thinPostriors );

%%
lastEntropy = Inf;
%pruneValues = [1e3,1e6,1e5];
pruneValues = [3e2,5e2,Inf];
threshholdIdx = 0 ; 
% while( true )
    solver              = Solver( rsm.masks( traceIdx, : ),         ...
                              rsm.plainXORMask( traceIdx, : ),  ...
                              stateProbabilites,                ...
                              mixColsProbabilites               ...
    );

    threshholdIdx = mod( threshholdIdx + 1, 3);
%     pruneValues( threshholdIdx + 1 ) = 0.5 * pruneValues( threshholdIdx + 1 );
    pruneValues

    x2Price = solver.CalcXor2CorrectPrice( rsm, traceIdx )
   
    solver.XORLeakPruneThreshhold = pruneValues( 1 );
    solver.XOR_4_PruneThreshhold  = pruneValues( 2 );
    solver.s5_PruneThreshhold     = pruneValues( 3 );

    tic;
    solver.Solve();
    toc
    %%
    ranksOfKeysParts = solver.CalcRanksOfKeyParts( rsm.AES_KEY )
    %%
    possibleKeys = solver.GetPossibleKeys( 350 );
    location = find(ismember( possibleKeys(1:16,:)', rsm.AES_KEY(1:16)', 'rows' ));
    [prices,ids] = sort( possibleKeys( 17, : ), 'ascend' );
    rank = find( ids == location )
    
    %%














