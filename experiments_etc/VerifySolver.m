
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


function [ allOK ] = VerifySolver( rsm, solver, traceIdx )
    allOK = true;
    for keyByteIdx = 0:15
        correctValue = rsm.AES_KEY( keyByteIdx + 1 );
        solverVals = find( ~isinf( solver.possibleKeys( keyByteIdx + 1, : ) ) ) - 1;
        correctValuePresent = sum( ismember( solverVals, correctValue ) );
        if correctValuePresent == 1
            fprintf( 'Key byte %d is PRESENT!\n', keyByteIdx ); 
        else
            fprintf( 'Key byte %d is ABSENT!!!!!!\n', keyByteIdx ); 
            allOK = false;
        end
    end
    %%
    for byteIdx = 0:15
        correctValue = rsm.addRoundKeyBytes( traceIdx, byteIdx + 1 );
        solverVals = find( ~isinf( solver.s2Prices( byteIdx + 1, : ) ) ) - 1;
        correctValuePresent = sum( ismember( solverVals, correctValue ) );
        if correctValuePresent == 1
            fprintf( 'Add round key byte %d is PRESENT!\n', byteIdx ); 
        else
            fprintf( 'Add round key byte %d is ABSENT!!!!!!\n', byteIdx ); 
            allOK = false;
        end
    end
    %%
    for byteIdx = 0:15
        correctValue = rsm.afterSubBytes( traceIdx, byteIdx + 1 );
        solverVals = find( ~isinf( solver.s3Prices( byteIdx + 1, : ) ) ) - 1;
        correctValuePresent = sum( ismember( solverVals, correctValue ) );
        if correctValuePresent == 1
            fprintf( 'Subbytes byte %d is PRESENT!\n', byteIdx ); 
        else
            fprintf( 'Subbytes rows byte %d is ABSENT!!!!!!\n', byteIdx ); 
            allOK = false;
        end
    end

    %%
    for byteIdx = 0:15
        correctValue = rsm.afterShiftRowsBytes( traceIdx, byteIdx + 1 );
        solverVals = find(  ~isinf( solver.s4Prices( byteIdx + 1, : )  )) - 1;
        correctValuePresent = sum( ismember( solverVals, correctValue ) );
        if correctValuePresent == 1
            fprintf( 'After shift rows byte %d is PRESENT!\n', byteIdx ); 
        else
            fprintf( 'After shift rows byte %d is ABSENT!!!!!!\n', byteIdx ); 
            allOK = false;
        end
    end


    %%
    leaks_1_1_ids = [ 2,4,6,8 ];

    for colIdx = 0:3
       for leakIdx = leaks_1_1_ids
          correctValue = rsm.extraLeaks( colIdx + 1, traceIdx, leakIdx );
          leakData   = solver.s5_1_1_Prices{ colIdx + 1, leakIdx / 2 };
          if prod( size( leakData ) ) == 0
              solverVals = [];
          else
            valuesIdx  = 3;
            solverVals = leakData( valuesIdx, : );
          end
          correctValuePresent = sum( ismember( solverVals, correctValue ) );
          if correctValuePresent >= 1
             fprintf( 'Column %d, leak %d is PRESENT!\n', colIdx, leakIdx ); 
          else
             fprintf( 'Column %d, leak %d is ABSENT!!!!!!\n', colIdx, leakIdx ); 
             allOK = false;
          end
       end
    end

    %%
    leaks_1_2_ids = [ 3,5,7,9 ];

    for colIdx = 0:3
       for leakIdx = leaks_1_2_ids
          correctValue = rsm.extraLeaks( colIdx + 1, traceIdx, leakIdx );
          leakData   = solver.s5_1_2_Prices{ colIdx + 1, (leakIdx-1) / 2 };
          if prod( size( leakData ) ) == 0
              solverVals = [];
          else
            valuesIdx  = 4;
            solverVals = leakData( valuesIdx, : );
          end
          correctValuePresent = sum( ismember( solverVals, correctValue ) );
          if correctValuePresent >= 1
             fprintf( 'Column %d, leak %d is PRESENT!\n', colIdx, leakIdx ); 
          else
             fprintf( 'Column %d, leak %d is ABSENT!!!!!!\n', colIdx, leakIdx ); 
             allOK = false;
          end
       end
    end

    %%
    leaks_0_1_id = 1

    for colIdx = 0:3
        correctValue = rsm.extraLeaks( colIdx + 1, traceIdx, leaks_0_1_id );
        leakData     = solver.s5_0_1_Prices{ colIdx + 1 };
        if prod( size( leakData ) ) == 0
            solverVals = [];
        else
            valuesIdx  = 11; 
            solverVals = leakData( valuesIdx, : );
        end
        correctValuePresent = sum( ismember( solverVals, correctValue ) );
        if correctValuePresent >= 1
             fprintf( 'Column %d, leak 1 is PRESENT!\n', colIdx  ); 
        else
             fprintf( 'Column %d, leak 1 is ABSENT!!!!!!\n', colIdx  ); 
             allOK = false;
        end
    end
    
    %%
    for byteIdx = 0:15
        correctValue = rsm.afterMixColsBytes( traceIdx, byteIdx + 1 );
        solverVals = find(  ~isinf( solver.s5Prices( byteIdx + 1, : )  )) - 1;
        correctValuePresent = sum( ismember( solverVals, correctValue ) );
        if correctValuePresent == 1
            fprintf( 'After mix cols byte %d is PRESENT!\n', byteIdx ); 
        else
            fprintf( 'After mix cols byte %d is ABSENT!!!!!!\n', byteIdx ); 
            allOK = false;
        end
    end

    if ~allOK
       fprintf( 'Solver has some values MISSING!!!!!!!!\n' ); 
    else
       fprintf( 'Solvr has the right values.\n' );
    end
end

