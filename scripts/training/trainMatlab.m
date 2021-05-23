% imagesFolder = '/home/koosk/Data-linux/tmp/matlabdl/results/images';
% trainingFile = '/home/koosk/Data-linux/tmp/matlabdl/results/labels/trainingData.mat';
% imagesFolder = '/home/koosk/Data-linux/data/DicCellDetection/dataset_matlab/origSize/images';
% trainingFile = '/home/koosk/Data-linux/data/DicCellDetection/dataset_matlab/origSize/labels/trainingData.mat';
% checkpointFolder = '/home/koosk/Data-linux/data/DicCellDetection/dataset_matlab/origSize/checkpoints';
imagesFolder = '/home/koosk/data/data/DicCellDetection/dataset_matlab/downsampled/images';
trainingFile = '/home/koosk/data/data/DicCellDetection/dataset_matlab/downsampled/labels/trainingData.mat';
checkpointFolder = '/home/koosk/data/data/DicCellDetection/dataset_matlab/downsampled/checkpoints';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
addpath(imagesFolder);
trainingData = load(trainingFile);
trainingData = table(trainingData.imageFilename, trainingData.cellList, trainingData.deadCellList, trainingData.otherList, ...
    'VariableNames', {'imageFilename', 'Cell', 'DeadCell', 'Other'});
trainingData.DeadCell = [];
trainingData.Other = [];
trainingData = trainingData(1:10, :);

% net = vgg16;
net = alexnet;
% net = resnet50;
options = trainingOptions('adam', ...
  'MiniBatchSize', 1, ...
  'InitialLearnRate', 1e-3, ...
  'LearnRateDropFactor', 0.1, ...
  'LearnRateDropPeriod', 1, ... 
  'MaxEpochs', 2, ...
  'CheckpointPath', checkpointFolder ...
  );

% % % layersTransfer = net.Layers(1:end-3);
% % % % layers(end-2) = fullyConnectedLayer(2);
% % % % layers(end-1) = softmaxLayer();
% % % % layers(end) = classificationLayer('Name', 'output');
% % % numClasses = 2;
% % % layers = [
% % %     layersTransfer
% % %     fullyConnectedLayer(numClasses,'WeightLearnRateFactor',1,'BiasLearnRateFactor',1)
% % %     softmaxLayer
% % %     classificationLayer];
% % % layers = [imageInputLayer([28 28 1]);
% % %           convolution2dLayer(5,16);
% % %           reluLayer();
% % %           maxPooling2dLayer(2,'Stride',2);
% % %           fullyConnectedLayer(3);
% % %           softmaxLayer();
% % %           classificationLayer()];
% % % rcnn = trainRCNNObjectDetector(trainingData, layers, options, 'NegativeOverlapRange', [0 0.3]);
% % % rcnn = trainFastRCNNObjectDetector(trainingData, layers, options, 'NegativeOverlapRange', [0 0.3]);

%%%%% faster RCNN specific code
net = resnet50;
lgraph = layerGraph(net);

% Remove the last 3 layers. 
layersToRemove = {
    'fc1000'
    'fc1000_softmax'
    'ClassificationLayer_fc1000'
    };
lgraph = removeLayers(lgraph, layersToRemove);

% Specify the number of classes the network should classify.
numClasses = 1;
numClassesPlusBackground = numClasses + 1;
% Define new classification layers.
newLayers = [
    fullyConnectedLayer(numClassesPlusBackground, 'Name', 'rcnnFC')
    softmaxLayer('Name', 'rcnnSoftmax')
    classificationLayer('Name', 'rcnnClassification')
    ];

% Add new object classification layers.
lgraph = addLayers(lgraph, newLayers);

% Connect the new layers to the network. 
lgraph = connectLayers(lgraph, 'avg_pool', 'rcnnFC');

% Define the number of outputs of the fully connected layer.
numOutputs = 4 * numClasses;

% Create the box regression layers.
boxRegressionLayers = [
    fullyConnectedLayer(numOutputs,'Name','rcnnBoxFC')
    rcnnBoxRegressionLayer('Name','rcnnBoxDeltas')
    ];

