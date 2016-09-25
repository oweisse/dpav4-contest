
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


TRACE_PATH_TEMPLATE         =  'c:/dev/DPA/Repo/DPA/Contest/exracted_traces/Z1Trace%05d.trc';
BYTES_TO_SKIP_IN_TRACE_FILE = 357;
NUM_SAMPLES_IN_TRACE        = 435002;
TOTAL_TRACES                = 10;

traces = zeros( TOTAL_TRACES, NUM_SAMPLES_IN_TRACE );

parfor file_index = 0:999
    f = fopen( sprintf( TRACE_PATH_TEMPLATE, file_index ) );
    fread(f, BYTES_TO_SKIP_IN_TRACE_FILE);
    traces( file_index + 1, : ) = fread( f, NUM_SAMPLES_IN_TRACE , 'int8' );
    fclose(f);
end