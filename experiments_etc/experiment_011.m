
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


% 26 Nov 2013
%% load traces and leaks
NUM_TRACES = 1000;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();
%%
load( 'classifiers-2013_11_12_16-10-35.mat' );

powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = [ 50:149 ]; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers       = classifiers;


%%
ATACKED_TRACES = 411:411;
% numTraces = length( ATACKED_TRACES );
% id = 0;
for traceIdx = ATACKED_TRACES
    plain      = rsm.plainTexts( traceIdx, : );
    maskOffset = rsm.offsets( traceIdx );
    postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );

    [ idealPostrios, idealProbaility ] = GenerateIdealPostrios(                 ...
                                           postriors,                       ...
                                           leaksToLearn,   ...
                                           rsm.leaks( traceIdx, : )         ...
    );
    

    %%
  
    %%
    realPostriors = postriors;
    realPostriors( idealPostrios < 0.5 ) = 0;
%     [ ~, ranks ] = sort( postriors, 2, 'descend' );
%     numLeaks = size( realPostriors, 1 );
%     for leakIdx = leaksToLearn
%         FIRST_RANK  = 1;
%         SECOND_RANK = 2;
%         THIRD_RANK  = 3;
%         realPostriors( leakIdx, ranks( leakIdx, FIRST_RANK ) ) = postriors( leakIdx, ranks( leakIdx, FIRST_RANK ) );
%         realPostriors( leakIdx, ranks( leakIdx, SECOND_RANK ) ) = postriors( leakIdx, ranks( leakIdx, FIRST_RANK ) );
%         realPostriors( leakIdx, ranks( leakIdx, THIRD_RANK ) ) = 0.0001;
%     end
    
    %%
%     experimentPostrios = postriors;
%     experimentPostrios( idealPostrios == 0 ) = 0;
    VERSION = 'v028';
    opbFilePath_ideal = sprintf( 'scip/equations/equations_%s_ForTrace_%d.opb', VERSION, traceIdx );
    GenerateOPB( plain, maskOffset, realPostriors, opbFilePath_ideal );
%     
%     
%     %%
%     leakDifferFromIdeal   = find( sum( abs( realPostriors - idealPostrios ), 2 ) ~= 0 );
%     correktLeaksLocations = find( idealPostrios == 0.9992 );
%     leaksWithTotalError   = find( realPostriors( correktLeaksLocations ) == 0 );
% %     correktLeaksLocations( leaksWithTotalError ) = 0.0001;
%     
%     
%     %%
%     experimentPostrios = idealPostrios;
%     numRealLeaksToTake = 5;
%     for idx = 1:numRealLeaksToTake
%         leakIdx = leaksToLearn( idx );
%         experimentPostrios( leakIdx, : ) = realPostriors( leakIdx, : );
%     end
%     %%
%     VERSION = 'v022';
%     opbFilePath_ideal = sprintf( 'scip/equations/equations_%s_ForTrace_%d.opb', VERSION, traceIdx );
%     GenerateOPB( plain, maskOffset, experimentPostrios, opbFilePath_ideal );
%     

end






