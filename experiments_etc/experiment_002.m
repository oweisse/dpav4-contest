
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


%16 October 2013
%The purpose of this experiment is to measure classification performance
%when taking as features the neighborhood of each correlation peak. This
%experiment tries different sizes of neighborhoods (window sizes) and put
%the classification results in a matrix called classificationPerformance.
%%  
clear all;
%%
NUM_TRACES = 400;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();
%%
f = fopen( 'c:/dev/DPA/Repo/DPA/Contest/leaks.txt', 'w' );
for leakIdx = 1:length( rsm.leaksDescryptions )
    fprintf(  f, 'leak %03d: %s\n', leakIdx, cell2mat( rsm.leaksDescryptions(leakIdx) ) );
end
fclose( f );
%%
powerAnalyzer                   = PowerAnalyzer();
powerAnalyzer.SetDataPool( rsm.traces, rsm.leaks );
leaksToLearn                    = [ 1,2,3, 50,51,52 ];
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.setTrainingTracesIds( 1:200 ); %all the other traces will be used for validation
%%
powerAnalyzer.CalcCorrelationsOnTrainingTraces();
%%
testROIWindowSizes        = 1:30;
classificationPerformance = zeros( length( testROIWindowSizes ), length( leaksToLearn ) );
%%
for ROIWindowSizeIdx = 1:length( testROIWindowSizes )
    powerAnalyzer.ROIWindowSize = testROIWindowSizes( ROIWindowSizeIdx );
    fprintf( 'Trying to classify with window size = %d\n', powerAnalyzer.ROIWindowSize );
    powerAnalyzer.CalcHighCorrelationWindows();
    powerAnalyzer.PreprocessFeatures();
    powerAnalyzer.LearnTemplates();
    powerAnalyzer.MeasureClassificationPerformance();
    
    for leakIdx = 1:length( leaksToLearn ) 
        ps =  powerAnalyzer.classifiers( leaksToLearn( leakIdx ) ); 
        classificationPerformance( ROIWindowSizeIdx, leakIdx ) = ps.performance.correctRate;
    end
end

classificationPerformance