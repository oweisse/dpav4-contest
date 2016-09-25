
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


classdef MergeX4Computer < handle
   properties
        
    end
    
    methods
        function obj = MergeX4Computer()
        end
        
        function [ dstValues ] = Compute( ~, srcValues )
            EXPECTED_HALF_LENGTH = 25;
            plainIDs     = 1:4;
            keyIDs       = 5:8;
            addKeyIDs    = 9:12;
            subBytesIDs  = 13:16;
            shiftRowsIDs = 17:20;
            x2_leak_1_ID = 21;
            x2_leak_2_ID = 21 + EXPECTED_HALF_LENGTH;
            x2_leak_3_ID = 22;
            x2_leak_4_ID = 22 + EXPECTED_HALF_LENGTH;
            xt_leak_1_ID = 23;
            xt_leak_2_ID = 23 + EXPECTED_HALF_LENGTH;
            xt_leak_3_ID = 24;
            xt_leak_4_ID = 24 + EXPECTED_HALF_LENGTH;
            x4_leak_ID   = 25;
            
%             x2_leak_2_Vals = bitxor( srcValues( :, shiftRowsIDs( 2 ) ), ...
%                                      srcValues( :, shiftRowsIDs( 3 ) ) );
%             x2_leak_4_Vals = bitxor( srcValues( :, shiftRowsIDs( 4 ) ), ...
%                                      srcValues( :, shiftRowsIDs( 1 ) ) );
%             xt_leak_2_vals = aes_xtimes( x2_leak_2_Vals );
%             xt_leak_4_vals = aes_xtimes( x2_leak_4_Vals );
%             
            
            idsReordered = [ plainIDs, keyIDs, addKeyIDs, subBytesIDs,              ...
                             shiftRowsIDs,                                          ...
                             x2_leak_1_ID, x2_leak_2_ID, x2_leak_3_ID, x2_leak_4_ID,...
                             xt_leak_1_ID, xt_leak_2_ID, xt_leak_3_ID, xt_leak_4_ID ...
                             x4_leak_ID                                             ...
            ];
            reorderedSrc = srcValues(:, idsReordered );
           
            dstValues           = reorderedSrc ;
        end
        
        function [ validCombinations ] = GetValidCombinations(    ...
                                                ~,                   ...
                                                srcValues            ...  
        )
            keyByteIDs = 5:8;
            src1Vals =  srcValues{1}' ;
            src2Vals =  srcValues{2}' ;
            [ src1ValidIDs, matchInSrc2 ] = ...
                           ismember( src1Vals( :, keyByteIDs ), ...
                                     src2Vals( :, keyByteIDs ), ...
                                     'rows'                     ... 
            );
        
            src1ValidVals     = src1Vals( src1ValidIDs, : );
            matchingIDsInSrc2 = matchInSrc2( src1ValidIDs );
            src2MatchingVals  = src2Vals( matchingIDsInSrc2, : );
            
            validCombinations = [ src1ValidVals, src2MatchingVals ];
            %it's more efficient to reconstruct src2 from valid src1
            %instead of finding the actual couples between src1 & src2
            
%             plainIDs     = 1:4;
%             keyIDs       = 5:8;
%             addKeyIDs    = 9:12;
%             subBytesIDs  = 13:16;
%             shiftRowsIDs = 17:20;
% %             x2_leak_1_ID = 21;
% %             x2_leak_3_ID = 22;
% %             xt_leak_1_ID = 23;
% %             xt_leak_3_ID = 24;
%             x4_leak_ID   = 25;
%             
%             x2_leak_2_Vals = bitxor( src1ValidVals( :, shiftRowsIDs( 2 ) ), ...
%                                      src1ValidVals( :, shiftRowsIDs( 3 ) ) );
%             x2_leak_4_Vals = bitxor( src1ValidVals( :, shiftRowsIDs( 4 ) ), ...
%                                      src1ValidVals( :, shiftRowsIDs( 1 ) ) );
%             xt_leak_2_vals = aes_xtimes( x2_leak_2_Vals );
%             xt_leak_4_vals = aes_xtimes( x2_leak_4_Vals );
%             
%             mutualMembersIDs  = [ plainIDs, keyIDs, addKeyIDs, ...
%                                   subBytesIDs, shiftRowsIDs ];
%             reconstructedSrc2 = [ src1ValidVals( :, mutualMembersIDs ), ...
%                                   x2_leak_2_Vals,                       ...
%                                   x2_leak_4_Vals,                       ...
%                                   xt_leak_2_vals,                       ...
%                                   xt_leak_4_vals,                       ...
%                                   src1ValidVals( :, x4_leak_ID )        ...
%             ];
%             validCombinations = [ src1ValidVals, reconstructedSrc2 ];
        end
    end
    
end

