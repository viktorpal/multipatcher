classdef DummyCameraController < CameraController
    %DUMMYCAMERACONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        width = 1392
        height = 1040
    end
    
    methods
        function image = capture(this)
            image = rand(this.height, this.width);
        end
        
        function [width, height] = getResolution(this)
            width = this.width;
            height = this.height;
        end
        
        function [sizeX, sizeY] = getPixelSize(this)
            
        end
        
        function time_msec = getExposureTime(this)
            time_msec = 0;
        end
        
        function turnOffAutoSettings(this)
            
        end
        
        function resetDefaultSettings(this)
            
        end
        
        function setCurrentSettingsAsDefault(this)
            
        end
    end % methods
end % classdef

