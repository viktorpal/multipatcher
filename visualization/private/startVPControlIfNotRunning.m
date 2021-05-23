function startVPControlIfNotRunning(handles)
%STARTVPCONTROLIFNOTRUNNING Start Visual Patcher Controller app if not running already
%   Starts Visuap Patcher Control mlapp or brings it to focus if it is already running.

model = get(handles.mainfigure, 'UserData');

%% load/popup Visual Patcher Control
vph = model.visualPatcherControl;
if isempty(vph) || ~isvalid(vph) || ~isa(vph, 'VisualPatcherControl')  || ~ishandle(vph.VisualPatcherControlUIFigure) ...
        || ~strcmp(get(vph.VisualPatcherControlUIFigure, 'type'), 'figure')
    vph = VisualPatcherControl;
    vph.initialize(model.visualPatcher, @(position) saveVisualPatcherControlPosition(model, position));
    vph.moveToPosition(model.visualPatcherControlPosition);
    model.visualPatcherControl = vph;
end
vph.VisualPatcherControlUIFigure.Visible = 'on';
drawnow;

%% load/popup PatchClampDiary first
dgh = model.diaryGui;
if isempty(dgh) || ~isvalid(dgh) || ~isa(dgh, 'DiaryGui')  || ~ishandle(dgh.PatchClampDiaryUIFigure) ...
        || ~strcmp(get(dgh.PatchClampDiaryUIFigure, 'type'), 'figure')
    dgh = DiaryGui;
    dgh.initialize(model.visualPatcher.diary, model.microscope, @(position) saveDiaryGuiPosition(model, position));
    dgh.moveToPosition(model.diaryGuiPosition);
    model.diaryGui = dgh;
end
% dgh.PatchClampDiaryUIFigure.Visible = 'off';
% dgh.PatchClampDiaryUIFigure.Visible = 'on';
drawnow;
end

function saveVisualPatcherControlPosition(model, position)
    model.visualPatcherControlPosition = position;
end

function saveDiaryGuiPosition(model, position)
    model.diaryGuiPosition = position;
end

