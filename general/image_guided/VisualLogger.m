classdef VisualLogger < matlab.mixin.SetGet
    %VISUALLOGGER Logs camera images and different phases of patch clamping
    %   
    
    properties (Constant)
        defaultEnabled = true;
        defaultFolderpath = fullfile('.', 'log');
    end
    
    properties
        enabled
        folderpath
    end
    
    properties (Access = protected)
        autopatcher
        visualPatcher
        autopatcherStatusListener
        visualPatcherPhaseListener
        visualPatcherSubphaseListener
    end
    
    methods
        function this = VisualLogger(autopatcher, visualPatcher)
            this.enabled = this.defaultEnabled;
            this.folderpath = this.defaultFolderpath;
            this.autopatcher = autopatcher;
            this.visualPatcher = visualPatcher;
            
            this.autopatcherStatusListener = this.autopatcher.addlistener('status', 'PostSet', ...
                @(src,event) this.apStatusChangeCb());
            this.visualPatcherPhaseListener = this.visualPatcher.addlistener('phase', 'PostSet', ...
                @(src,event) this.vpPhaseChangeCb());
            this.visualPatcherSubphaseListener = this.visualPatcher.addlistener('subphase', 'PostSet', ...
                @(src,event) this.vpSubphaseChangeCb());
        end
        
        function delete(this)
            delete(this.autopatcherStatusListener);
            delete(this.visualPatcherPhaseListener);
            delete(this.visualPatcherSubphaseListener);
        end
        
        function set.enabled(this, value)
            assert(islogical(value), 'Value should be a logical.');
            this.enabled = value;
        end
        
        function set.folderpath(this, value)
            assert(ischar(value) && exist(value, 'dir'), 'Value should be a character array of an existing folder path.');
            this.folderpath = value;
        end
        
        function set.autopatcher(this, autopatcher)
            assert(~isempty(autopatcher) && isa(autopatcher, 'AutoPatcher'), 'Input should be an AutoPatcher object!');
            this.autopatcher = autopatcher;
        end
        
        function set.visualPatcher(this, visualPatcher)
            assert(isa(visualPatcher, 'VisualPatcher'), 'Input should be a VisualPatcher object!');
            this.visualPatcher = visualPatcher;
        end
    end
    
    methods (Access = protected)
        function log(this, name, img)
            if this.enabled
                name = [datestr(now,'yyyy-mm-dd_HH-MM-SS,FFF_'), strrep(name, ' ', '_'), '.png'];
                log4m.getLogger().trace(['Logging image with name: ', name]);
                try
                    imwrite(mat2gray(img), fullfile(this.folderpath, name));
                catch ex
                    log4m.getLogger().error(['Error while logging image: ', ex.message]);
                end
            end
        end
        
        function apStatusChangeCb(this)
            switch this.autopatcher.status
                case AutoPatcherStates.Hunting
                    name = 'AP_hunting';
                case AutoPatcherStates.Sealing
                    name = 'AP_sealing';
                otherwise
                    name = [];
            end
            if ~isempty(name)
                img = this.autopatcher.microscope.camera.capture();
                log4m.getLogger().debug('Logging image due to AP status change.');
                this.log(name, img);
            end
        end
        
        function vpPhaseChangeCb(this) %#ok<MANU>
            log4m.getLogger().trace('Currently not logging anything at VP phase change.');
        end
        
        function vpSubphaseChangeCb(this)
            if this.visualPatcher.subphase == 3 && this.visualPatcher.phase == 0
                name = 'VP_starting';
                img = this.visualPatcher.autopatcher.microscope.camera.capture();
                log4m.getLogger().debug('Logging image at VP startup.');
                this.log(name, img);
            end
        end
    end
    
end

