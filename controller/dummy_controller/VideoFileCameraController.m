classdef VideoFileCameraController < CameraController
    %VideoFileCAMERACONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetObservable)
        filepath
    end
    
    properties (Access = protected)
        video
    end
    
    properties (Access = private)
        filepathChangeListener
    end
    
    methods
        function this = VideoFileCameraController(filepath)
            this.filepathChangeListener = this.addlistener('filepath', 'PostSet', @(src,event) this.filepathChangedCb());
            this.filepath = filepath;
        end
        
        function delete(this)
            if ~isempty(this.video) && ishandle(this.video)
                delete(this.video);
            end
            if ~isempty(this.filepathChangeListener) && ishandle(this.filepathChangeListener)
                delete(this.filepathChangeListener);
            end
        end
        
        function set.filepath(this, filepath)
            assert(ischar(filepath), 'Input ''filepath'' should be a string (character array)!');
            this.filepath = filepath;
        end
        
        function image = capture(this)
            if ~hasFrame(this.video)
                this.video.CurrentTime = 0;
            end
            image = rgb2gray(mat2gray(readFrame(this.video)));
        end
        
        function [width, height] = getResolution(this)
            width = this.video.Width;
            height = this.video.Height;
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
    
    methods (Access = protected)
        function filepathChangedCb(this)
            if ~isempty(this.video) && ishandle(this.video)
                delete(this.video);
            end
            this.video = VideoReader(this.filepath);
        end
    end
end % classdef

