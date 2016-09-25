
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


%Last updated: 17 October 2013
%The purpose of this script is to try to classify traces with a single
%feature every time. Hopefully this will help us fnd features which contain
%helpfull information
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
%leaksToLearn                    = [ 1,2,3, 50,51,52 ];
leaksToLearn                    = [50];
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.setTrainingTracesIds( 1:200 ); %all the other traces will be used for validation
%%
powerAnalyzer.CalcCorrelationsOnTrainingTraces();
%%
powerAnalyzer.ROIWindowSize = 200;
powerAnalyzer.CalcHighCorrelationWindows();
%%
%For each leak, try to classify with single feature, for all features
%within high correlation windows
powerAnalyzer.CalcFeaturesScores();
%plot( powerAnalyzer.featuresScores' );
%%
powerAnalyzer.featureExtractionMethod = FeatureExtraction.TakeTopScore;
powerAnalyzer.takeTopScoreFeatures = 10;
powerAnalyzer.PreprocessFeatures();
powerAnalyzer.LearnTemplates();
powerAnalyzer.MeasureClassificationPerformance();

%%
MAX_TOP_SCORES            = 20;
classificationPerformance = zeros( MAX_TOP_SCORES, length( leaksToLearn ) );

for topScoresToTake = 1:MAX_TOP_SCORES
    
    powerAnalyzer.takeTopScoreFeatures = topScoresToTake;
    powerAnalyzer.LearnTemplates();
    powerAnalyzer.MeasureClassificationPerformance();
    
    for leakIdx = 1:length( leaksToLearn ) 
            ps =  powerAnalyzer.classifiers( leaksToLearn( leakIdx ) ); 
            classificationPerformance( topScoresToTake, leakIdx ) = ps.performance.correctRate
    end
end

classificationPerformance

