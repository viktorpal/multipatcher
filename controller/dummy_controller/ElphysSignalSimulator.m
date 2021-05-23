classdef ElphysSignalSimulator < ElectrophysiologySignalProcessor & handle
    %ELPHYSSIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        t
    end
    
    methods
        function this = ElphysSignalSimulator(timerPeriod)
            if nargin < 1
                period = 0.2;
            else
                period = timerPeriod;
            end
            this.t = timer();
            this.t.ExecutionMode = 'fixedRate';
            this.t.Period = period;
            this.t.TimerFcn = @this.timerFcn;
            this.t.Name = 'ElphysSignalSimulator-timer';
            this.resistance = 5;
            this.current = 0;
            start(this.t);
        end
        
        function delete(this)
            stop(this.t);
            delete(this.t);
        end
        
        function updateTime = getUpdateTime(this)
            updateTime = this.t.Period;
        end
        
        function setResistance(this, value)
        %   SETRESISTANCE Resistance can be set in simulator using this function
            assert(~isempty(value) && isnumeric(value) && value >= 0);
            this.resistance = value;
        end
    end
    
    methods (Access = private)
        function timerFcn(this, ~, ~)
            notify(this, 'DataChange');
        end
    end
    
end

