classdef (Abstract) CameraController < handle
    %CAMERACONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Abstract)
        image = capture(this);
        [width, height] = getResolution(this);
        time_msec = getExposureTime(this);
        setCurrentSettingsAsDefault(this);
        resetDefaultSettings(this);
        turnOffAutoSettings(this);
    end
    
end

