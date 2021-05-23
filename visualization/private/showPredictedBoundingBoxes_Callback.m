function showPredictedBoundingBoxes_Callback(handles)
% AUTHOR:	Krisztian Koos, Tamas Balassa
% DATE: 	Sept 19, 2017
% NAME: 	showPredictedBoundingBoxes_Callback
% 
% This callback is called when the Predict Stack button is pressed on the
% visualisation tool figure. It is used to perform the prediction and
% bounding box visualisation on the loaded stack.
%

model = get(handles.mainfigure, 'UserData');
if isempty(model.stackPredictionBoxes)
    return;
end

deleteHandles(model.stackPredictionBoxesHandles);
model.stackPredictionBoxesHandles = [];

for i=1:size(model.stackPredictionBoxes,2)
    if model.stackPredictionBoxes(i).z ~= model.zslice
       continue;
    end
    if isempty(model.stackPredictionSelectedIndex) || model.stackPredictionSelectedIndex ~= i
       lineStyle = '-';
    else
       lineStyle = '--';
    end

    props = model.stackPredictionBoxes(i);
    model.stackPredictionBoxesHandles(end+1) = rectangle('Position',[props.BoundingBox(1), ...
        props.BoundingBox(2),props.BoundingBox(3),props.BoundingBox(4)], 'EdgeColor',[props.color 0 1],'LineWidth', 2, ...
        'LineStyle', lineStyle, 'Parent', handles.mainaxes);
    
    strMinMaxMean = [num2str(props.ProbabilityMin, '%0.2f'), '; ' num2str(props.ProbabilityMax, '%0.2f'), '; ', num2str(props.ProbabilityMean, '%0.2f')];
    model.stackPredictionBoxesHandles(end+1) = text(props.BoundingBox(1), props.BoundingBox(2)+10, strMinMaxMean, 'Parent', handles.mainaxes);
end