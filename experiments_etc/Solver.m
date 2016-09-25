
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


classdef Solver < handle
    %Solver Solver finds all possible RSM AES keys according to a given
    %planXORMask and postrior probabilites

    
    properties
        mask;
        plainXORMask;         
        stateProbabilites;
        mixColsProbabilites;
        possibleKeys;
        s2Prices;
        s2ApriorPrices;
        s3Prices;
        s3ApriorPrices;
        s4Prices;
        s4ApriorPrices;;
        
        s5_1_1_Prices;
        s5_1_1_ApriorPrices;
        s5_1_2_Prices;
        s5_1_2_ApriorPrices;
        s5_0_1_Prices;
        s5_0_1_ApriorPrices;
        s5Prices;
        s5ApriorPrices;
        
        addKeySolvers;
        subBytesSolvers;
        shiftRowsSolvers;
        xor2Solvers;
        xtimesSolvers;
        xor4Solvers;
        mixColsSolvers;
        
        recordedState;
        
        XORLeakPruneThreshhold;
        XOR_4_PruneThreshhold;
        s5_PruneThreshhold;
    end
    
    properties(Constant = true)
       byteHammingWeights = ...
                [  0,  1,  1,  2,  1,  2,  2,  3, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   1,  2,  2,  3,  2,  3,  3,  4, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   2,  3,  3,  4,  3,  4,  4,  5, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   3,  4,  4,  5,  4,  5,  5,  6, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   4,  5,  5,  6,  5,  6,  6,  7, ...
                   5,  6,  6,  7,  6,  7,  7,  8 ]; 
               
      originalAESSbox = uint8([                     ...
            99,  124, 119, 123, 242, 107, 111, 197, ...
            48,    1, 103,  43, 254, 215, 171, 118, ...
            202, 130, 201, 125, 250,  89,  71, 240, ...
            173, 212, 162, 175, 156, 164, 114, 192, ...
            183, 253, 147,  38,  54,  63, 247, 204, ...
            52,  165, 229, 241, 113, 216,  49,  21, ...
            4,   199,  35, 195,  24, 150,   5, 154, ...
            7,    18, 128, 226, 235,  39, 178, 117, ...
            9,   131,  44,  26,  27, 110,  90, 160, ...
            82,   59, 214, 179,  41, 227,  47, 132, ...
            83,  209,   0, 237,  32, 252, 177,  91, ...
            106, 203, 190,  57,  74,  76,  88, 207, ...
            208, 239, 170, 251,  67,  77,  51, 133, ...
            69,  249,   2, 127,  80,  60, 159, 168, ...
            81,  163,  64, 143, 146, 157,  56, 245, ...
            188, 182, 218,  33,  16, 255, 243, 210, ...
            205,  12,  19, 236,  95, 151,  68,  23, ...
            196, 167, 126,  61, 100,  93,  25, 115, ...
            96,  129,  79, 220,  34,  42, 144, 136, ...
            70,  238, 184,  20, 222,  94,  11, 219, ...
            224,  50,  58,  10,  73,   6,  36,  92, ...
            194, 211, 172,  98, 145, 149, 228, 121, ...
            231, 200,  55, 109, 141, 213,  78, 169, ...
            108,  86, 244, 234, 101, 122, 174,   8, ...
            186, 120,  37,  46,  28, 166, 180, 198, ...
            232, 221, 116,  31,  75, 189, 139, 138, ...
            112,  62, 181, 102,  72,   3, 246,  14, ...
            97,   53,  87, 185, 134, 193,  29, 158, ...
            225, 248, 152,  17, 105, 217, 142, 148, ...
            155,  30, 135, 233, 206,  85,  40, 223, ...
            140, 161, 137,  13, 191, 230,  66, 104, ...
            65,  153,  45,  15, 176,  84, 187, 22]);
        
            shiftRowsMapping = [ 1  6  11 16 ...
                                 5  10 15 4  ...
                                 9  14 3  8  ...
                                 13 2  7  12 ];
                             
            GOAL_TERM_SCALING_FACTOR = 10;
            
            ADD_ROUND_KEY_STATE = 1;
            SUB_BYTES_STATE     = 2;
            SHIFT_ROWS_STATE    = 3;
            MIX_COLS_STATE      = 4;
            
            LEAKS_1_1_IDS = [ 2,4,6,8 ];
            LEAKS_1_2_IDS = [ 3,5,7,9 ];
            LEAK_0_1_ID   = 1;
            NUM_COLS      = 4;
    end
    
    methods
        function obj = Solver(  mask,                   ...
                                plainXORMask,           ...
                                stateProbabilites,      ...
                                mixColsProbabilites     ...
        )
            obj.mask                = mask;
            obj.plainXORMask        = plainXORMask;
            obj.stateProbabilites   = stateProbabilites;
            obj.mixColsProbabilites = mixColsProbabilites;
            
