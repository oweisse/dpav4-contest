
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


%%
clear
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
clear powerAnalyzer;
%%
powerAnalyzer                   = PowerAnalyzer();
powerAnalyzer.SetDataPool( rsm.traces, rsm.leaks );
leaksToLearn                    = [ 1,2,3, 50,51,52 ];
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.setTrainingTracesIds( 1:200 ); %all the other traces will be used for validation
%powerAnalyzer.setTrainingData( rsm.traces, rsm.leaks( 1:150, : ) );
%%
powerAnalyzer.ROIWindowSize = 1;
% powerAnalyzer.ROIWindowSize = 200;
powerAnalyzer.CalcCorrelationsOnTrainingTraces();
%%
powerAnalyzer.CalcHighCorrelationWindows();
%% 
imagesc( powerAnalyzer.windowsOfHighCorrelation ); colormap(hot); colorbar; grid on;
%%
powerAnalyzer.LearnTemplates();
powerAnalyzer.measureClassificationPerformance();

%%
testROIWindowSizes        = 1:30;
classificationPerformance = zeros( length( testROIWindowSizes ), length( leaksToLearn ) );

%%

for ROIWindowSizeIdx = 1:length( testROIWindowSizes )
    powerAnalyzer.ROIWindowSize = testROIWindowSizes( ROIWindowSizeIdx );
    
    powerAnalyzer.CalcHighCorrelationWindows();
    powerAnalyzer.LearnTemplates();
    powerAnalyzer.measureClassificationPerformance();
    
    for leakIdx = 1:length( leaksToLearn ) 
        ps =  powerAnalyzer.classifiers( leaksToLearn( leakIdx ) ); 
        classificationPerformance( ROIWindowSizeIdx, leakIdx ) = ps.performance.correctRate;
        classificationPerformance
    end
end
%% Rubbish:

%plot( leaksInfo(1).correlation )
%plot(leaksInfo(1).correlation );
%%
% [ ~, traceLength ]  = size( rsm.traces );
% [ ~, numLeaks ]     = size( rsm.leaks );
% allCorrelations     = zeros( numLeaks, traceLength );
% allMasks            = zeros( numLeaks, traceLength );
for k = 1:length( rsm.leaksDescryptions )
%     allCorrelations( k, : ) = leaksInfo(k).correlation ;
%     allMasks( k, : )        = leaksInfo(k).regionsOfInterestMask;
    fprintf( '%03d: ', k );
    disp(  rsm.leaksDescryptions( k ) );
end

%%
plot( allCorrelations' );
hold on;
plot( allMasks' );
hold off;

%%
figure;
t = 0.4; clims = [t,t+1e-4]; imagesc( abs(allMasks), clims ); colormap(summer); colorbar; grid on;

%%
plot( allCorrelations( 1, : ) )
%%
THRESHHOLD = 0.5;
rawMask = abs( [ allCorrelations( 3, : ); allCorrelations( 3, : ) > THRESHHOLD ]' );

plot( [allCorrelations( 3, : ); ( allCorrelations( 3, : ) > THRESHHOLD)*1.1;...
    filtfilt( ones(  windowSize, 1 ), 1, double( allCorrelations( 3, : ) > THRESHHOLD )) > 1  ]' );
%plot( rawMask );
%%
%powerAnalyzer.trainClassifiers( methodParams); %(PCA, basian, SVM...)
%powerAnalyzer.validateClassifiers( validationTraces, validationLeaks );
%estimatedLeaks = powerAnalyzer.classify( attackTrace )
%powerAnalyzer.extrapulateClassifiers();
%powerAnalyzer.validateExtrapulatedClassifiers( validationTraces, validationLeaks );


%%
varyingWindows = windowsOfHighCorrelation;
[ numLeaks, ~ ] = size( varyingWindows );
for leakIdx = 1:numLeaks
    cc = bwconncomp( windowsOfHighCorrelation(leakIdx,:) );
    for windowIdx = 1:length( cc.PixelIdxList )
        windowIds = cell2mat( cc.PixelIdxList( windowIdx ));
        varyingWindows( leakIdx, windowIds ) = max( abs( correlations( leakIdx, : ) ) );
    end
end



