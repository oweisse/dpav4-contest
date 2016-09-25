
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


%1/1/2014
close all;

data         = cell( 2, 2 );
data( 1, 1 ) = cellstr( 'c:\Users\Ofir\Dropbox\DPA\from_repo\totalInfo-x2_3e2_2014_01_01.mat' );
data( 1, 2 ) = cellstr( 'c:\Users\Ofir\Dropbox\DPA\from_repo\solutions-x2_3e2_2014_01_01.mat' );
data( 2, 1 ) = cellstr( 'c:\Users\Ofir\Dropbox\DPA\from_repo\totalInfo-x2_4e2_2014_01_01.mat' );
data( 2, 2 ) = cellstr( 'c:\Users\Ofir\Dropbox\DPA\from_repo\solutions-x2_4e2_2014_01_01.mat' );
% data( 3, 1 ) = cellstr( 'c:\Users\Ofir\Dropbox\DPA\from_repo\totalInfo-x2_5e2_2014_01_02.mat' );
% data( 3, 2 ) = cellstr( 'c:\Users\Ofir\Dropbox\DPA\from_repo\solutions-x2_5e2_2014_01_02.mat' );

%%
TOTAL_INFO      = 1;
SOLUTIONS       = 2;
SOLVING_TIME    = 4;
KEY_PART_RANKS  = 9:12;
KEY_PART_PRICES = 13:16;

FIGURE_SOLVING_TIMES        = 1;
FIGURE_MAX_RANKS            = 2;
FIGURE_SUM_OF_RANKS         = 3;
FIGURE_NUM_PAIR_CANDIDATES  = 4;
FIGURE_HIST                 = 5;
% solvingTimes    = [];
% numSolved       = zeros( 1, size( data, 1 ) );
% successRate     = zeros( 1, size( data, 1 ) );
% numTraces       = 0;
%%

for dataIdx = 1:size( data, 1 )
    load( data{ dataIdx, TOTAL_INFO } );
    solvingTimes        = totalInfo( :, SOLVING_TIME );

    sumOfKeyPartRanks   = sum( totalInfo( :, KEY_PART_RANKS ), 2 );
    numSolved           = sum( ~isinf( sumOfKeyPartRanks ) );
    numTraces           = size( totalInfo, 1 );
%     successRate         = numNotSolved / numTraces;
    
    figure( FIGURE_SOLVING_TIMES ); 
    [f,x] = ecdf( solvingTimes );
    plot( x,f );
    hold all;
    
    %% max ranks
    maxOfKeyPartRanks = max( totalInfo( :, KEY_PART_RANKS ), [],  2 );
    figure( FIGURE_MAX_RANKS );
    subplot( 1, 2, 1); hold all;
    [f,x] = ecdf( maxOfKeyPartRanks );
    plot( x,f );
    set(gca,'xscale','log')
    subplot( 1, 2, 2); hold all;
    [f,x] = ecdf( log2(maxOfKeyPartRanks.^4) );
    plot( x,f );
    
    %% sum of ranks
    sumOfKeyPartRanks = sum( totalInfo( :, KEY_PART_RANKS ), 2 );
    figure( FIGURE_SUM_OF_RANKS ); hold all;
    subplot( 1, 2, 1); hold all;
    [f,x] = ecdf( sumOfKeyPartRanks );
    plot( x,f );
    set(gca,'xscale','log')
    subplot( 1, 2, 2); hold all;
    numCandidates = NumKeyCandidates( sumOfKeyPartRanks );
    [f,x] = ecdf( log2( numCandidates ) );
    plot( x,f );
end
figure( FIGURE_SOLVING_TIMES );
grid on;
title( 'CDF of solving time' );
legend( 'xor 2 prune threshold = 3e2', 'xor 2 prune threshold = 4e2', 'xor 2 prune threshold = 5e2' );
xlabel( 'Seconds' );
ylabel( '%' );

figure( FIGURE_MAX_RANKS );
subplot( 1, 2, 1);
title( 'Max rank of key part per trace' );
grid on;
legend( '3e2', '4e2', '5e2' );
xlabel( 'rank' );
ylabel( '%' );

subplot( 1, 2, 2);
title( 'Keys to try before finding the right key (MaxRank^4)' );
grid on;
legend( '3e2', '4e2', '5e2' );
xlabel( 'log2(numKeys)' );
ylabel( '%' );

figure( FIGURE_SUM_OF_RANKS );
subplot( 1, 2, 1);
title( 'Sum of ranks of all key parts per trace' );
grid on;
xlabel( 'Sum of ranks' );
ylabel( '%' );
legend( '3e2', '4e2', '5e2' );

