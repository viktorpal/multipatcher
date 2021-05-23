function varargout = BlindPatcherGui(varargin)
% BLINDPATCHERGUI MATLAB code for BlindPatcherGui.fig
%      BLINDPATCHERGUI, by itself, creates a new BLINDPATCHERGUI or raises the existing
%      singleton*.
%
%      H = BLINDPATCHERGUI returns the handle to a new BLINDPATCHERGUI or the handle to
%      the existing singleton*.
%
%      BLINDPATCHERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BLINDPATCHERGUI.M with the given input arguments.
%
%      BLINDPATCHERGUI('Property','Value',...) creates a new BLINDPATCHERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BlindPatcherGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BlindPatcherGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BlindPatcherGui

% Last Modified by GUIDE v2.5 03-Jan-2018 15:33:11


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BlindPatcherGui_OpeningFcn, ...
                   'gui_OutputFcn',  @BlindPatcherGui_OutputFcn, ...
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


% --- Executes just before BlindPatcherGui is made visible.
function BlindPatcherGui_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

p = inputParser;
defaultConfigFile = 'blindpatcher_config.xml';

addParameter(p, 'autopatcher', [], @(x) isempty(x) || isa(x, 'AutoPatcher'));
addParameter(p, 'rsImprover', [], @(x) isempty(x) || isa(x, 'RSImprover'));
addParameter(p, 'configFile', defaultConfigFile, @ischar);
addParameter(p, 'predefinedVariables', []);
addParameter(p, 'trackPredefined', []);
addParameter(p, 'restriction', []);
addParameter(p, 'restrictionIsExclusion', []);
parse(p, varargin{:});

autopatcher = p.Results.autopatcher;
rsImprover = p.Results.rsImprover;
configFile = p.Results.configFile;
predefinedVariables = p.Results.predefinedVariables;
trackPredefined = p.Results.trackPredefined;
restriction = p.Results.restriction;
restrictionIsExclusion = p.Results.restrictionIsExclusion;

if (isempty(autopatcher) && ~isempty(rsImprover)) || (~isempty(autopatcher) && isempty(rsImprover))
    error('AutoPatcher and RSImprover have to be defined together.');
end

if ~isempty(autopatcher)
%     if isempty(model)
%         model = BlindPatcherGuiModel();
%     end
%     model.autopatcher = autopatcher;
%     model.rsImprover = rsImprover;
    trackPredefined = false;
    restriction = {'blindPatcherGuiModel'};
    restrictionIsExclusion = false;
    predefinedVariables = {'autopatcher', autopatcher; ...
                           'rsImprover', rsImprover};
    [confmodel, confobj] = Config.createFromXml(fullfile('config', configFile), predefinedVariables, trackPredefined, ...
        restriction, restrictionIsExclusion);
    model = confmodel.blindPatcherGuiModel;
    model.isOwnerOfObjects = false;
    model.config = confobj;
else
    [confmodel, confobj] = Config.createFromXml(fullfile('config', configFile), predefinedVariables, trackPredefined, ...
        restriction, restrictionIsExclusion);
    model = confmodel.blindPatcherGuiModel;
    model.config = confobj;
%     model.autopatcher = confmodel.autopatcher;
%     model.rsImprover = confmodel.rsImprover;
end

ap = model.autopatcher;
model.setSecondsToShow(BlindPatcherGuiModel.defaultSecondsToShow);
set(handles.secondsToShow, 'String', num2str(BlindPatcherGuiModel.defaultSecondsToShow));
set(handles.resistanceAxes, 'XLim', [1 numel(model.resistanceHistory)]);
set(handles.mainfigure, 'UserData', model);
model.elphysListener = ap.elphysProcessor.addlistener('DataChange', @(src,event) elphysDataChangeCallback(handles));
model.pressureListener = ap.pressureController.addlistener('DataChange', @(src,event) pressureDataChangeCallback(handles));
set(handles.desiredResistanceInput, 'String', num2str(model.rsImprover.desiredResistance));
model.breakInResistanceListener = ap.elphysProcessor.addlistener('calculateBreakInResistance', 'PostSet', ...
    @(src, event) calculateBreakInResistanceValueChangeCb(src, event, handles));
model.pressureStatusListener = ap.pressureController.addlistener('state', 'PostSet', ...
    @(src, event) pressureStatusChangeCb(src, event, handles));