%             obj.possibleKeys   = zeros( 16, 256 );
%             obj.s2Prices       = obj.GetStateLeaks( obj.ADD_ROUND_KEY_STATE );
            obj.s2ApriorPrices = obj.GetStateLeaks( obj.ADD_ROUND_KEY_STATE );
%             obj.s3Prices       = obj.GetStateLeaks( obj.SUB_BYTES_STATE );
            obj.s3ApriorPrices = obj.GetStateLeaks( obj.SUB_BYTES_STATE );
%             obj.s4Prices       = obj.GetStateLeaks( obj.SHIFT_ROWS_STATE );
            obj.s4ApriorPrices = obj.GetStateLeaks( obj.SHIFT_ROWS_STATE );
            
            obj.s5_1_1_ApriorPrices = obj.GetMixColsLeaks( obj.LEAKS_1_1_IDS );
%             obj.s5_1_1_Prices       = cell( obj.NUM_COLS, length( obj.LEAKS_1_1_IDS ) );
            obj.s5_1_2_ApriorPrices = obj.GetMixColsLeaks( obj.LEAKS_1_2_IDS );
            obj.s5_0_1_ApriorPrices = obj.GetMixColsLeaks( obj.LEAK_0_1_ID );
            obj.s5ApriorPrices      = obj.GetStateLeaks( obj.MIX_COLS_STATE );
            
            obj.recordedState = -1;
            obj.XORLeakPruneThreshhold = Inf;
            obj.XOR_4_PruneThreshhold  = Inf;
            obj.s5_PruneThreshhold     = Inf;
     
            obj.xtimesSolvers       = cell( 1, 4 );
            obj.xor4Solvers         = cell( 1, 4 );
            obj.mixColsSolvers      = cell( 1, 4 );
            
            obj.SetupAddKeySolvers( plainXORMask );
            obj.SetupSubBytesSolvers();
            obj.SetupShiftRowsSolvers();
            obj.SetupXor2Solvers();
            
           
            for colIdx = 0:3
                xtimesSolver = LeakSolver_Xtimes(                       ...
                            obj.s5_1_2_ApriorPrices( colIdx +1, :, : ), ...
                            obj.xor2Solvers( colIdx + 1, : )            ...
                );
                x4Solver     = LeakSolver_MixColsXor4(               ...
                         xtimesSolver,                               ...
                         obj.s4ApriorPrices( colIdx * 4 + (1:4), : ),...
                         obj.s5_1_1_ApriorPrices( colIdx +1, :, : ), ...
                         obj.s5_1_2_ApriorPrices( colIdx +1, :, : ), ...
                         obj.s5_0_1_ApriorPrices( colIdx + 1, : )    ...
                );
                mixColsSolver = LeakSolver_MixColsOut(              ...
                            x4Solver,                               ...
                            obj.s5ApriorPrices(colIdx * 4 + (1:4),: ) ...
                );
                
                obj.xtimesSolvers( colIdx + 1 )  = { xtimesSolver };
                obj.xor4Solvers( colIdx + 1 )    = { x4Solver };
                obj.mixColsSolvers( colIdx + 1 ) = { mixColsSolver };
            end
        end
        
        function SetupAddKeySolvers( obj, plainXORMask )
            obj.possibleKeys        = cell( 4, 4 );
            obj.addKeySolvers       = cell( 4, 4 );
            
            for colIdx = 0:3
                for rowIdx = 0:3
                    byteIdx = colIdx * obj.NUM_COLS + rowIdx + 1;
                    obj.possibleKeys( colIdx + 1, rowIdx + 1 ) = ...
                                                        { PossibleKeys() };
                    obj.addKeySolvers( colIdx + 1, rowIdx + 1 ) = {             ...
                       LeakSolver_SingleByte(                                   ...
                                    obj.possibleKeys{ colIdx + 1, rowIdx + 1},  ...
                                    obj.s2ApriorPrices( byteIdx, : ),                 ...
                                    @obj.ComputeAddRoundKeyValues,              ...
                                    plainXORMask( byteIdx )                     ...
                    ) };
                
                    
               end
            end
        end
        
        function SetupSubBytesSolvers( obj )
            obj.subBytesSolvers     = cell( 4, 4 );
            
            for colIdx = 0:3
                for rowIdx = 0:3
                    byteIdx = colIdx * obj.NUM_COLS + rowIdx + 1;
                    subBytesInfo = struct( 'mask', obj.mask,                        ...
                                           'byteIdx', byteIdx - 1 );
                    obj.subBytesSolvers( colIdx + 1, rowIdx + 1 ) = {               ...
                           LeakSolver_SingleByte(                                   ...
                                        obj.addKeySolvers{ colIdx + 1, rowIdx + 1}, ...
                                        obj.s3ApriorPrices( byteIdx, : ),           ...
                                        @obj.ComputeSubBytesValues,                 ...
                                        subBytesInfo                                ...
                    ) };
                end
            end
        end
            
        function SetupShiftRowsSolvers( obj )
            obj.shiftRowsSolvers    = cell( 4, 4 );
            
            for colIdx = 0:3
                for rowIdx = 0:3
                    byteIdx                  = colIdx * obj.NUM_COLS + rowIdx + 1;
                    shiftRowsSource          = obj.shiftRowsMapping( byteIdx );
                    [ sourceRow, sourceCol ] = ind2sub( [ 4, 4 ], shiftRowsSource );
                    
                    obj.shiftRowsSolvers( colIdx + 1, rowIdx + 1 ) = {               ...
                           LeakSolver_SingleByte(                                    ...
                                        obj.subBytesSolvers{ sourceCol, sourceRow }, ...
                                        obj.s4ApriorPrices( byteIdx, : ),            ...
                                        @obj.ComputeShiftRowsValues,                 ...
                                        []                                           ...
                    ) };
                end
            end
        end
        
        function SetupXor2Solvers( obj )
            obj.xor2Solvers = cell( 4, 4 );
            
            for colIdx = 0:3
                for leakIdx = 0:3
                    byte_0_idx  = mod( leakIdx, 4 );
                    byte_1_idx  = mod( leakIdx + 1, 4 );
                    source0Solver = obj.shiftRowsSolvers{ colIdx + 1, byte_0_idx + 1 }; 
                    source1Solver = obj.shiftRowsSolvers{ colIdx + 1, byte_1_idx + 1 };
                    obj.xor2Solvers( colIdx + 1, leakIdx + 1 ) = {                    ...
                           LeakSolver_Xor2(                                           ...
                                source0Solver, source1Solver,                         ...
                                obj.s5_1_1_ApriorPrices( colIdx + 1, leakIdx + 1, : ) ...
                    ) };
                end
            end
        end
        
        function Solve( obj )
            while true
                obj.SolveAddKeyRound();
                obj.SolveSubbytesRound();
                if obj.SourcesChanged( obj.subBytesSolvers )
                    continue;
                end
                
                obj.SolveShiftrowsRound();
                if obj.SourcesChanged( obj.shiftRowsSolvers )
                    continue;
                end

                
                obj.SolveMixCols_Xor2();
                if obj.SourcesChanged( obj.xor2Solvers )
                    continue;
                end
                
                obj.SolveMixCols_xtimes();
                if obj.SourcesChanged( obj.xtimesSolvers )
                    continue;
                end
              
                
                obj.SolveMixCols_Xor4();