subplot( 1, 2, 2);
title( 'Brute force attempts until finding the key' );
grid on;
xlabel( 'log2(numOfAttempts)' );
ylabel( '%' );
legend( '3e2', '4e2', '5e2' );
%%
BINS = [ -1 0 1 2 ];
ranksHist = zeros( size( data, 1 ), length( BINS ) );
maxPriceOfCorrectSolution = zeros( 1, size( data, 1 ) );
minPriceOfInvalidSolution = zeros( 1, size( data, 1 ) );
allSolutionStatistics = cell( 2, size( data, 1 ) );
STATS_NUM_CANDIDATES = 1;
STATS_PAIR_SOLUTIONS = 2;
for dataIdx = 2:size( data, 1 )
    clear solutions;
    fprintf( 'Loading %s.. ', data{ dataIdx, SOLUTIONS } );
    tic;
    load( data{ dataIdx, SOLUTIONS } );
    elapsedTime = toc;
    fprintf( 'done! (took %.1f sec\n', elapsedTime );
    
    numKeyCandidates = zeros( 1, numTraces );
    for traceIdx = 1:numTraces
        keyCandidates = 1;
        for colIdx = 1:4
           colSolution       = solutions{ traceIdx, colIdx };
           keyPartCandidates = size( colSolution, 2 );
           keyCandidates     = keyPartCandidates * keyPartCandidates;
        end
        numKeyCandidates( traceIdx ) = keyCandidates;
    end
    allSolutionStatistics( STATS_NUM_CANDIDATES, dataIdx ) = { numKeyCandidates };
    
    %% candiate keys
    figure( 3 ); hold all;
    [f,x] = ecdf( log2(numKeyCandidates) );
    plot( x,f );
    
    pairsStatistics  = ComputeCoupleStatistices( solutions );
    invalidSolutions = isinf( pairsStatistics( CORRECT_KEY_RANK_ROW_ID, : ) );
    pairsStatistics( CORRECT_KEY_RANK_ROW_ID, invalidSolutions )  = -1;
    
    allSolutionStatistics( STATS_PAIR_SOLUTIONS, dataIdx ) = { pairsStatistics };
    save( 'allSolutionStatistics.mat', 'allSolutionStatistics' );

end

%%
NUM_CADIDATES_ROW_ID    = 1;
CORRECT_KEY_RANK_ROW_ID = 2;
CHEAPEST_PRICE_ROW_ID   = 3;

for dataIdx = 1:(size( data, 1 ))
    pairsStatistics   = allSolutionStatistics{ STATS_PAIR_SOLUTIONS, dataIdx};
    nonEmptySolutions = pairsStatistics( NUM_CADIDATES_ROW_ID, : ) > 0;
    ranksHist( dataIdx, : ) = ...
            hist( pairsStatistics( CORRECT_KEY_RANK_ROW_ID, : ), BINS );
    
    figure( FIGURE_NUM_PAIR_CANDIDATES ); hold all;
    [f,x] = ecdf( log2( pairsStatistics(NUM_CADIDATES_ROW_ID ,nonEmptySolutions )));
    plot( x,f );
end

figure( FIGURE_NUM_PAIR_CANDIDATES );
% set(gca,'xscale','log');
title( 'log2 of number of candidates for pairs' );
xlabel( 'Bits of entropy' );
ylabel( '%' );
legend( '3e2', '4e2' );
grid on;

figure( FIGURE_HIST );
bar( ranksHist' );
legend( '3e2', '4e2' );
xlabel( {'1 - missing keys';            ...
         '2 - no keys';                 ...
         '3 - keys ranked 1';           ...
         '4 - keys ranked higher than 1'} )
title( 'Analysis of pairs of solutions' );
grid on;


% %%
% figure( 3 );
% title( 'Number of candidate keys' );
% grid on;
% legend( '3e2', '4e2' );
% xlabel( 'log2(numKeys)' );
% ylabel( '%' );
% %%
% figure( 4 );
% title( 'Num solutions for pairs' );
% xlabel( 'Num solutions' );
% ylabel( '%' );
% grid on;
%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(6); hold all;
validSolutions = logical( (~invalidSolutions).* nonEmptySolutions );
[f,x] = ecdf( pairsStatistics(CHEAPEST_PRICE_ROW_ID , validSolutions ));
plot( x, f );
[f,x] = ecdf( pairsStatistics(CHEAPEST_PRICE_ROW_ID , invalidSolutions ));
plot( x, f );