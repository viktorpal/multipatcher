function stopLivePrediction(handles, force)
% AUTHOR:	Tamas Balassa
% DATE: 	Aug 28, 2017
% NAME: 	stopLivePrediction
% 
% This function stops the timer for the live prediction. 
% (The timer starts the actual prediction that is drawn on the live image.)
%

if get(handles.livePredictionButton, 'Value') || (nargin > 1 && force)
    stopPrediction(handles);
    set(handles.livePredictionButton, 'Value', 0);
end

function stopPrediction(handles)
% function for stopping the timer

log4m.getLogger().trace('Stopping live prediction');
model = get(handles.mainfigure, 'UserData');
stop(model.livePredictionTimer);
deleteHandles(model.boundingBoxesHandle);
model.boundingBoxesHandle = [];

