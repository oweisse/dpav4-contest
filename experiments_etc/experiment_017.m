
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


% 04 Jan 2014 - train mask classifier
%%
NUM_TRACES = 1000;
rsm = RSM( 1:NUM_TRACES );
rsm.CalcLeaks();

%%
load( 'classifiers-2013_11_12_16-10-35.mat' );

powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = 34:49; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers       = classifiers;

%%
TRACES = 401:1000;
PLAIN_XOR_MASK_LEAK_IDS = 34:49;
estimatedOffsets = zeros( size( TRACES ) );
for traceIdx = TRACES;
    idx       = traceIdx - TRACES( 1 ) + 1;
    postriors = powerAnalyzer.EstimatePostriorProbabilites( rsm.traces( traceIdx, : ) );
    
    plain  = rsm.plainTexts( traceIdx, : );
    estimatedOffsets( idx ) = Solver.EsitimateOffset(                        ...
                                    postriors( PLAIN_XOR_MASK_LEAK_IDS, : ), ...
                                    plain                                    ...
    );
end
%%
% NUM_POSSIBLE_MASKS = 16;
% plain              = rsm.plainTexts( traceIdx, : );
% plainXORMask       = zeros( NUM_POSSIBLE_MASKS, length( plain ) );
% for offset = 0:15
%     mask = Moffset( offset );
%     for byteIdx = 1:16
%         plainXORMask( offset + 1, byteIdx ) = bitxor( plain( :, byteIdx ), ...
%                                                       mask( :, byteIdx ) ...
%         );
%     end
% end
% 
% %%
% PLAIN_XOR_MASK_LEAK_IDX = 34;
% load( 'byte_Hamming_weight.mat' );
% plainXorMaskHW          = byte_Hamming_weight( plainXORMask + 1 );
% probabilites            = zeros( size( plainXORMask ) );
% 
% %%
% for byteIdx = 0:15
%    byteHW                         = plainXorMaskHW( :, byteIdx + 1 );
%    probabilites( :, byteIdx + 1 ) =                                           ...
%                                 postriors( PLAIN_XOR_MASK_LEAK_IDX + byteIdx, ...
%                                            byteHW + 1                         ...
%    );
% end
% candidateProbabilites = prod( probabilites, 2 );












