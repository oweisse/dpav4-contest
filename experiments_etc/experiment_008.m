
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


% 24 oct 2013
%% 
clear all;
startStamp = datestr(now);
%%
NUM_TRACES = 1000;
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
leaksToLearn                    = [50]; %see leaks.txt %[ 1:16, 34:149, 166:245 ]; %skip 17-33, 150-165, which are mask bytes
powerAnalyzer.leaksToLearnIds   = leaksToLearn;

trainingTracesIds        =   1:200;
estimationTracesIds      = 201:400; %Used to measure features scores, and for 
                                    %opportunistic feature selection
performanceTestTracesIds = 401:1000;
powerAnalyzer.AssignTracesToRoles( trainingTracesIds, ...
                                   estimationTracesIds, ...
                                   performanceTestTracesIds ... 
);
% %%
% powerAnalyzer.CalcCorrelationsOnTrainingTraces();
% %%
% powerAnalyzer.ROIWindowSize = 200;
% powerAnalyzer.CalcHighCorrelationWindows();

%%
load( 'correlations.mat' );
load( 'windowsOfHighCorrelation.mat' );
%%
powerAnalyzer.correlations             = correlations;
powerAnalyzer.windowsOfHighCorrelation = windowsOfHighCorrelation;

%%
powerAnalyzer.featureScoresMethod = FeatureScoreMethod.ExtendedClassifierMeanRank;
powerAnalyzer.CalcFeaturesScores();

%%
load( 'scores.mat' );
powerAnalyzer.featuresScores           = featuresScores;

%%
powerAnalyzer.featureExtractionMethod = FeatureExtraction.OpportunisticTopScore;
powerAnalyzer.featureScoresMethod     = FeatureScoreMethod.ExtendedClassifierMeanPostrior;
powerAnalyzer.takeTopScoreFeatures    = 500;
powerAnalyzer.PreprocessFeatures();

%% save selectedFeatures
selectedFeatures = false( powerAnalyzer.numLeaks, powerAnalyzer.traceLength );
for leakIdx = powerAnalyzer.leaksToLearnIds 
    selectedFeatures( leakIdx, : ) = powerAnalyzer.classifiers( leakIdx ).featuresIds;
end
selectedFeaturesFilename     = sprintf( 'selectedFeatures-%s.mat', datestr(now,'yyyy_mm_dd_HH-MM-SS') );
save( selectedFeaturesFilename, 'selectedFeatures' );

%% load selectedFeatures
%load( 'selectedFeatures.mat' );
load( 'selectedFeatures-2013_10_26_00-54-16.mat' )
for leakIdx = powerAnalyzer.leaksToLearnIds 
    powerAnalyzer.classifiers( leakIdx ).featuresIds = selectedFeatures( leakIdx, : );
end

%%
powerAnalyzer.featureExtractionMethod = FeatureExtraction.OpportunisticTopScore;
powerAnalyzer.LearnTemplates();
powerAnalyzer.ExtendClassifiers();
powerAnalyzer.MeasuerExtendedPerformance();

%%
allRanks     = zeros( length( performanceTestTracesIds ), powerAnalyzer.numLeaks );
allPostriors = zeros( length( performanceTestTracesIds ), powerAnalyzer.numLeaks );
rawPostriors = zeros( length( performanceTestTracesIds ), powerAnalyzer.numLeaks, 9 );
for leakIdx = powerAnalyzer.leaksToLearnIds 
    allRanks( :, leakIdx )     = powerAnalyzer.classifiers( leakIdx ).extendedStatistics.ranks;
    allPostriors( :, leakIdx ) = powerAnalyzer.classifiers( leakIdx ).extendedStatistics.correctClassesPostriors;
    rawPostriors( :, leakIdx, : ) = powerAnalyzer.classifiers( leakIdx ).extendedStatistics.postrios;
end

%%
ranksFilename        = sprintf( 'ranks-%s', datestr(now,'yyyy_mm_dd_HH-MM-SS') );
postriorsFilename    = sprintf( 'postriors-%s', datestr(now,'yyyy_mm_dd_HH-MM-SS') );
rasPostriorsFilename = sprintf( 'raw_postriors-%s', datestr(now,'yyyy_mm_dd_HH-MM-SS') );
save( ranksFilename, 'allRanks' );
save( postriorsFilename, 'allPostriors' );
save( rasPostriorsFilename, 'rawPostriors' );

