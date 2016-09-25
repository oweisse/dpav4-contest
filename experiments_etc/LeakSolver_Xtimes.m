
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


classdef LeakSolver_Xtimes < LeakSolver
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xor2Solvers;
        possibleXtimesPrices;
        xtimesApriorPrices;
        inputChanged;
    end

    methods
        function obj = LeakSolver_Xtimes(       ...
                            xtimesApriorPrices, ...
                            xor2Solvers         ...
        )
            obj.xtimesApriorPrices = squeeze( xtimesApriorPrices );
            obj.xor2Solvers        = xor2Solvers;
            
            obj.possibleXtimesPrices = cell( 1, 4 );
        end
        
        function Solve( obj )  
            obj.inputChanged = false;
            
            for leakIdx = 0:3
                [ inputs, comuptedXtimes ] = ...
                            obj.ComputeMixColsXtimesValues( leakIdx );
 
                [ validInputsWithPrices, evolvedXtimesPrices ] =   ...
                    obj.EliminateImpossibleValues_multivar(         ...
                            inputs,                      ...
                            obj.PossiblexTimes( leakIdx ) ,  ...
                            obj.xtimesApriorPrices( leakIdx + 1, : ),...
                            comuptedXtimes                          ...
                );

                if obj.DifferentLengths(                             ...
                        obj.xor2Solvers{ leakIdx + 1 }.outputPrices, ...
                        validInputsWithPrices )          
                    
                    obj.inputChanged = true;
                end
                
                obj.xor2Solvers{ leakIdx + 1 }.outputPrices = validInputsWithPrices;
                obj.possibleXtimesPrices( leakIdx + 1 )     = { evolvedXtimesPrices };
            end
        end
        
         function [ inputs, xtimesVals ] = ...
                            ComputeMixColsXtimesValues( obj, leakIdx )
            inputs = obj.xor2Solvers{ leakIdx + 1 }.outputPrices;
%             
%             %%%%%%%%%%%%%%%%%%% temporary
%             keysStub     = zeros( 2, size( inputs, 2 ) );
%             addKeyStub   = zeros( 2, size( inputs, 2 ) );
%             subBytesStub = zeros( 2, size( inputs, 2 ) );
%             inputs = [ keysStub; addKeyStub; subBytesStub; inputs; ];
%             %%%%%%%
            
            inputs  = obj.ReconcileCobinations(       ...                   ...
                    inputs,                           ...
                    obj.X2_SHIFT_ROWS_ID,                    ...
                    obj.possibleXtimesPrices{ leakIdx + 1 }, ...
                    obj.X2_SHIFT_ROWS_ID                     ...
            );
            
            xtimesVals = aes_xtimes( inputs( obj.X2_VALUE_ID, : ) );
         end
        
      function [ possibleVals ] = PossiblexTimes( obj, leakIdx )
            prices = obj.possibleXtimesPrices{ leakIdx + 1 };
            if isempty( prices )
                nonInfByteIDs = ~isinf( obj.xtimesApriorPrices( leakIdx + 1, :) );
                possibleVals  = find( nonInfByteIDs ) - 1;    
            else
                mixColsResult = prices( obj.XTIMES_RESULT_ID, : );
                possibleVals  = unique( mixColsResult );
            end    
        end
    end
    
end

