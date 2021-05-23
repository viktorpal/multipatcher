function trackerPositionUpdateListenerCallback(src, ~, handles)
%TRACKERPOSITIONUPDATELISTENERCALLBACK
%

model = get(handles.mainfigure, 'UserData');
deleteHandles(model.trackerBoxHandles);
model.trackerBoxHandles = src.drawOnAxis(handles.mainaxes);

end