
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


%Author: Ofir Weisse, www.ofirweisse.com, OfirWeisse@gmail.com
classdef ExtendedBayesClassifeir
    %ExtendedBayesClassifeir This class takes an ordinary NAive Bayes
    %Classifier that was trained for Hamming Weights 2,3,4,5,6 and extends
    %it to apply for classes 0,1,2,3,4,5,6,7,8
    
    properties
        extendedMeans;
        extendedSigmas;
        customClassifier;
    end
    
    properties(Constant = true)
        NUM_OF_EXTENDED_CLASSES   = 4; %We add classes 0,1,7,8
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        ClassLevels;
        NClasses;
    end
    
    methods
        function obj = ExtendedBayesClassifeir( origClassifier )
           obj.ClassLevels = 0:8;
           obj.NClasses    = 9;
           
           [ origMeans, origSigmas ] = obj.ExtractParams( origClassifier );
           obj.extendedMeans  = obj.CalcExtendedMeans( origMeans );
           obj.extendedSigmas = obj.CalcExtendedSigmas( origSigmas );
           
           HammingWeightClasses = 0:8;
           [ ~, numFeatures ]   = size( obj.extendedMeans );
           obj.customClassifier = CustomGaussianClassifier( ...
                                       numFeatures, ...
                                       HammingWeightClasses, ...
                                       obj.extendedMeans,...%.*rand( size( means( :, selected_dims )) ), ...
                                       obj.extendedSigmas, ...
                                       obj.HWPriorProbabilities() ...
           );
        end
        
        function [ means, sigmas ] = ExtractParams( ~, origClassifier )
            params = origClassifier.Params;
            means  = zeros( size( params ) );
            sigmas = zeros( size( params ) );

            for class_idx = 1:size( params , 1 )
               for dim_idx = 1:size( params , 2 )
                  cell = cell2mat( params( class_idx, dim_idx ) );
                  means( class_idx, dim_idx )  = cell( 1 );
                  sigmas( class_idx, dim_idx ) = cell( 2 );
               end
            end
        end
        
        function [ extendedMeans ] = CalcExtendedMeans( obj, origMeans )
            NUM_COEFFICIENTS_FOR_LINE = 2; %f(x) = a*x + b --> a,b are the coefficients
            PERFORM_LINEAR_REGRESSION = 1; %Run polifit to fit a polynom of degree 1
            
            [ numClasses, numFeatures ] = size( origMeans );
           
            linearRegressionCoeffients = ...
                zeros( numFeatures, NUM_COEFFICIENTS_FOR_LINE );
            extendedMeans          = ...
                zeros( numClasses + obj.NUM_OF_EXTENDED_CLASSES, numFeatures );
        
            for featureIdx = 1:numFeatures
                x_values = 2:6; %HW classes 2,3,4,5,6
                y_values = origMeans( : , featureIdx )';
                linearRegressionCoeffients( featureIdx, : ) = ...
                    polyfit( x_values, y_values, PERFORM_LINEAR_REGRESSION );

                extendedXValues                    = 0:8; %for classes 0,1,2,3,4,5,6,7,8
                extendedMeans( :, featureIdx ) = ...
                    extendedXValues * linearRegressionCoeffients( featureIdx, 1 ) + ...
                    linearRegressionCoeffients( featureIdx, 2);
            end 
        end
        
        function [ extendedSigmas ] = CalcExtendedSigmas( obj, origSigmas )
            PERFORM_CONSTANT_VALUE_REGRESSION = 0;
            [ numClasses, numFeatures ]       = size( origSigmas );
            sigmasConstantValues              = zeros( numFeatures, 1 );
            extendedSigmas                = ...
                zeros(  numClasses + obj.NUM_OF_EXTENDED_CLASSES, numFeatures );
            
            for featureIdx = 1:numFeatures
                x_values = 2:6; %HW classes 2,3,4,5,6
                y_values = origSigmas( : , featureIdx )';
                sigmasConstantValues( featureIdx ) = ...
                    polyfit( x_values, y_values, PERFORM_CONSTANT_VALUE_REGRESSION );
                extendedSigmas( :, featureIdx ) = ...
                    ones(1,9)*sigmasConstantValues(featureIdx,1);
            end
        end
        
        function [ predictions, postriors ]  = predict( obj, test )
             if nargout == 1
                predictions = obj.customClassifier.predict( test );
             else
                [ predictions, postriors ] = obj.customClassifier.predict( test );
             end
        end
    end
    
    methods (Static = true)
     function [ priors ] = HWPriorProbabilities()
            no_idea_about_hw = [nchoosek(8,0), ...
                                nchoosek(8,1), ...
                                nchoosek(8,2), ...
                                nchoosek(8,3), ...
                                nchoosek(8,4), ...
                                nchoosek(8,5), ...
                                nchoosek(8,6), ...
                                nchoosek(8,7), ...
                                nchoosek(8,8)...
            ];
            no_idea_about_hw = no_idea_about_hw / sum( no_idea_about_hw ) ;
            priors = no_idea_about_hw;
        end
    end
    
end

