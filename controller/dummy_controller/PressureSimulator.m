classdef PressureSimulator < PressureController
    %CUSTOMPRESSURECONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        demandedPressure
        currentPressure
        controlTimer
    end
    
    methods
        function this = PressureSimulator()
            this.currentPressure = 0;
            this.demandedPressure = 0;
            this.state = PressureStates.Regulating;
            this.controlTimer = timer('TimerFcn', @this.timerCallback, 'Period', 0.1, 'ExecutionMode', 'fixedRate', ...
                'Name', 'PressureSimulator-timer');
            start(this.controlTimer);
        end
        
        function setPressure(this, value)
            this.demandedPressure = value;
            this.state = PressureStates.Regulating;
        end
        
        function pressure = getPressure(this)
            pressure = this.currentPressure;
        end
        
        function updateTime = getUpdateTime(this)
            updateTime = this.controlTimer.Period;
        end
        
        function breakIn(this, pressure, delay)
            this.state = PressureStates.BreakIn;
            this.state = PressureStates.BreakInComplete;
        end
        
        function disable(this)
            this.state = PressureStates.Disabled;
        end
        
        function setOffsetToCurrentValues(this)
            disp('Pressure offset not supported in simulator!');
        end
        
        function delete(this)
            stop(this.controlTimer);
            delete(this.controlTimer);
        end
    end
    
    methods (Access = private)
        function timerCallback(this, ~, ~)
            diff = abs(this.currentPressure - this.demandedPressure);
            if diff > eps
                this.currentPressure = this.currentPressure + sign(this.demandedPressure-this.currentPressure)*min(diff,30);
            end
            notify(this, 'DataChange');
        end
    end
end

