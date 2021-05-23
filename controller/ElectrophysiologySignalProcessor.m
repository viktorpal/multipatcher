classdef (Abstract) ElectrophysiologySignalProcessor < matlab.mixin.SetGet
    %ELPHYSSIGNALCONTROLLER Abstract class that regularly measures
    %resistance
    %   The implementing class should listen to an event or run a timer
    %   that regularly checks the electrophysiology signal and measures the
    %   resistance. The resistance and current value should be copied to the
    %   'resistance' property and a 'DataChange' event should be fired. The
    %   most recent values can be queried by usual matlab commands or be
    %   tracked by event listeners.
    
    events
        DataChange
    end
    
    properties (SetAccess = protected)
        resistance
        current
    end
    
    properties (SetAccess = protected, SetObservable)
        calculateBreakInResistance
    end
    
    methods (Abstract)
        updateTime = getUpdateTime(this)
    end
    
    methods
        function this = ElectrophysiologySignalProcessor()
            this.disableBreakInResistance();
        end
        
        function requestBreakInResistance(this)
            this.calculateBreakInResistance = true;
        end
        
        function disableBreakInResistance(this)
            this.calculateBreakInResistance = false;
        end
    end
    
end