% Add the layers to the network.
lgraph = addLayers(lgraph, boxRegressionLayers);

% Connect the regression layers to the layer named 'avg_pool'.
lgraph = connectLayers(lgraph,'avg_pool','rcnnBoxFC');

% Select a feature extraction layer.
featureExtractionLayer = 'activation_40_relu';

% Disconnect the layers attached to the selected feature extraction layer.
lgraph = disconnectLayers(lgraph, featureExtractionLayer,'res5a_branch2a');
lgraph = disconnectLayers(lgraph, featureExtractionLayer,'res5a_branch1');

% Add ROI max pooling layer.
outputSize = [14 14];
roiPool = roiMaxPooling2dLayer(outputSize,'Name','roiPool');
lgraph = addLayers(lgraph, roiPool);

% Connect feature extraction layer to ROI max pooling layer.
lgraph = connectLayers(lgraph, featureExtractionLayer,'roiPool/in');

% Connect the output of ROI max pool to the disconnected layers from above.
lgraph = connectLayers(lgraph, 'roiPool','res5a_branch2a');
lgraph = connectLayers(lgraph, 'roiPool','res5a_branch1');



% Define anchor boxes.
anchorBoxes = [
    16 16
    32 16
    16 32
    ];

% Create the region proposal layer.
proposalLayer = regionProposalLayer(anchorBoxes,'Name','regionProposal');

lgraph = addLayers(lgraph, proposalLayer);

% Number of anchor boxes.
numAnchors = size(anchorBoxes,1);

% Number of feature maps in coming out of the feature extraction layer. 
numFilters = 1024;

rpnLayers = [
    convolution2dLayer(3, numFilters,'padding',[1 1],'Name','rpnConv3x3')
    reluLayer('Name','rpnRelu')
    ];

lgraph = addLayers(lgraph, rpnLayers);

% Connect to RPN to feature extraction layer.
lgraph = connectLayers(lgraph, featureExtractionLayer, 'rpnConv3x3');


% Add RPN classification layers.
rpnClsLayers = [
    convolution2dLayer(1, numAnchors*2,'Name', 'rpnConv1x1ClsScores')
    rpnSoftmaxLayer('Name', 'rpnSoftmax')
    rpnClassificationLayer('Name','rpnClassification')
    ];
lgraph = addLayers(lgraph, rpnClsLayers);

% Connect the classification layers to the RPN network.
lgraph = connectLayers(lgraph, 'rpnRelu', 'rpnConv1x1ClsScores');

% Add RPN regression layers.
rpnRegLayers = [
    convolution2dLayer(1, numAnchors*4, 'Name', 'rpnConv1x1BoxDeltas')
    rcnnBoxRegressionLayer('Name', 'rpnBoxDeltas');
    ];

lgraph = addLayers(lgraph, rpnRegLayers);

% Connect the regression layers to the RPN network.
lgraph = connectLayers(lgraph, 'rpnRelu', 'rpnConv1x1BoxDeltas');


% Connect region proposal network.
lgraph = connectLayers(lgraph, 'rpnConv1x1ClsScores', 'regionProposal/scores');
lgraph = connectLayers(lgraph, 'rpnConv1x1BoxDeltas', 'regionProposal/boxDeltas');

% Connect region proposal layer to roi pooling.
lgraph = connectLayers(lgraph, 'regionProposal', 'roiPool/roi');

rcnn = trainFasterRCNNObjectDetector(trainingData, lgraph, options, 'PositiveOverlapRange', [0.2, 1]);
%%%%

numToShow = 10;
imgIndicesToShow = randi(numel(trainingData.imageFilename),numToShow);
for i = 1:numToShow
    img = imread(['/home/koosk/data/tmp/matlabdl/results/images/', trainingData.imageFilename{imgIndicesToShow(i)}]);
    [bbox, score, label] = detect(rcnn, img);
    detectedImg = insertShape(img2,'Rectangle',bbox);
    figure
    imshow(detectedImg)
end
rmpath(imagesFolder);
