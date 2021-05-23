function startLiveViewIfNotRunning(handles, force)
if ~get(handles.liveViewButton, 'Value') || (nargin > 1 && force) 
    startLiveView(handles);
    set(handles.liveViewButton, 'Value', true);
end

function startLiveView(handles)
log4m.getLogger().trace('Starting live view');
set(handles.mainaxes, 'Visible', 'on');
set(handles.mainaxes, 'HitTest', 'on');
set(handles.zSlider, 'Visible', 'off');
set(handles.zsliceText, 'Visible', 'on');
model = get(handles.mainfigure, 'UserData');
[w, h] = model.microscope.camera.getResolution();
delete(model.imgHandle);
cla(handles.mainaxes);
model.imgHandle = imshow(zeros(h,w), 'Parent', handles.mainaxes);
axis(handles.mainaxes, 'image');
set(model.imgHandle, 'HitTest', 'off');
start(model.liveViewTimer);
start(model.zlevelTimer);