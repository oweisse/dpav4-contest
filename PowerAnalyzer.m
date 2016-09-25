
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
classdef PowerAnalyzer < handle
    %PowerAnalyzer class for analyzing leaks of crypt info in power traces
    
    properties
        allTraces;
        allLeaks;
        leaksToLearnIds;
        numLeaks;
        numTraces;
        traceLength;
        correlations;
        windowsOfHighCorrelation;
        featuresScores;
        classificationScoreThreshhold;
        featureExtractionMethod  = FeatureExtraction.TakeWindows;
        featureScoresMethod      = FeatureScoreMethod.SimpleClassifierCorrectRate;
        ROICorrelationThreshhold = 0.45;
        takeTopScoreFeatures     = 1;
        ROIWindowSize            = 25;
        classifiers              = struct( 'featuresIds',            0, ...
                                           'classifier',             0, ...
                                           'performance',            0, ...
                                           'pcaHelper',              0, ...
                                           'extendedClassifer',      0, ...
                                           'extendedPerformance',    0) ;
        pcaNumFeaturesToTake     = 10;
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        trainingTracesIds;
        estimationTracesIds;
        performanceTestTracesIds;
    end
    
    properties(Constant = true)
        MEAN_POSTRIOR_SCORE = 1;
        MEAN_RANK_SCORE     = 2;
    end
    
    methods
        function obj = PowerAnalyzer()
           
        end
        
        function setTrainingTracesIds( obj, ids )
            %TODO: set traces for test, then make Mesure.. to test on those
            %traces
            
            obj.trainingTracesIds        = false( obj.numTraces, 1 );
            obj.trainingTracesIds( ids ) = true;
            obj.estimationTracesIds      = ~obj.trainingTracesIds;
            obj.performanceTestTracesIds = obj.estimationTracesIds;
        end
        
        function AssignTracesToRoles(   obj, ...
                                        trainingTracesIds, ...
                                        estimationTracesIds, ...
                                        performanceTestTracesIds ... 
        )
            obj.trainingTracesIds        = false( obj.numTraces, 1 );
            obj.estimationTracesIds      = false( obj.numTraces, 1 );
            obj.performanceTestTracesIds = false( obj.numTraces, 1 );
            
            obj.trainingTracesIds( trainingTracesIds )               = true;
            obj.estimationTracesIds( estimationTracesIds)            = true;
            obj.performanceTestTracesIds( performanceTestTracesIds ) = true;
        end
        
        function SetDataPool( obj, traces, leaks )
            obj.allTraces                      = traces;
            obj.allLeaks                       = leaks;
            
            [ obj.numTraces, obj.numLeaks ]    = size( obj.allLeaks );
            [ ~, obj.traceLength ]             = size( obj.allTraces );
            
            obj.classifiers( obj.numLeaks, 1 ) = struct( 'featuresIds', 0, ...
                                                         'classifier',  0, ...
                                                         'performance', 0, ...
                                                         'pcaHelper',   0, ...
                                                         'extendedClassifer',      0, ...
                                                         'extendedPerformance',    0) ;
            obj.leaksToLearnIds                = 1:obj.numLeaks;
            
            SPLIT_TO_2_GROUPS = 2;
            obj.trainingTracesIds              = ...
                find( crossvalind( 'Kfold', obj.numTraces, SPLIT_TO_2_GROUPS ) == 1 );
        end
        
        function CalcCorrelationsOnTrainingTraces( obj )
            obj.correlations    = zeros( obj.numLeaks, obj.traceLength );
            for leakIdx = obj.leaksToLearnIds
                tic;
                fprintf( 'Calculating correlation for leak number %d.. ', leakIdx );
                tic;
                obj.correlations( leakIdx, : ) = ...
                    calcCorrelation(  obj.allTraces( obj.trainingTracesIds, : ), ...
                                      obj.allLeaks( obj.trainingTracesIds, leakIdx  )...
                );
                totalTime = toc;
                fprintf( 'Done! Took %.3f seconds\n', totalTime );
            end
        end
        
        function CalcHighCorrelationWindows( obj )
            [corrNumRows, corrNumCols ] = size( obj.correlations );
            if corrNumRows == 0 || corrNumCols == 0
               error( 'correlation matrix is empty. Call CalcCorrelations' );
            end
            fprintf( 'Calculating windows of high correlation. Correlation threshhold: %f; window size: %d\n', ...
                        obj.ROICorrelationThreshhold, ...
                        obj.ROIWindowSize ...
            );
            
            obj.windowsOfHighCorrelation = zeros( size( obj.correlations ) );
            for leakIdx = obj.leaksToLearnIds
                fprintf( 'Calculating windows of high correlation for leak number %d.\n', leakIdx );
                
                obj.findWindowsOfHighCorrelationForLeak           ( leakIdx );
                obj.adjustWindowsOfHighCorrelationToMaxCorrelation( leakIdx );
            end
        end
        
        function LearnTemplates( obj )
            for leakIdx = obj.leaksToLearnIds
                fprintf( 'Learning template for leak %3d..', leakIdx );
                tic;
                classificationFeatures                = ...
                    obj.ExtractFeatures( ...
                        leakIdx,...
                        obj.allTraces( obj.trainingTracesIds, : ) ...
                );

                obj.classifiers( leakIdx ).classifier = ...
                    obj.Train( leakIdx, classificationFeatures ); 
                
                totalTime = toc;
                fprintf( 'Done! Took %.3f seconds\n', totalTime );
            end
        end
        
        function MeasureClassificationPerformance( obj )
           for leakIdx = obj.leaksToLearnIds
                validationFeatures = obj.ExtractFeatures( ...
                        leakIdx,...
                        obj.allTraces( obj.performanceTestTracesIds, : ) ...
                );
                validationTrueLabels   = ...
                    obj.getTrueLables( obj.allLeaks( obj.performanceTestTracesIds, ...
                                                     leakIdx ...
                                       ) ...
                ); 
                obj.classifiers( leakIdx ).performance  = ...
                    obj.MeasureClassifierPerformance( ...
                                obj.classifiers( leakIdx ).classifier, ...
                                validationFeatures, ...
                                validationTrueLabels...
                    );
           end 
        end
        
        function CalcFeaturesScores( obj )
            switch( obj.featureScoresMethod )
                case FeatureScoreMethod.SimpleClassifierCorrectRate 
                    obj.CalcFeaturesScores_SimpleClassifierCorrectRate();
                case FeatureScoreMethod.ExtendedClassifierMeanPostrior
                    obj.CalcFeaturesScores_ExtendedClassifierStats();
                case FeatureScoreMethod.ExtendedClassifierMeanRank
                    obj.CalcFeaturesScores_ExtendedClassifierStats();
            end
        end
        
        function ExtendClassifiers( obj )
             for leakIdx = obj.leaksToLearnIds
                fprintf( 'Extending classifier for leak %3d\n', leakIdx );
                origClassifier    = obj.classifiers( leakIdx ).classifier;
                extendedClassifer = ExtendedBayesClassifeir( origClassifier );
                obj.classifiers( leakIdx ).extendedClassifer = extendedClassifer;
             end
        end
        
         function MeasuerExtendedPerformance( obj )
           for leakIdx = obj.leaksToLearnIds
                tic;
                fprintf( 'MeasuerExtendedPerformance for leak %3d..', leakIdx );
                validationFeatures = obj.ExtractFeatures( ...
                        leakIdx,...
                        obj.allTraces( obj.performanceTestTracesIds, : ) ...
                );
                validationTrueLabels    = obj.allLeaks( obj.performanceTestTracesIds, ...
                                                        leakIdx ...
                ); 
                [ performance, extendedStatistics ]  = ...
                    obj.MeasureClassifierPerformance( ...
                                obj.classifiers( leakIdx ).extendedClassifer, ...
                                validationFeatures, ...
                                validationTrueLabels ...
                    );
                
                obj.classifiers( leakIdx ).extendedPerformance = performance;
                obj.classifiers( leakIdx ).extendedStatistics  = extendedStatistics;
                
                totalTime = toc;
                fprintf( 'Done! Took %.3f seconds\n', totalTime );
           end 
         end
        
         function PreprocessFeatures( obj )
             for leakIdx = obj.leaksToLearnIds
                obj.SetupFeatureExtraction(  leakIdx );
             end
         end
         
         function [ postriorProbabilities ] = ...
                                EstimatePostriorProbabilites( obj, trace )
            postriorProbabilities = zeros( obj.numLeaks, 9 );
            for leakIdx = obj.leaksToLearnIds
                classifier                                  = ...
                        obj.classifiers( leakIdx ).extendedClassifer;
                classificationFeatures                      = ...
                        trace(  obj.classifiers( leakIdx ).featuresIds );  
                
                [ ~, postriorProbabilities( leakIdx, : )  ] = ...
                        classifier.predict( classificationFeatures );
            end
         end
         
         function [ extendedStatistics ] = CalcExtendedStatistics( ...
                                                ~,... %obj
                                                postriorProbabilities, ...
                                                validationTrueLabels,...
                                                classLevels...
         )           
            SORT_EACH_ROW = 2;
            [ orderedPostriors, classesOrderedByPostriorProbability ] = ...
                sort( postriorProbabilities, SORT_EACH_ROW, 'descend' );
            [ ~, numClasses ]                          = ...
                size( classesOrderedByPostriorProbability );
            
            %if classLevels == 0:8 then we need to transform
            %validationTrueLabels to be in range 1:9. If classLevels = 2:6
            %then we need to transform validationTrueLabels to be in range
            %1:5. This transformation is required so we can use sort output
            %to calculate the rank of the true lables
            classLevelsDelta         = min( classLevels ) - 1;
            labelsAsRunningIndices   = validationTrueLabels - classLevelsDelta;
            
            %replicate labelsAsRunningIndices colums so we can use it to
            %efficeintly compute the location of each true lable in
            %classesOrderedByPostriorProbability matrix
            correctClasses           = repmat( labelsAsRunningIndices, 1, numClasses );
            correctClassesBitfield   = ...
               ( correctClasses == classesOrderedByPostriorProbability );
            [ ~, ranks ]             = ...
                max( correctClassesBitfield, [], 2 );
            
            correctClassesPostriors = correctClassesBitfield.* orderedPostriors;
            TAKE_SUM_OF_EACH_ROW    = 2;
            correctClassesPostriors = sum( correctClassesPostriors, TAKE_SUM_OF_EACH_ROW );
            
            extendedStatistics.ranks                   = ranks;     
            extendedStatistics.correctClassesPostriors = correctClassesPostriors;
            extendedStatistics.postrios                = postriorProbabilities;
        end
    end
    
    methods(Access = private)
        function findWindowsOfHighCorrelationForLeak( obj, leakIdx )
            pointsOfInterest                            = ...
                abs( obj.correlations( leakIdx, : ) ) > obj.ROICorrelationThreshhold;
            
            if obj.ROIWindowSize > 1
                filterMask                                  = ...
                    ones( obj.ROIWindowSize, 1 );
                obj.windowsOfHighCorrelation( leakIdx, : )  = ...
                    filtfilt( filterMask, 1, double( pointsOfInterest ) ) > 1;
            else
                 obj.windowsOfHighCorrelation( leakIdx, : ) = ...
                     pointsOfInterest;
            end
        end
        
        function adjustWindowsOfHighCorrelationToMaxCorrelation( obj, leakIdx )
            %The purpose of this function is to set window height to the
            %max value of correlation inside this window. This allows
            %viewing windows with imagesc with adjusting colors according
            %to the max correlation inside th window
            
            %find windows by finding connected components
            connectedComponents = bwconncomp( obj.windowsOfHighCorrelation( leakIdx, : ) );
            for windowIdx = 1:length( connectedComponents.PixelIdxList )
                windowSamplesIds = cell2mat( connectedComponents.PixelIdxList( windowIdx ));
                obj.windowsOfHighCorrelation( leakIdx, windowSamplesIds ) = ...
                    max( abs( obj.correlations( leakIdx, : ) ) );
            end
        end
        
        function [ trueLabels ] = getTrueLables( ~, leakVector, NClasses )
            if nargin == 2
                NClasses = 5;
            end
            
            if NClasses == 9
                trueLabels = leakVector;
            elseif NClasses == 5
                %Due to sparsity of classes 0,1,7,8 we merge 0,1 into class 2
                %and 7,8 into class 6
                mergedTrueLabels = leakVector;
                mergedTrueLabels( leakVector ==0 ) = 2;
                mergedTrueLabels( leakVector ==1 ) = 2;
                mergedTrueLabels( leakVector ==7 ) = 6;
                mergedTrueLabels( leakVector ==8 ) = 6;
                trueLabels = mergedTrueLabels;
            else
                error( 'NClasses should be either 5 or 9' )
            end
        end
        
        function [ classifier ] = Train( obj, leakIdx, classificationFeatures )
            trainingTrueLabels      = ...
                obj.getTrueLables( obj.allLeaks( obj.trainingTracesIds, ...
                                                 leakIdx ...
                                   ) ...
            );
            classifier              = NaiveBayes.fit( ...
                                                    classificationFeatures, ...
                                                    trainingTrueLabels,...
                                                    'Distribution', ...
                                                    'normal' ...
            );
        end
        
        function [ performance, extendedStatistics ] = MeasureClassifierPerformance( ...
                                obj, ...
                                classifier, ...
                                validationFeatuers, ...
                                validationTrueLabels ...
        )
            if nargout == 2
                [ predictedLeaks, postriorProbabilities ] ...
                                    = classifier.predict( validationFeatuers );
                extendedStatistics  = obj.CalcExtendedStatistics( ...
                    postriorProbabilities, ...
                    validationTrueLabels,...
                    classifier.ClassLevels...
                );              
            else
                predictedLeaks      = classifier.predict( validationFeatuers );
            end
            
            performance             = classperf( validationTrueLabels );
            classperf( performance, predictedLeaks );
        end
        
        function SetupPCAHelper( obj, leakIdx, traces, relevantFeaturesIds )
            obj.classifiers( leakIdx ).pcaHelper = PCAHelper( traces, relevantFeaturesIds );
        end
        
        function [ classificationFeatures ] = ExtractFeatures( obj, leakIdx, traces )
            switch( obj.featureExtractionMethod )
                case FeatureExtraction.PCA 
                    classificationFeatures = obj.TakePCAFeatures( leakIdx, traces );
                case FeatureExtraction.OpportunisticTopScore_PCA
                    classificationFeatures = obj.TakePCAFeatures( leakIdx, traces );
                case FeatureExtraction.OpportunisticTopScore
                    classificationFeatures = obj.TakeSelectedFeatures( leakIdx, traces );
                case FeatureExtraction.TakeWindows
                    classificationFeatures = ...
                        obj.TakeEntireWindowsAsFeatures( leakIdx, traces );
                case FeatureExtraction.TakeTopScore
                    classificationFeatures = ...
                        obj.TakeTopScoreFeatures( leakIdx, traces );
            end
        end
        
        function  [ classificationFeatures ] = TakePCAFeatures( obj, leakIdx, traces )  
            pcaHelper              = obj.classifiers( leakIdx ).pcaHelper;
            classificationFeatures = pcaHelper.GetPrincipalFeatures( traces );
            classificationFeatures = classificationFeatures( :, 1:obj.pcaNumFeaturesToTake );
        end
        function  [ classificationFeatures ] = ...
                        TakeEntireWindowsAsFeatures( obj, leakIdx, traces )
                    
            featuresIds                          = ...
                    obj.windowsOfHighCorrelation( leakIdx, : ) > 0;
            obj.classifiers( leakIdx ).featuresIds = featuresIds;

            classificationFeatures               = ...
                traces( :,  obj.classifiers( leakIdx ).featuresIds ); 
        end
        
        function  [ classificationFeatures ] = ...
                        TakeTopScoreFeatures( obj, leakIdx, traces )
                    
            [ ~, sortedByScoreFeatureIds ]         = ...
                sort( obj.featuresScores( leakIdx, : ), 'descend' );
            obj.classifiers( leakIdx ).featuresIds = ...
                sortedByScoreFeatureIds( 1:obj.takeTopScoreFeatures );

            classificationFeatures                 = ...
                traces( :,  obj.classifiers( leakIdx ).featuresIds ); 
        end
        
        function [ classificationFeatures ] = ...
                        TakeSelectedFeatures( obj, leakIdx, traces )
            classificationFeatures               = ...
                traces( :,  obj.classifiers( leakIdx ).featuresIds );     
        end
        
        function PerformIterativeTopScoreFeatureSelection( obj, leakIdx )
            switch obj.featureScoresMethod 
                case FeatureScoreMethod.SimpleClassifierCorrectRate
                    obj.IterativeFeatureSelection_Simple( leakIdx );
                case FeatureScoreMethod.ExtendedClassifierMeanRank
                    obj.IterativeFeatureSelection_Extended( leakIdx );
                case FeatureScoreMethod.ExtendedClassifierMeanPostrior
                    obj.IterativeFeatureSelection_Extended( leakIdx );
            end
        end
        
        function SetupFeatureExtraction( obj, leakIdx )
             switch( obj.featureExtractionMethod )
                case FeatureExtraction.PCA 
                    relevantFeaturesIds = ...
                        obj.windowsOfHighCorrelation( leakIdx, : ) > 0;
                    obj.SetupPCAHelper( leakIdx,...
                                        obj.allTraces( obj.trainingTracesIds, : ), ...
                                        relevantFeaturesIds ...
                    );
                
                case FeatureExtraction.OpportunisticTopScore_PCA
                    obj.PerformIterativeTopScoreFeatureSelection( leakIdx );
                    
                    relevantFeaturesIds = obj.classifiers( leakIdx ).featuresIds;
                    obj.SetupPCAHelper( leakIdx,...
                                        obj.allTraces( obj.trainingTracesIds, : ), ...
                                        relevantFeaturesIds ...
                    );
                
                case FeatureExtraction.OpportunisticTopScore
                    obj.PerformIterativeTopScoreFeatureSelection( leakIdx );
             end
        end

        function [ performance, extendedStatistics ] = EstimatePerformance( obj,            ...
                                                        leakIdx,        ...
                                                        classifier,     ...
                                                        usedFeatures    ...
        )
            estimationFeatures     =                     ...
                obj.allTraces(  obj.estimationTracesIds, ...
                                usedFeatures             ...
                );
            estimationTrueLabels   =                                      ...
                    obj.getTrueLables(                                    ...
                        obj.allLeaks( obj.estimationTracesIds, leakIdx ), ...                                    ...
                        classifier.NClasses                               ...
                 );    
            
            if nargout == 1
                performance            =                ...
                    obj.MeasureClassifierPerformance(   ...
                            classifier,                 ...
                            estimationFeatures,         ...
                            estimationTrueLabels        ...
                );
            else
                [ performance, extendedStatistics ] =       ...
                        obj.MeasureClassifierPerformance(   ...
                                classifier,                 ...
                                estimationFeatures,         ...
                                estimationTrueLabels        ...
                ); 
            end
        end
        
        function CalcFeaturesScores_SimpleClassifierCorrectRate( obj )
            obj.featuresScores = zeros( obj.numLeaks, obj.traceLength );
            for leakIdx = obj.leaksToLearnIds
                tic;
                fprintf( 'Calculating features scores for leak %d.. ', leakIdx );
                
                featuresIds                            = ...
                    obj.windowsOfHighCorrelation( leakIdx, : ) > 0;

                for featureIdx = find( featuresIds )
                    classificationFeatures = ...
                        obj.allTraces( obj.trainingTracesIds,  ...
                                       featureIdx              ...
                    );
                    classifier  = obj.Train( leakIdx, classificationFeatures );
                    performance = obj.EstimatePerformance( leakIdx,    ...
                                                           classifier, ...
                                                           featureIdx  ...
                    );

                    obj.featuresScores( leakIdx, featureIdx ) = performance.correctRate;
                end

                totalTime = toc;
                fprintf( 'Done! Took %.3f seconds\n', totalTime );
            end
        end
        
        function CalcFeaturesScores_ExtendedClassifierStats( obj )
            fprintf( 'Feature Score method is "ExtendedClassifierStats"\n' );
            obj.featuresScores = zeros( obj.numLeaks, obj.traceLength, 2 );
            for leakIdx = obj.leaksToLearnIds
                tic;
                fprintf( 'Calculating features scores for leak %d.. ', leakIdx );
                
                featuresIds                            =        ...
                    obj.windowsOfHighCorrelation( leakIdx, : ) > 0;

                for featureIdx = find( featuresIds )
                    classificationFeatures  =                   ...
                        obj.allTraces( obj.trainingTracesIds,   ...
                                       featureIdx               ...
                    );
                    classifier        = obj.Train( leakIdx, classificationFeatures );
                    extendedClassifer = ExtendedBayesClassifeir( classifier );

                    [ ~, extendedStatistics ]  =                    ...
                        obj.EstimatePerformance( leakIdx,           ...
                                                 extendedClassifer, ...
                                                 featureIdx         ...
                    );
                    
                    meanPostriors = mean( extendedStatistics.correctClassesPostriors );
                    meanRanks     = mean( extendedStatistics.ranks );
                    obj.featuresScores( leakIdx, featureIdx, obj.MEAN_POSTRIOR_SCORE ) = ...
                        meanPostriors;
                    obj.featuresScores( leakIdx, featureIdx, obj.MEAN_RANK_SCORE ) = ...
                        meanRanks;
                end

                totalTime = toc;
                fprintf( 'Done! Took %.3f seconds\n', totalTime );
            end
        end
        
        function IterativeFeatureSelection_Simple( obj, leakIdx )
            featureIdsSortedByScore = obj.SortFeaturesByScore( leakIdx );
            usedFeatures            = false( obj.traceLength, 1 );
            lastClassifierGrade     = 0;
            
            fprintf( 'Performing opportunistic feature selection for leak %3d.. ', leakIdx );
            tic;
            for topScoreFeatureIdx = 1:obj.takeTopScoreFeatures
                currentFeature                 = featureIdsSortedByScore( topScoreFeatureIdx );
                usedFeatures( currentFeature ) = true;
                classificationFeatures = obj.allTraces( obj.trainingTracesIds, usedFeatures );
                classifier             = obj.Train( leakIdx, classificationFeatures ); 
                
                performance = obj.EstimatePerformance( leakIdx,     ...
                                                       classifier,  ...
                                                       usedFeatures ...
                    );
