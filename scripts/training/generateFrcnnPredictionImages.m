resultFolder = '/home/koosk/data/images/ap_validation_set/PredictionResults/';
% predictor = FrcnnPredictor('/home/koosk/data/data/DicCellDetection/checkpoints/resnet3/rcnn_model_result.mat');
predictor = FrcnnPredictor(detectorResnet4);
predictor.predictionThreshold = 0.1;

%%
imgFolderToPredict = '/home/koosk/data/images/ap_validation_set';
imgfiles = dir([imgFolderToPredict, '/*.tif']);

for iFiles = 1:numel(imgfiles)
    imgFilepath = fullfile(imgFolderToPredict, imgfiles(iFiles).name);

    imgstack = ImageStack.load(imgFilepath);
    stack = imgstack.getStack();
    sz = size(stack, 3);

    lastFolder = strsplit(imgFilepath,filesep);
    lastFolder = lastFolder{end-1};
    [~, fname, ~] = fileparts(imgFilepath);
    fullResultFolder = fullfile(resultFolder, lastFolder, fname);
    mkdir(fullResultFolder);
    for i = 1:sz
        image = stack(:,:,i);
        image = imresize(image,[520 696]);
        image = imresize(image, 0.7);
        [bbox, score, label] = predictor.customPredict(image);
        detectedImg = insertShape(image,'Rectangle',bbox);
        sliceFname = strcat(fname, '_slice', sprintf('%03d.png', i));
        imwrite(detectedImg , fullfile(fullResultFolder, sliceFname));
    end
end


