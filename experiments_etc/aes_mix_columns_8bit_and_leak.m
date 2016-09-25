function [result leak]= aes_mix_columns_8bit_and_leak(input_data, encrypt)

% performs the AES MixColumns transformation like a 8-bit uC would, leaking
% the intermediate results for the purpose of SCA
%
% DESCRIPTION:
%
% aes_mix_columns_8bit(input_data, encrypt)
%
% This function performs an AES MixColumns operation on each line of the
% byte matrix 'input_data'. 'input_data' is a matrix of bytes with an
% arbitrary number of lines that are four bytes wide (or a width that is a
% multiple of four bytes - in this case the MixColumns operation is
% performed on the bytes 1..4, 5..8, 8..12, ... ).
%
% PARAMETERS:
%
% - input_data:
%   A matrix of bytes with an arbitrary number of lines and a number of
%   columns that is a multiple of 4.
% - encrypt:
%   Paramter indicating whether an encryption or a decryption is performed
%   (1 = encryption, 0 = decryption). In case of a decrytion, an inverse
%   Mix1:ends operation is performed.
%
% RETURNVALUES:
%
% - result:
%   A matrix of bytes of the size of the 'data' matrix. Each line of this
%   matrix consists of the MixColumns result of the corresponding line of
%   'input_data'.
% - leak:
%   The leaked intermediate results of the MixColumns operation
%   Size is #lines x #cols x 9 for encryption, #lines x #cols x 18 for decryption
%
% EXAMPLE:
%
% aes_mix_columns_8bit([1, 2, 3, 4; 5, 6, 7 ,8], 1)

% AUTHORS: Stefan Mangard, Mario Kirschbaum, Yossi Oren
%
% CREATION_DATE: 31 July 2001
% LAST_REVISION: 30 June 2009

n = size(input_data,2);

times = ceil(n /4);

data = double(input_data);

result = data;
if (encrypt == 0) % decryption
    leak = zeros([times size(input_data,1) 18]);
else % encryption
    leak = zeros([times size(input_data,1) 9]);
end

for i=0:times-1

    if encrypt == 0
        % inverse mixcolumns  - 8 bit implementation 
        tmp = bitxor(bitxor(bitxor( ...
            data(1:end,1+4*i), data(1:end,2+4*i)), ...
            data(1:end,3+4*i)), data(1:end,4+4*i));         % Leak #0.1
        leak(i+1,:,1) = tmp;
        
        xtmp = aes_xtimes(tmp);                             % Leak #0.2
        leak(i+1,:,2) = xtmp;

        h1 = bitxor(bitxor(...
            xtmp, data(1:end,1+4*i)), data(1:end,3+4*i));   % Leak #0.3
        leak(i+1,:,3) = h1;
        
        h1 = aes_xtimes(h1);                                % Leak #0.4
        leak(i+1,:,4) = h1;

        h1 = aes_xtimes(h1);                                % Leak #0.5
        leak(i+1,:,5) = h1;

        h1 = bitxor(h1, tmp);                               % Leak #0.6
        leak(i+1,:,6) = h1;

        h2 = bitxor(bitxor(...
            xtmp, data(1:end,2+4*i)), data(1:end,4+4*i));   % Leak #0.7
        leak(i+1,:,7) = h2;

        h2 = aes_xtimes(h2);                                % Leak #0.8
        leak(i+1,:,8) = h2;

        h2 = aes_xtimes(h2);                                % Leak #0.9
        leak(i+1,:,9) = h2;

        h2 = bitxor(h2, tmp);                               % Leak #0.10
        leak(i+1,:,10) = h2;

        tm=bitxor(data(1:end,1+4*i), data(1:end,2+4*i));    % Leak #1.1
        leak(i+1,:,11) = tm;

        tm=aes_xtimes(tm);                                  % Leak #1.2
        leak(i+1,:,12) = tm;

        result(1:end,1+4*i)=bitxor(bitxor(...
            data(1:end,1+4*i), tm), h1);                    % (output)

        tm=bitxor(data(1:end,2+4*i), data(1:end,3+4*i));    % Leak #2.1
        leak(i+1,:,13) = tm;

        tm=aes_xtimes(tm);                                  % Leak #2.2
        leak(i+1,:,14) = tm;

        result(1:end,2+4*i)=bitxor(bitxor(...               % (output)
            data(1:end,2+4*i), tm), h2);

        tm=bitxor(data(1:end,3+4*i), data(1:end,4+4*i));    % Leak #3.1
        leak(i+1,:,15) = tm;
        
        tm=aes_xtimes(tm);                                  % Leak #3.2
        leak(i+1,:,16) = tm;

        result(1:end,3+4*i)=bitxor(bitxor(...
            data(1:end,3+4*i), tm), h1);                    % (output)

        tm=bitxor(data(1:end,4+4*i), data(1:end,1+4*i));    % Leak #4.1
        leak(i+1,:,17) = tm;

        tm=aes_xtimes(tm);                                  % Leak #4.2
        leak(i+1,:,18) = tm;

        result(1:end,4+4*i)=bitxor(bitxor(...               
            data(1:end,4+4*i), tm), h2);                    % (output)
        % Total 18 extra leaks per column
    else
        % mixcolumns  - 8 bit implementation 
        tmp = bitxor(bitxor(bitxor( ...
            data(1:end,1+4*i), data(1:end,2+4*i)), ...
            data(1:end,3+4*i)), data(1:end,4+4*i));         % Leak #0.1
        leak(i+1,:,1) = tmp;

        tm=bitxor(data(1:end,1+4*i), data(1:end,2+4*i));    % Leak #1.1
        leak(i+1,:,2) = tm;

        tm=aes_xtimes(tm);                                  % Leak #1.2
        leak(i+1,:,3) = tm;

        result(1:end,1+4*i)=bitxor(bitxor(...
            data(1:end,1+4*i), tm), tmp);                   % (output)

        tm=bitxor(data(1:end,2+4*i), data(1:end,3+4*i));    % Leak #2.1
        leak(i+1,:,4) = tm;

        tm=aes_xtimes(tm);                                  % Leak #2.2
        leak(i+1,:,5) = tm;

        result(1:end,2+4*i)=bitxor(bitxor(...
            data(1:end,2+4*i), tm), tmp);                   % (output)

        tm=bitxor(data(1:end,3+4*i), data(1:end,4+4*i));    % Leak #3.1
        leak(i+1,:,6) = tm;

        tm=aes_xtimes(tm);                                  % Leak #3.2
        leak(i+1,:,7) = tm;

        result(1:end,3+4*i)=bitxor(bitxor(...
            data(1:end,3+4*i), tm), tmp);                   % (output)

        tm=bitxor(data(1:end,4+4*i), data(1:end,1+4*i));    % Leak #4.1
        leak(i+1,:,8) = tm;

        tm=aes_xtimes(tm);                                  % Leak #4.2
        leak(i+1,:,9) = tm;

        result(1:end,4+4*i)=bitxor(bitxor(...               % (output)
            data(1:end,4+4*i), tm), tmp);
    end % Total 9 extra leaks per column
end

result = uint8(result);
