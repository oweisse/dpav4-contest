function [result] = aes_xtimes(input_data)

% helper function for the AES key expansion
%
% DESCRIPTION:
%
% aes_xtimes(input_data)
% 
% multiplies each byte of 'input_data' with two the GF(2^8) as it is used
% for the AES.
%
% PARAMETERS:
%
% - input_data:
%   A matrix of bytes
%
% RETURNVALUES:
%
% - result:
%   A matrix of bytes with the same size as input_data. Each byte in this matrix is the
%   result of the multiplication of the corresponding byte of 'input_data' with 2.
%
% EXAMPLE:
%
% aes_xtime([1, 2,3 ,4; 5, 6 ,7 ,8])

% AUTHORS: Stefan Mangard, Mario Kirschbaum
%
% CREATION_DATE: 31 July 2001
% LAST_REVISION: 27 October 2008


result = 0;

result = bitset(result, 1, bitget( input_data,8) );
result = bitset(result, 2, bitxor( bitget(input_data,1), bitget(input_data,8)) );
result = bitset(result, 3, bitget( input_data,2) );
result = bitset(result, 4, bitxor( bitget(input_data,3), bitget(input_data,8)) );
result = bitset(result, 5, bitxor( bitget(input_data,4), bitget(input_data,8)) );
result = bitset(result, 6, bitget( input_data,5) );
result = bitset(result, 7, bitget( input_data,6) );
result = bitset(result, 8, bitget( input_data,7) );
