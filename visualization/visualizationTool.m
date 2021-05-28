function varargout = visualizationTool(varargin)
% VISUALIZATIONTOOL MATLAB code for visualizationTool.fig
%      VISUALIZATIONTOOL, by itself, creates a new VISUALIZATIONTOOL or raises the existing
%      singleton*.
%
%      H = VISUALIZATIONTOOL returns the handle to a new VISUALIZATIONTOOL or the handle to
%      the existing singleton*.
%
%      VISUALIZATIONTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALIZATIONTOOL.M with the given input arguments.
%
%      VISUALIZATIONTOOL('Property','Value',...) creates a new VISUALIZATIONTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before visualizationTool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to visualizationTool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help visualizationTool

% Last Modified by GUIDE v2.5 28-May-2021 08:43:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @visualizationTool_OpeningFcn, ...
                   'gui_OutputFcn',  @visualizationTool_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before visualizationTool is made visible.
function visualizationTool_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for visualizationTool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
movegui(hObject, 'northwest');

[confmodel, confobj] = Config.createFromXml(fullfile('config', 'vistool_config.xml'));
model = confmodel.modelParameters;
model.config = confobj;
set(handles.mainfigure, 'UserData', model);
cameraTimerPeriod = model.generalParameters.cameraTimerPeriod;
predictionTimerPeriod = model.generalParameters.predictionTimerPeriod;
model.liveViewTimer = timer('TimerFcn', @(obj,event) updateLiveView(obj, handles), 'ExecutionMode', 'fixedRate', ...
    'Period', cameraTimerPeriod, 'BusyMode', 'drop', 'Name', 'updateLiveView-timer');
model.livePredictionTimer = timer('TimerFcn', @(obj,event) updateLivePrediction(obj, handles), 'StartDelay', 0.01, ...
    'ExecutionMode', 'fixedRate', 'Period', predictionTimerPeriod, 'BusyMode', 'drop', 'Name', 'updateLivePrediction-timer');
createUIContextMenus(handles)
model.zsliceListener = model.addlistener('zslice', 'PostSet', @(src,event) zSliceChanged_Callback(handles));
model.predictionZsliceListener = model.addlistener('zslice', 'PostSet', ...
    @(src,event) showPredictedBoundingBoxes_Callback(handles));
model.zlevelTimer = timer('TimerFcn', @(obj,event) updateZsliceText(handles), ...
    'ExecutionMode', 'fixedRate', 'Period', 0.25, 'BusyMode', 'drop', 'Name', 'updateZsliceText-timer');
pipetteList = model.microscope.getPipetteList().keys;
handles.activePipetteId_popup.String = pipetteList;

drawnow;

%model.activepipetteid_popup = model.microscope.getPipette('pip1','pip2')

if ~isempty(model.figureOuterPosition)
    hObject.OuterPosition = model.figureOuterPosition;
end
drawnow;


% --- Outputs from this function are returned to the command line.
function varargout = visualizationTool_OutputFcn(hObject, ~, handles) %#ok<INUSL>
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close mainfigure.
function mainfigure_CloseRequestFcn(hObject, ~, handles) %#ok<DEFNU>
stopLiveViewIfRunning(handles);
try
    model = hObject.UserData;
    model.figureOuterPosition = hObject.OuterPosition;
    if ~isempty(model.visualPatcherControl) && isvalid(model.visualPatcherControl)
        model.visualPatcherControl.closeRequest();
    end
    if ~isempty(model.diaryGui) && isvalid(model.diaryGui)
        model.diaryGui.closeRequest();
    end
    model.config.save();
    delete(model);
catch ex
    log4m.getLogger().error(['Error while closing window: ', ex.message]);
end
delete(hObject);


% --- Executes on slider movement.
function zSlider_Callback(hObject, ~, handles) %#ok<DEFNU>
sliderValue = get(hObject,'Value');
sliderValue = round(sliderValue);
set(hObject, 'Value', sliderValue);
model = get(handles.mainfigure, 'UserData');
model.zslice = sliderValue;


