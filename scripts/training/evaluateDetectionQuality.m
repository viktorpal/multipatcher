% fpath = '/home/koosk/Data-linux/images/stack_images/tissues/20170915_human/tissue';
% extension = '.tif';
% imageIndices = 1:24;
% labelsFolder = '/home/koosk/work/traindata/human/20170915';

fpath = '/home/koosk/data/images/ap_validation_set/tissue';
extension = '.tif';
imageIndices = 7:9;
% imageIndices = 8;
labelsFolder = '/home/koosk/data/images/ap_validation_set/ground_truth/20180214';

xyThreshold = 43.4783; % 5um = 43.4783 pix, 10um = 86.9565 pix
zThreshold = 3;

predictionThresholdList = 0.06;
% predictionThresholdList = 0:0.01:1;

dropAboveZ = 999;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = struct(...
    'imgpath', {}, ...
    'precision', {}, ...
    'recall', {}, ...
    'accuracy', {}, ...
    'f1score', {}, ...
    'numTotalPaired', {}, ...
    'numLabeled', {}, ...
    'TP', {}, ...
    'FP', {}, ...
    'FN', {}, ...
    'modelFilepath', {}, ...
    'predictionThreshold', {}, ...
    'xyThreshold', {}, ...
    'zThreshold', {}, ...
    'dropAboveZ', {} ...
    );
% predictor = PredictorRemote('10.7.3.107', 7878);
% predictor = PredictorLocal('data/deploy.prototxt', 'data/snapshot_iter_53928.caffemodel');
predictor = PredictorCaffe('data/dic-tissue.prototxt', 'data/snapshot_iter_53928.caffemodel');
for imageIdx = imageIndices
    fullfpath = [fpath, sprintf('%03d', imageIdx), extension];
    imgstack = ImageStack.load(fullfpath);
    stack = imgstack.getStack();
    if size(stack,3) > dropAboveZ
        stack = stack(:,:,1:dropAboveZ);
        imgstack = ImageStack(stack);
    end
    clear stack
    
    %% load labels

    [~, fname, ~] = fileparts(fullfpath);
    labelFpath = fullfile(labelsFolder, [fname,'.mat']);
    labelData = load(labelFpath);
    keptLabelDataIdx = labelData.segmentedIndices(:,5)<=dropAboveZ;
    labelData = struct('label', labelData.label(keptLabelDataIdx), 'segmentedIndices', labelData.segmentedIndices(keptLabelDataIdx,:));

    % labeledCells = labelData.segmentedIndices(labelData.label==1,:); % healty only
    % labeledCells = labelData.segmentedIndices(:,:); % all
    healthyIndices = labelData.label==1;
    deadIndices = labelData.label==2;
    togetherIndices = healthyIndices | deadIndices;
    labeledCells = labelData.segmentedIndices(healthyIndices | deadIndices,:); % healthy and dead
    healthyIndices = labelData.label(togetherIndices)==1;
    deadIndices = labelData.label(togetherIndices)==2;
    clear togetherIndices

    numLabeled = size(labeledCells,1);
    labeledCenterPoints = zeros(numLabeled,3);
    for i = 1:size(labeledCells,1)
        labeledCenterPoints(i,1:2) = [(labeledCells(i,1)+labeledCells(i,3))/2, (labeledCells(i,2)+labeledCells(i,4))/2];
        labeledCenterPoints(i,3) = labeledCells(i,5);
    end
    
    %% predict
    for predictionThreshold = predictionThresholdList
        predictor.predictionThreshold = predictionThreshold;
        
        params = struct('predictor', predictor, 'predictionMinOverlapToUnite', 0.6, 'predictionMaxZdistanceToUnite', 3, ...
            'predictionMinObjectDimension', [100,100], 'predictionMaxObjectDimension', [200,230]);
        pcells = predictStack(imgstack, params);
        numPcells = length(pcells);
        for i = 1:numPcells
            pcells(i).CenterPoint = [pcells(i).BoundingBox(1)+pcells(i).BoundingBox(3)/2, pcells(i).BoundingBox(2)+pcells(i).BoundingBox(4)/2];
        end

        %% evaluate

        xyDistanceMatrix = ones(numLabeled, numPcells)*inf;
        zDistanceMatrix = ones(numLabeled, numPcells)*inf;
        xyThresholded = zeros(numLabeled, numPcells);
        zThresholded = zeros(numLabeled, numPcells);
        for i = 1:numLabeled
            for j = 1:numPcells
                xyDistanceMatrix(i,j) = sqrt(( labeledCenterPoints(i,1)-pcells(j).CenterPoint(1) )^2 + ( labeledCenterPoints(i,2)-pcells(j).CenterPoint(2) )^2);
                zDistanceMatrix(i,j) = abs(pcells(j).z - labeledCenterPoints(i,3));
                xyThresholded(i,j) = xyDistanceMatrix(i,j) <= xyThreshold;
                zThresholded(i,j) = zDistanceMatrix(i,j) <= zThreshold;
            end
        end

        pairedPositions = xyThresholded & zThresholded;
        % figure, imagesc(pairedPositions)
        numTotalPaired = nnz(max(pairedPositions,[],1));
        disp(['Total paired: ', num2str(numTotalPaired), '/', num2str(numLabeled)]);
        healthyPaired = pairedPositions;
        healthyPaired(deadIndices,:) = 0;
        deadPaired = pairedPositions;
        deadPaired(healthyIndices,:) = 0;
        numHealthyPaired = nnz(max(healthyPaired,[],1));
        numDeadPaired = nnz(max(deadPaired,[],1));

        falsePositive = numPcells-numHealthyPaired;
        falseNegative = nnz(healthyIndices)-numHealthyPaired;
        truePositive = numHealthyPaired;
        precision = truePositive/(truePositive+falsePositive)*100;
        recall = truePositive/(truePositive+falseNegative)*100;
        accuracy = truePositive/(truePositive+falsePositive+falseNegative)*100;
        f1score = 2*precision*recall/(precision+recall);

        %% display/save results

        disp(' ')
        disp(['Total paired: ', num2str(numTotalPaired), '/', num2str(numLabeled)]);
        disp(['TP=',num2str(truePositive), ', FP=', num2str(falsePositive), ', FN=', num2str(falseNegative)]);
        disp(['Precision = ', num2str(precision), '%, recall = ', num2str(recall), '%']);
        disp(['accuracy = ', num2str(accuracy), '%, f1score = ', num2str(f1score), '%']);
        results(end+1) = struct(...
                'imgpath', fullfpath, ...
                'predictionThreshold', predictionThreshold, ...
                'xyThreshold', xyThreshold, ...
                'zThreshold', zThreshold, ...
                'dropAboveZ', dropAboveZ, ...
                'numTotalPaired', numTotalPaired, ...
                'numLabeled', numLabeled, ...
                'precision', precision, ...
                'recall', recall, ...
                'accuracy', accuracy, ...
                'f1score', f1score, ...
                'TP', truePositive, ...
                'FP', falsePositive, ...
                'FN', falseNegative, ...
                'modelFilepath', predictor.datafile ...
                );
    end
end
save(['evaluation_results_caffe_', datestr(now, 'yyyy_mm_dd_HH_MM_SS'), '.mat'], 'results');



