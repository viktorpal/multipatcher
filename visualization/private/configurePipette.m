function configurePipette(handles)
%CONFIGUREPIPETTE Pipette configuration by user clicks
%   

dialogName = 'Pipette Configuration';
model = get(handles.mainfigure, 'UserData');
pipette = model.microscope.getPipette(model.autopatcher.activePipetteId);
stage = model.microscope.stage;

%% movements
h = msgbox('Bring the pipette nearly to focus, click on the tip and press OK!', dialogName, 'help');
uiwait(h);
centerTurretPos = model.microscope.getStagePosition();
centerPipettePositionPx = get(handles.mainaxes, 'CurrentPoint');
centerPipettePosition = pipette.getPosition();
h = msgbox(['Move the pipette about 100 microns in the y direction left (based on where the pipette ', ...
    'points), keep it in the screen and click on the tip! Click OK when done.'], dialogName, 'help');
uiwait(h);
leftTurretPos = model.microscope.getStagePosition();
leftPipettePosition = pipette.getPosition();
model.microscope.moveStageTo(centerTurretPos(1), centerTurretPos(2), centerTurretPos(3));
leftPipettePositionPx = get(handles.mainaxes, 'CurrentPoint');
pipette.moveTo(centerPipettePosition(1), centerPipettePosition(2), centerPipettePosition(3));
h = msgbox('Move the pipette about 100 microns upwards, keep the focus and click the tip! Click OK when done.', ...
    dialogName, 'help');
uiwait(h);
upTurretPos = model.microscope.getStagePosition();
upPipettePosition = pipette.getPosition();
pipette.moveTo(centerPipettePosition(1), centerPipettePosition(2), centerPipettePosition(3));
pipette.waitForFinished();
model.microscope.moveStageTo([], [], centerTurretPos(3));
model.microscope.stage.waitForFinishedZ();
model.microscope.moveStageTo(centerTurretPos(1), centerTurretPos(2), []);
upPipettePositionPx = get(handles.mainaxes, 'CurrentPoint');
h = msgbox('Finally, move the pipette about 100 microns forward, keep the focus and click the tip! Click OK when done.', ...
    dialogName, 'help');
uiwait(h);
forwardTurretPos = model.microscope.getStagePosition();
forwardPipettePosition = pipette.getPosition();
model.microscope.moveStageTo(centerTurretPos(1), centerTurretPos(2), centerTurretPos(3));
pipette.moveTo(centerPipettePosition(1), centerPipettePosition(2), centerPipettePosition(3));
forwardPipettePositionPx = get(handles.mainaxes, 'CurrentPoint');

%% calculations
pipette.focusPosition = [centerPipettePosition(1), centerPipettePosition(2), centerPipettePosition(3)];
% centerTurretPos
tx = centerTurretPos(1) + centerPipettePositionPx(1,1)*model.microscope.pixelSizeX;
ty = centerTurretPos(2) - centerPipettePositionPx(1,2)*model.microscope.pixelSizeY;
tz = centerTurretPos(3);
pipette.focusTurretPosition = [tx, ty, tz];

forwardFocusPosition = forwardTurretPos ...
    + [1, -1, 0] .* forwardPipettePositionPx(1,:) .* [model.microscope.pixelSizeX, model.microscope.pixelSizeY, 0];
leftFocusPosition = leftTurretPos ...
    + [1, -1, 0] .* leftPipettePositionPx(1,:) .* [model.microscope.pixelSizeX, model.microscope.pixelSizeY, 0];
upFocusPosition = upTurretPos ...
    + [1, -1, 0] .* upPipettePositionPx(1,:) .* [model.microscope.pixelSizeX, model.microscope.pixelSizeY, 0];
forwardVector = forwardFocusPosition - pipette.focusTurretPosition;
leftVector = leftFocusPosition - pipette.focusTurretPosition;
upVector = upFocusPosition - pipette.focusTurretPosition;
pipette.setXAnglesFromVector(forwardVector);
pipette.setYAnglesFromVector(leftVector);
pipette.setZAnglesFromVector(upVector);
if centerPipettePosition(1) > forwardPipettePosition(1)
    pipette.x_forward = -1;
else
    pipette.x_forward = 1;
end
if centerPipettePosition(2) > leftPipettePosition(2)
    pipette.y_forward = -1;
else
    pipette.y_forward = 1;
end
if centerPipettePosition(3) > upPipettePosition(3)
    pipette.z_forward = -1;
else
    pipette.z_forward = 1;
end

stage.waitForFinished();
pipette.waitForFinished();
msgbox('Pipette configuration finished!', 'Pipette Configuration', 'help')

end

