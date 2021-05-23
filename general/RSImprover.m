classdef RSImprover < matlab.mixin.SetGet
    %RSIMPROVER Resistance Series (access resistance) improver
    %   Tries to improve resistance by applying pressure or vacuum on a
    %   sealed cell.
    
    properties (Constant, Hidden)
        defaultDesiredResistance = 30
    end
    
    properties
        pressureController
        elphysProcessor
        amplifier
        desiredResistance
    end
    
    properties (SetAccess = protected, SetObservable)
        status
    end
    
    properties (Access = private)
        t
        detailedResistanceHistory
        resistanceListener
        phase
        startTime
        phaseChangeTime
        baseResistance
    end
    
    methods
        function this = RSImprover()
            this.t = timer;
            this.t.TimerFcn = @this.timerFcn;
            this.t.Period = 0.5;
            this.t.ExecutionMode = 'fixedRate';
            this.t.Name = 'RSImprover timer';
            this.desiredResistance = this.defaultDesiredResistance;
            this.status = 'not started';
        end
        
        function start(this)
            this.amplifier.rsImprovementSetup();
            this.elphysProcessor.requestBreakInResistance();
            this.detailedResistanceHistory = Inf*ones(1,...
                round(this.t.Period/(this.elphysProcessor.getUpdateTime())));
            this.resistanceListener = this.elphysProcessor.addlistener('DataChange', ...
                @(src,event) this.resistanceDataChangeCallback());
            this.phase = 0;
            
            this.startTime = now;
            this.baseResistance = [];
            start(this.t);
            this.status = 'running';
        end
        
        function stop(this)
            this.stopProcess();
            this.status = 'stopped';
        end
        
        function delete(this)
            delete(this.resistanceListener);
            deleteTimer(this.t);
        end
        
        function b = isRunning(this)
            b = false;
            if strcmp(this.status, 'running')
                b = true;
            end
        end
        
        function set.desiredResistance(this, value)
            assert(isnumeric(value) && ~isempty(value) && ~isnan(value));
            this.desiredResistance = value;
        end
    end
    
    methods (Access = private)
        function resistanceDataChangeCallback(this)
            this.detailedResistanceHistory = [this.detailedResistanceHistory(2:end), this.elphysProcessor.resistance];
        end
        
        function timerFcn(this, ~, ~)
            if isempty(this.baseResistance) && time2sec(now - this.startTime) > 3
                this.phase = 1;
            end
            if time2sec(now - this.startTime) > 60
                this.phase = 'failed';
                this.status = 'failed';
                this.stopProcess();
                return
            end
            if time2sec(now - this.startTime) > 3
                switch this.phase
                    case 1
                        this.baseResistance = mean(this.detailedResistanceHistory);
                        this.pressureController.setPressure(-20);
                        this.phase = 2;
                        this.phaseChangeTime = now;
                    case 2
                        if time2sec(now - this.phaseChangeTime) > 10
                            this.phase = 3;
                            this.phaseChangeTime = now;
                        end
                        if mean(this.detailedResistanceHistory) - this.baseResistance > 10
                            this.phase = 3;
                            this.phaseChangeTime = now;
                        end
                        if mean(this.detailedResistanceHistory) < this.desiredResistance
                            this.phase = 'finished';
                            this.status = 'success';
                            this.stopProcess();
                        end
                    case 3
                        this.pressureController.setPressure(20);
                        this.baseResistance = mean(this.detailedResistanceHistory);
                        this.phase = 4;
                        this.phaseChangeTime = now;
                    case 4
                        if time2sec(now - this.phaseChangeTime) > 10
                            this.phase = 1;
                            this.phaseChangeTime = now;
                        end
                        if mean(this.detailedResistanceHistory) - this.baseResistance > 10
                            this.phase = 1;
                            this.phaseChangeTime = now;
                        end
                        if mean(this.detailedResistanceHistory) < this.desiredResistance
                            this.phase = 'finished';
                            this.status = 'success';
                            this.stopProcess();
                        end
                end
            end
        end
        
        function stopProcess(this)
            stop(this.t);
            delete(this.resistanceListener);
            this.amplifier.rsImprovementFinished();
            this.pressureController.setPressure(0);
            this.elphysProcessor.disableBreakInResistance();
        end
    end
    
end

