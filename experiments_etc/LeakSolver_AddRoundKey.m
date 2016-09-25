
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


classdef LeakSolver_AddRoundKey < LeakSolver

    properties
        inputKeysPrices;
        plainXORMask;
        possibleKeysPrices;
        possibleAddKeyPrices;
        addKeyApriorPrices;
        
        
    end
    
    methods
        function obj = LeakSolver_AddRoundKey( inputKeysPrices,     ...
                                               plainXORMask,        ...
                                               addKeyApriorPrices   ...
        )
            obj.inputKeysPrices     = inputKeysPrices;
            obj.plainXORMask        = plainXORMask;
            obj.addKeyApriorPrices  = addKeyApriorPrices;
        end
        
        function Solve( obj )
                computedAddKeyVals = obj.ComputeAddRoundKeyValues();
                
                inputs = obj.possibleKeysPrices;
                [ validInputsWithPrices, evolvedAddKeyPrices ] =   ...
                    obj.EliminateImpossibleValues_multivar(         ...
                            inputs,                      ...
                            obj.PossibleAddKeyVals() ,  ...
                            obj.addKeyApriorPrices,...
                            computedAddKeyVals                          ...
                );
            
                obj.possibleKeysPrices   = validInputsWithPrices;
                obj.possibleAddKeyPrices = evolvedAddKeyPrices;
        end
        
        function [ computedValues ] = ComputeAddRoundKeyValues( obj )
            possibleKeysValues      = obj.PossibleKeys();
            obj.possibleKeysPrices  = [ possibleKeysValues;                           ...
                                   obj.inputKeysPrices( possibleKeysValues + 1 ) ...
            ];
            numPossibleKeys    = size( obj.possibleKeysPrices, 2 );
            plainXORMaskByte   = repmat( obj.plainXORMask, ...
                                       1, numPossibleKeys               ...
            );
            computedValues     = bitxor( plainXORMaskByte, ...
                                       possibleKeysValues  ...
            );
        end
        
        function [ possibleVals ] = PossibleKeys( obj )
            if isempty( obj.possibleKeysPrices )
                nonInfByteIDs = ~isinf( obj.inputKeysPrices );
                possibleVals  = find( nonInfByteIDs ) - 1;
            else
                possibleVals = obj.possibleKeysPrices( 1, : );
            end
        end
        
        function [ possibleVals ] = PossibleAddKeyVals( obj )
            if isempty( obj.possibleAddKeyPrices )
                nonInfByteIDs = ~isinf( obj.addKeyApriorPrices );
                possibleVals  = find( nonInfByteIDs ) - 1;
            else
                possibleVals = obj.possibleAddKeyPrices( 2, : );
            end
        end
    end
    
end

