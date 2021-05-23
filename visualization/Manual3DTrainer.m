function varargout = Manual3DTrainer(varargin)
% MANUAL3DTRAINER MATLAB code for Manual3DTrainer.fig
%      MANUAL3DTRAINER, by itself, creates a new MANUAL3DTRAINER or raises the existing
%      singleton*.
%
%      H = MANUAL3DTRAINER returns the handle to a new MANUAL3DTRAINER or the handle to
%      the existing singleton*.
%
%      MANUAL3DTRAINER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUAL3DTRAINER.M with the given input arguments.
%
%      MANUAL3DTRAINER('Property','Value',...) creates a new MANUAL3DTRAINER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Manual3DTrainer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Manual3DTrainer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Manual3DTrainer

% Last Modified by GUIDE v2.5 30-Oct-2017 13:17:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Manual3DTrainer_OpeningFcn, ...
                   'gui_OutputFcn',  @Manual3DTrainer_OutputFcn, ...
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


% --- Executes just before Manual3DTrainer is made visible.
function Manual3DTrainer_OpeningFcn(hObject, ~, handles, varargin)
% Choose default command line output for Manual3DTrainer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% model = Manual3DTrainerModel();
[model, confobj] = Config.createFromXml(fullfile('config', 'trainer.xml'));
model = model.trainerModel;
model.config = confobj;
set(handles.mainfigure, 'UserData', model);

p = inputParser;
addParameter(p, 'vistoolGuiModel', []);
addParameter(p, 'mainFigure', []);
addParameter(p, 'ax', []);
parse(p, varargin{:});

model.mainWindowGuiModel = p.Results.vistoolGuiModel;
model.ax = p.Results.ax;
model.mainFigure = p.Results.mainFigure;
assert(~isempty(model.mainWindowGuiModel));
assert(~isempty(model.ax));

model.currentIndexToShowListener = model.addlistener('currentIndexToShow', 'PostSet', ...
    @(src, event) currentIndexToShowChangeListener(src, event, handles));
model.segmentedIndicesListener = model.addlistener('segmentedIndices', 'PostSet', ...
    @(src, event) segmentedIndicesChangeListener(src, event, handles));
model.zSliceListener = model.mainWindowGuiModel.addlistener('zslice', 'PostSet', ...
    @(src, event) trainer_updateSegmentationBox(handles));
model.boxSizeListener = model.addlistener('boxSize', 'PostSet', ...
    @(src, event) trainer_updateSegmentationBox(handles));
model.mainWindowOriginalWindowKeyReleaseFcn = model.mainFigure.WindowKeyReleaseFcn;
model.mainFigure.WindowKeyReleaseFcn = @(src,event) trainer_mainfigWindowKeyReleaseFcn(src,event,handles);


