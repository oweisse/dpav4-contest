
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

% %% load traces and leaks
% NUM_TRACES = 1000;
% rsm = RSM( 1:NUM_TRACES );
% rsm.CalcLeaks();
% %%
% load( 'classifiers-2013_11_12_16-10-35.mat' );
% 
% powerAnalyzer                   = PowerAnalyzer();
% leaksToLearn                    = 50:149; %see leaks.txt 
% powerAnalyzer.leaksToLearnIds   = leaksToLearn;
% powerAnalyzer.classifiers       = classifiers;

%%

KEY_PART_MAX_PRICE = 400;

totalInfo = [];
traceIdx = 402
for maskIdx = 0:15
    postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );
    stateProbabilites   = OPBCreator.ExtractStateProbabilites( postriors );
    mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( postriors );
%%
    mask = Moffset( maskIdx );
    plainText = rsm.plainTexts( traceIdx, : );
    plainXORMask = zeros( 1, 16 );
    for byteIdx = 1:16
		plainXORMask( byteIdx ) = bitxor( plainText( byteIdx ), ...
                                          mask( byteIdx )       ...
		);
    end
%%
    solver              = Solver( mask,         ...
                              plainXORMask,  ...
                              stateProbabilites,                ...
                              mixColsProbabilites               ...
    );
    solver.XORLeakPruneThreshhold = 3e2;
    solver.XOR_4_PruneThreshhold  = 5e2;
    
    tic;
    solver.Solve();
    totalTime = toc;
    
%     ranksOfKeysParts = solver.CalcRanksOfKeyParts( rsm.AES_KEY );
    
    possibleKeys = solver.GetPossibleKeys( KEY_PART_MAX_PRICE );
    fprintf( 'Trace %d, mask %d: took %.1f sec, key candidates: %d\n', ...
             traceIdx, maskIdx, totalTime, size( possibleKeys, 2) );
%     location = find(ismember( possibleKeys(1:16,:)', rsm.AES_KEY(1:16)', 'rows' ));
%     [prices,ids] = sort( possibleKeys( 17, : ), 'ascend' );
%     rank = find( ids == location );
%     
%     info = [ traceIdx,                      ...
%              solver.XORLeakPruneThreshhold, ...
%              solver.XOR_4_PruneThreshhold,  ...
%              totalTime,                     ...
%              size( possibleKeys, 2 ),          ...
%              rank,                          ...
%              prices( rank ),                ...
%              ranksOfKeysParts(1, 1:4),      ...
%              ranksOfKeysParts(2, 1:4) ];
%          
%     fprintf( 'Trace %d: took %.1f sec, key candidates: %d, rank: %d, price: %d\n', ...
%              traceIdx, totalTime, size( possibleKeys, 2), rank, prices( rank ) );
%     totalInfo = [ totalInfo; info ];%#ok<AGROW>
end









