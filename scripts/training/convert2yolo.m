%% mouse and rat samples
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170424_1-50';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/201704/20170424_1-50';
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170424_51-133_labeled';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/201704/20170424_51-133';
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170425_1-50';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/201704/20170425_1-50';
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170425_51-100';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/201704/20170425_51-100';

%% human samples
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170530_human';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/human/20170530';
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/labeled_links/20170622_human';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/human/20170622';
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170915_human_labeled';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/human/20170915';

%% validation set
imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20180214_human_labeled';
traindataFolder = '/home/koosk/data/data/autopatcher/traindata/human/validation/20180214_Reka';

%%
% resultFolder = '/home/koosk/data/images/tissue_yolo/healthy_only';
resultFolder = '/home/koosk/data/images/tissue_yolo/healthy_only_val';


includeDeadCells = false;
includeOthers = false;
downsample = false; % reduce image size using gauss pyramid
backgroundCorrection = false;

outimgFormat = 'jpg';
zPositions = -2:2; %0; %[-2, 0, 2]; %-1:1;%-3:3; % set to 0 if only the selected slice should be used
zPosDontcares = [0, 0]; % number of first and last elements to mark as DontCares in zPositions list. Set [0, 0] to exclude DontCares.
bgcorrSigma = 200; % used if backgroundCorrection == true

positiveLabelText = '0';
deadCellLabelText = '1';
otherLabelText = '2';
dontCareText = '3';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

UNLABELED = Manual3DTrainerModel.UNLABELED;
POSITIVE_LABEL = Manual3DTrainerModel.POSITIVE_LABEL;
DEADCELL_LABEL = Manual3DTrainerModel.NEGATIVE_LABEL;
OTHER_LABEL = Manual3DTrainerModel.OTHER_LABEL;

if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end

imgstackFiles = [dir(fullfile(imgstackFolder, '*.tif')); dir(fullfile(imgstackFolder, '*.tiff'))];
trainerFiles = dir(fullfile(traindataFolder, '*.mat'));

if numel(imgstackFiles) ~= numel(trainerFiles)
    error('The number of image stack files does not match the number of trainer files!');
end

folderPrefix = split(imgstackFolder, '/');
if isempty(folderPrefix(end))
    folderPrefix = char(folderPrefix(end-1));
else
    folderPrefix = char(folderPrefix(end));
end

imgstackNames = {imgstackFiles(:).name};
imgstackNames = cellfun(@(x) split(x, '.'), imgstackNames, 'UniformOutput', false);
imgstackExtensions = cellfun(@(x) x{2}, imgstackNames, 'UniformOutput', false);
imgstackNames = cellfun(@(x) x{1}, imgstackNames, 'UniformOutput', false);
positiveCounter = 0;
deadcellCounter = 0;
otherCounter = 0;
unlabeledCounter = 0;

mappingFpath = fullfile(resultFolder, 'mapping.mat');
clear fnameMapping
if exist(mappingFpath, 'file')
    load(mappingFpath)
end
if exist('fnameMapping', 'var')
    imgCounterStart = size(fnameMapping, 1);
else
    fnameMapping = cell(0,2);
    imgCounterStart = 0;
