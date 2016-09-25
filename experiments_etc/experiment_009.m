
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


%Experiment 009, October 30 2013
%%
clear opbCreator;
%%
NUM_TRACES = 1000;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();
%%
load( 'classifiers-2013_11_12_16-10-35.mat' );
%%
powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = [ 1:16, 34:149, 214:245 ]; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers = classifiers;

%%
TRACE_ID   = 401;
plain      = rsm.plainTexts( TRACE_ID, : );
maskOffset = rsm.offsets( TRACE_ID );
postriors  = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( TRACE_ID, : ) );

stateProbabilites   = OPBCreator.ExtractStateProbabilites( postriors );
mixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( postriors );

%%
opbCreator          = OPBCreator( plain, maskOffset, stateProbabilites, mixColsProbabilites );

%%
opbCreator.GenerateOPBFile();

%%
idealPostrios = zeros( size( postriors ) );
for leakIdx = powerAnalyzer.leaksToLearnIds
    %make error leak with small probability
    if rsm.leaks( TRACE_ID, leakIdx ) ~= 0 
        idealPostrios( leakIdx, 0 + 1 ) = 0.0001;
    else
        idealPostrios( leakIdx, 1 + 1 ) = 0.0001;
    end
        
    idealPostrios( leakIdx, rsm.leaks( TRACE_ID, leakIdx ) + 1 ) = 0.9992;
end
idealStateProbabilites   = OPBCreator.ExtractStateProbabilites( idealPostrios );
idealMixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( idealPostrios );

opbCreator = OPBCreator( plain, maskOffset, idealStateProbabilites, idealMixColsProbabilites );
opbCreator.GenerateOPBFile();

%%
truncatedPostrios = postriors;
truncatedPostrios( truncatedPostrios < 1e-10 ) = 0;

trancatedStateProbabilites   = OPBCreator.ExtractStateProbabilites( truncatedPostrios );
trancatedMixColsProbabilites = OPBCreator.ExtractMixColsProbabilites( truncatedPostrios );

opbCreator = OPBCreator( plain, maskOffset, trancatedStateProbabilites, trancatedMixColsProbabilites );
opbCreator.GenerateOPBFile();


