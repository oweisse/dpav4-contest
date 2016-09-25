
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


function [ solutionStatistics ] = ComputeCoupleStatistices( solutions )
    numSolutions = size( solutions, 1 );
    KEYS_IDS     = 1:4;
    CORRECT_KEY  = [ 108   236   198   127    ...
                     40   125     8    61     ...
                     235   135   102   240    ...
                     115   139    54 207 ];

    STARTING_TRACE_IDX = 401;

    solutionStatistics      = zeros( 3, floor( numSolutions / 2 ) );
    NUM_CADIDATES_ROW_ID    = 1;
    CORRECT_KEY_RANK_ROW_ID = 2;
    CHEAPEST_PRICE_ROW_ID   = 3;
    for idx = 1:2:(numSolutions - 1)
        coupleIdx = floor( idx / 2 ) + 1;
        reconciledSolution = cell( 1, 4 );
        totalSOlutions = 1;
        for colIdx = 1:4
            sol1 = solutions{ idx, colIdx };
            sol2 = solutions{ idx + 1, colIdx };
            matchIDs       = find( ismember( sol1( KEYS_IDS, : )', ...
                                             sol2( KEYS_IDS, : )', ...
                                             'rows'                ...
            ) );
            totalSOlutions = totalSOlutions * length( matchIDs );
            reconciledSolution( colIdx ) = { sol1( :, matchIDs ) } ;
    %         reconciledSol( colIdx ) = find( 
        end
        fprintf( 'ID %d-%d: totalSOlutions = %6d',  ...
                 STARTING_TRACE_IDX + idx - 1,      ...
                 STARTING_TRACE_IDX + idx,          ...
                 totalSOlutions                     ...
        );
        solutionStatistics( NUM_CADIDATES_ROW_ID, coupleIdx ) = totalSOlutions;
        if totalSOlutions == 0
            fprintf( '\n' );
            continue;
        end

        candidateKeys = combvec(    reconciledSolution{ 1 }, ...
                                    reconciledSolution{ 2 }, ...
                                    reconciledSolution{ 3 }, ...
                                    reconciledSolution{ 4 }  ...
        );
        prices = sum( candidateKeys( [5, 10, 15, 20], :) );
        candidateWithoutPrices = candidateKeys( [1:4, 6:9, 11:14, 16:19 ], : );
        keys = zeros( 17, size( candidateKeys, 2 ) );
        for byteIdx = 1:16
            origLocation = Solver.shiftRowsMapping( byteIdx );
            keys( origLocation, : ) = candidateWithoutPrices( byteIdx, : );
        end
        keys( 17, : ) = prices;
        [vals,ranks] = sort( keys( 17, : ), 'ascend' );
        location      = find(                                      ...
                                        ismember( keys( 1:16, :)', ...
                                                  CORRECT_KEY,     ...
                                                  'rows'           ...
                                         )                         ...
        );
        if isempty( location ) 
            fprintf( ' Correct key NOT FOUND! (cheapest price: %d)\n', vals(1) );
            solutionStatistics( CORRECT_KEY_RANK_ROW_ID, coupleIdx ) = inf;
            solutionStatistics( CHEAPEST_PRICE_ROW_ID, coupleIdx )   = vals(1) ;
        else
            correctKeyRank = find( ranks == location );
            fprintf( ' Rank of correct key: %d (cheapest price: %d)\n', ...
                      correctKeyRank, vals(1) );
            solutionStatistics( CORRECT_KEY_RANK_ROW_ID, coupleIdx ) = correctKeyRank;
            solutionStatistics( CHEAPEST_PRICE_ROW_ID, coupleIdx )   = vals(1) ;
        end
    end
end