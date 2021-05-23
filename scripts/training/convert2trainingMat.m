% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/20170424_1-50';
% traindataFolder = '/home/koosk/work/traindata/201704/20170424_1-50';
% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/20170424_51-133_labeled';
% traindataFolder = '/home/koosk/work/traindata/201704/20170424_51-133';
% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/20170425_1-50';
% traindataFolder = '/home/koosk/work/traindata/201704/20170425_1-50';
% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/20170425_51-100';
% traindataFolder = '/home/koosk/work/traindata/201704/20170425_51-100';
%% human samples
% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/20170530_human';
% traindataFolder = '/home/koosk/work/traindata/human/20170530';
% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/labeled_links/20170622_human';
% traindataFolder = '/home/koosk/work/traindata/human/20170622';
% imgstackFolder = '/home/koosk/Data-linux/images/stack_images/tissues/labeled_links/tissues_human_20170915';
% traindataFolder = '/home/koosk/work/traindata/human/20170915';

%%
% imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20170915_human_labeled_train';
% traindataFolder = '/home/koosk/data/data/autopatcher/traindata/human/20170915_selected';
% resultFolder = '/home/koosk/data/data/DicCellDetection/dataset_matlab/ds_rev2_v2/';

imgstackFolder = '/home/koosk/data/images/stack_images/tissues/20180214_human_labeled_train';
traindataFolder = '/home/koosk/data/data/autopatcher/traindata/human/20180214_selected';
resultFolder = '/home/koosk/data/data/DicCellDetection/dataset_matlab/ds_rev2_v2/';

%%
% imgstackFolder = '/home/koosk/Data-linux/tmp/matlabdl/smallset_20170425_1-50';
% traindataFolder = '/home/koosk/Data-linux/tmp/matlabdl/smalltrain_20170425_1-50';
% resultFolder = '/home/koosk/Data-linux/data/DicCellDetection/dataset_matlab/origSize/';
% resultFolder = '/home/koosk/Data-linux/data/DicCellDetection/dataset_matlab/downsampled/';

includeDeadCells = false;
includeOthers = false;
downsample = true; % reduce image size using gauss pyramid
backgroundCorrection = false;
rgbAs3D = false; % puts +/-1 slices to R and B channels and focus img to channel G; cannot be true together with dicAndReconstructions or onlyReconstruction
dicAndReconstructions = false; % put dic into the R channel and its reconstruction into the G; cannot be true together with rgbAs3D or onlyReconstruction
onlyReconstruction = false; %%

useLastFolderAsFilenamePrefix = true;
outimgFormat = 'png';
zPositions = -2:2;% 0; [-2, 0, 2]; %-1:1;%-3:3; % set to 0 if only the selected slice should be used
bgcorrSigma = 200; % used if backgroundCorrection == true

reconstructionFnamePrefix = 'rec-'; % The prefix of the reconstruction files, if there are any. Only used if dicAndReconstructions is true


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

UNLABELED = Manual3DTrainerModel.UNLABELED;
POSITIVE_LABEL = Manual3DTrainerModel.POSITIVE_LABEL;
DEADCELL_LABEL = Manual3DTrainerModel.NEGATIVE_LABEL;
OTHER_LABEL = Manual3DTrainerModel.OTHER_LABEL;

if nnz([rgbAs3D, dicAndReconstructions, onlyReconstruction]) > 1
    error(['Parameters ''rgbAs3D'', ''dicAndReconstructions'', and ''onlyReconstruction'' ', ...
        'cannot be true at the same time!']);
end

if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end
imagesDir = fullfile(resultFolder, 'images');
labelsDir = fullfile(resultFolder, 'labels');
if ~exist(imagesDir, 'dir')
    mkdir(imagesDir);
end
if ~exist(labelsDir, 'dir')
    mkdir(labelsDir);
end
labelsFpath = fullfile(labelsDir, 'trainingData.mat');

imgstackFiles = [dir(fullfile(imgstackFolder, '*.tif')); dir(fullfile(imgstackFolder, '*.tiff'))];
trainerFiles = dir(fullfile(traindataFolder, '*.mat'));

if numel(imgstackFiles) ~= numel(trainerFiles)
    error('The number of image stack files does not match the number of trainer files!');
