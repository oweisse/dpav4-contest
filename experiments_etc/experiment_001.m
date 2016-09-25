
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
%This script demostrate how to use RSM class in order to retrieve traces,
%and expected leaks of information. This script run correlation test on all
%leaks using the PowerAnalyzer class. After calculation the correlation
%test for each leak, windows of regions of high correlation are computed
%for each leak. The heght of the window is the height of the maximum
%correlation inside the window. All the windows for all the leaks are then
%plotted via imagesc.
tic
%%
clear all;
close all;

%%
NUM_TRACES = 100;
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
TAKE_NUM_ROWS    = 1;
TAKE_NUM_COLUMNS = 2;
powerAnalyzer.leaksToLearnIds   = 1:size( rsm.leaks, TAKE_NUM_COLUMNS );
%powerAnalyzer.leaksToLearnIds   = [150:165];
powerAnalyzer.setTrainingTracesIds( 1:size( rsm.leaks, TAKE_NUM_ROWS ) ); %all the other traces will be used for validation

%%
powerAnalyzer.CalcCorrelationsOnTrainingTraces();
%%
powerAnalyzer.ROIWindowSize = 200; %We use this value to make the windows 
                                   %very wide so it will be viewable on imagesc
powerAnalyzer.CalcHighCorrelationWindows();
%% 
imagesc( powerAnalyzer.windowsOfHighCorrelation ); colormap(hot); colorbar; grid on;
xlabel( 'Location in trace' );
ylabel( 'Leak index' );
title( 'Corralation Peaks' );
%%
timing = toc;