% --- Executes on button press in setFocusBtn.
function setFocusBtn_Callback(hObject, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isempty(model.imgstack) && ~get(handles.liveViewButton, 'Value')
    warndlg('Use live mode or load a stack before using this function!', 'Warning!');
    return
end
if isempty(model.imgHandle) || ~ishandle(model.imgHandle)
    set(hObject, 'Value', 0)
end


% --- Executes on button press in liveViewButton.
function liveViewButton_Callback(hObject, ~, handles) %#ok<DEFNU>
if get(hObject,'Value')
    startLiveViewIfNotRunning(handles, true);
    if get(handles.livePredictionButton,'Value')
        startLivePrediction(handles, true);
    end
else
    stopLiveViewIfRunning(handles, true);
    model = get(handles.mainfigure, 'UserData');
    if ~isempty(model.imgstack)
%         loadGeneralImage(handles, model.imgstack);
        enableDrawArea(handles);
        showImageStack(handles)
    end
end


% --- Executes on button press in setSampleTopBtn.
function setSampleTopBtn_Callback(hObject, ~, handles) %#ok<INUSL,DEFNU>
model = get(handles.mainfigure, 'UserData');
if ~isempty(model.imgstack) || get(handles.liveViewButton, 'Value')
    setSampleTop(handles);
else
    warndlg('Use live mode or load a stack before using this function!', 'Warning!');
end


function gaussPyramidPopup_CreateFcn(hObject, ~, handles) %#ok<INUSD,DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over axes background.
function mainaxes_ButtonDownFcn(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
clickType = get(handles.mainfigure, 'SelectionType');
trainerFig = model.trainerFigure;
isLiveView = get(handles.liveViewButton, 'Value');
if get(handles.setFocusBtn, 'Value') && strcmp(clickType, 'normal')
    axesClickedSetFocus(handles);
elseif ~isLiveView && (~isempty(trainerFig) && ishandle(trainerFig) && strcmp(get(trainerFig, 'type'), 'figure')) ...
        && (strcmp(clickType, 'normal') || strcmp(clickType, 'open') || strcmp(clickType, 'alt'))
    pt = get(handles.mainaxes, 'CurrentPoint');
    pt = pt(1,1:2);
    if strcmp(clickType, 'normal') % selection 
        trainer_selectBox(trainerFig, model, pt);
    elseif strcmp(clickType, 'open') %% add new area
        trainer_addNewPositive(trainerFig, model, pt);
    else % resize box; strcmp(clickType, 'alt')
        trainer_resizeBox(handles.mainfigure, handles.mainaxes, trainerFig, model);
    end
end


function openTrainer(handles)
model = get(handles.mainfigure, 'UserData');
h = model.trainerFigure;
if isempty(h) || ~ishandle(h) || ~strcmp(get(h, 'type'), 'figure')
    if isempty(model.imgstack)
        warndlg('Load an image before starting the Trainer!', 'No image loaded!', 'modal');
        return
    end
    model.trainerFigure = Manual3DTrainer('vistoolGuiModel', model, 'ax', handles.mainaxes, 'mainFigure', handles.mainfigure);
else
    figure(h);
end


% --- Executes during object creation, after setting all properties.
function zsliceText_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
set(hObject, 'String', '');


function updateZsliceText(handles)
%UPDATEZSLICETEXT Updates the z slice or z level text element
%   In live mode, this function is called by a timer, because we cannot set an event listener to the hardware and it 
% can be modified manually.
try
    isLiveView = get(handles.liveViewButton, 'Value');
    zText = handles.zsliceText;
    model = get(handles.mainfigure, 'UserData');
    if isLiveView
        zLevel = model.microscope.stage.getZ();
        label = [num2str(zLevel), ' um'];
        if ~isempty(model.sampleTop)
            label = [label, newline,'(', num2str(zLevel-model.sampleTop), ')'];
        end
        set(zText, 'String', label);
    else
        if ~isempty(model.imgstack)
            nSlicesString = num2str(size(model.imgstack.getStack(), 3));
            if ~isempty(model.zslice)
                label = [num2str(model.zslice), '/', nSlicesString];
                try
                    zLevel = model.imgstack.meta.stageZ + (model.zslice-1)*model.imgstack.meta.pixelSizeZ;
                    if ~isempty(model.sampleTop)
                        label = [label, newline,'(', num2str(zLevel-model.sampleTop), ')'];
                    end
                catch ex %#ok<NASGU>
                end
                set(zText, 'String', label);
            else
                set(zText, 'String', ['-/', nSlicesString]);
            end
        end
    end
catch ex
    log4m.getLogger().error(['No idea why this could happen, lets find out: ', ex.message]);
end


function zSliceChanged_Callback(handles)
showImageStack(handles)
updateZsliceText(handles);


% --- Executes on scroll wheel click while the figure is in focus.
function mainfigure_WindowScrollWheelFcn(~, eventdata, handles) %#ok<DEFNU>
isLiveView = get(handles.liveViewButton, 'Value');
if ~isLiveView
    model = get(handles.mainfigure, 'UserData');
    if ~isempty(model.zslice)
        nextZslice = model.zslice - eventdata.VerticalScrollCount;
        if nextZslice > 0 && nextZslice <= size(model.imgstack.getStack(), 3)
            model.zslice = nextZslice;
        end
    end
end


function openPredictionProperties(handles)
model = get(handles.mainfigure, 'UserData');
poh = model.predictionOptionsFigure;
if isempty(poh) || ~isvalid(poh) || ~isa(poh, 'PredictionProperties')  || ~ishandle(poh.mainfigure) ...
        || ~strcmp(get(poh.mainfigure, 'type'), 'figure')
    poh = PredictionProperties('generalParameters', model.generalParameters);
    model.predictionOptionsFigure = poh;
end
poh.Visible = 'off';
poh.Visible = 'on';
drawnow;


% --- Executes on button press in livePredictionButton.
function livePredictionButton_Callback(~, ~, handles) %#ok<DEFNU>
if get(handles.livePredictionButton,'Value')
    if get(handles.liveViewButton, 'Value')
        startLivePrediction(handles, true); % second param (true) forces it
    end
else
    stopLivePrediction(handles, true);
end


% --------------------------------------------------------------------
function viewMenu_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>


% --------------------------------------------------------------------
function blindPatcherMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
startBlindPatcherIfNotRunning(handles);


% --------------------------------------------------------------------
function cleanerMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
startCleanGuiIfNotRunning(handles)


% --------------------------------------------------------------------
function pipetteMenu_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>


% --------------------------------------------------------------------
function stackMenu_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>


% --------------------------------------------------------------------
function optionsMenu_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>


% --------------------------------------------------------------------
function predictionOptionsMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
openPredictionProperties(handles);


% --------------------------------------------------------------------
function loadStackMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
try
    loadGeneralImage(handles);
catch e
    msgbox(e.message, 'Error while loading cell images', 'error')
end


% --------------------------------------------------------------------
function acquireStackMenuItem_Callback(~, ~, handles)
stopLiveViewIfRunning(handles);
acquireImageStack(handles);


% --------------------------------------------------------------------
function predictStackMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
predictStackCallback(handles);


% --------------------------------------------------------------------
function patchPredictedMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
patchPredicted(handles);


% --------------------------------------------------------------------
function showOriginalMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
if strcmp(handles.showOriginalMenuItem.Checked, 'off')
    handles.showOriginalMenuItem.Checked = 'on';
    handles.showReconstructedMenuItem.Checked = 'off';
    handles.showBgCorrectedMenuItem.Checked = 'off';
    model = get(handles.mainfigure, 'UserData');
    if ~isempty(model.imgstack)
        showImageStack(handles);
    end
end


% --------------------------------------------------------------------
function showReconstructedMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
if strcmp(handles.showReconstructedMenuItem.Checked, 'off')
    handles.showOriginalMenuItem.Checked = 'off';
    handles.showReconstructedMenuItem.Checked = 'on';
    handles.showBgCorrectedMenuItem.Checked = 'off';
    model = get(handles.mainfigure, 'UserData');
    if ~isempty(model.imgstack)
        showImageStack(handles);
    end
end


% --------------------------------------------------------------------
function showBgCorrectedMenuItem_Callback(~, ~, handles)
if strcmp(handles.showBgCorrectedMenuItem.Checked, 'off')
    handles.showOriginalMenuItem.Checked = 'off';
    handles.showReconstructedMenuItem.Checked = 'off';
    handles.showBgCorrectedMenuItem.Checked = 'on';
    model = get(handles.mainfigure, 'UserData');
    if ~isempty(model.imgstack)
        showImageStack(handles);
    end
end


% --------------------------------------------------------------------
function configurePipetteMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
startLiveViewIfNotRunning(handles);
configurePipette(handles);


% --------------------------------------------------------------------
function visualPatcherMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
startVPControlIfNotRunning(handles);


% --------------------------------------------------------------------
function trainerMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
openTrainer(handles)


% --------------------------------------------------------------------
function setFocusAtClickMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
set(handles.setFocusBtn, 'Value', 1);


% --------------------------------------------------------------------
function ignoreSampleTopMenuItem_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
if strcmp(hObject.Checked, 'on')
    hObject.Checked = 'off';
else
    hObject.Checked = 'on';
end


% --- Executes on button press in setupElectrodeBtn.
function setupElectrodeBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
model.autopatcher.setupInBath();


% --- Executes on button press in findAndPatchBtn.
function findAndPatchBtn_Callback(~, ~, handles) %#ok<DEFNU>
acquireStackMenuItem_Callback([], [], handles)
showBgCorrectedMenuItem_Callback([], [], handles)
patchPredicted(handles)


% --------------------------------------------------------------------
function resetDcamMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isa(model.microscope.camera, 'DCAMController')
    model.microscope.camera.reset();
else
    warndlg('Only DCAM cameras can be reset using this function!', 'Warning', 'modal');
end


% --------------------------------------------------------------------
function detectFocusMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
isLiveView = get(handles.liveViewButton, 'Value');
step = 1;
if isLiveView
    stopLiveViewIfRunning(handles);
    model.microscope.stage.move([], [], -30);
    while model.microscope.stage.isMovingZ()
        pause(0.1);
    end
    imgstack = model.microscope.captureStack(60, step, 'bot');
else
    warndlg('Focus detection is only supported in live mode! Bring the pipette nearly to focus in the image and try again!', ...
        'Warning');
    return
end
[x, y, z] = estimateFocusPipeline(imgstack, model.microscope.getPipette(model.activePipetteID), model.microscope.pixelSizeX);
turretPos = model.microscope.getStagePosition();
focusTurretPosition = turretPos + [1, -1, 1] .* [x, y, z*step] ...
    .* [model.microscope.pixelSizeX, model.microscope.pixelSizeY, 1];
pipette = model.microscope.getPipette(model.activePipetteID);
pipette.focusTurretPosition = focusTurretPosition;
pipette.focusPosition = pipette.getPosition();
model.microscope.stage.moveTo([],[],focusTurretPosition(3));
startLiveViewIfNotRunning(handles);
log4m.getLogger().debug(['Focus detected at (x px, y px, z turret): ', num2str(x), ', ', num2str(y), ', ', num2str(focusTurretPosition(3))]);
plot(handles.mainaxes, x, y, 'x', 'MarkerSize', 10, 'LineWidth', 2, 'color', 'red')


% --------------------------------------------------------------------
function toolsMenu_Callback(~, ~, ~) %#ok<DEFNU>


% --------------------------------------------------------------------
function captureAndSaveImage_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
img = model.microscope.camera.capture();
timestampStr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
img = mat2gray(img);
fdl = model.fileDialogLocation;
if ~isdir(fdl)
    fdl = '';
end
[fname, pathName] = uiputfile(fullfile(fdl, [timestampStr, '.png']), 'Save image');
if 0 == fname
    return
end
model.fileDialogLocation = pathName;
fullpath = fullfile(pathName, fname);
try
    imwrite(img, fullpath);
catch ex
    errordlg(['Error occurred: ', ex.message], 'Error saving image');
    log4m.getLogger().debug(['Error while saving image: ', ex.message]);
end


% --------------------------------------------------------------------
function generalOptionsMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
optionsApp = model.optionsApp;
if isempty(optionsApp) || ~isvalid(optionsApp)
    optionsApp = VisualizationToolOptions();
    optionsApp.initialize(model.generalParameters);
    model.optionsApp = optionsApp;
else
    optionsApp.VisualizationTooloptionsUIFigure.Visible = 'off';
    optionsApp.VisualizationTooloptionsUIFigure.Visible = 'on';
    drawnow;
end


% --------------------------------------------------------------------
function saveStackMenuItem_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
imgstack = model.imgstack;
if isempty(imgstack)
    warndlg('No image stack is loaded that could be saved!', 'Save stack');
    return
end
timestampStr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
fdl = model.fileDialogLocation;
if ~isdir(fdl)
    fdl = '';
end
[fname, pathName] = uiputfile(fullfile(fdl, [timestampStr, '.tif']), 'Save stack');
if 0 == fname
    return
end
model.fileDialogLocation = pathName;
fullpath = fullfile(pathName, fname);
try
    imgstack.save(fullpath);
catch ex
    errordlg(['Error occurred: ', ex.message], 'Error saving stack');
    log4m.getLogger().debug(['Error while saving stack: ', ex.message]);
end




% --- Executes on selection change in activePipetteId_popup.
function activePipetteId_popup_Callback(hObject, eventdata, handles)

model = get(handles.mainfigure, 'UserData');
contents = cellstr(get(hObject,'String'));
model.activePipetteID = str2num(contents{get(hObject,'Value')});
% hObject    handle to activePipetteId_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns activePipetteId_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from activePipetteId_popup


% --- Executes during object creation, after setting all properties.
function activePipetteId_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to activePipetteId_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text3.
function text3_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