end

if useLastFolderAsFilenamePrefix
    folderPrefix = split(imgstackFolder, '/');
    if isempty(folderPrefix(end))
        folderPrefix = char(folderPrefix(end-1));
    else
        folderPrefix = char(folderPrefix(end));
    end
end

imgstackNames = {imgstackFiles(:).name};
imgstackNames = cellfun(@(x) split(x, '.'), imgstackNames, 'UniformOutput', false);
imgstackExtensions = cellfun(@(x) x{2}, imgstackNames, 'UniformOutput', false);
imgstackNames = cellfun(@(x) x{1}, imgstackNames, 'UniformOutput', false);
positiveCounter = 0;
deadcellCounter = 0;
otherCounter = 0;
unlabeledCounter = 0;
allImageFilename = cell(0,1);
allCellList = cell(0,1);
allDeadCellList = cell(0,1);
allOtherList = cell(0,1);
for i = 1:numel(imgstackFiles)
    trainerData = load(fullfile(traindataFolder, trainerFiles(i).name));
    if isempty(trainerData)
        continue
    end
    [~, fname, ~] = fileparts(trainerFiles(i).name);
    ext = imgstackExtensions(strcmp(imgstackNames,fname));
    if numel(ext) ~= 1
        error(['Could not determine image file for: ', fname]);
    end
    imgpath = fullfile(imgstackFolder,[fname, '.', ext{1}]);
    img = ImageStack.load(imgpath, false);
    img = img.getStack();
    [sy, sx, sz] = size(img);
    if ~all(trainerData(:).segmentedIndices(:,1) > 0) && ~all(trainerData(:).segmentedIndices(:,2) > 0) && ...
            ~all(trainerData(:).segmentedIndices(:,3) <= sx) && ~all(trainerData(:).segmentedIndices(:,4) <= sy) && ...
            ~all(trainerData(:).segmentedIndices(:,5) <= sz) && ~all(trainerData(:).segmentedIndices(:,5) > 0)
        error(['Position corruption error in file: ', fname]);
    end
    if dicAndReconstructions || onlyReconstruction
        recImgpath = fullfile(imgstackFolder,'reconstructions',[reconstructionFnamePrefix, fname, '.', ext{1}]);
        recimg = ImageStack.load(recImgpath, false);
        recimg = recimg.getStack();
    end
    if backgroundCorrection
        bg = imgaussfilt(img, bgcorrSigma);
        img = img - bg;
        img = img - min(img(:));
        img = img ./ max(img(:));
    end
    if downsample
        img = imresize(img, [520, 696]);
    end
    imgWritten = false(sz, 1);
    imageFilename = cell(sz,1);
    sliceFileName = cell(sz,1);
    cellList = cell(sz,1);
    deadCellList = cell(sz,1);
    otherList = cell(sz,1);
    for j = 1:sz
        if useLastFolderAsFilenamePrefix
            sliceName = [folderPrefix, '_', fname];
        else
            sliceName = fname; %#ok
        end
        sliceFname = [sliceName, '_slice', sprintf('%03d', j), '.'];
        sliceFileName{j} = sliceFname;
        imageFilename{j} = [sliceFname, outimgFormat];
    end
    
    for j = 1:numel(trainerData.label)
        sampleCenterPos = trainerData.segmentedIndices(j,:);
        
        track = true;
        switch trainerData.label(j)
            case POSITIVE_LABEL
                positiveCounter = positiveCounter + 1;
            case DEADCELL_LABEL
                deadcellCounter  = deadcellCounter + 1;
                if ~includeDeadCells
                    track = false;
                end
            case OTHER_LABEL
                otherCounter = otherCounter + 1;
                if ~includeOthers
                    track = false;
                end
            case UNLABELED
                track = false;
                unlabeledCounter = unlabeledCounter + 1;
            otherwise
                error(['Unsupported label value: ', num2str(trainerData(j).label)]);
        end
        
        if track
            zPosList = sampleCenterPos(5) + zPositions;
            while zPosList(1) < 1
                zPosList = zPosList(2:end);
            end
            while zPosList(end) > sz
                zPosList = zPosList(1:end-1);
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
            %% TODO check Image Labeler app's output
            bbox(3) = bbox(3) - bbox(1); %convert to x y h w
            bbox(4) = bbox(4) - bbox(2);
            
            nZpos = numel(zPosList);
            for zposIdx = 1:nZpos
                zpos = zPosList(zposIdx);
            
                switch trainerData.label(j)
                    case POSITIVE_LABEL
                        cellList{zpos} = [cellList{zpos}; bbox];
                    case DEADCELL_LABEL
                        deadCellList{zpos} = [deadCellList{zpos}; bbox];
                    case OTHER_LABEL
                        otherList{zpos} = [otherList{zpos}; bbox];
                    otherwise
                        error(['Unsupported label value: ', num2str(trainerData(j).label)]);
                end
                
                
                if ~imgWritten(zpos)
                    imgslicePath = fullfile(imagesDir, imageFilename{zpos});
                    if rgbAs3D
                        if zpos == 1 || zpos == sz
                            continue
                        end
                        outimg = img(:,:, zpos + [-1, 0, 1]);
                    elseif dicAndReconstructions
                        outimg = img(:,:, zpos);
                        outimg(:,:,2) = recimg(:,:, zpos);
                        outimg(:,:,3)= zeros(size(img(:,:,zpos),1), size(img(:,:,zpos),2));
                    elseif onlyReconstruction
                        outimg = recimg(:,:, zpos);
                    else
                        outimg = img(:,:,zpos);
                    end
                    imwrite(outimg, imgslicePath); 
                    imgWritten(zpos) = true;
                end
            end
        end
    end
    clear img recimg
    emptyIndices = cellfun(@isempty, cellList) & cellfun(@isempty, deadCellList) & cellfun(@isempty, otherList);
    allImageFilename = [allImageFilename; imageFilename(~emptyIndices)]; %#ok<AGROW>
    allCellList = [allCellList; cellList(~emptyIndices)]; %#ok<AGROW>
    allDeadCellList = [allDeadCellList; deadCellList(~emptyIndices)]; %#ok<AGROW>
    allOtherList = [allOtherList; otherList(~emptyIndices)]; %#ok<AGROW>
