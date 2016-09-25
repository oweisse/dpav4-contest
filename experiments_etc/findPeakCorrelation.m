
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
clear all;
load( 'traces_1_1000.mat' );
load('-mat','byte_Hamming_weight' );
plains  = csvread( 'plains.csv' );
offsets = csvread( 'offsets.csv' );
AES_KEY = sscanf( '6cecc67f287d083deb8766f0738b36cf164ed9b246951090869d08285d2e193b', ...
    '%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x'...
);

%% Correlate with plain
KEY_BYTE_INDEX  = 1;
NUM_TRACES  = 100;
leakVector_plain  = plains( 1:NUM_TRACES, KEY_BYTE_INDEX );
plainByte1Correlation = calcCorrelation(  traces(1:NUM_TRACES,:), leakVector_plain );
plot( plainByte1Correlation )

%% Correlate with plain hamming weight
KEY_BYTE_INDEX  = 1;
NUM_TRACES  = 100;
leakVector_plain  = plains( 1:NUM_TRACES, KEY_BYTE_INDEX );
leakVector_plainHW = byte_Hamming_weight( leakVector_plain + 1 )';
plainHW1Correlation = calcCorrelation(  traces(1:NUM_TRACES,:), leakVector_plainHW );
plot( plainHW1Correlation )

%% Correlate with plain XOR mask
NUM_TRACES      = 100;
masks = Moffset( offsets( 1:NUM_TRACES ) );
leakVector_plainXMask    = bitxor( plains( 1:NUM_TRACES, KEY_BYTE_INDEX ), ...
                                  masks( :, KEY_BYTE_INDEX ) ...
);
plainXMaskCorrelation    = calcCorrelation(  traces(1:NUM_TRACES,:), leakVector_plainXMask );
plot( plainXMaskCorrelation )

%% Correlate with ( plain XOR mask ) hamming weight
NUM_TRACES      = 100;
masks = Moffset( offsets( 1:NUM_TRACES ) );
leakVector_plainXMask    = bitxor( plains( 1:NUM_TRACES, KEY_BYTE_INDEX ), ...
                                  masks( :, KEY_BYTE_INDEX ) ...
);
leakVector_plainXMaskHW  = byte_Hamming_weight( leakVector_plainXMask + 1 )';
plainXMaskHWCorrelation  = calcCorrelation(  traces(1:NUM_TRACES,:), leakVector_plainXMaskHW );
plot( plainXMaskHWCorrelation )

%% Correlate with plain XOR mask XOR key
NUM_TRACES      = 100;
masks = Moffset( offsets( 1:NUM_TRACES ) );
leakVector_plainXMask    = bitxor( plains( 1:NUM_TRACES, KEY_BYTE_INDEX ), ...
                                  masks( :, KEY_BYTE_INDEX ) ...
);

leakVector_afterRoundKey = bitxor( leakVector_plainXMask, ...
                                   AES_KEY( 1 ) ...
);
afterRoundKeyCorrelation = calcCorrelation(  traces(1:NUM_TRACES,:), leakVector_afterRoundKey );
plot( afterRoundKeyCorrelation )

%% Correlate with plain XOR mask XOR key hamming weight
NUM_TRACES      = 100;
masks = Moffset( offsets( 1:NUM_TRACES ) );
leakVector_plainXMask    = bitxor( plains( 1:NUM_TRACES, KEY_BYTE_INDEX ), ...
                                  masks( :, KEY_BYTE_INDEX ) ...
);
leakVector_afterRoundKey = bitxor( leakVector_plainXMask, ...
                                   AES_KEY( 1 ) ...
);
leakVector_afterRoundKeyHW = byte_Hamming_weight( leakVector_afterRoundKey + 1 )';
afterRoundKeyHWCorrelation = calcCorrelation(  traces(1:NUM_TRACES,:), leakVector_afterRoundKeyHW );
plot( afterRoundKeyHWCorrelation )

%% Plot all correlations graph
plot( [ plainByte1Correlation, plainXMaskCorrelation, afterRoundKeyCorrelation ] );
legend( 'Correlation with first plain byte', ...
        'Correlation with plain XOR mask', ...
        'Correlation with first plain XOR mask XOR key' );
title( 'Correlation of plain mask and key with power traces' );

%% Plot all correlations graph of Hamming Weight
plot( [ plainHW1Correlation, plainXMaskHWCorrelation, afterRoundKeyHWCorrelation ] );
legend( 'Correlation with first plain byte', ...
        'Correlation with plain XOR mask', ...
        'Correlation with first plain XOR mask XOR key' );
title( 'Correlation ofHamming Weight plain mask and key with power traces' );
