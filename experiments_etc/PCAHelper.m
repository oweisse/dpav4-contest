
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


classdef PCAHelper < handle
    %PCAHelper helps manage pca extraction process
    
    properties
        coeff;
        score;
        latent;
        tsquared;
        explained;
        rawFeaturesAverages;
        relevantFeaturesIDs;
    end
    
    methods
        function obj = PCAHelper( allFeatures, relevantFeaturesIDs )
           obj.relevantFeaturesIDs = relevantFeaturesIDs;
           relevantFeatures        = allFeatures( :, relevantFeaturesIDs );
           
           [ obj.coeff, ...
             obj.score, ...
             obj.latent, ...
             obj.tsquared, ...
             obj.explained ]       = ...
               pca( relevantFeatures ); 
           obj.rawFeaturesAverages = mean( relevantFeatures );
        end
        
        function pcaFeatures = GetPrincipalFeatures( obj, allFeatures )
           relevantFeatures = allFeatures( :, obj.relevantFeaturesIDs );
           
           numSamples       = size( relevantFeatures, 1 );
           averagesMatrix   = repmat( obj.rawFeaturesAverages, numSamples, 1 );
           pcaFeatures      = ( relevantFeatures - averagesMatrix ) * obj.coeff;
        end
    end
    
end

