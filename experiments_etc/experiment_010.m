
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


% 17 Nov 2013
clear all

%% load traces and leaks
NUM_TRACES = 1000;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();
%%
load( 'classifiers-2013_11_12_16-10-35.mat' );

powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = [ 1:16, 34:149, 214:245 ]; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers       = classifiers;

%%
VERSION = 'v025';
ATTACKED_TRACES = 406:406;
for traceIdx = ATTACKED_TRACES
    plain      = rsm.plainTexts( traceIdx, : );
    maskOffset = rsm.offsets( traceIdx );
    postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );

    %% calc ideal postrios
    [ idealPostrios, idealProbaility ] = GenerateIdealPostrios(                 ...
                                           postriors,                       ...
                                           powerAnalyzer.leaksToLearnIds,   ...
                                           rsm.leaks( traceIdx, : )         ...
    );

    %%%%%%%%%%%
%     smudgedLeaks = idealPostrios;
%     FILTER =  [0.15 0.7 0.15];
%     
%     for leakIdx = powerAnalyzer.leaksToLearnIds
%         smudgedLeaks( leakIdx, : ) = ...
%             filtfilt( FILTER, 1, smudgedLeaks( leakIdx, : ) );
%     end
    %%%%%%%%%%%
%     smudgedLeaks( 55, : ) = circshift( smudgedLeaks( 55, : ), [0,1] );
    %%%%%%%%%%%%%
    opbFilePath_ideal = sprintf( 'scip/equations/idealEquations_%s_ForTrace_%d.opb', VERSION, traceIdx );
    GenerateOPB( plain, maskOffset, idealPostrios, opbFilePath_ideal );
      
    %% truncate HW with low probabilities
    threshhold        = min(min( postriors( idealPostrios > 0.5 ) ) ) * 1e-3;
    truncatedPostrios = postriors;
    truncatedPostrios( truncatedPostrios < threshhold ) = 0;

    opbFilePathReal = sprintf( 'equations_%s_ForTrace_%d.opb', VERSION, traceIdx );
%     GenerateOPB( plain, maskOffset, trancatedStateProbabilites, opbFilePathReal );
    
    %% correct bad leaks
    badLeaksIDs        = FindBadLeaks( postriors, idealPostrios, idealProbaility );
    correctedPostrrios = truncatedPostrios;
    for badLeakIdx = badLeaksIDs
        correctedPostrrios( badLeakIdx, : ) = ...
                            ExtendedBayesClassifeir.HWPriorProbabilities();
    end                 
    opbFilePath = sprintf( 'equationsWithCorrection_%s_ForTrace_%d.opb', VERSION, traceIdx );
%     GenerateOPB( plain, maskOffset, correctedPostrrios, opbFilePath );

    %% smudge leakse
    smudgedLeaks = truncatedPostrios;
    FILTER =  [0.15 0.7 0.15];
    
    for leakIdx = powerAnalyzer.leaksToLearnIds
        smudgedLeaks( leakIdx, : ) = ...
            filtfilt( FILTER, 1, smudgedLeaks( leakIdx, : ) );
    end
    smudgedOPBFilePath = sprintf( 'smudgedEquations_%s_ForTrace_%d.opb', VERSION, traceIdx );
%     GenerateOPB( plain, maskOffset, smudgedLeaks, smudgedOPBFilePath );
    
    %% smudge selected
    smudgedLeaks = truncatedPostrios;
    FILTER = [0.25 0.5 0.25];
    
    for leakIdx = FindBadLeaks( postriors, idealPostrios, idealProbaility );
        smudgedLeaks( leakIdx, : ) = ...
            filtfilt( FILTER, 1, smudgedLeaks( leakIdx, : ) );
    end
    smudgedOPBFilePath = sprintf( 'smudgedNoisyEquations_%s_ForTrace_%d.opb', VERSION, traceIdx );
%     GenerateOPB( plain, maskOffset, smudgedLeaks, smudgedOPBFilePath );
end



