
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


classdef LeakSolver_Xor2 < LeakSolver

    
    properties
        source0Solver;
        source1Solver;
        appriorOutputPrices;        
        
        outputPrices;
        inputChanged;
        pruneThreshhold;
    end
    
    methods
        function obj = LeakSolver_Xor2( source0Solver, ...
                                        source1Solver, ...
                                        appriorOutputPrices ...
        )
            obj.source0Solver       = source0Solver;
            obj.source1Solver       = source1Solver;
            obj.appriorOutputPrices = squeeze( appriorOutputPrices )';
            obj.pruneThreshhold     = Inf;
        end
        
        function Solve( obj )
            obj.inputChanged = false;
            
            inputs = obj.GenerateInputs();
            computedXor2 = bitxor( inputs( obj.X2_SHIFT_ROWS_ID(1), : ), ...
                                   inputs( obj.X2_SHIFT_ROWS_ID(2), : )  ...
            );
           
            [ validSourceBytes, evolvedOutputPrices ] =     ...
                obj.EliminateImpossibleValues_multivar(     ...
                        inputs,                             ...
                        obj.PossibleOutputVals() ,          ...
                        obj.appriorOutputPrices,            ...
                        computedXor2                        ...
            );

            obj.UpdateSourcePrices( validSourceBytes );
            obj.outputPrices = evolvedOutputPrices;
        end
        
        function [ inputs ] = GenerateInputs( obj )
            [ allCombinations, combinationsPrices ] = obj.GetAllCombinations();
            [ affordableCombinations, affordablePrices ] =                 ...
                                    obj.TakeCheapestCombinatios(           ...
                                                allCombinations,           ...
                                                combinationsPrices,        ...
                                                obj.pruneThreshhold        ...
            );
            
            inputs_temp = [ affordableCombinations( 1:(end-2),: ); affordablePrices ];
            inputs      = obj.ReconcileCobinations(                      ...
                                inputs_temp, obj.X2_SHIFT_ROWS_ID,       ...
                                obj.outputPrices, obj.X2_SHIFT_ROWS_ID   ...
            );
        end
        
        function [ allCombinations, combinationsPrices ] = GetAllCombinations( obj )
            halfLength      = size( obj.source0Solver.outputPrices, 1 );
            allCombinations = combvec( obj.source0Solver.outputPrices, ...
                                       obj.source1Solver.outputPrices ...
            );
            
            reorder = [];
            for j = 1:halfLength
                reorder = [ reorder, j, j + halfLength ];%#ok<AGROW>
            end
            allCombinations    = allCombinations( reorder, : );            
            combinationsPrices = sum( allCombinations( (end-1):(end), : ) );
        end
        
        function UpdateSourcePrices( obj, validSourceBytes )
            source0ValidInputs = unique( validSourceBytes( obj.X2_SHIFT_ROWS_ID(1), : ) );
            source1ValidInputs = unique( validSourceBytes( obj.X2_SHIFT_ROWS_ID(2), : ) );
            
            SHIFT_ROWS_VAL_ID  = 1+1+1+1; %key, after add key, sub bytes, shift rows;
            source0ValidIDs    = ismember(                              ...
                obj.source0Solver.outputPrices( SHIFT_ROWS_VAL_ID, : ), ...
                source0ValidInputs                                      ...
            );
            source1ValidIDs    = ismember(                              ...
                obj.source1Solver.outputPrices( SHIFT_ROWS_VAL_ID, : ), ...
                source1ValidInputs                                      ...
            );
            
            if obj.DifferentLengths( obj.source0Solver.outputPrices,  ...
                                     source0ValidIDs )          
               obj.inputChanged = true;
            end
            if obj.DifferentLengths( obj.source1Solver.outputPrices,  ...
                                     source1ValidIDs )          
               obj.inputChanged = true;
            end
            
            obj.source0Solver.outputPrices = ...
                    obj.source0Solver.outputPrices( :, source0ValidIDs );
            obj.source1Solver.outputPrices = ...
                    obj.source1Solver.outputPrices( :, source1ValidIDs );
        end
        
        function [ possibleVals ] = PossibleOutputVals( obj )
            if isempty( obj.outputPrices )
                nonInfByteIDs = ~isinf( obj.appriorOutputPrices );
                possibleVals  = find( nonInfByteIDs ) - 1;
            else
                possibleVals = obj.outputPrices( end - 1, : );
            end
        end
    end
    
end

