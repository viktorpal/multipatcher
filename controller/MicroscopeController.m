classdef MicroscopeController < matlab.mixin.SetGet
    %MICROSCOPECONTROLLER Microscope controller
    %   This class contains the controllers of microscope components (stage,
    %   pipette, camera), provides some additional functionalities that
    %   require multiple components to work, or simply forward a call to
    %   the component. The object are the owner of the components (i.e. it
    %   deletes controllers when the object itself is being deleted).
    
    properties (Constant, Hidden)
        default40xPixelSize = 0.115;
    end
    
    properties
        pixelSizeX
        pixelSizeY
        stage
        camera
    end
    
    properties% (Access = private)
        pipetteList
    end
    
    methods
        function this = MicroscopeController()
            this.pipetteList = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end
        
        function delete(this)
            delete(this.stage);
            delete(this.camera);
            for key = this.pipetteList.keys
                delete(this.pipetteList(key{:}));
            end
        end
        
        function pipetteList = getPipetteList(this)
            pipetteList = containers.Map(this.pipetteList.keys, this.pipetteList.values);
        end
        
        function pipetteController = getPipette(this, id)
            pipetteController = this.pipetteList(id);
        end
        
        function setPipetteList(this, pipetteList)
            assert(isa(pipetteList, 'containers.Map'), 'Input is not an instance of containers.Map!');
            for i = pipetteList.keys
                j = cell2mat(i);
                this.addPipette(j, pipetteList(j));
            end
        end
        
        function addPipette(this, pipetteID, pipette)
            assert(isa(pipette, 'PipetteController'), 'Input is not an instance of PipetteController!');
            this.pipetteList(pipetteID) = pipette;
        end
        
        function removePipette(this, pipetteID)
            this.pipetteList.remove(pipetteID);
        end
        
        function moveStageTo(this, x, y, z, varargin)
            this.stage.moveTo(x, y, z, varargin);
        end
        
        function moveStage(this, x, y, z, varargin)
            this.stage.move(x, y, z, varargin);
        end
        
        function movePipetteTo(this, id, x, y, z, varargin)
            this.getPipette(id).moveTo(x, y, z, varargin);
        end
        
        function movePipette(this, id, x, y, z, varargin)
            this.getPipette(id).move(x, y, z, varargin);
        end
        
        function image = captureImage(this)
            image = this.camera.capture();
        end
        
        function [x, y, z] = getStagePosition(this)
            if nargout == 3
                [x, y, z] = this.stage.getPosition();
            else
                x = this.stage.getPosition();
            end
        end
        
        function x = getStageX(this)
            x = this.stage.getX();
        end
        
        function y = getStageY(this)
            y = this.stage.getY();
        end
        
        function z = getStageZ(this)
            z = this.stage.getZ();
        end
        
        function [x, y, z] = getPipettePosition(this, id)
            if nargout == 3
                [x, y, z] = this.getPipette(id).getPosition();
            else
                x = this.getPipette(id).getPosition();
            end
        end
        
        function x = getPipetteX(this, id)
            x = this.getPipette(id).getX();
        end
        
        function y = getPipetteY(this, id)
            y = this.getPipette(id).getY();
        end
        
        function z = getPipetteZ(this, id)
            z = this.getPipette(id).getZ();
        end
        
        function imageStack = captureStack(this, thickness, step, mode, varargin)
            if nargin < 4
                mode = 'center';
            end
            if nargin < 3
                step = 1;
            end
            p = inputParser;
            %% TODO if mode is manual, thickness is supposed be empty
            addRequired(p, 'thickness', @(x) isempty(x) || (isnumeric(x) && all(x>0)));
            addRequired(p, 'step', @(x) isnumeric(x) && (x>0));
            addRequired(p, 'mode',@(x) ischar(x));
            parse(p, thickness, step, mode);

            expectedModes = {'center', 'top', 'bot', 'manual'};
            validatestring(mode,expectedModes);
            
            p = inputParser;
            addParameter(p, 'botPosition', [], @(x) isnumeric(x));
            addParameter(p, 'generateMeta', true, @(x) islogical(x));
            parse(p, varargin{:});
%             botPosition = p.Results.botPosition;
            generateMeta = p.Results.generateMeta;
