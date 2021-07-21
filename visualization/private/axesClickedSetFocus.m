function axesClickedSetFocus( handles )
%AXESCLICKEDSETFOCUS Set pipette focus position at click
%   

model = get(handles.mainfigure, 'UserData');
isLiveView = get(handles.liveViewButton, 'Value');
if isempty(model.imgHandle) || ~ishandle(model.imgHandle)
    set(handles.setFocusBtn, 'Value', 0);
    return
end
if isLiveView
    set(handles.setFocusBtn, 'Value', 0);
    turretPos = model.microscope.getStagePosition();
    pipettePosPx = get(handles.mainaxes, 'CurrentPoint');
    focusTurretPosition = turretPos + [1, -1, 0] .* pipettePosPx(1,:) ...
        .* [model.microscope.pixelSizeX, model.microscope.pixelSizeY, 0];
    pipette = model.microscope.getPipette(model.autopatcher.activePipetteId);
    pipette.focusTurretPosition = focusTurretPosition;
    pipette.focusPosition = pipette.getPosition();
else
    pt = get(handles.mainaxes, 'CurrentPoint');
    set(handles.setFocusBtn, 'Value', 0);
    pt1 = pt(1,:);
    pt2 = pt(2,:);
    ptNorm = pt2 - pt1;
    sliceIntersection = model.graphics.zslice-1;
    lineT = (sliceIntersection-pt1(3))/ptNorm(3);
    ptIntersection = (pt1 + lineT*ptNorm) + [0 0 1];
    ptIntersection(2) = model.imgstack.meta.height - ptIntersection(2);

    model.focusData.focusPosition = ptIntersection;
    turretPos = [model.imgstack.meta.stageX, ...
                 model.imgstack.meta.stageY, ...
                 model.imgstack.meta.stageZ];
    focusTurretPos = turretPos + ptIntersection .* [model.imgstack.meta.pixelSizeX, ...
                                                    model.imgstack.meta.pixelSizeY, ...
                                                    model.imgstack.meta.pixelSizeZ];
    pipette = model.microscope.getPipette(model.autopatcher.activePipetteId);
    pipette.focusTurretPosition = focusTurretPos;
    pipette.focusPosition = [model.imgstack.meta.pipette1X, ...
                             model.imgstack.meta.pipette1Y, ...
                             model.imgstack.meta.pipette1Z];
end

end