model.autopatcherStatusListener = ap.addlistener('status', 'PostSet', ...
    @(src, event) autopatcherStatusChangeCb(src, event, handles));
model.autopatcherMessageListener = ap.addlistener('message', 'PostSet', ...
    @(src, event) autopatcherMessageChangeCb(src, event, handles));
model.rsiListener = model.rsImprover.addlistener('status', 'PostSet', ...
    @(src,event) rsImproverStatusChangeCb(src,event,handles));
if ~isempty(model.figureOuterPosition)
    hObject.OuterPosition = model.figureOuterPosition;
end
drawnow;


% --- Outputs from this function are returned to the command line.
function varargout = BlindPatcherGui_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;
if nargout == 2
    varargout{2} = get(handles.mainfigure, 'UserData');
end


function mainfigure_CloseRequestFcn(hObject, ~, handles) %#ok<DEFNU>
try
    model = get(handles.mainfigure, 'UserData');
    model.figureOuterPosition = hObject.OuterPosition;
    if ~isempty(model.config)
        model.config.save();
    end
    delete(model);
catch ex
    log4m.getLogger().error(['Error while closing window: ', ex.message]);
end
delete(hObject);


function elphysDataChangeCallback(handles)
model = get(handles.mainfigure, 'UserData');
resistance = model.autopatcher.elphysProcessor.resistance;
model.resistanceHistory = [model.resistanceHistory(2:end), resistance];
plot(handles.resistanceAxes, model.resistanceHistory);
if ~isnan(resistance)
    set(handles.resistanceText, 'String', sprintf('%0.2f', round(resistance*100)/100));
else
    set(handles.resistanceText, 'String', '-');
end
set(handles.currentText, 'String', sprintf('%0.4f', model.autopatcher.elphysProcessor.current));


function pressureDataChangeCallback(handles)
model = get(handles.mainfigure, 'UserData');
model.pressureHistory = [model.pressureHistory(2:end), model.autopatcher.pressureController.getPressure()];
pressure = model.autopatcher.pressureController.getPressure();
if pressure >=0
    pressure = floor(pressure);
else
    pressure = ceil(pressure);
end
set(handles.pressureText, 'String', num2str(pressure));


function calculateBreakInResistanceValueChangeCb(~, event, handles)
set(handles.calculateBreakInResistanceCbx, 'Value', event.AffectedObject.calculateBreakInResistance);


function pressureStatusChangeCb(~, event, handles)
set(handles.pressureStatusText, 'String', char(event.AffectedObject.state));


function autopatcherStatusChangeCb(~, event, handles)
set(handles.autopatcherStatusText, 'String', char(event.AffectedObject.status));


function autopatcherMessageChangeCb(~, event, handles)
set(handles.autopatcherMessageText, 'String', char(event.AffectedObject.message));


function secondsToShow_Callback(hObject, ~, handles) %#ok<DEFNU>
value = str2double(get(hObject,'String'));

if isnan(value)
    set(hObject, 'String', '#');
elseif value <= 0
    set(hObject, 'String', '>0');
else
    model = get(handles.mainfigure, 'UserData');
    model.setSecondsToShow(value);
    set(handles.resistanceAxes, 'XLim', [1 numel(model.resistanceHistory)]);
end


% --- Executes during object creation, after setting all properties.
function secondsToShow_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function startBlindPatchButton_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if model.rsImprover.isRunning()
    warndlg('Cannot start autopatching while RS Improver is running!', 'Warning!');
    return
end
if model.autopatcher.isRunning()
    warndlg('Autopatcher is already running!', 'Warning!');
    return
end
model.autopatcher.start();


function stopBlindPatchButton_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if model.autopatcher.isRunning()
    model.autopatcher.stop();
end
if model.rsImprover.isRunning()
    model.rsImprover.stop();
end


function requestedPressureValue_Callback(hObject, ~, handles) %#ok<DEFNU>
value = str2double(get(hObject,'String'));
if ~isnan(value)
    model = get(handles.mainfigure, 'UserData');
    model.autopatcher.pressureController.setPressure(value);
else
    set(hObject, 'String', '#');
end


function requestedPressureValue_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function inBathBtn_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
model = get(handles.mainfigure, 'UserData');
model.autopatcher.setupInBath();