%             assert(xor(strcmp(mode,'manual'), isempty(botPosition)), ...
%                 'Parameter ''botPosition'' should be defined when mode is ''manual''.');

            zOriginal = this.stage.getZ();
            switch mode
                case 'center'
                    top = zOriginal + floor(thickness/2);
                    bot = zOriginal - floor(thickness/2);
                case 'top'
                    top = zOriginal;
                    bot = top - thickness;
                case 'bot'
                    bot = zOriginal;
                    top = bot + thickness;
                case 'manual'
                    %% TODO this is still a bit messy
                    bot = zOriginal;
%                     top = bot + thickness;
                    zList = bot + thickness;
            end
            if ~strcmp(mode, 'manual')
                zList = bot:step:top;
            end

            [width, height] = this.camera.getResolution();
            exposureTime = this.camera.getExposureTime() * 0.001;
            imageStack = ImageStack(zeros(height, width, numel(zList)));
%             this.camera.setCurrentSettingsAsDefault();
%             this.camera.turnOffAutoSettings();
            this.stage.moveTo([], [], bot);
            for i = 1:numel(zList)
                timerval = tic;
                this.stage.moveTo([], [], zList(i));
                this.stage.waitForFinishedZ();
                pause(exposureTime);
                img = im2double(this.captureImage());
                imageStack.setSlice(img, i);
                elapsedTime = toc(timerval);
                log4m.getLogger().trace([num2str(i) '/' num2str(numel(zList)), ' images taken, last one took ', ...
                    num2str(elapsedTime), ' seconds']);
            end
            this.stage.moveTo([], [], zOriginal);
%             this.camera.resetDefaultSettings();
            
            if generateMeta
                imageStack.meta.Creator = 'Autopatcher';
                imageStack.meta.CreationTime = datestr(datetime);
                imageStack.meta.width = width;
                imageStack.meta.height = height;
                imageStack.meta.D3Size = numel(zList);
                imageStack.meta.pixelSizeX = this.pixelSizeX;
                imageStack.meta.pixelSizeY = this.pixelSizeY;
                imageStack.meta.pixelSizeZ = step;
                pos = this.stage.getPosition();
                imageStack.meta.stageX = pos(1);
                imageStack.meta.stageY = pos(2);
                imageStack.meta.stageZ = bot;
                pipetteKeys = this.pipetteList.keys();
                for i = 1:numel(pipetteKeys)
                    propname = strcat('pipette', any2str(pipetteKeys{i}));
                    propnameX = strcat(propname, 'X');
                    propnameY = strcat(propname, 'Y');
                    propnameZ = strcat(propname, 'Z');
                    try
                        pos = this.pipetteList(pipetteKeys{i}).getPosition();
                        imageStack.meta.(propnameX) = pos(1);
                        imageStack.meta.(propnameY) = pos(2);
                        imageStack.meta.(propnameZ) = pos(3);
                    catch ex
                        imageStack.meta.(propnameX) = 'error';
                        imageStack.meta.(propnameY) = 'error';
                        imageStack.meta.(propnameZ) = 'error';
                        log4m.getLogger.trace(['Could not get pipette position: ', ex.message]);
                    end
                end
            end
        end
        
        function set.stage(this, stage)
            assert(isa(stage, 'StageController'), 'Input is not an instance of StageController!');
            this.stage = stage;
        end
        
        function set.camera(this, camera)
            assert(isa(camera, 'CameraController'), 'Input is not an instance of CameraController!');
            this.camera = camera;
        end
        
        function set.pixelSizeX(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.pixelSizeX = value;
        end
        
        function set.pixelSizeY(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.pixelSizeY = value;
        end
        
        function centerCameraToCoord(this, stageCoord, wait)
        %CENTERCAMERATOCOORD Centers the camera to a position by moving the microscope
        %   pos - the position in stage coordinates that will be centered in the camera
        %   wait (true,optional) - wait for the movement to finish
            
            if nargin < 2
                error('stageCoord is a required parameter!');
            end
            if nargin < 3
                wait = true;
            end
            assert(isnumeric(stageCoord) && ~isempty(stageCoord) && numel(stageCoord)==3, 'stageCoord should be a 3 element numeric vector');

            [imw, imh] = this.camera.getResolution();
            halfW = round(imw/2);
            halfH = round(imh/2);
            cpos = stageCoord - [halfW*this.pixelSizeX, -halfH*this.pixelSizeY, 0];
            this.stage.moveTo(cpos(1), cpos(2), cpos(3), 'speed', 'fast');
            if wait
                this.stage.waitForFinished();
            end
        end
    end
    
end

