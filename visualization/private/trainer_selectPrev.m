function trainer_selectPrev( handles )
%TRAINER_SELECTPREV Select previous segmentation

model = get(handles.mainfigure, 'UserData');
if isempty(model.segmentedIndices)
    errordlg('No segmentation data to show! Load or segment first, or check if it is empty!', 'Error', 'modal');
    return
end
if isempty(model.currentIndexToShow)
    model.currentIndexToShow = size(model.segmentedIndices, 1);
elseif model.currentIndexToShow > 1
    model.currentIndexToShow = model.currentIndexToShow - 1;
else
    msgbox('No more indices, starting from the last.', 'Starting over', 'modal');
    model.currentIndexToShow = size(model.segmentedIndices, 1);
end

end