% --- Outputs from this function are returned to the command line.
function varargout = Manual3DTrainer_OutputFcn(~, ~, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close mainfigure.
function mainfigure_CloseRequestFcn(hObject, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if model.isSaveRecommended
    qans = questdlg('Some changes are not saved. Would you like to save them before closing trainer window?', ...
        'Warning: Manual3DTrainer', 'Yes', 'No', 'No');
    if strcmp(qans, 'Yes')
        trainer_saveModel(model);
    end
end
try
    model.config.save();
catch ex
    log4m.getLogger().error(['Error while saving Manual3DTrainer config file: ', ex.message]);
end
model.mainFigure.WindowKeyReleaseFcn = model.mainWindowOriginalWindowKeyReleaseFcn;
delete(model);
delete(hObject);


% --- Executes on button press in prevBtn.
function prevBtn_Callback(~, ~, handles) %#ok<DEFNU>
trainer_selectPrev(handles);


% --- Executes on button press in nextBtn.
function nextBtn_Callback(~, ~, handles) %#ok<DEFNU>
trainer_selectNext(handles);


% --- Executes on button press in saveBtn.
function saveBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isempty(model.segmentedIndices)
    warndlg('No data to be saved!', 'Warning', 'modal');
    return
end
trainer_saveModel(model);


% --- Executes on button press in loadBtn.
function loadBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
vistoolModel = model.mainWindowGuiModel;
if isempty(vistoolModel.imgstack)
    warndlg('Load an image before loading a training file!', 'No image loaded!', 'modal');
    return
end
[fileName, pathName] = uigetfile('*.mat','Load corresponding training set (.mat)', model.filepath);
if pathName == 0
    return
end
filepath = [pathName, fileName];

trainer_loadData(filepath, model, vistoolModel);

% --- Executes on button press in positiveExampleBtn.
function positiveExampleBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isempty(model.currentIndexToShow)
    errordlg('Select a segmentation first!', 'No segmentation selected');
end
model.label(model.currentIndexToShow) = model.POSITIVE_LABEL;
trainer_updateSegmentationBox(handles);
updateCurrentIndexText(handles)


% --- Executes on button press in negativeExampleBtn.
function negativeExampleBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isempty(model.currentIndexToShow)
    errordlg('Select a segmentation first!', 'No segmentation selected');
end
model.label(model.currentIndexToShow) = model.NEGATIVE_LABEL;
trainer_updateSegmentationBox(handles);
updateCurrentIndexText(handles)


% --- Executes on button press in negativeOtherBtn.
function negativeOtherBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isempty(model.currentIndexToShow)
    errordlg('Select a segmentation first!', 'No segmentation selected');
end
model.label(model.currentIndexToShow) = model.OTHER_LABEL;
trainer_updateSegmentationBox(handles);
updateCurrentIndexText(handles)


% --- Executes on button press in removeLabelBtn.
function removeLabelBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if isempty(model.currentIndexToShow)
    errordlg('Select a segmentation first!', 'No segmentation selected');
end
model.label(model.currentIndexToShow) = model.UNLABELED;
trainer_updateSegmentationBox(handles);
updateCurrentIndexText(handles)


function currentIndexToShowChangeListener(~, ~, handles)
updateCurrentIndexText(handles);
trainer_updateSegmentationBox(handles);
model = get(handles.mainfigure, 'UserData');
if ~isempty(model.currentIndexToShow)
    vistoolModel = model.mainWindowGuiModel;
    vistoolModel.zslice = model.segmentedIndices(model.currentIndexToShow,5); % this fires an event and calls updateSegmentationBox
end


function segmentedIndicesChangeListener(~, ~, handles)
model = get(handles.mainfigure, 'UserData');
numIndices = size(model.segmentedIndices,1);
set(handles.numSegIdxTxt, 'String', num2str(numIndices));
if model.currentIndexToShow > numIndices
    model.currentIndexToShow = [];
end
trainer_updateSegmentationBox(handles);


function updateCurrentIndexText(handles)
model = get(handles.mainfigure, 'UserData');
if ~isempty(model.currentIndexToShow)
    set(handles.currentIdxTxt, 'String', num2str(model.currentIndexToShow));
else
    set(handles.currentIdxTxt, 'String', '');
end
if ~isempty(model.currentIndexToShow)
    switch model.label(model.currentIndexToShow)
        case model.UNLABELED
            color = model.unlabeledColor;
        case model.POSITIVE_LABEL
            color = model.positiveColor;
        case model.NEGATIVE_LABEL
            color = model.negativeColor;
        case model.OTHER_LABEL
                color = model.otherColor;
        otherwise
            color = 'black';
    end
    set(handles.currentIdxTxt, 'ForegroundColor', color);
end


function predictBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
if ~isempty(model.segmentedIndices)
    qans = questdlg('Some data is loaded which will be removed. Continue?','Warning');
    if ~strcmp(qans, 'Yes')
        return
    end
end
trainer_findCells(model);


% --- Executes on button press in optionsBtn.
function optionsBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
Manual3DTrainerOptions('trainerModel', model);


% --- Executes on button press in deleteBtn.
function deleteBtn_Callback(~, ~, handles) %#ok<DEFNU>
model = get(handles.mainfigure, 'UserData');
trainer_deleteSelectedBox(model);


% --- Executes on key release with focus on mainfigure or any of its controls.
function mainfigure_WindowKeyReleaseFcn(~, eventdata, handles) %#ok<DEFNU>
trainer_mainfigWindowKeyReleaseFcn([], eventdata, handles)


% --- Executes on button press in zplusButton.
function zplusButton_Callback(~, ~, handles) %#ok<DEFNU>
trainer_changeZposition(handles, +1);


% --- Executes on button press in zminusButton.
function zminusButton_Callback(~, ~, handles) %#ok<DEFNU>
trainer_changeZposition(handles, -1);
