classdef WebcamController < CameraController
    %WEBCAMCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        savedSettings
    end
    
    properties (SetAccess = private)
        webcam
    end
    
    methods
        function this = WebcamController(webcam)
            assert(isa(webcam, 'webcam'), 'Input should be a ''webcam'' object.');
            this.webcam = webcam;
        end
        
        function image = capture(this)
            image = rgb2gray(snapshot(this.webcam));
        end
        
        function [width, height] = getResolution(this)
            dims = strsplit(this.webcam.Resolution, 'x');
            width = str2double(dims{1});
            height = str2double(dims{2});
        end
        
        function time_msec = getExposureTime(this) %#ok<MANU>
            time_msec = 0;
        end
        
        function setCurrentSettingsAsDefault(this)
            this.savedSettings = struct();
            params = set(this.webcam);
            fields = fieldnames(params);
            for i = 1:numel(fields)
                validInput = set(this.webcam, fields{i});
                autoable = any(strcmp(validInput,'auto')) & any(strcmp(validInput,'manual'));
                if autoable
                    this.savedSettings.(fields{i}) = get(this.webcam, fields{i});
                end
            end
        end
        
        function resetDefaultSettings(this)
            set(this.webcam, this.savedSettings);
        end
        
        function turnOffAutoSettings(this)
            fields = fieldnames(this.savedSettings);
            for i = 1:numel(fields)
                this.webcam.(fields{i}) = 'manual';
            end
        end
    end
    
end

