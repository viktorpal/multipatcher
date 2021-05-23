function setSampleTop( handles )
%SETSAMPLETOP Set sample top in the model
%   In stack mode the position of the shown z slice will be the top. In live
%   mode it is the current Z position of the microscope stage.

model = get(handles.mainfigure, 'UserData');
if get(handles.liveViewButton, 'Value')
    model.sampleTop = model.microscope.getStageZ();
else
    zslice = model.zslice-1;
    model.sampleTop = model.imgstack.meta.stageZ + zslice*model.imgstack.meta.pixelSizeZ;
end

end
