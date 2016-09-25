
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


function [] = LaunchRSMAttack(  )
%Attack for DPA contest v4 <http://www.dpacontest.org/v4>
%Create by Ofir Weisse <ofirweisse@gmail.com>, 
%Tel Aviv University, Israel on Jan 2014
%
%Based on attack_windows.m Version 1, 29/07/2013 created by 
%Guillaume Duc <guillaume.duc@telecom-paristech.fr>
%
%%
PLAIN_XOR_MASK_LEAK_IDS = 34:49;

%%
load( 'classifiers-2013_11_12_16-10-35.mat' );

powerAnalyzer                   = PowerAnalyzer();
leaksToLearn                    = 34:149; %see leaks.txt 
powerAnalyzer.leaksToLearnIds   = leaksToLearn;
powerAnalyzer.classifiers       = classifiers;

%%
attacked_subkey = 0;


fifo_in_filename = '\\.\pipe\fifo_from_wrapper';
fifo_out_filename = '\\.\pipe\fifo_to_wrapper';

fifo_in = java.io.FileInputStream(fifo_in_filename);
fifo_out = java.io.FileOutputStream(fifo_out_filename);

% Retrieve the number of traces

num_traces_b = arrayfun(@(x) fifo_in.read(), 1:4);
num_traces = num_traces_b(4) * 2^24 + num_traces_b(3) * 2^16 + num_traces_b(2) * 2^8 + num_traces_b(1);

% Send start of attack string

fifo_out.write([10 46 10]);

solutions = cell( num_traces, 4 );
% Main loop
for iteration = 1:num_traces

    % Read trace
    plaintext = arrayfun(@(x) fifo_in.read(), 1:16);
    ciphertext = arrayfun(@(x) fifo_in.read(), 1:16);
    dummyOffset = fifo_in.read(); %will always be zero..

    samples = arrayfun(@(x) fifo_in.read(), 1:435002); % read samples as unsigned bytes
    samples = arrayfun(@(x) typecast(uint8(x),'int8'), samples); % convert to signed bytes
    samples = double( samples );
    %%%%%%%%%%%%%%%%
    postriors = powerAnalyzer.EstimatePostriorProbabilites( samples );
    offset = AESNetworkSolver.EsitimateOffset(                               ...
                                    postriors( PLAIN_XOR_MASK_LEAK_IDS, : ), ...
                                    plaintext                                ...
    );
    mask         = Moffset( offset );
    plainXorMask =  bitxor( plaintext, mask );
    
    stateProbabilites   = AESNetworkSolver.ExtractStateProbabilites( postriors );
    mixColsProbabilites = AESNetworkSolver.ExtractMixColsProbabilites( postriors );

    X2Probabilities = squeeze(mixColsProbabilites( :, 2:2:9, : ));
    XTProbabilities = squeeze(mixColsProbabilites( :, 3:2:9, : ));
    X4Probabilities = squeeze(mixColsProbabilites( :, 1, : ));
    
    %%
    clear solver
    solver       = AESNetworkSolver( plainXorMask,      ...
                                     mask,              ...
                                     stateProbabilites, ...
                                     X2Probabilities,   ...
                                     XTProbabilities,   ...
                                     X4Probabilities    ...
    );
    
    solver.Solve();
    
    solutions( iteration, : ) =  solver.mixColsCostStoreNodes(:);
    for numSoulutionsToCombine = iteration:-1:1
        foundSolution = false;
        
        for combination = combnk( iteration:-1:1, numSoulutionsToCombine )';
           if sum( combination == iteration ) == 0
               %combination does not include new info from this iteration -
               %that means we tried that combination in previous iterations
               continue;
           end
            
           multipleSolutions    = solutions( combination, : );
           intersectionSolution = AESNetworkSolver.IntersectSolutions( multipleSolutions );
           if isempty( intersectionSolution )
               continue;
           else
                bytes         = ...
                    AESNetworkSolver.GenerateResults( intersectionSolution );
                foundSolution = true;
                break;
           end
        end
        
        if foundSolution
            break;
        end
    end
    %%%%%%%%%%%%%%
    
    
    % Send result
    fifo_out.write(attacked_subkey);
    fifo_out.write(bytes(:,1));
    fifo_out.write(bytes(:,2));
    fifo_out.write(bytes(:,3));
    fifo_out.write(bytes(:,4));
    fifo_out.write(bytes(:,5));
    fifo_out.write(bytes(:,6));
    fifo_out.write(bytes(:,7));
    fifo_out.write(bytes(:,8));
    fifo_out.write(bytes(:,9));
    fifo_out.write(bytes(:,10));
    fifo_out.write(bytes(:,11));
    fifo_out.write(bytes(:,12));
    fifo_out.write(bytes(:,13));
    fifo_out.write(bytes(:,14));
    fifo_out.write(bytes(:,15));
    fifo_out.write(bytes(:,16));
end

% Close the two FIFOs
fifo_in.close();
fifo_out.close();

end

