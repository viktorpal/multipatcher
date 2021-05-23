function stackClickedMovePipette(handles)

% if strcmp(get(handles.mainaxes, 'Visible'), 'off')
%     return
% end

pt = get(handles.mainaxes, 'CurrentPoint');
pt1 = pt(1,:);
pt2 = pt(2,:);
ptNorm = pt2-pt1;
model = get(handles.mainfigure, 'UserData');
sliceIntersection = model.zslice-1;
lineT = (sliceIntersection-pt1(3))/ptNorm(3);
ptIntersection = (pt1 + lineT*ptNorm) + [0 0 1];
siz = [model.imgstack.meta.height, model.imgstack.meta.width, model.imgstack.meta.D3Size];
if ptIntersection(1) < 1 || ptIntersection(1) > siz(2) || ...
        ptIntersection(2) < 1 || ptIntersection(2) > siz(1) || ...
        ptIntersection(3) < 1 || ptIntersection(3) > siz(3)
    return
end
log4m.getLogger.trace(['Calculating pipette movement caused by click in stack at ', num2str(ptIntersection)]);

ptStageCoord = [model.imgstack.meta.stageX, model.imgstack.meta.stageY, model.imgstack.meta.stageZ];
ptStageCoord = ptStageCoord + [1, -1, 1] .*(ptIntersection - [0 0 1]) .* [model.imgstack.meta.pixelSizeX, ...
                                                                          model.imgstack.meta.pixelSizeY, ...
                                                                          model.imgstack.meta.pixelSizeZ];
pipette = model.microscope.getPipette(model.activePipetteID);
newPipetteCoord = pipette.microscope2pipette(ptStageCoord, 'absolute');
if strcmp(handles.ignoreSampleTopMenuItem.Checked, 'on')
    pipette.moveTo(newPipetteCoord(1), newPipetteCoord(2), newPipetteCoord(3));
else
    pipette.smartMoveTo(newPipetteCoord(1), newPipetteCoord(2), newPipetteCoord(3), model.sampleTop);
end
ptIntersection(2) = size(model.imgstack.getStack(),1) - ptIntersection(2);
% visualizePipette(handles, ptIntersection);

end