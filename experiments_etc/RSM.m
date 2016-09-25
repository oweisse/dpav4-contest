
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


classdef RSM < handle
    %RSM - class for retrieving traces and leaks of RSM encryption of DPA
    %contest v4

    properties
        traces;
        relevantTracesIdx;
        plainTexts;
        offsets;
        masks;
        AES_KEY;
        leaks;
        leaksDescryptions;
        byteHammingWeight;
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
       currentLeakIdx = 1;
       plainXORMask;
       addRoundKeyBytes;
       afterSubBytes;
       afterShiftRowsBytes;
       afterMixColsBytes;
       extraLeaks;
    end
    
    properties(Constant = true)
       originalAESSbox = uint8([
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
   end
    
    methods
        function obj = RSM( tracesIndices )
            obj.traces      = loadTraces( tracesIndices);

            allPlainTexts   = csvread( 'plains.csv' );
            obj.plainTexts  = allPlainTexts( tracesIndices, : );
            
            allOffsets      = csvread( 'offsets.csv' );
            obj.offsets     = allOffsets( tracesIndices );
            obj.masks       = Moffset( obj.offsets );
            
            obj.AES_KEY = sscanf ( '6cecc67f287d083deb8766f0738b36cf164ed9b246951090869d08285d2e193b', ...
                '%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x'...
            );
        
            byteHammingWeightStruct = load('-mat','byte_Hamming_weight' ); 
            obj.byteHammingWeight   = byteHammingWeightStruct.byte_Hamming_weight;
            
            obj.relevantTracesIdx   = tracesIndices;
            
            obj.leaksDescryptions = cell( 1 );
        end
        
        function CalcLeaks( obj )
            obj.addPlainBytesLeak       ();
            obj.addRSMLeak              ();
            obj.addMaskedPlainLeak      ();
            obj.addAfterRoundKeyLeak    ();
            obj.addSubBytesLeak         ();
            obj.addShiftRowsLeak        ();
            obj.addMixColumnsLeak       ();
            obj.addMaskCompensationLeaks();
        end
        
        function hammingWeights = HammingWeight( obj, bytesVector )
            hammingWeights = obj.byteHammingWeight( bytesVector + 1 )';
        end
    end
    
    methods(Access = private)
        function addPlainBytesLeak( obj )
            for plainByteIDX = 1:16
                plainByte                          = obj.plainTexts( :, plainByteIDX );
                obj.leaks( :, obj.currentLeakIdx ) = obj.HammingWeight( plainByte );
                
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                   cellstr( sprintf( 'Plain byte %d HW', plainByteIDX ) );
               
                obj.currentLeakIdx                 = obj.currentLeakIdx + 1;
            end
        end
        
         function addRSMLeak( obj )
            obj.leaks( :, obj.currentLeakIdx )          = obj.HammingWeight( obj.offsets );
            obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                   cellstr( sprintf( 'offset byte HW' ) );
            obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
              
             
            for byteIdx = 1:16
                maskByte                                    = obj.masks( :, byteIdx );
                obj.leaks( :, obj.currentLeakIdx )          = obj.HammingWeight( maskByte );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                   cellstr( sprintf( 'mask byte %d HW', byteIdx ) );
               
                obj.currentLeakIdx                 = obj.currentLeakIdx + 1;
            end
        end
        
        function addMaskedPlainLeak( obj )
            for byteIdx = 1:16
                obj.plainXORMask( :, byteIdx )         = bitxor( ...
                    obj.plainTexts( :, byteIdx ), ...
                    obj.masks( :, byteIdx ) ...
                );
                obj.leaks( :, obj.currentLeakIdx )          = ...
                    obj.HammingWeight( obj.plainXORMask( :, byteIdx ) );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                    cellstr( sprintf( 'Plain byte %d XOR mask HW', byteIdx ) );

                obj.currentLeakIdx                          = obj.currentLeakIdx + 1;
            end
        end
        
        function addAfterRoundKeyLeak( obj )
            for byteIdx = 1:16
                obj.addRoundKeyBytes( :, byteIdx )          =  ...
                    bitxor(                                 ...
                            obj.plainXORMask( :, byteIdx ),                   ...
                            obj.AES_KEY( byteIdx )   ...
                );
                obj.leaks( :, obj.currentLeakIdx )          = ...
                            obj.HammingWeight( obj.addRoundKeyBytes( :, byteIdx ) );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                            cellstr( sprintf( 'Byte %d after add round key HW', byteIdx ) );

                obj.currentLeakIdx = obj.currentLeakIdx + 1;
            end
        end
        
        function addSubBytesLeak( obj )
            for byteIdx = 1:16
                obj.afterSubBytes( :, byteIdx )             = ...
                    obj.MaskedSbox( ...
                            obj.addRoundKeyBytes( :, byteIdx ), ...
                            byteIdx ...
                );  
                obj.leaks( :, obj.currentLeakIdx )          = ...
                    obj.HammingWeight( obj.afterSubBytes( :, byteIdx )    );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                    cellstr( sprintf( 'Byte %d after MaskedSubBytes HW', byteIdx ) );

                obj.currentLeakIdx                          = obj.currentLeakIdx + 1;
            end
        end
        
        function addShiftRowsLeak( obj )
            obj.afterShiftRowsBytes                = obj.ShiftRows( obj.afterSubBytes );
             
            for byteIdx = 1:16
                obj.leaks( :, obj.currentLeakIdx )          = ...
                            obj.HammingWeight( obj.afterShiftRowsBytes( :, byteIdx ) );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                            cellstr( sprintf( 'Byte %d after shift rows HW', byteIdx ) );

                obj.currentLeakIdx                          = obj.currentLeakIdx + 1;
            end
        end
        
        function addMixColumnsLeak( obj )
            MIX_COLS_ENCRYPT = 1;
            [ obj.afterMixColsBytes, obj.extraLeaks ]              = ...
                aes_mix_columns_8bit_and_leak( obj.afterShiftRowsBytes, MIX_COLS_ENCRYPT);
             
            for byteIdx = 1:16
                obj.leaks( :, obj.currentLeakIdx )          = ...
                            obj.HammingWeight( obj.afterMixColsBytes( :, byteIdx ) );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                            cellstr( sprintf( 'Byte %d after mix cols HW', byteIdx ) );

                obj.currentLeakIdx                          = obj.currentLeakIdx + 1;
            end
            
            %Add extra leaks
            for colNumber = 1:4
               for extraLeakIdx = 1:9
                    obj.leaks( :, obj.currentLeakIdx )          = ...
                            obj.HammingWeight( obj.extraLeaks( colNumber, :, extraLeakIdx ) );
                    obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                            cellstr( sprintf( 'Column %d leak %d of mix columns HW', ...
                                              colNumber, ...
                                              extraLeakIdx ...
                                     )...
                     );

                    obj.currentLeakIdx                          = obj.currentLeakIdx + 1;
               end
            end
        end
        
        function addMaskCompensationLeaks( obj )
            MIX_COLS_ENCRYPT    = 1;
            m_offsetPart        = Moffset( mod( obj.offsets + 1, 16 ));
            m_offsetShiftedRows = obj.ShiftRows( m_offsetPart );
            [ mixColsPart, ~ ]  = ...
                aes_mix_columns_8bit_and_leak( m_offsetShiftedRows, MIX_COLS_ENCRYPT);
            compensationMask    = bitxor( m_offsetPart, ...
                                          double( mixColsPart ) ...
            );
            afterCompensation   = bitxor( double( obj.afterMixColsBytes ), ...
                                          compensationMask ...
            );
        
            %m_offsetPart leaks
            for byteIdx = 1:16
                    obj.leaks( :, obj.currentLeakIdx )          = ...
                         obj.HammingWeight( m_offsetPart( :, byteIdx ) );
                    obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                        cellstr( sprintf( 'Intermediate value of comp mask - M(offset+1) byte %d HW', byteIdx ) );
                    obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
            end
            
            %m_offsetShiftedRows leaks
            for byteIdx = 1:16
                    obj.leaks( :, obj.currentLeakIdx )          = ...
                         obj.HammingWeight( m_offsetShiftedRows( :, byteIdx ));
                    obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                        cellstr( sprintf( 'Intermediate value of comp mask - after shift rows byte %d HW', byteIdx ) );
                    obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
            end     
            
            %mixColsPart leaks
            for byteIdx = 1:16
                    obj.leaks( :, obj.currentLeakIdx )          = ...
                         obj.HammingWeight( mixColsPart( :, byteIdx ) );
                    obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                        cellstr( sprintf( 'Intermediate value of comp mask - after mix cols byte %d HW', byteIdx ) );
                    obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
            end     
            
            %compensationMask leaks
            for byteIdx = 1:16
                    obj.leaks( :, obj.currentLeakIdx )          = ...
                         obj.HammingWeight( compensationMask( :, byteIdx ) );
                    obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                        cellstr( sprintf( 'Compensation mask key byte %d HW', byteIdx ) );
                    obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
            end     
        
            %afterCompensation leaks
            for byteIdx = 1:16
                    obj.leaks( :, obj.currentLeakIdx )          = ...
                         obj.HammingWeight( afterCompensation( :, byteIdx ) );
                    obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                        cellstr( sprintf( 'After compensation mask byte %d HW', byteIdx ) );
                    obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
            end     
            
            %withSecondRoundKey leaks
            for byteIdx = 1:16
                withSecondRoundKey = bitxor( obj.AES_KEY( byteIdx + 16 ), ...
                    afterCompensation( :, byteIdx ) );
                obj.leaks( :, obj.currentLeakIdx )          = ...
                     obj.HammingWeight( withSecondRoundKey );
                obj.leaksDescryptions( obj.currentLeakIdx ) = ...
                    cellstr( sprintf( 'After compensation mask XOR 2nd round key byte %d HW', byteIdx ) );
                obj.currentLeakIdx                          = obj.currentLeakIdx + 1;   
            end     
        end
        
        function [ result ] = MaskedSbox( obj, data, byteIndex )
           %IMPORTANT NOTE: in this module byteIndex is between 1 and 16!!
           % Implementation of masked sbox
           currentByteMask = obj.masks( :, byteIndex );                    %M_i in RSM documentation
           
           % Next we compute the next byte index modulu 16. Note that modulo 
           % computation starts with 0, but matlab indices starts from 1
           nextByteIndex   = byteIndex + 1;                       %inc index
           nextByteIndex   = mod( nextByteIndex - 1, 16 ) + 1;    %substitude 1 for mod computation, but then add 1 to fit matlab indices
           nextByteMask    = obj.masks( :, nextByteIndex ); %M_i+1 in RSM documentation
           
           maskedData      = bitxor( data, currentByteMask );
           intermediate    = obj.originalAESSbox( maskedData + 1 )'; %indices in Matlab starts from 1
           result          = bitxor( double( intermediate ), nextByteMask );  
        end
        
        function [ result ] = ShiftRows( ~, input_data )
            result = input_data;
            % first 4 bytes stay where they are

            % second 4 bytes
            result(1:end, 2) = input_data(1:end,   6);
            result(1:end, 6) = input_data(1:end,  10);
            result(1:end, 10) = input_data(1:end, 14);
            result(1:end, 14) = input_data(1:end,  2);
            
            % third 4 bytes
            result(1:end,  3) = input_data(1:end, 11);
            result(1:end,  7) = input_data(1:end, 15);
            result(1:end, 11) = input_data(1:end,  3);
            result(1:end, 15) = input_data(1:end,  7); 
              
            % fourth 4 bytes
            result(1:end,  4) = input_data(1:end, 16);
            result(1:end,  8) = input_data(1:end,  4);
            result(1:end, 12) = input_data(1:end,  8);
            result(1:end, 16) = input_data(1:end, 12);
        end
    end
    
end

function relevantTraces = loadTraces( tracesIndices )
    if max( tracesIndices ) <= 100 
        tempTraces = load( 'traces_1_100.mat' );
    elseif max( tracesIndices ) <= 200 
        tempTraces = load( 'traces_1_200.mat' );
    else
        tempTraces = load( 'traces_1_1000.mat' );
    end
    relevantTraces = tempTraces.traces( tracesIndices, : );
end



