classdef DCAMController < CameraController
    %DCAMCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        savedSettings
    end
    
    properties
        video
        height
        width
        flip
    end
    
    methods
        function this = DCAMController(video)
            this.flip = false;
            this.video = video;
            triggerconfig(this.video, 'manual');
            start(this.video);
            this.setCurrentSettingsAsDefault();
        end
        
        function delete(this)
            stop(this.video);
        end
        
        function set.flip(this, value)
            assert(islogical(value), 'Value should be of logical.');
            this.flip = value;
        end
        
        function image = capture(this)
            
            %% TODO this try catch is only for testing purposes, maybe it should be removed later
            try
                image = getsnapshot(this.video);
                if this.flip
                    image = flipud(image);
                end
            catch ex
                log4m.getLogger().error(ex.message);
                image = zeros(this.height, this.width);
            end
        end
        
        function [width, height] = getResolution(this)
            width = this.width;
            height = this.height;
        end
        
        function time_msec = getExposureTime(this)
            src = this.video.Source;
            time_msec = src.AutoExposure;
        end
        
        function setCurrentSettingsAsDefault(this)
            this.savedSettings = struct();
            src = this.video.Source;
            params = get(src);
            fields = fieldnames(params);
            for i = 1:numel(fields)
                validInput = set(src, fields{i});
                autoable = any(strcmp(validInput,'auto')) & any(strcmp(validInput,'manual'));
                if autoable
                    this.savedSettings.(fields{i}) = params.(fields{i});
                end
            end
        end
        
        function resetDefaultSettings(this)
            set(this.video.Source, this.savedSettings);
        end
        
        function turnOffAutoSettings(this)
            fields = fieldnames(this.savedSettings);
            src = this.video.Source;
            for i = 1:numel(fields)
                src.(fields{i}) = 'manual';
            end
        end
        
        function reset(this)
            stop(this.video);
            start(this.video);
        end
    end % methods
end % classdef

