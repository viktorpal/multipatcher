function startLivePrediction(handles, force)
% AUTHOR:	Tamas Balassa
% DATE: 	Aug 25, 2017
% NAME: 	startLivePrediction
% 
% This function starts the timer for the live prediction. (The timer starts
% the actual prediction that is drawn on the live image.)
% 

if ~get(handles.livePredictionButton, 'Value') || (nargin > 1 && force) 
    startPrediction(handles);
    set(handles.livePredictionButton, 'Value', 1);
end

function startPrediction(handles)
% function for starting the timer

log4m.getLogger().trace('Starting live prediction');
model = get(handles.mainfigure, 'UserData');
start(model.livePredictionTimer);