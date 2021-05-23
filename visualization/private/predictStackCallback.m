function predictStackCallback(handles)
%PREDICTSTACKCALLBACK Stack prediction with status bar

model = get(handles.mainfigure, 'UserData');
wbh = waitbar(0, 'Predicting image stack...');
cells = predictStack(model.imgstack, model.generalParameters, @(x) waitbar(x, wbh));
model.stackPredictionBoxes = cells;
model.stackPredictionSelectedIndex = [];
model.zslice = model.zslice;
close(wbh);

end

