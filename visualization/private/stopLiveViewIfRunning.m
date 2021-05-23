function stopLiveViewIfRunning(handles, force)
if get(handles.liveViewButton, 'Value') || (nargin > 1 && force)
    stopLiveView(handles);
end

function stopLiveView(handles)
log4m.getLogger().trace('Stopping live view');
model = get(handles.mainfigure, 'UserData');
stop(model.liveViewTimer);
set(handles.liveViewButton, 'Value', 0);
delete(model.imgHandle);

stopLivePrediction(handles, true);

set(handles.mainaxes, 'Visible', 'off');
set(handles.mainaxes, 'HitTest', 'off');
set(handles.zsliceText, 'Visible', 'off');
cla(handles.mainaxes);
stop(model.zlevelTimer);
