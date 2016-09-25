
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


classdef CustomGaussianClassifier  
    properties
        NDims
        ClassLevels
        NClasses
        Means
        Sigmas
        Priors
    end
    
    methods
        function obj = CustomGaussianClassifier(    ndims, ...
                                                    class_levels, ...
                                                    means, ...
                                                    sigmas, ...
                                                    priors )
            obj.NDims = ndims;
            obj.ClassLevels = class_levels;
            obj.NClasses = length( class_levels );
            obj.Means = means;
            obj.Sigmas = sigmas;
            obj.Priors = priors;
        end
        
        function postrior_porabilities = Postrior( obj, test )
            nTest = size( test, 1 );
            logCondPDF = NaN(nTest, obj.NClasses);
            
            %debugVotes = zeros( obj.NClasses, obj.NDims );
            for class_idx = 1:obj.NClasses
                logPdf = zeros(nTest,1);
                class_params = [ obj.Means( class_idx, : ); obj.Sigmas( class_idx, : ) ];
                m1 = true( 1, obj.NDims );
                templogPdf = bsxfun(@plus, -0.5* (bsxfun(@rdivide,...
                            bsxfun(@minus,test(:,m1),class_params(1,:)),class_params(2,:))) .^2,...
                            -log(class_params(2,:))) -0.5 *log(2*pi);
             %   debugVotes( class_idx, : ) = templogPdf;
                logPdf = logPdf + sum(templogPdf,2);
                
                logCondPDF(:,class_idx)= logPdf;
                
            end
               
            log_condPdf =bsxfun(@plus,logCondPDF, log(obj.Priors));
            [maxll, cidx] = max(log_condPdf,[],2);
            postP = exp(bsxfun(@minus, log_condPdf, maxll));
            %density(i) is \sum_j \alpha_j P(x_i| \theta_j)/ exp(maxll(i))
            density = nansum(postP,2); %ignore the empty classes
            %normalize posteriors
            postP = bsxfun(@rdivide, postP, density);
            
            postrior_porabilities = postP;
        end
        
        function [ predictions, postriors ] = predict( obj, test )
           postrior_porabilities = obj.Postrior( test );
           
           [~, class_ids ] = max( postrior_porabilities, [], 2 );
           predictions = obj.ClassLevels( class_ids );
           
           if nargout == 2
               postriors = postrior_porabilities;
           end
        end
    end
    
end