% --- Executes on button press in rsImproverStartBtn.
function rsImproverStartBtn_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
model = get(handles.mainfigure, 'UserData');
if ~model.rsImprover.isRunning()
    if model.autopatcher.isRunning()
        warndlg('Cannot start RS Improver while Autopatcher is running!', 'Warning');
        return
    end
    set(handles.rsImproverStatusText, 'String', 'running');
    model.rsImprover.start();
else
    model.rsImprover.stop();
end


function rsImproverStatusChangeCb(~, ~, handles)
model = get(handles.mainfigure, 'UserData');
set(handles.rsImproverStatusText, 'String', model.rsImprover.status);
if model.rsImprover.isRunning()
    set(handles.rsImproverStartBtn, 'String', 'Stop');
else
    set(handles.rsImproverStartBtn, 'String', 'Start');
end


% --- Executes on button press in calculateBreakInResistanceCbx.
function calculateBreakInResistanceCbx_Callback(hObject, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if get(hObject,'Value')
    model.autopatcher.elphysProcessor.requestBreakInResistance();
else
    model.autopatcher.elphysProcessor.disableBreakInResistance();
end


function applyHighNegativePressureBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
value = model.autopatcher.highNegativePressure;
model.autopatcher.pressureController.setPressure(value);
set(handles.requestedPressureValue, 'String', num2str(value));


function applyLowNegativePressureBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
value = model.autopatcher.lowNegativePressure;
model.autopatcher.pressureController.setPressure(value);
set(handles.requestedPressureValue, 'String', num2str(value));


function applyHighPositivePressureBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
value = model.autopatcher.highPositivePressure;
model.autopatcher.pressureController.setPressure(value);
set(handles.requestedPressureValue, 'String', num2str(value));


function applyLowPositivePressureBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
value = model.autopatcher.lowPositivePressure;
model.autopatcher.pressureController.setPressure(value);
set(handles.requestedPressureValue, 'String', num2str(value));


function atmosphereBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
model.autopatcher.pressureController.setPressure(0);
set(handles.requestedPressureValue, 'String', num2str(0));


function startFromBreakInBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if model.rsImprover.isRunning()
    warndlg('Cannot start autopatching while RS Improver is running!', 'Warning!');
    return
end
if model.autopatcher.isRunning()
    warndlg('Autopatcher is already running!', 'Warning!');
    return
end
model.autopatcher.startFromBreakIn();


function desiredResistanceInput_Callback(hObject, ~, handles) %#ok<DEFNU>
value = str2double(get(hObject,'String'));
if ~isnan(value)
    model = get(handles.mainfigure, 'UserData');
    model.rsImprover.desiredResistance = value;
else
    set(hObject, 'String', '#');
end

% --- Executes during object creation, after setting all properties.
function desiredResistanceInput_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calibratePressureBtn.
function calibratePressureBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
button = questdlg(['Do you really want to start the pressure calibration process? If another process is actively using ', ...
    'the pressure system, it can behave unexpectedly!'], 'Pressure Offset Calibration');
if strcmp(button, 'Yes')
    model.autopatcher.pressureController.calibrate();
end


function autopatcherStatusText_ButtonDownFcn(hObject, ~, handles) %#ok<DEFNU>
set(hObject, 'String', '-');
set(handles.autopatcherMessageText, 'String', '-');


function autopatcherMessageText_ButtonDownFcn(hObject, ~, ~) %#ok<DEFNU>
set(hObject, 'String', '-');


function disablePressureControllerBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
model.autopatcher.pressureController.disable();


function startFromSealingBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if model.rsImprover.isRunning()
    warndlg('Cannot start autopatching while RS Improver is running!', 'Warning!');
    return
end
if model.autopatcher.isRunning()
    warndlg('Autopatcher is already running!', 'Warning!');
    return
end
model.autopatcher.startFromSeal();


function optionsBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
optionsApp = model.optionsApp;
if isempty(optionsApp) || ~isvalid(optionsApp)
    optionsApp = BlindPatcherOptions();
    optionsApp.initialize(model.autopatcher);
    model.optionsApp = optionsApp;
else
    optionsApp.BlindPatcheroptionsUIFigure.Visible = 'off';
    optionsApp.BlindPatcheroptionsUIFigure.Visible = 'on';
    drawnow;
end
