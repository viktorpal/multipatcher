function trainer_findCells(trainerModel)
%TRAINER_FINDCELLS Predict cells and add to Trainer structure for visualization
%   This function uses the deep learning prediction loaded with the configuration.

vistoolModel = trainerModel.mainWindowGuiModel;
wbh = waitbar(0, 'Predicting image stack...');
cells = predictStack(vistoolModel.imgstack, vistoolModel.generalParameters, @(x) waitbar(x, wbh));
close(wbh);

trainerModel.segmentedIndices = [];
for i = 1:numel(cells)
    if cells(i).color ~= 1
        continue
    end
    top = round(cells(i).BoundingBox(2));
    left = round(cells(i).BoundingBox(1));
    right = left + cells(i).BoundingBox(3);
    bot = top + cells(i).BoundingBox(4);
    trainerModel.segmentedIndices(end+1,:) = [left, top, right, bot, cells(i).z];
end
trainerModel.label = repmat(Manual3DTrainerModel.POSITIVE_LABEL, size(trainerModel.segmentedIndices,1), 1);
if numel(cells) > 0
    trainerModel.currentIndexToShow = 1;
end

end