%                 fprintf( 'Success rate with feature %d: %f ', ...
%                          currentFeature, ...
%                          performance.correctRate ...
%                 );
            
                if( performance.correctRate <= lastClassifierGrade )
                    usedFeatures( currentFeature ) = false;
%                     fprintf( 'DISCARDING\n' );
                else
                    lastClassifierGrade = performance.correctRate;
%                     fprintf( 'ADDING\n' );
                end
            end
            
            obj.classifiers( leakIdx ).featuresIds = usedFeatures;
            
            totalTime = toc;
            fprintf( 'Done! Last success rate: %2.2f; Took %.3f seconds\n', ...
                     lastClassifierGrade, ...
                     totalTime ...
            );
        end
        
        function IterativeFeatureSelection_Extended( obj, leakIdx )
            featureIdsSortedByScore = obj.SortFeaturesByScore( leakIdx );
            usedFeatures            = false( obj.traceLength, 1 );
            lastClassifierGrade     = 0;
            
            fprintf( 'Performing opportunistic feature selection for leak %3d.. ', leakIdx );
            tic;
            for topScoreFeatureIdx = 1:obj.takeTopScoreFeatures
                currentFeature                 = featureIdsSortedByScore( topScoreFeatureIdx );
                usedFeatures( currentFeature ) = true;
                classificationFeatures = obj.allTraces( obj.trainingTracesIds, usedFeatures );
                classifier             = obj.Train( leakIdx, classificationFeatures ); 
                extendedClassifer      = ExtendedBayesClassifeir( classifier );
                
                [ ~, extendedStatistics ]  =                    ...
                    obj.EstimatePerformance( leakIdx,           ...
                                             extendedClassifer, ...
                                             usedFeatures       ...
                );
                currentGrade = obj.CalcClassifierGrade( extendedStatistics );

                fprintf( 'Leak %d: Feature grade for feature %d is %f (%3d/%3d)', ...
                         leakIdx,            ...
                         currentFeature,     ...
                         currentGrade,       ...
                         topScoreFeatureIdx, ...
                         obj.takeTopScoreFeatures ...
                );
                if( currentGrade <= lastClassifierGrade )
                    usedFeatures( currentFeature ) = false;
                    fprintf( '->DISCARDING\n' );
                else
                    lastClassifierGrade = currentGrade;
                    fprintf( '->ADDING\n' );
                end
            end
            
            obj.classifiers( leakIdx ).featuresIds = usedFeatures;
            
            totalTime = toc;
            fprintf( '\nDone! Last grade: %2.2f; Took %.3f seconds\n',   ...
                     lastClassifierGrade,                           ...
                     totalTime                                      ...
            );
        end
        
        function [ sortedByScoreFeatureIds ] = SortFeaturesByScore( obj, leakIdx )
            switch obj.featureScoresMethod 
                case FeatureScoreMethod.SimpleClassifierCorrectRate
                    [ ~, sortedByScoreFeatureIds ]         = ...
                        sort( obj.featuresScores( leakIdx, : ), 'descend' );
                case FeatureScoreMethod.ExtendedClassifierMeanRank
                    ranks                           = ...
                        obj.featuresScores( leakIdx, :, obj.MEAN_RANK_SCORE );
                    ranks( ranks == 0 )             = Inf; %ignore zero values in sort
                    [ ~, sortedByScoreFeatureIds ]  = sort( ranks, 'ascend' );
                case FeatureScoreMethod.ExtendedClassifierMeanPostrior
                    [ ~, sortedByScoreFeatureIds ]         = ...
                        sort( obj.featuresScores( leakIdx, :, obj.MEAN_POSTRIOR_SCORE ), 'descend' );
            end
        end
        
        function [ classifierGrade ] = CalcClassifierGrade( obj, extendedStatistics )
            switch obj.featureScoresMethod 
                case FeatureScoreMethod.ExtendedClassifierMeanRank
                    meanRanks       = mean( extendedStatistics.ranks );
                    classifierGrade = 1/meanRanks;
                case FeatureScoreMethod.ExtendedClassifierMeanPostrior
                    meanPostriors   = mean( extendedStatistics.correctClassesPostriors );
                    classifierGrade = meanPostriors;
            end
        end
    end
end




















