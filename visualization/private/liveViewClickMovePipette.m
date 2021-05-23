function liveViewClickMovePipette( handles )

pt = get(handles.mainaxes, 'CurrentPoint');
pt = pt(1,:);
log4m.getLogger.trace(['Calculating pipette movement caused by click in live view at ', num2str(pt)]);

model = get(handles.mainfigure, 'UserData');
ptStageCoord = model.microscope.getStagePosition() + [1, -1, 1] .* pt .* [model.microscope.pixelSizeX, ...
                                                                          model.microscope.pixelSizeY, ...
                                                                          0];
pipette = model.microscope.getPipette(model.activePipetteID);
newPipetteCoord = pipette.microscope2pipette(ptStageCoord, 'absolute');
if strcmp(handles.ignoreSampleTopMenuItem.Checked, 'on')
    pipette.moveTo(newPipetteCoord(1), newPipetteCoord(2), newPipetteCoord(3));
else
    pipette.smartMoveTo(newPipetteCoord(1), newPipetteCoord(2), newPipetteCoord(3), model.sampleTop);
end

end

