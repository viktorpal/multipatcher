classdef CustomPressureController < PressureController & handle
    %CUSTOMPRESSURECONTROLLER Pressure controller for the custom made device
    %   Pressure controller using NI board and Honeywell pressure sensonrs.
    %   Valve roles: 
    %       1: positive input to tank
    %       2: vacuum input to tank
    %       3: tank atmosphere
    %       4: tank to pipette
    %       5: pipette atmosphere
    
    properties (Constant, Hidden)
        defaultAllowedPressureDifference = 10; % mbar
        defaultBreakInOpenValveDelay = 0.5; % sec
        defaultPipetteOffset = 0;
        defaultTankOffset = 0;
        defaultEnableLog = false;
        HistorySize = 100;
    end
    
    properties (SetAccess = immutable)
        system
    end
    
    properties
        allowedPressureDifference % mbar
        breakInOpenValveDelay % minimum delay in sec before opening valve 5
        pipetteOffset
        tankOffset
        enableLog
    end
    
    properties (Access = private)
        demandedPressure
        rawPipettePressure
        pipettePressure
        rawTankPressure
        tankPressure
        valveStates
        breakInTimestamp
        breakInPhase
        calibrationTimestamp
        dataListener
        pressureHistory
        pressureHistoryIdx
    end
    
    methods
        function this = CustomPressureController(pressureAndElphysSystem)
            assert(isa(pressureAndElphysSystem, 'PressureAndElphysSystem'), ...
                'Input system is not a ''PressureAndElphysSystem'' object.');
            this.system = pressureAndElphysSystem;
            this.rawPipettePressure = 0;
            this.pipettePressure = 0;
            this.rawTankPressure = 0;
            this.tankPressure = 0;
            this.demandedPressure = 0;
            this.state = PressureStates.Regulating;
            this.breakInTimestamp = 0;
            this.allowedPressureDifference = this.defaultAllowedPressureDifference;
            this.breakInOpenValveDelay = this.defaultBreakInOpenValveDelay;
            this.pipetteOffset = this.defaultPipetteOffset;
            this.tankOffset = this.defaultTankOffset;
            this.enableLog = this.defaultEnableLog;
            this.pressureHistory = zeros(this.HistorySize, 2);
            this.pressureHistoryIdx = 1;
            this.valveStates = [~this.system.VALVE1OPEN,...
                                ~this.system.VALVE2OPEN,...
                                ~this.system.VALVE3OPEN,...
                                ~this.system.VALVE4OPEN,...
                                ~this.system.VALVE5OPEN];
            this.system.valves.outputSingleScan(this.valveStates);
            this.dataListener = addlistener(this.system, 'PressureDataAvailable', @this.pressureRegulatorCallback);
        end
        
        function setPressure(this, value)
            this.demandedPressure = value;
            log4m.getLogger().debug(['Requesting pressure: ', num2str(value)]);
            this.state = PressureStates.Regulating;
        end
        
        function pressure = getPressure(this)
            pressure = this.pipettePressure;
        end
        
        function tankPressure = getTankPressure(this)
            tankPressure = this.tankPressure;
        end
        
        function set.allowedPressureDifference(this, value)
            this.allowedPressureDifference = value;
        end
        
        function set.breakInOpenValveDelay(this, value)
            this.breakInOpenValveDelay = value;
        end
        
        function set.enableLog(this, value)
            assert(islogical(value), 'Input should be a logical.');
            this.enableLog = value;
        end
        
        function breakIn(this, pressure, delay)
            this.demandedPressure = pressure;
            this.state = PressureStates.BreakIn;
            this.breakInTimestamp = 0;
            if nargin > 1
                this.breakInOpenValveDelay = delay;
            end
        end
        
        function updateTime = getUpdateTime(this)
            updateTime = this.system.updateTime;
        end
        
        function calibrate(this)
            this.state = PressureStates.Calibration;
            this.calibrationTimestamp = now;
        end
        
        function disable(this)
            this.state = PressureStates.Disabled;
        end
        
        function delete(this)
            delete(this.dataListener);
            this.system.valves.outputSingleScan([~this.system.VALVE1OPEN, ...
                                                 ~this.system.VALVE2OPEN, ...
                                                 ~this.system.VALVE3OPEN, ...
                                                 ~this.system.VALVE4OPEN, ...
                                                 ~this.system.VALVE5OPEN]);
            if ~this.system.hasListener()
                delete(this.system);
            end
        end
    end
    
    methods (Access = private)
        function pressureRegulatorCallback(this, ~, event)
            this.rawPipettePressure = (mean(event.Data(:,1))-2.5)/2*1000; % -2.5 because it means 0 mBar of 5 V max voltage, div by 2 because working range is 0.5-4.5 V
            this.rawTankPressure = (mean(event.Data(:,2))-2.5)/2*1000;    % *1000 converts it to mbar
            this.pipettePressure = this.rawPipettePressure - this.pipetteOffset;
            this.tankPressure = this.rawTankPressure - this.tankOffset; 
            tankdiff = this.demandedPressure - this.tankPressure;
            pipdiff = this.demandedPressure - this.pipettePressure;
            
            if this.enableLog
                this.pressureHistory(this.pressureHistoryIdx,:) = [this.pipettePressure, this.tankPressure];
                this.pressureHistoryIdx = this.pressureHistoryIdx + 1;
                if this.pressureHistoryIdx > this.HistorySize
                    log4m.getLogger().trace(['Pipette pressures of last ', num2str(this.HistorySize), ' values: ', ...
                        sprintf('%.1f,', this.pressureHistory(:,1)), ' tank pressures: ', sprintf('%.1f,', this.pressureHistory(:,2))]);
                    this.pressureHistoryIdx = 1;
                end
            end
            
            
            if this.state == PressureStates.BreakIn...
                    && ((tankdiff > 0 && tankdiff < this.allowedPressureDifference) || this.breakInTimestamp~=0)
                if this.breakInTimestamp == 0
                    this.valveStates = [~this.system.VALVE1OPEN,...
                                        ~this.system.VALVE2OPEN,...
                                        ~this.system.VALVE3OPEN,...
                                         this.system.VALVE4OPEN,...
                                        ~this.system.VALVE5OPEN];
                    this.breakInTimestamp = now;
                    this.breakInPhase = 1;
                else
                    delay = time2sec(now - this.breakInTimestamp);
                    if delay >= this.breakInOpenValveDelay && this.breakInPhase == 1
                        this.valveStates(5) = this.system.VALVE5OPEN;
                        this.breakInTimestamp = now;
                        this.breakInPhase = 2;
                    elseif delay >= 1 && this.breakInPhase == 2
                        this.valveStates(4) = ~this.system.VALVE4OPEN;
                        this.breakInTimestamp = now;
                        this.breakInPhase = 3;
                    elseif delay >= 0 && this.breakInPhase == 3
                        this.demandedPressure = 0;
                        this.state = PressureStates.BreakInComplete;
                        this.breakInTimestamp = 0;
                        this.breakInPhase = 0;
                    end
                end
            elseif this.state == PressureStates.Calibration
                this.valveStates = [~this.system.VALVE1OPEN,...
                                    ~this.system.VALVE2OPEN,...
                                     this.system.VALVE3OPEN,...
                                    ~this.system.VALVE4OPEN,...
                                     this.system.VALVE5OPEN];
                if time2sec(now - this.calibrationTimestamp) > 5
                    this.setOffsetToCurrentValues();
                    this.state = PressureStates.CalibrationComplete;
                end
            elseif this.state == PressureStates.Disabled
                this.valveStates = [~this.system.VALVE1OPEN,...
                                    ~this.system.VALVE2OPEN,...
                                    ~this.system.VALVE3OPEN,...
                                    ~this.system.VALVE4OPEN,...
                                    ~this.system.VALVE5OPEN];
            else
                this.valveStates([4,5]) = [~this.system.VALVE4OPEN, ~this.system.VALVE5OPEN];
                if this.state == PressureStates.Regulating
                    if this.demandedPressure == 0
                        if abs(pipdiff) >= this.allowedPressureDifference/2
                            this.valveStates(5) = this.system.VALVE5OPEN;
                        end
                    elseif sign(this.demandedPressure) == 1
                        if (pipdiff > 0 || pipdiff < -this.allowedPressureDifference)...
                                && tankdiff < 0 && tankdiff > -this.allowedPressureDifference
                            this.valveStates(4) = this.system.VALVE4OPEN;
                        end
                    elseif sign(this.demandedPressure) == -1
                        if (pipdiff < 0 || pipdiff > this.allowedPressureDifference)...
                                && tankdiff > 0 && tankdiff < this.allowedPressureDifference
                            this.valveStates(4) = this.system.VALVE4OPEN;
                        end
                    end
                end

                if this.valveStates(4) == ~this.system.VALVE4OPEN
                    if this.demandedPressure == 0
                        this.valveStates([1,2]) = [~this.system.VALVE1OPEN, ~this.system.VALVE2OPEN];
                        if abs(tankdiff) < this.allowedPressureDifference/2
                            this.valveStates(3) = ~this.system.VALVE3OPEN;
                        else
                            this.valveStates(3) = this.system.VALVE3OPEN;
                        end
                    elseif sign(this.demandedPressure) == 1
                        if tankdiff >= -this.allowedPressureDifference && tankdiff <= 0
                            this.valveStates([1,2,3]) = [~this.system.VALVE1OPEN, ~this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                        elseif tankdiff > 0 % positive open
                            this.valveStates([1,2,3]) = [this.system.VALVE1OPEN, ~this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                        elseif tankdiff < -this.allowedPressureDifference % atmosphere open
                            this.valveStates([1,2,3]) = [~this.system.VALVE1OPEN, this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                        end
                    elseif sign(this.demandedPressure) == -1
                        if tankdiff <= this.allowedPressureDifference && tankdiff > 0
                            this.valveStates([1,2,3]) = [~this.system.VALVE1OPEN, ~this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                        elseif tankdiff > this.allowedPressureDifference % positive open
                            this.valveStates([1,2,3]) = [this.system.VALVE1OPEN, ~this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                        elseif tankdiff < 0 % atmosphere open
                            this.valveStates([1,2,3]) = [~this.system.VALVE1OPEN, this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                        end
                    end
                else
                    this.valveStates([1,2,3]) = [~this.system.VALVE1OPEN, ~this.system.VALVE2OPEN, ~this.system.VALVE3OPEN];
                end
            end
            
%             disp([this.pipettePressure, this.tankPressure, this.valveStates]);
            this.system.valves.outputSingleScan(this.valveStates);
            notify(this, 'DataChange');
        end
        
        function setOffsetToCurrentValues(this)
            this.pipetteOffset = this.rawPipettePressure;
            this.tankOffset = this.rawTankPressure;
        end
    end
    
end

