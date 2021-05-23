classdef StackFileCameraController < CameraController
    %STACKFILECAMERACONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Hidden)
        defaultCountPerSlice = 10;
    end
    
    properties (SetObservable)
        filepath
    end
    
    properties
        countPerSlice
    end
    
    properties (Access = protected)
        imgstack
        counter
    end
    
    properties (Access = private)
        filepathChangeListener
    end
    
    methods
        function this = StackFileCameraController(filepath)
            this.filepathChangeListener = this.addlistener('filepath', 'PostSet', @(src,event) this.filepathChangedCb());
            this.countPerSlice = this.defaultCountPerSlice;
            this.counter = 0;
            this.filepath = filepath;
        end
        
        function delete(this)
            if ~isempty(this.filepathChangeListener) && ishandle(this.filepathChangeListener)
                delete(this.filepathChangeListener);
            end
        end
        
        function set.filepath(this, filepath)
            assert(ischar(filepath), 'Input ''filepath'' should be a string (character array)!');
            this.filepath = filepath;
        end
        
        function image = capture(this)
            this.counter = this.counter + 1;
            if this.counter > size(this.imgstack.getStack(),3)*this.countPerSlice-1
                this.counter = 1;
            end
            a = floor(this.counter/this.countPerSlice)+1;
            image = mat2gray(this.imgstack.getLayer(floor(this.counter/this.countPerSlice)+1));
        end
        
        function [width, height] = getResolution(this)
            width = size(this.imgstack.getStack(),2);
            height = size(this.imgstack.getStack(),1);
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
        
        function set.countPerSlice(this, value)
            assert(isnumeric(value) && value > 0, 'Input should be a positive numeric.');
            this.countPerSlice = value;
        end
    end % methods
    
    methods (Access = protected)
        function filepathChangedCb(this)
            this.imgstack = ImageStack.load(this.filepath, false);
        end
    end
end % classdef

