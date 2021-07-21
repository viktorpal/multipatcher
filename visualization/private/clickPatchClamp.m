function clickPatchClamp(~, ~, handles, approachOnly)
%CLICKPATCHCLAMP Move pipette and start patch clamping
%   This function calculates the required (smart) pipette movement to the clicked
%   position, performs almost every of them but the last which should be a
%   forward movement in the pipette's X direction. Instead, the last
%   movement is a 'blind patch-clamp' operation.

if nargin < 4
    approachOnly = false;
end

model = get(handles.mainfigure, 'UserData');
if isempty(model.sampleTop)
    errordlg('The sample''s top position is not defined. Targeted patch-clamping is not allowed until it is set!', ...
            'Patch clamping error');
	return
end

if get(handles.liveViewButton, 'Value')
    pt = get(handles.mainaxes, 'CurrentPoint');
    pt = pt(1,:);
    ptStageCoord = model.microscope.getStagePosition() + [1, -1, 1] .* pt .* [model.microscope.pixelSizeX, ...
                                                                              model.microscope.pixelSizeY, ...
                                                                              0];
    log4m.getLogger.debug(['Starting targeted patch-clamping caused by click in live view at ', num2str(ptStageCoord), ...
        ', pixel positions xy: ', num2str(pt(1)), ', ', num2str(pt(2))]);
else % stack mode
    %% not tested and not sure if it should be supported
%     warndlg(warningstring,dlgname, 'modal');
    if strcmp(get(handles.mainaxes, 'Visible'), 'off')
        return
    end

    pt = get(handles.mainaxes, 'CurrentPoint');
    pt = pt(1,:);

    ptStageCoord = [model.imgstack.meta.stageX, model.imgstack.meta.stageY, model.imgstack.meta.stageZ];
    ptStageCoord = ptStageCoord + [1, -1, 1] .*(pt - [0 0 1]) .* [model.imgstack.meta.pixelSizeX, ...
                                                                  model.imgstack.meta.pixelSizeY, ...
                                                                  model.imgstack.meta.pixelSizeZ];
    log4m.getLogger.trace(['Starting targeted patch-clamping caused by click in stack at ', num2str(ptStageCoord)]);
end

if ptStageCoord(3) > model.sampleTop
    warndlg(['The target location is detected to be above the sample''s top location. ', ...
        'Patch clamping will be performed there, but success is not likely'], 'Warning');
end

if ~isempty(model.trackerPositionUpdateListener) && ishandle(model.trackerPositionUpdateListener)
    delete(model.trackerPositionUpdateListener);
end
deleteHandles(model.trackerBoxHandles);
model.trackerBoxHandles = [];
startBlindPatcherIfNotRunning(handles);
drawnow;
startVPControlIfNotRunning(handles);
drawnow;
startLiveViewIfNotRunning(handles);
pipetteId = model.autopatcher.activePipetteId;
model.trackerPositionUpdateListener = model.visualPatcher.tracker.addlistener('PositionUpdate', ...
    @(src,event) trackerPositionUpdateListenerCallback(src,event,handles));
model.visualPatcher.start(ptStageCoord, model.sampleTop, 'pipetteId', pipetteId, 'approachOnly', approachOnly);

end