end
imgCounter = imgCounterStart;
for i = 1:numel(imgstackFiles)
    imgCounter = imgCounter + 1;
    
    trainerData = load(fullfile(traindataFolder, trainerFiles(i).name));
    if isempty(trainerData)
        continue
    end
    [~, fname, ~] = fileparts(trainerFiles(i).name);
    ext = imgstackExtensions(strcmp(imgstackNames,fname));
    if numel(ext) ~= 1
        error(['Could not determine image file for: ', fname]);
    end
    
    fnameMapping(end+1, :) = {imgCounter , [imgstackFolder, '_', fname]};
    
    imgpath = fullfile(imgstackFolder,[fname, '.', ext{1}]);
    img = ImageStack.load(imgpath, false);
    img = img.getStack();
    [sy, sx, sz] = size(img);
    if ~all(trainerData(:).segmentedIndices(:,1) > 0) && ~all(trainerData(:).segmentedIndices(:,2) > 0) && ...
            ~all(trainerData(:).segmentedIndices(:,3) <= sx) && ~all(trainerData(:).segmentedIndices(:,4) <= sy) && ...
            ~all(trainerData(:).segmentedIndices(:,5) <= sz) && ~all(trainerData(:).segmentedIndices(:,5) > 0)
        error(['Position corruption error in file: ', fname]);
    end
    if backgroundCorrection
        bg = imgaussfilt(img, bgcorrSigma);
        img = img - bg;
        img = img - min(img(:));
        img = img ./ max(img(:));
    end
    if downsample
        img = impyramid(img, 'reduce');
    end
    imgWritten = false(sz, 1);
    for j = 1:numel(trainerData.label)
        sampleCenterPos = trainerData.segmentedIndices(j,:);
        
        labelType = [];
        track = true;
        switch trainerData.label(j)
            case POSITIVE_LABEL
                positiveCounter = positiveCounter + 1;
                labelType = positiveLabelText;
            case DEADCELL_LABEL
                deadcellCounter  = deadcellCounter + 1;
                if ~includeDeadCells
                    track = false;
                else
                    labelType = deadCellLabelText;
                end
            case OTHER_LABEL
                otherCounter = otherCounter + 1;
                if ~includeOthers
                    track = false;
                else
                    labelType = otherLabelText;
                end
            case UNLABELED
                track = false;
            otherwise
                error(['Unsupported label value: ', num2str(trainerData(j).label)]);
        end
        
        if track
%             sliceName = fname;
            sliceName = num2str(imgCounter);
        
            zPosList = sampleCenterPos(5) + zPositions;
            dontcareList = false(numel(zPosList),1);
            dontcareList(1:zPosDontcares(1)) = true;
            dontcareList(end-zPosDontcares(2)+1:end) = true;
            while zPosList(1) < 1
                zPosList = zPosList(2:end);
                dontcareList = dontcareList(2:end);
            end
            while zPosList(end) > sz
                zPosList = zPosList(1:end-1);
                dontcareList = dontcareList(1:end-1);
            end
            
            bbox = [sampleCenterPos(1), sampleCenterPos(2), sampleCenterPos(3), sampleCenterPos(4)];
            if bbox(1) <= 1
                bbox(1) = 1;
            end
            if bbox(2) <= 1
                bbox(2) = 1;
            end
            if bbox(3) >= sx
                bbox(3) = sx;
            end
            if bbox(4) >= sy
                bbox(4) = sy;
            end
            if downsample
                bbox = ceil(bbox./2);
            end
            bbox = bbox - 1; % convert to zero based indices
            yolobb = [(bbox(1) + bbox(3)) / 2, ...
                      (bbox(2) + bbox(4)) / 2, ...
                      bbox(3) - bbox(1), ...
                      bbox(4) - bbox(2)];
            yolobb(1) = yolobb(1) / (sx-1);
            yolobb(2) = yolobb(2) / (sy-1);
            yolobb(3) = yolobb(3) / (sx-1);
            yolobb(4) = yolobb(4) / (sy-1);
            currentLabelType = labelType;
            
            nZpos = numel(zPosList);
            for zposIdx = 1:nZpos
                zpos = zPosList(zposIdx);
                isDontCare = dontcareList(zposIdx);
                
                sliceFileName = [sliceName, '_slice', sprintf('%03d', zpos), '.'];
                if isDontCare
                    currentLabelType = dontCareText;
                end
                entry = [currentLabelType, ' ', ...
                    num2str(yolobb(1)), ' ', num2str(yolobb(2)), ' ', num2str(yolobb(3)), ' ', num2str(yolobb(4)), ' ', ...
                ];
                
                if ~imgWritten(zpos)
                    imgslicePath = fullfile(resultFolder, [sliceFileName, outimgFormat]);
                    outimg = img(:,:,zpos);
                    imwrite(outimg, imgslicePath); 
                    imgWritten(zpos) = true;
                end
                labelPath = fullfile(resultFolder, [sliceFileName, 'txt']);
                fid = fopen(labelPath, 'a');
                fprintf(fid, '%s\n', entry);
                fclose(fid);
            end
        end
    end
end
save(fullfile(resultFolder, 'mapping.mat'), 'fnameMapping')


