function trainer_changeZposition(handles, value)
%TRAINER_CHANGEZPOSITION Change the z slice value of the selected box
%   handles - gui handles of Manual3dTrainer
%   value - relative change value, +/-1 is recommended

model = get(handles.mainfigure, 'UserData');
if ~isempty(model.currentIndexToShow)
    current = model.segmentedIndices(model.currentIndexToShow,5);
    newValue = current + value;
    if newValue < 1
        newValue = 1;
    else
        sz = size(model.mainWindowGuiModel.imgstack.getStack(), 3);
        if newValue > sz
            newValue = sz;
        end
    end
    model.segmentedIndices(model.currentIndexToShow,5) = newValue;
    model.currentIndexToShow = model.currentIndexToShow; % easy and save way of updating every gui element
else
    warndlg('No box is selected!', 'Trainer', 'modal');
end

end