%                 if obj.SourcesChanged( obj.xor4Solvers )
%                     continue;
%                 end
                
                obj.SolveMixColsOut(); 
%                 if obj.SourcesChanged( obj.mixColsSolvers )
%                     continue;
%                 end
                break;
            end
        end
        
        function [ ranksOfKeysParts ] = CalcRanksOfKeyParts( obj, correctKey )
            PRICE_ID            = 30;
            KEYS_IDS            = 1:4;
            ranksOfKeysParts    = zeros( 2, 4 );
            
            for colIdx = 0:3
                solutions     =  obj.mixColsSolvers{ colIdx + 1 }.mixColsPrices;
                relevantBytes = obj.shiftRowsMapping( colIdx*4 + (1:4) );
                keyPart       = correctKey( relevantBytes );
                location      = find(                                   ...
                                    ismember( solutions( KEYS_IDS, : )',...
                                              keyPart',                  ...
                                              'rows'                    ...
                                     )                                  ...
                );
                [vals, ids]   = sort( solutions( PRICE_ID, : ),  'ascend' );
                if isempty( location )
                    ranksOfKeysParts( 1, colIdx + 1 ) = Inf;
                    ranksOfKeysParts( 2, colIdx + 1 ) = Inf;
                else
                    rank          = find( ids == location );
                    ranksOfKeysParts( 1, colIdx + 1 ) = rank;
                    ranksOfKeysParts( 2, colIdx + 1 ) = vals( rank );
                end
            end
        end
        
        function [ keys ] = GetPossibleKeys( obj, maxPriceForKeyPart )
            PRICE_ID            = 30;
            KEYS_IDS            = 1:4;
            candidates          = cell( 1, 4 );
            MAX_POSSIBLE_KEYS   = 20e6;
            
            totalKeys = 1;
            for colIdx = 1:4
               solutions       =  obj.mixColsSolvers{ colIdx }.mixColsPrices;
               
               [ affordableSolutions, ~ ] =                                 ...
                   LeakSolver.TakeCheapestCombinatios(                      ...
                                                solutions,                  ...
                                                solutions( PRICE_ID, : ),   ...
                                                maxPriceForKeyPart          ...
               );
               
               solutionsToTake = min( floor( MAX_POSSIBLE_KEYS/totalKeys ), ...
                                      size( affordableSolutions, 2 )        ...
               );
               candidates( colIdx ) =                                       ...
                   { affordableSolutions(   [KEYS_IDS, PRICE_ID],           ...
                                            1:solutionsToTake               ...
               ) };
               totalKeys            = totalKeys * solutionsToTake;
            end
            
            candidateKeys = combvec(    candidates{ 1 }, ...
                                        candidates{ 2 }, ...
                                        candidates{ 3 }, ...
                                        candidates{ 4 }  ...
            );
            prices = sum( candidateKeys( [5, 10, 15, 20], :) );
            
            candidateWithoutPrices = candidateKeys( [1:4, 6:9, 11:14, 16:19 ], : );
            keys = zeros( 17, size( candidateKeys, 2 ) );
            for byteIdx = 1:16
                origLocation = obj.shiftRowsMapping( byteIdx );
                keys( origLocation, : ) = candidateWithoutPrices( byteIdx, : );
            end
            keys( 17, : ) = prices;
        end
        
        function [ maxX2Price ] = CalcXor2CorrectPrice( obj, rsm, traceIdx )
           maxX2Price = 0;
           for colIdx = 0:3
              for leakIdx = 0:3
                  byte_0_idx  = mod( leakIdx, 4 );
                  byte_1_idx  = mod( leakIdx + 1, 4 );
                  
                  id0 = colIdx * 4 + byte_0_idx + 1;
                  id1 = colIdx * 4 + byte_1_idx + 1;
                  src_id0 = obj.shiftRowsMapping( id0 );
                  src_id1 = obj.shiftRowsMapping( id1 );
                  
                  correctAddKey0 = rsm.addRoundKeyBytes( traceIdx, src_id0 );
                  correctAddKey1 = rsm.addRoundKeyBytes( traceIdx, src_id1 );
                  addKeyPrice = obj.s2ApriorPrices( src_id0, correctAddKey0 + 1 ) + ...
                                obj.s2ApriorPrices( src_id1, correctAddKey1 + 1 );
                            
                  correctSubBytes0 = rsm.afterSubBytes( traceIdx, src_id0 );
                  correctSubBytes1 = rsm.afterSubBytes( traceIdx, src_id1 );
                  subbytesPrice = obj.s3ApriorPrices( src_id0, correctSubBytes0 + 1 ) + ...
                                  obj.s3ApriorPrices( src_id1, correctSubBytes1 + 1 );
                              
                  correctShiftRows0 = rsm.afterShiftRowsBytes( traceIdx, id0 );
                  correctShiftRows1 = rsm.afterShiftRowsBytes( traceIdx, id1 );
                  shiftRowsPrice = obj.s4ApriorPrices( id0, correctShiftRows0 + 1 ) + ...
                                   obj.s4ApriorPrices( id1, correctShiftRows1 + 1 );
                               
                  totalPrice = addKeyPrice + subbytesPrice + shiftRowsPrice;
                  if isinf( totalPrice )
                     error( 'infinite price' ); 
                  end
                  maxX2Price = max( maxX2Price, totalPrice );
              end
           end
        end
        
