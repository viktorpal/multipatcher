fs = filesep;
CAFFE_PATH = fullfile('..', 'caffe', 'matlab');
[AP_PATH, ~, ~] = fileparts(mfilename('fullpath'));
AP_PATH = [AP_PATH, fs];
addpath(AP_PATH)
addpath(CAFFE_PATH)
addpath(fullfile(AP_PATH, 'util'))
addpath(fullfile(AP_PATH, 'util', 'log4m'))
L = log4m.getLogger('autopatcher.log');
L.setLogLevel(log4m.ALL);
L.setCommandWindowLevel(log4m.DEBUG)
addpath(fullfile(AP_PATH, 'config'))
addpath(fullfile(AP_PATH, 'general'))
addpath(fullfile(AP_PATH, 'general', 'focus_estimation'))
addpath(fullfile(AP_PATH, 'general', 'image_guided'))
addpath(fullfile(AP_PATH, 'general', 'image_guided', 'Prediction'))
addpath(fullfile(AP_PATH, 'util', 'allcomb'))
addpath(fullfile(AP_PATH, 'util', 'fft2utils'))
addpath(fullfile(AP_PATH, 'util', 'gui'))
addpath(fullfile(AP_PATH, 'util', 'RemoteWorker'))
if ~ispc && ~isunix
    warning('DIC reconstruction is only supported on Windows and Linux systems.');
end
addpath(fullfile(AP_PATH, 'visualization'))
addpath(fullfile(AP_PATH, 'controller'))
addpath(fullfile(AP_PATH, 'controller', 'dummy_controller'))
addpath(fullfile(AP_PATH, 'controller', 'LNController'))
addpath(fullfile(AP_PATH, 'controller', 'MixedControllers'))
addpath(fullfile(AP_PATH, 'controller', 'Camera'))
addpath(fullfile(AP_PATH, 'controller', 'PressureControllers'))
addpath(fullfile(AP_PATH, 'controller', 'niboard'))
addpath(fullfile(AP_PATH, 'controller', 'Electrophysiology'))
addpath(fullfile(AP_PATH, 'controller', 'PressureControllers'))
addpath(fullfile(AP_PATH, 'controller', 'Amplifier'))
addpath(fullfile(AP_PATH, 'scripts'))
addpath(fullfile(AP_PATH, 'scripts', 'tracking'))
addpath(fullfile(AP_PATH, 'scripts', 'training'))

clear fs AP_PATH L CAFFE_PATH