end

imageFilename = allImageFilename;
cellList = allCellList;
deadCellList = allDeadCellList;
otherList = allOtherList;

if exist(labelsFpath, 'file')
    trainingData = load(labelsFpath);
    imageFilename = [trainingData.imageFilename; imageFilename]; %#ok<NASGU>
    cellList = [trainingData.cellList; cellList]; %#ok<NASGU>
    deadCellList = [trainingData.deadCellList; deadCellList]; %#ok<NASGU>
    otherList = [trainingData.otherList; otherList]; %#ok<NASGU>
end

save(labelsFpath, 'imageFilename', 'cellList', 'deadCellList', 'otherList');

disp(['Conversion finished. (Original statistics) Cells: ', num2str(positiveCounter), '; dead cells: ', num2str(deadcellCounter), '; others: ', num2str(otherCounter), '; unlabeled: ', num2str(unlabeledCounter)]);

clear trainingData allImageFilename allCellList allDeadCellList  allOtherList imageFilename cellList deadCellList otherList
clear labelsFpath sliceFname emptyIndices
clear alpha backgroundCorrection bbox bg bgcorrSigma currentLabelType DEADCELL_LABEL
clear deadcellCounter deadCellLabelText dicAndReconstructions dimensions dontcareList
clear dontCareText downsample entry ext fid fname folderPrefix i imagesDir imgpath
clear imgslicePath imgstackExtensions imgstackFiles imgstackFolder imgstackNames
clear imgWritten includeDeadCells includeOthers isDontCare j labelPath labelsDir labelType
clear location nZpos occluded onlyReconstruction OTHER_LABEL otherCounter otherLabelText
clear outimg outimgFormat POSITIVE_LABEL positiveCounter positiveLabelText
clear recImgpath reconstructionFnamePrefix resultFolder rgbAs3D rotation_y
clear sampleCenterPos sliceFileName sliceName sx sy sz track traindataFolder
clear trainerData trainerFiles truncated UNLABELED unlabeledCounter useLastFolderAsFilenamePrefix
clear zpos zPosDontcares zposIdx zPositions zPosList


