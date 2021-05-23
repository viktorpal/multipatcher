function varargout = PredictionProperties(varargin)
% PREDICTIONPROPERTIES MATLAB code for PredictionProperties.fig
	
%      singleton*.
%
%      H = PREDICTIONPROPERTIES returns the handle to a new PREDICTIONPROPERTIES or the handle to
%      the existing singleton*.
%
%      PREDICTIONPROPERTIES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREDICTIONPROPERTIES.M with the given input arguments.
%
%      PREDICTIONPROPERTIES('Property','Value',...) creates a new PREDICTIONPROPERTIES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PredictionProperties_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PredictionProperties_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PredictionProperties

% Last Modified by GUIDE v2.5 13-Mar-2018 09:30:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PredictionProperties_OpeningFcn, ...
                   'gui_OutputFcn',  @PredictionProperties_OutputFcn, ...
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


% --- Executes just before PredictionProperties is made visible.
function PredictionProperties_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;

guidata(hObject, handles);

p = inputParser;
addParameter(p, 'generalParameters', []);
parse(p, varargin{:});

generalParameters = p.Results.generalParameters;
set(handles.mainfigure, 'UserData', generalParameters);

set(handles.predictionThresholdEdit, 'String', num2str(generalParameters.predictor.predictionThreshold));
set(handles.predictionTimerEdit, 'String', num2str(generalParameters.predictionTimerPeriod));
set(handles.minObjectWidthEdit, 'String', num2str(generalParameters.predictionMinObjectDimension(1)));
set(handles.minObjectHeightEdit, 'String', num2str(generalParameters.predictionMinObjectDimension(2)));
set(handles.maxObjectWidthEdit, 'String', num2str(generalParameters.predictionMaxObjectDimension(1)));
set(handles.maxObjectHeightEdit, 'String', num2str(generalParameters.predictionMaxObjectDimension(2)));
set(handles.minOverlapToUniteEdit, 'String', num2str(generalParameters.predictionMinOverlapToUnite));
set(handles.maxZdistanceToUniteEdit, 'String', num2str(generalParameters.predictionMaxZdistanceToUnite));


% --- Outputs from this function are returned to the command line.
function varargout = PredictionProperties_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;


% --- Executes on button press in okBtn.
function okBtn_Callback(~, ~, handles) %#ok<DEFNU>
close(handles.mainfigure);
delete(handles.mainfigure);


function predictionThresholdEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    if value > 1
        value = 1;
        set(hObject, 'String', num2str(value));
    end
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictor.predictionThreshold = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function predictionThresholdEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function predictionTimerEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionTimerPeriod = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function predictionTimerEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function minObjectWidthEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionMinObjectDimension(1) = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function minObjectWidthEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function minObjectHeightEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionMinObjectDimension(2) = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function minObjectHeightEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxObjectWidthEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionMaxObjectDimension(1) = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function maxObjectWidthEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxObjectHeightEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionMaxObjectDimension(2) = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function maxObjectHeightEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function minOverlapToUniteEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = validatePositiveNumeric(hObject);
if isnumeric(value)
    if value > 1
        value = 1;
        set(hObject, 'String', num2str(value));
    end
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionMinOverlapToUnite = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function minOverlapToUniteEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxZdistanceToUniteEdit_Callback(hObject, ~, handles) %#ok<DEFNU>
value = str2double(get(hObject,'String'));
if ~isnan(value)
    if value < 0
        value = '>=0';
    end
else
    value = '#';
end
if isnumeric(value)
    if value > 1
        value = 1;
        set(hObject, 'String', num2str(value));
    end
    generalParameters = get(handles.mainfigure, 'UserData');
    try
        generalParameters.predictionMaxZdistanceToUnite = value;
    catch ex
        set(hObject, 'String', ex.message);
    end
else
    set(hObject, 'String', num2str(value));
end


% --- Executes during object creation, after setting all properties.
function maxZdistanceToUniteEdit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function value = validatePositiveNumeric(hObject)
value = str2double(get(hObject,'String'));
if ~isnan(value)
    if value <= 0
        value = '>0';
        return
    end
else
    value = '#';
end
