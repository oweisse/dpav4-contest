
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


function [ idealPostrios, idealProbaility ] = ...
            GenerateIdealPostrios( postriors, leaksToLearnIds, trueLeaks )
%GenerateIdealPostrios Genrate 245 leaks * 9 Hamming weights probabilities
%vector. in each 9 HW vector the correct HW will get close to 1 probability
%while exactly one of the other HW will get some near zero probability

%postriors       - 245 X 9  real classifier probabilites
%leaksToLearnIds - 245 X 1 boolean vector: 
%                  ids of leaks (out of 1:245) to take into calculations
%trueLeaks       - 245 X 1 vector: the correct leak values

    idealProbaility =  0.9992;
    idealPostrios = zeros( size( postriors ) );
    for leakIdx = leaksToLearnIds
        %make error leak with small probability
%         if trueLeaks( leakIdx ) ~= 0 
%             idealPostrios( leakIdx, 0 + 1 ) = 0.0001;
%         else
%             idealPostrios( leakIdx, 1 + 1 ) = 0.0001;
%         end
        
%         
        if trueLeaks( leakIdx ) ~= 0 
            idealPostrios( leakIdx, trueLeaks( leakIdx )  ) = 0.0001;
        end
% %              idealPostrios( leakIdx, trueLeaks( leakIdx ) + 2 ) = 0.0001;
% %         end
%         if trueLeaks( leakIdx ) ~= 8
%             idealPostrios( leakIdx, trueLeaks( leakIdx ) + 2 ) = 0.0001;
%         end
        
        idealPostrios( leakIdx, trueLeaks( leakIdx ) + 1 ) = 0.72;
            
        
    end


%     idealProbaility = 0.9992; 
%     idealPostrios = zeros( size( postriors ) );
%     for leakIdx = leaksToLearnIds
%         %make error leak with small probability
%         if trueLeaks( leakIdx ) ~= 0 
%             idealPostrios( leakIdx, 0 + 1 ) = 0.0001;
%         else
%             idealPostrios( leakIdx, 1 + 1 ) = 0.0001;
%         end
% 
%         idealPostrios( leakIdx, trueLeaks( leakIdx ) + 1 ) = idealProbaility;
%     end

end

