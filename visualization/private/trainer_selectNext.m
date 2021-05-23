function trainer_selectNext( handles )
%TRAINER_SELECTNEXT Select next segmentation

model = get(handles.mainfigure, 'UserData');
if isempty(model.segmentedIndices)
    errordlg('No segmentation data to show! Load or segment first, or check if it is empty!', 'Error', 'modal');
    return
end
if isempty(model.currentIndexToShow)
    model.currentIndexToShow = 1;
elseif model.currentIndexToShow < size(model.segmentedIndices, 1)
    model.currentIndexToShow = model.currentIndexToShow + 1;
else
    msgbox('No more indices, starting from the first.', 'Starting over', 'modal');
    model.currentIndexToShow = 1;
end

end

