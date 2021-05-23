function varargout = Manual3DTrainerOptions(varargin)
% MANUAL3DTRAINEROPTIONS MATLAB code for Manual3DTrainerOptions.fig
%      MANUAL3DTRAINEROPTIONS, by itself, creates a new MANUAL3DTRAINEROPTIONS or raises the existing
%      singleton*.
%
%      H = MANUAL3DTRAINEROPTIONS returns the handle to a new MANUAL3DTRAINEROPTIONS or the handle to
%      the existing singleton*.
%
%      MANUAL3DTRAINEROPTIONS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUAL3DTRAINEROPTIONS.M with the given input arguments.
%
%      MANUAL3DTRAINEROPTIONS('Property','Value',...) creates a new MANUAL3DTRAINEROPTIONS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Manual3DTrainerOptions_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Manual3DTrainerOptions_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Manual3DTrainerOptions

% Last Modified by GUIDE v2.5 28-Apr-2017 15:30:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Manual3DTrainerOptions_OpeningFcn, ...
                   'gui_OutputFcn',  @Manual3DTrainerOptions_OutputFcn, ...
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


% --- Executes just before Manual3DTrainerOptions is made visible.
function Manual3DTrainerOptions_OpeningFcn(hObject, ~, handles, varargin)
% Choose default command line output for Manual3DTrainerOptions
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

p = inputParser;
addParameter(p, 'trainerModel', []);
parse(p, varargin{:});

trainerModel = p.Results.trainerModel;
set(handles.mainfigure, 'UserData', trainerModel);

set(handles.boxSizeXEdit, 'String', num2str(trainerModel.boxSize(1)));
set(handles.boxSizeYEdit, 'String', num2str(trainerModel.boxSize(2)));
set(handles.boxSizeZEdit, 'String', num2str(trainerModel.boxSize(3)));


% --- Outputs from this function are returned to the command line.
function varargout = Manual3DTrainerOptions_OutputFcn(~, ~, handles)
varargout{1} = handles.output;


function boxSizeXEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validateOddPositiveRound(hObject);
set(hObject, 'String', num2str(value));
trainerModel = get(handles.mainfigure, 'UserData');
if isnumeric(value)
    try
        trainerModel.boxSize(1) = value;
    catch e
        set(hObject, 'String', e.message);
    end
end


function boxSizeXEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function boxSizeYEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validateOddPositiveRound(hObject);
set(hObject, 'String', num2str(value));
trainerModel = get(handles.mainfigure, 'UserData');
if isnumeric(value)
    try
        trainerModel.boxSize(2) = value;
    catch e
        set(hObject, 'String', e.message);
    end
end


function boxSizeYEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function boxSizeZEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validateOddPositiveRound(hObject);
set(hObject, 'String', num2str(value));
trainerModel = get(handles.mainfigure, 'UserData');
if isnumeric(value)
    try
        trainerModel.boxSize(3) = value;
    catch e
        set(hObject, 'String', e.message);
    end
end
    

function boxSizeZEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function value = validateOddPositiveRound(hObject)
value = str2double(get(hObject,'String'));
if ~isnan(value)
    if value <= 0
        value = '>0';
        return
    end
    if value ~= round(value)
        value = round(value);
    end
    if mod(value,2) ~= 1
        value = value + 1;
    end
else
    value = '#';
end


function okButton_Callback(~, ~, handles) %#ok<DEFNU>
close(handles.mainfigure);
delete(handles.mainfigure);
