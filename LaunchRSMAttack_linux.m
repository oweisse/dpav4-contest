
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


function [statistics] = LaunchRSMAttack(  )
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

% %%
% attacked_subkey = 0;
% 
% 
% fifo_in_filename = '\\.\pipe\fifo_from_wrapper';
% fifo_out_filename = '\\.\pipe\fifo_to_wrapper';
% 
% fifo_in = java.io.FileInputStream(fifo_in_filename);
% fifo_out = java.io.FileOutputStream(fifo_out_filename);
% 
% % Retrieve the number of traces
% 
% num_traces_b = arrayfun(@(x) fifo_in.read(), 1:4);
% num_traces = num_traces_b(4) * 2^24 + num_traces_b(3) * 2^16 + num_traces_b(2) * 2^8 + num_traces_b(1);
% 
% % Send start of attack string
% 
% fifo_out.write([10 46 10]);
% FIFO filenames (TODO: adapt them)

fifo_in_filename = '/home/ofir/dev/DPA/contest/testbench/code/fifo_from_wrapper';
fifo_out_filename = '/home/ofir/dev/DPA/contest/testbench/code/fifo_to_wrapper';

% Number of the attacked subkey
% TODO: adapt it
attacked_subkey = 0;


% Open the two communication FIFO

[fifo_in,msg] = fopen(fifo_in_filename, 'r');
if fifo_in < 0
    error('Cannot open FIFO: %s', msg);
end

[fifo_out,msg] = fopen(fifo_out_filename, 'w');
if fifo_out < 0
    error('Cannot open FIFO: %s', msg);
end

% Retrieve the number of traces

num_traces = fread(fifo_in, 1, '*uint32', 0, 'l');

% Send start of attack string

fwrite(fifo_out, [10 46 10], 'uint8');


solutions = cell( num_traces, 4 );
% Main loop
statistics = [];
for iteration = 1:num_traces

    % Read trace
%     plaintext = arrayfun(@(x) fifo_in.read(), 1:16);
%     ciphertext = arrayfun(@(x) fifo_in.read(), 1:16);
%     dummyOffset = fifo_in.read(); %will always be zero..
% 
%     samples = arrayfun(@(x) fifo_in.read(), 1:435002); % read samples as unsigned bytes
%     samples = arrayfun(@(x) typecast(uint8(x),'int8'), samples); % convert to signed bytes
%     samples = double( samples );

    % Read trace
    plaintext = fread(fifo_in, 16, '*uint8'); % 16x1 uint8
    ciphertext = fread(fifo_in, 16, '*uint8'); % 16x1 uint8
    offset = fread(fifo_in, 1, '*uint8'); % 1x1 uint8
    samples = fread(fifo_in, 435002, '*int8'); % 435002x1 int8
    samples = double( samples );
    
    plaintext = double( plaintext' );
    samples = samples';

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
    tic;
    solver.Solve();
    solvingTime = toc;
  
    
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
                
                stats = [ iteration,   ...
                          solvingTime, ...
                          size( solver.mixColsCostStoreNodes{ 1 }.values, 1 ), ...
                          size( solver.mixColsCostStoreNodes{ 2 }.values, 1 ), ...
                          size( solver.mixColsCostStoreNodes{ 3 }.values, 1 ), ...
                          size( solver.mixColsCostStoreNodes{ 4 }.values, 1 ), ...
                          size( intersectionSolution{ 1 }.values, 1 ), ...
                          size( intersectionSolution{ 2 }.values, 1 ), ...
                          size( intersectionSolution{ 3 }.values, 1 ), ...
                          size( intersectionSolution{ 4 }.values, 1 ) ];
                statistics = [ statistics; stats ];
                
                break;
           end
        end
        
        if foundSolution
            break;
        end
    end
    %%%%%%%%%%%%%%
    
    % Send result
    fwrite(fifo_out, attacked_subkey, 'uint8');
    fwrite(fifo_out, bytes, 'uint8');
%     % Send result
%     fifo_out.write(attacked_subkey);
%     fifo_out.write(bytes(:,1));
%     fifo_out.write(bytes(:,2));
%     fifo_out.write(bytes(:,3));
%     fifo_out.write(bytes(:,4));
%     fifo_out.write(bytes(:,5));
%     fifo_out.write(bytes(:,6));
%     fifo_out.write(bytes(:,7));
%     fifo_out.write(bytes(:,8));
%     fifo_out.write(bytes(:,9));
%     fifo_out.write(bytes(:,10));
%     fifo_out.write(bytes(:,11));
%     fifo_out.write(bytes(:,12));
%     fifo_out.write(bytes(:,13));
%     fifo_out.write(bytes(:,14));
%     fifo_out.write(bytes(:,15));
%     fifo_out.write(bytes(:,16));
end

% Close the two FIFOs
fclose(fifo_in);
fclose(fifo_out);


end