%         function [ possibleVals ] = PossibleS3Values( obj, byteIdx )
%             nonInfByteIDs = ~isinf( obj.s3Prices( byteIdx + 1, : ) );
%             possibleVals  = find( nonInfByteIDs ) - 1;
%         end
        
%         function [ possibleVals ] = PossibleS4Values( obj, byteIdx )
%             nonInfByteIDs = ~isinf( obj.s4Prices( byteIdx + 1, : ) );
%             possibleVals  = find( nonInfByteIDs ) - 1;
%         end
        
        function [ possibleVals ] = PossibleValues( ~, prices, byteIdx )
            nonInfByteIDs = ~isinf( prices( byteIdx + 1, : ) );
            possibleVals  = find( nonInfByteIDs ) - 1;
        end
              
        function [ possibleVals ] = PossibleS5_1_1( obj, colIdx, leakIdx )
            if isempty( cell2mat( obj.s5_1_1_Prices( colIdx + 1, leakIdx + 1 ) ) )
                nonInfByteIDs = ~isinf( obj.s5_1_1_ApriorPrices( colIdx + 1, leakIdx + 1, : ) );
                possibleVals  = find( nonInfByteIDs ) - 1;          
            else
                leakData = cell2mat( obj.s5_1_1_Prices(  colIdx + 1, leakIdx + 1 ) );
                s5_1_1_valuesIdx = 3;
                possibleVals = unique( leakData( s5_1_1_valuesIdx, : ) );
            end
        end
        
        function [ possibleVals ] = PossibleS5_1_2( obj, colIdx, leakIdx )
            if isempty( cell2mat( obj.s5_1_2_Prices( colIdx + 1, leakIdx + 1 ) ) )
                nonInfByteIDs = ~isinf( obj.s5_1_2_ApriorPrices( colIdx + 1, leakIdx + 1, : ) );
                possibleVals  = find( nonInfByteIDs ) - 1;          
            else
                leakData = cell2mat( obj.s5_1_2_Prices(  colIdx + 1, leakIdx + 1 ) );
                s5_1_2_valuesIdx = 4;
                possibleVals = unique( leakData( s5_1_2_valuesIdx, : ) );
            end
        end
        
        function [ possibleVals ] = PossibleS5_0_1( obj, colIdx )
            if isempty( cell2mat( obj.s5_0_1_Prices( colIdx + 1 )  ) )
                nonInfByteIDs = ~isinf( obj.s5_0_1_ApriorPrices( colIdx + 1, : ) );
                possibleVals  = find( nonInfByteIDs ) - 1;    
            else
                leakData = cell2mat( obj.s5_0_1_Prices(  colIdx + 1 ) );
                s5_0_1_valuesIdx = 11;
                possibleVals = unique( leakData( s5_0_1_valuesIdx, : ) );
            end   
        end
        
        function [ possibleVals ] = PossibleS5Values( obj, byteIdx )
            nonInfByteIDs = ~isinf( obj.s5Prices( byteIdx + 1, : ) );
            possibleVals  = find( nonInfByteIDs ) - 1;       
        end
        
     
        
        function SolveAddKeyRound( obj )
            for colIdx = 0:3
                for rowIdx = 0:3
                    solver = obj.addKeySolvers{ colIdx + 1, rowIdx + 1 };
                    solver.Solve();
                end
            end
        end
        
        function SolveSubbytesRound( obj )
            for colIdx = 0:3
                for rowIdx = 0:3
                    solver = obj.subBytesSolvers{ colIdx + 1, rowIdx + 1 };
                    solver.Solve();
                end
            end
        end
        
        
        function SolveShiftrowsRound( obj )
            for colIdx = 0:3
                for rowIdx = 0:3
                    solver = obj.shiftRowsSolvers{ colIdx + 1, rowIdx + 1 };
                    solver.Solve();
                end
            end
        end
         
        function SolveMixCols_Xor2( obj )
            for colIdx = 0:3
               for leakIdx = 0:3
                  solver = obj.xor2Solvers{ colIdx + 1, leakIdx + 1 };
                  solver.pruneThreshhold = obj.XORLeakPruneThreshhold;
                  solver.Solve();
               end
            end
        end
        
        function SolveMixCols_xtimes( obj )
            for colIdx = 0:3
                solver = obj.xtimesSolvers{ colIdx + 1 };
                solver.Solve();
            end
        end
        
        function SolveMixCols_Xor4( obj )
            for colIdx = 0:3
               obj.SolveMixCols_XorOf4( colIdx ); 
            end
        end
        
        function SolveMixColsOut( obj )
            for colIdx = 0:3
                solver = obj.mixColsSolvers{ colIdx + 1 };
                solver.Solve();
            end
        end
       
        function [ entropy ] = PrintEntropy( obj )
            entropy = obj.GetEntropy();
            fprintf( 'Entropy: %f\n', entropy );
        end
        
        function [ entropy ] = GetEntropy( obj )
            entropy = log2( prod( sum( ~isinf( obj.possibleKeys ), 2 ) ) ); 
        end
        
        function [ result ] = SourcesChanged( ~, solversCellArray )
            result = false;
            for solver = solversCellArray(:)'
              if solver{1}.inputChanged
                  result = true;
                  return;
              end
            end
        end
    end
    
    methods(Access = private)
        function [ leakByteValues ] = GetStateLeaks( obj, stateIndex )
            %leakByteValues - vector of possible intermediate
            %values for state stateIndex, computed
            %according to obj.stateProbabilites
            byteHWProbabilities = squeeze(                              ...
                obj.stateProbabilites( stateIndex, :, : )      ...
            );
            byteHWPrices = floor( -log( byteHWProbabilities ) *  ...
                                  obj.GOAL_TERM_SCALING_FACTOR   ...
            );

            leakByteValues          = zeros( 16, 256 );
            for byteIdx = 1:16
                for hwId = 1:9
                    bytesWithThisHW = ( obj.byteHammingWeights == (hwId - 1 ) );
                    leakByteValues( byteIdx, bytesWithThisHW  ) = byteHWPrices( byteIdx, hwId );
                end
            end
        end
         
        function [ leakByteValues ] = GetMixColsLeaks( obj, leakIds )
            NUM_LEAKS           = length( leakIds );
            ALL_POSSIBLE_VALUES = 256;
            leakByteValues      = zeros( obj.NUM_COLS,              ...
                                         NUM_LEAKS,         ...
                                         ALL_POSSIBLE_VALUES    ...
            );
            
            for colIdx = 1:obj.NUM_COLS
                byteHWProbabilities     = squeeze(                              ...
                        obj.mixColsProbabilites( colIdx, leakIds, : )     ...
                );
                byteHWPrices = floor( -log( byteHWProbabilities ) *  ...
                                      obj.GOAL_TERM_SCALING_FACTOR   ...
                );
                if size( byteHWPrices, 2 ) == 1
                    byteHWPrices = byteHWPrices';
                end
            
                for leakIdx = 1:NUM_LEAKS
                    for hwId = 1:9
                        bytesWithThisHW = ...
                            ( obj.byteHammingWeights == (hwId - 1 ) );
                        leakByteValues( colIdx, leakIdx, bytesWithThisHW  ) = ...
                            byteHWPrices( leakIdx, hwId );
                    end
                end
            end
        end
 
        function [ evolvedSources, evolvedDest ] = EliminateImpossibleValues(  ...
                               ~,                                       ... %obj
                               origSourceValues, origSourcePrices ,     ...
                               predictedDestValues, predictedDestPrices,... 
                               calculatedDestValues                     ...
           )
            validDestValues  = intersect( predictedDestValues, calculatedDestValues );

            validSourceIDs   = ismember( calculatedDestValues, validDestValues );
            validSourceBytes = origSourceValues( validSourceIDs );
            evolvedSources                         = inf(1, 256 );
            evolvedSources( validSourceBytes + 1 ) = ...
                        origSourcePrices( validSourceIDs );

            validDestIDs     = ismember( predictedDestValues, validDestValues );
            validDestBytes   = predictedDestValues( validDestIDs );
            evolvedDest                       = inf(1, 256 );
            evolvedDest( validDestBytes + 1 ) = ...
                            predictedDestPrices( validDestIDs );
            
            if sum( isinf( evolvedDest ) ) == length( evolvedDest ) 
                return; %no solution
            end
            for destVal = unique( calculatedDestValues )
                possibleSources            = ( calculatedDestValues == destVal );
                evolvedDest( destVal + 1 ) =                            ...
                            evolvedDest( destVal + 1 ) +                ...
                            min( origSourcePrices( possibleSources ) ) ;
            end
        end
        
         function [ validInputsWithPrices, evolvedDest ] =                  ...
                 EliminateImpossibleValues_multivar(                    ...
                               ~,                                       ... %obj
                               sourceValuesAndPrices,                   ...
                               possibleDestValues, apriorDestPrices,    ... 
                               calculatedDestValues                     ...
           )
            validDestValues       = intersect( possibleDestValues, calculatedDestValues );
            validSourceIDs        = ismember( calculatedDestValues, validDestValues );
            validInputsWithPrices = sourceValuesAndPrices( : , validSourceIDs );
            validDestBytes        = calculatedDestValues( validSourceIDs );
            
            validInputsPrices = sourceValuesAndPrices( end, validSourceIDs );
            validDestPrices   = apriorDestPrices( validDestBytes + 1 ) + ...
                                validInputsPrices;
            validInputs       = validInputsWithPrices( 1:(end-1), : );
            evolvedDest       = [  validInputs;    ...
                                   validDestBytes; ...
                                   validDestPrices ];
         end
        
