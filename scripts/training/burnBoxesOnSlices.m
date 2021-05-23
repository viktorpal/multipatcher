% inputStackPath = '/home/koosk/Data-linux/images/stack_images/tissues/20180214_human/tissue005.tif';
% traindataFolder = '/home/koosk/work/traindata/human/validation/20180214_Reka';
% inputStackPath = '/home/koosk/Data-linux/images/stack_images/tissues/20180214_human/tissue009.tif';
% traindataFolder = '/home/koosk/work/traindata/human/20180214';
% inputStackPath = '/home/koosk/Data-linux/images/stack_images/tissues/20170915_human/tissue015.tif';
% traindataFolder = '/home/koosk/work/traindata/human/20170915';
% inputStackPath = '/home/koosk/Data-linux/images/stack_images/tissues/20170915_human/tissue003.tif';
% traindataFolder = '/home/koosk/work/traindata/human/20170915';
inputStackPath = '/home/koosk/Data-linux/images/stack_images/tissues/20170915_human/tissue025.tif';
traindataFolder = '/home/koosk/work/traindata/human/20170915';

resultFolder = '/home/koosk/Data-linux/tmp/trainer_images';
extension = '.png';
lineWidth = 3;
sliceDifference = 3; % on how many slices to put the bounding box from the center Z value
positiveColor = 'green';
negativeColor = 'red';
otherColor = 'yellow';


POSITIVE_LABEL = Manual3DTrainerModel.POSITIVE_LABEL;
DEADCELL_LABEL = Manual3DTrainerModel.NEGATIVE_LABEL;
OTHER_LABEL = Manual3DTrainerModel.OTHER_LABEL;

imgstack = ImageStack.load(inputStackPath);
[folder, fname, ~] = fileparts(inputStackPath);
folderParts = strsplit(folder, filesep);
stack = imgstack.getStack();
[sy, sx, sz] = size(stack);
resultStack = cell(sz,1);
for iStack = 1:sz
    resultStack{iStack} = cat(3, stack(:,:,iStack), stack(:,:,iStack), stack(:,:,iStack));
end
trainerData = load(fullfile(traindataFolder, [fname,'.mat']));

resultFolderPath = fullfile(resultFolder, folderParts{end}, fname);
mkdir(resultFolderPath);

labelCtr = 0;
for iLabel = 1:numel(trainerData.label)
    switch trainerData.label(iLabel)
        case POSITIVE_LABEL
            color = positiveColor;
        case DEADCELL_LABEL
            color = negativeColor;
        case OTHER_LABEL
            color = otherColor;
        otherwise
            continue
    end
    labelCtr = labelCtr + 1;
    objectRegion = [trainerData.segmentedIndices(iLabel,1), ...
                    trainerData.segmentedIndices(iLabel,2), ...
                    trainerData.segmentedIndices(iLabel,3) - trainerData.segmentedIndices(iLabel,1), ...
                    trainerData.segmentedIndices(iLabel,4) - trainerData.segmentedIndices(iLabel,2)];
    zLimits = [max(1,trainerData.segmentedIndices(iLabel,5)-sliceDifference), min(sz, trainerData.segmentedIndices(iLabel,5)+sliceDifference)];
    for zPos = zLimits(1):zLimits(2)
        resultStack{zPos} = ...
            insertShape(resultStack{zPos}, 'Rectangle', objectRegion, 'Color', color, 'LineWidth', lineWidth);
    end
end

for iStack = 1:sz
    resultFpath = fullfile(resultFolderPath, ['slice_', sprintf('%03d',iStack), extension]);
    imwrite(resultStack{iStack}, resultFpath);
end
