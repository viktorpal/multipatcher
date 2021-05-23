function trainer_deleteSelectedBox(model)
%TRAINER_DELETESELECTEDBOX Summary of this function goes here
%   model - Manual3DTrainerModel object

idx = model.currentIndexToShow;
if ~isempty(idx)
    idxShown = model.currentIndexToShow;
    if numel(model.label) ~= 1
        model.label = [model.label(1:idx-1); model.label(idx+1:end)];
    else
        model.label = [];
    end
    model.segmentedIndices = [model.segmentedIndices(1:idx-1,:); model.segmentedIndices(idx+1:end,:)];
    numRegions = size(model.segmentedIndices,1);
    if numRegions > 0
        if idxShown > 1
            model.currentIndexToShow = idxShown - 1;% redraws boxes
        else
            model.currentIndexToShow = 1;
        end
    else
        model.currentIndexToShow = [];
    end
end

end