%%
figure;
imagesc( allRanks ); colorbar; 
title( 'Rank of correct HW (1 is the highest)' );
xlabel( 'Leak index - see leaks.txt' )
ylabel( 'Trace index' );

%%
figure;
subplot( 2, 1, 1 );
stairs( mean( allRanks ) );
title( 'Mean rank of correct HW' );
xlabel( 'Leak index - see leaks.txt' )
ylabel( 'Mean rank' );

subplot( 2, 1, 2 );
stairs( median( allRanks ) );
title( 'Median rank of correct HW' );
xlabel( 'Leak index - see leaks.txt' )
ylabel( 'Median rank' );

%%
figure;
imagesc( allPostriors ); colorbar; 
title( 'Postrior probabilities of correct HW (1 is the highest)' );
xlabel( 'Leak index - see leaks.txt' )
ylabel( 'Trace index' );

%%
figure;
subplot( 2, 1, 1 );
stairs( mean( allPostriors ) );
title( 'Mean postrior probability of correct HW' );
xlabel( 'Leak index - see leaks.txt' )
ylabel( 'Mean postrior' );

subplot( 2, 1, 2 );
stairs( median( allPostriors ) );
title( 'Median postrior probability of correct HW' );
xlabel( 'Leak index - see leaks.txt' )
ylabel( 'Median postrior' );

%%

endStamp = datestr(now);
fprintf( 'Running time: %s --> %s\n', startStamp, endStamp );

%%
load( 'ranks-2013_10_26_01-01-46.mat' );
load( 'postriors-2013_10_26_01-01-46.mat' );

%%
% load( 'ranks-2013_10_24_13-02-46.mat' );
% load( 'postriors-2013_10_24_13-02-46.mat' );
% allRanks1 = allRanks;
% allPostrios1 = allPostriors;
% %%
% load( 'ranks-2013_10_25_18-50-11.mat' );
% load( 'postriors-2013_10_25_18-50-11.mat' );
% allRanks2 = allRanks;
% allPostrios2 = allPostriors;
% 

%%
% allRanks3 = allRanks;
% allPostrios3 = allPostriors;
% 
% load( 'ranks-2013_10_26_19-45-44.mat' );
% load( 'postriors-2013_10_26_19-45-44.mat' );
% allRanks4 = allRanks;
% allPostrios4 = allPostriors;
% 
% plot( [ mean( allRanks1 ); mean( allRanks2 ); mean( allRanks3 ); mean( allRanks4 )]' );
% plot( [ mean( allPostrios1 ); mean( allPostrios2 ); mean( allPostrios3 ); mean( allPostrios4 )]' );
% %%
% %%
% figure;
% subplot( 2, 1, 1 );
% stairs( [ mean( allPostrios1 ); mean( allPostrios2 ); mean( allPostrios3 )]' );
% title( 'Mean postrior probability of correct HW' );
% xlabel( 'Leak index - see leaks.txt' )
% ylabel( 'Mean postrior' );
% legend( 'Experiment 1', 'Experiment 2', 'Experiment 3' )
% grid on;
% 
% subplot( 2, 1, 2 );
% stairs( [ median( allPostrios1 ); median( allPostrios2 ); median( allPostrios3 )]' );
% title( 'Median postrior probability of correct HW' );
% xlabel( 'Leak index - see leaks.txt' )
% ylabel( 'Median postrior' );
% legend( 'Experiment 1', 'Experiment 2', 'Experiment 3' )
% grid on;
% 
% %%
% 
% figure;
% subplot( 2, 1, 1 );
% stairs( [ mean( allRanks1 ); mean( allRanks2 ); mean( allRanks3 )]' );
% title( 'Mean ranks of correct HW' );
% xlabel( 'Leak index - see leaks.txt' )
% ylabel( 'Mean postrior' );
% legend( 'Experiment 1', 'Experiment 2', 'Experiment 3' )
% grid on;
% 
% subplot( 2, 1, 2 );
% stairs( [ median( allRanks1 ); median( allRanks2 ); median( allRanks3 )]' );
% title( 'Median ranks of correct HW' );
% xlabel( 'Leak index - see leaks.txt' )
% ylabel( 'Median postrior' );
% legend( 'Experiment 1', 'Experiment 2', 'Experiment 3' )
% grid on;