%         function UpdateS4PricesAfterXORLeak(    obj,                ...
%                                                 validDestBytes,  ...
%                                                 colIdx,             ...
%                                                 leakIdx             ...
%         )
%             byte_0_idx   = mod( leakIdx, 4 );
%             byte_1_idx   = mod( leakIdx + 1, 4 );
%             s4Byte_0_Idx = 4 * colIdx + byte_0_idx + 1;
%             s4Byte_1_Idx = 4 * colIdx + byte_1_idx + 1;
%             
%             validBytes0Mask = ismember( 0:255, validDestBytes( 1, : ) );
%             validBytes1Mask = ismember( 0:255, validDestBytes( 2, : ) );
%             
%             obj.s4Prices( s4Byte_0_Idx, ~validBytes0Mask ) = inf;
%             obj.s4Prices( s4Byte_1_Idx, ~validBytes1Mask ) = inf;
%         end
        
%         function [ reconciledCombinations ] = ReconcileCobinations(                              ...
%                     ~,                                              ...
%                     sourceArray, sourceRowsToMatch,                 ...
%                     constraintCombinations, constraintRowsToMatch   ...
%         )
%             if isempty( constraintCombinations )
%                 reconciledCombinations = sourceArray;
%                 return;
%             end
%             
%             rowsToTake = ismember(                                      ...
%                     sourceArray( sourceRowsToMatch, : )',               ...
%                     constraintCombinations( constraintRowsToMatch, : )',...
%                     'rows'                                              ...
%             );
%             reconciledCombinations = sourceArray( :, rowsToTake );
%         end
%         
        function SolveMixCols_XorOf4( obj, colIdx )
            solver                       = obj.xor4Solvers{ colIdx + 1 };
            solver.XOR_4_PruneThreshhold = obj.XOR_4_PruneThreshhold;
            solver.Solve();
        end
        
        function UpdateS5SourcesPrices( obj, evolvedPrices, colIdx, rowIdx )
            s4_byteIdx                                     = colIdx*4 + rowIdx;
            obj.s4Prices( s4_byteIdx + 1, : )              = evolvedPrices( 1, : );
            obj.s5_0_1_Prices( colIdx + 1, : )             = evolvedPrices( 2, : );
            obj.s5_1_2_Prices( colIdx + 1, rowIdx + 1, : ) = evolvedPrices( 3, : );
        end
               
        function [ sumOfCells ] = SumOfCellArray( ~, cellArray )
            sumOfCells = 0;
            for c = 1:size( cellArray, 1 )
               for l = 1:size( cellArray, 2 ) 
                   sumOfCells = sumOfCells + ...
                                sum( sum( cellArray{ c, l } ) );
               end
            end
            
        end
        
        function [ numOptionsVector ] = NumOptionsInCellArray( ~, cellArray )
            numOptionsVector = zeros( 1, size( cellArray, 1 ) );
            for c = 1:size( cellArray, 1 )
                for l = 1:size( cellArray, 2 ) 
                   numOptionsVector( c ) = numOptionsVector( c ) + ...
                               size( cellArray{ c, l }, 2 );
               end
            end
        end
        
        function PrintArray( ~, array )
           for i = 1:length( array )
               fprintf( '%d ', array( i ) );
           end
           
           fprintf( '\n' );
        end
        
        function [ stateChanged ] = RecordState( obj )
            stateChanged = false;
            for byteIdx = 0:15
                solver = obj.addKeySolvers{ byteIdx + 1 };
                if solver.StateChanged()
                    stateChanged = true;
                end
            end    
        end
    end
    
    methods (Static = true)
        function [ computedValues ] = ComputeAddRoundKeyValues( previousSolver, extraInfo )
            numPossibleKeys    = size( previousSolver.outputPrices, 2 );
            possibleKeysValues = previousSolver.outputPrices( 1, : );
            bytePlainXORMask   = extraInfo;
            plainXORMaskByte   = repmat( bytePlainXORMask,  ...
                                         1, numPossibleKeys ...
            );
            computedValues     = bitxor( plainXORMaskByte, ...
                                         possibleKeysValues  ...
            );
        end 
        
        function [ computedValues ] = ComputeSubBytesValues( previousSolver, extraInfo )
            afterAddKeyVals = previousSolver.outputPrices( 2, : );
            computedValues  = Solver.MaskedSubBytes( extraInfo.mask,    ...
                                                     extraInfo.byteIdx, ...
                                                     afterAddKeyVals    ...
            )';
        end 
        
         function [ result ] = MaskedSubBytes( mask, byteIndex, inputByte )
           % Implementation of masked sbox
           %IMPORTANT NOTE: in this module byteIndex is between 0 and 15!!
           currentByteMask = mask( byteIndex + 1 ); %M_i in RSM documentation
           nextByteIndex   = mod( byteIndex + 1, 16 );    
           nextByteMask    = mask( nextByteIndex + 1 ); %M_i+1 in RSM documentation

           maskedData      = bitxor( inputByte, currentByteMask );
           intermediate    = Solver.originalAESSbox( maskedData + 1 )'; %indices in Matlab starts from 1
           result          = bitxor( double( intermediate ), nextByteMask );  
         end  
        
         
         function [ computedValues ] = ComputeShiftRowsValues( previousSolver, ~ )
                computedValues =  previousSolver.outputPrices( 3, : );
         end
         
         function [ estimatedOffset ] = EsitimateOffset( plainXorMaskPosteriors, ...
                                                         plain                   ...
         )
            NUM_POSSIBLE_MASKS    = 16;
            candidatePlainXORMask = zeros( NUM_POSSIBLE_MASKS, length( plain ) );
            for offset = 0:15
                candidateMask = Moffset( offset );
                for byteIdx = 1:16
                    candidatePlainXORMask( offset + 1, byteIdx ) =          ...
                                        bitxor( plain( :, byteIdx ),        ...
                                                candidateMask( :, byteIdx ) ...
                    );
                end
            end

            %%            
            plainXorMaskHW = Solver.byteHammingWeights( candidatePlainXORMask + 1 );
            probabilites   = zeros( size( candidatePlainXORMask ) );

            %%
            for byteIdx = 0:15
                byteHW                         = plainXorMaskHW( :, byteIdx + 1 );
                probabilites( :, byteIdx + 1 ) =                         ...
                                    plainXorMaskPosteriors( byteIdx + 1, ...
                                               byteHW + 1                ...
                );
            end
            
            candidateProbabilites     = prod( probabilites, 2 );
            [ ~, estimatedOffsetIdx ] = max( candidateProbabilites );
            estimatedOffset           = estimatedOffsetIdx - 1;
         end
    end
end

