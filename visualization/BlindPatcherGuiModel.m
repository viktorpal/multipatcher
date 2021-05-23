classdef BlindPatcherGuiModel < matlab.mixin.SetGet
    %BLINDPATCHERGUIMODEL
    
    properties (Constant, Hidden)
        defaultSecondsToShow = 10;
    end
    
    properties
        config
        autopatcher
        resistanceHistory
        pressureHistory 
        elphysListener
        pressureListener
        rsImprover
        rsiListener
        breakInResistanceListener
        pressureStatusListener
        autopatcherStatusListener
        autopatcherMessageListener
        optionsApp % BlindPatcherOptions mlapp object
        
        % OuterPosition property value of the figure which should be set on startup and saved upon exit. Empty should
        % mean the default values should be used.
        figureOuterPosition
        isOwnerOfObjects
    end
    
    methods
        function setSecondsToShow(this, sec)
            newResistanceLength = round(sec/this.autopatcher.elphysProcessor.getUpdateTime());
            if numel(this.resistanceHistory) < newResistanceLength
                this.resistanceHistory = [zeros(1,newResistanceLength-numel(this.resistanceHistory)), ...
                    this.resistanceHistory];
            else
                this.resistanceHistory = this.resistanceHistory(end-newResistanceLength+1:end);
            end
        end
        
        function delete(this)
            delete(this.elphysListener);
            delete(this.pressureListener);
            delete(this.rsiListener);
            delete(this.breakInResistanceListener);
            delete(this.pressureStatusListener);
            delete(this.autopatcherStatusListener);
            delete(this.autopatcherMessageListener);
            if this.isOwnerOfObjects % if started from visualizationTool, it should not delete objects
                delete(this.config);
                delete(this.rsImprover);
                delete(this.autopatcher);
            end
        end
        
        function set.isOwnerOfObjects(this, value)
            assert(islogical(value));
            this.isOwnerOfObjects = value;
        end
        
        function set.figureOuterPosition(this, value)
            assert(isempty(value) || (isvector(value) && numel(value)==4));
            this.figureOuterPosition = value;
        end
    end
    
end

