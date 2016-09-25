
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


 % 20 FEbuary 2014
 % 07 Jan 2014
%%
NUM_TRACES = 1000;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();


%%
%%%%%%%%%%%
load( 'classifiers-2013_11_12_16-10-35.mat' );

powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = 50:149; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers       = classifiers;
%%
allEvolutions = [];
for traceIdx = 415:420
    %%
%     traceIdx = 415;
    plainXorMask =  rsm.plainXORMask( traceIdx, : );
    mask         =  rsm.masks( traceIdx, : );

    %%
    postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );

    stateProbabilites   = OPBCreator.ExtractStateProbabilites( postriors );
    mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( postriors );

    X2Probabilities = squeeze(mixColsProbabilites( :, 2:2:9, : ));
    XTProbabilities = squeeze(mixColsProbabilites( :, 3:2:9, : ));
    X4Probabilities = squeeze(mixColsProbabilites( :, 1, : ));



    %%
    clear solver


    solver       = AESNetworkSolver( plainXorMask,      ...
                                     mask,              ...
                                     stateProbabilites, ...
                                     X2Probabilities,   ...
                                     XTProbabilities,   ...
                                     X4Probabilities    ...
    );
    fprintf( 'Solving trace %d.. ', traceIdx );
    tic; 
    solver.Solve();
    executionTime = toc;
    %%
    
    es = CalcEntropyEvolution( solver );
    allEvolutions = [ allEvolutions; sum(es) ];

end
%%



