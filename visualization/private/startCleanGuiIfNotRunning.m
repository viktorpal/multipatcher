function startCleanGuiIfNotRunning(handles)
%STARTCLEANGUIIFNOTRUNNING Summary of this function goes here
%   Detailed explanation goes here

model = get(handles.mainfigure, 'UserData');

%% load/popup PatchClampDiary first
cgh = model.cleanGui;
if isempty(cgh) || ~isvalid(cgh) || ~isa(cgh, 'CleanGUI')  || ~ishandle(cgh.CleanGUIUIFigure) ...
        || ~strcmp(get(cgh.CleanGUIUIFigure, 'type'), 'figure')
    cgh = CleanGUI;
    cgh.initialize(model.pipetteCleaner);
    model.cleanGui = cgh;
end
cgh.CleanGUIUIFigure.Visible = 'off';
cgh.CleanGUIUIFigure.Visible = 'on';
drawnow;

end

