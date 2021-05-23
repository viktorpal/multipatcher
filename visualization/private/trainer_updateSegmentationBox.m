function trainer_updateSegmentationBox(handles)
model = get(handles.mainfigure, 'UserData');
if ~isempty(model.boxHandlers)
    cellfun(@delete, model.boxHandlers)
end
if ~isempty(model.currentIndexToShow)
    model.boxHandlers = cell(size(model.segmentedIndices,1),1);
    vistoolModel = model.mainWindowGuiModel;
    zSliceShown = vistoolModel.zslice;
    for i = 1:size(model.segmentedIndices, 1)
        idx = model.segmentedIndices(i,:);
        if i == model.currentIndexToShow
            isActive = true;
        else
            isActive = false;
        end
        switch model.label(i)
            case model.UNLABELED
                color = model.unlabeledColor;
            case model.POSITIVE_LABEL
                color = model.positiveColor;
            case model.NEGATIVE_LABEL
                color = model.negativeColor;
            case model.OTHER_LABEL
                color = model.otherColor;
            otherwise
                color = [1, 1, 1];
        end
        model.boxHandlers(i) = {trainer_showSegmentationBox(model.ax, idx, zSliceShown, model.boxSize(3), color, isActive)};
    end
end