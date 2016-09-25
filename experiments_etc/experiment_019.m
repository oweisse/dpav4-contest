
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


 % 2014 Jan 25
 %Test attack wrapper of RSM
 
TRACES_PER_ATTACK = 3;
START_TRACE = 1000;
END_TRACE = 1008;
tracesIDs = START_TRACE:TRACES_PER_ATTACK:END_TRACE;
TRACES_DIR          = 'c:/dev/DPA/contest/DPA_contestv4_rsm';
ATTACK_WRAPPER_PATH = 'C:/dev/DPA/contest/attack_wrapper.exe';
RESULT_PARSER_PATH  = 'C:/dev/DPA/contest/compute_results.exe';
RESUTLS_TEMPLATE    = 'results/result_%d_%d';
ATTACK_CMD_TEMPLATE = 'start %s -i %d -o %s -t -d %s -f fifo -e v4_RSM -x %s > out.txt';

stats = [];
for traceIdx = tracesIDs
    endTraceIdx   = traceIdx + TRACES_PER_ATTACK - 1;
    indexFilePath = sprintf( 'attackIndexFiles/attackIndexFile_%d_%d.txt', traceIdx, endTraceIdx);
    resultsFile   = sprintf( RESUTLS_TEMPLATE, traceIdx, endTraceIdx );
    attackWrapperCmd = sprintf( ATTACK_CMD_TEMPLATE, ...
                                ATTACK_WRAPPER_PATH, ...
                                TRACES_PER_ATTACK,   ...
                                resultsFile,         ...
                                TRACES_DIR,          ...
                                indexFilePath        ...
    );
    
    fprintf( 'Start idx: %d, ', traceIdx )
    system( attackWrapperCmd );
    pause( 1 );
    tic;
    LaunchRSMAttack();
    elapsedTime = toc;
    fprintf( 'took %.1f sec, ', elapsedTime );
    
    system( sprintf( '%s %s -o results/parsedResults_', RESULT_PARSER_PATH, resultsFile ) );
    results = dlmread( 'results/parsedResults_global_success_rate.dat', '', 1, 0 );
    numTracesNeeded = find( results( :, 2 ) , 1 );
    if isempty( numTracesNeeded )
        numTracesNeeded = Inf;
    end
    fprintf( 'found entire key after %d traces\n', numTracesNeeded );
    stats = [ stats; [ traceIdx, numTracesNeeded, elapsedTime ] ]; %#ok<AGROW>
    save( 'stats.mat', 'stats' );
end
