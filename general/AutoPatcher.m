classdef AutoPatcher < matlab.mixin.SetGet
    %AutoPatcher Autopatcher system
    %   Blind patcher which is responsible for controlling the hunting, sealing and break-in phases of the patch 
    %   clamping process.
    
    properties (Constant, Hidden)
        defaultMinResistanceChangeForDetection = 0.5 % MOhm
        defaultInitialBreakInDelay = 0.5 % sec
        defaultBreakInDelayIncrease = 0.2 % sec
        defaultStepSize = 2
        defaultMaxDistance = 0
        defaultGigasealRvalue = 1200 % MOhm, default value which is considered a gigaseal. Some use higher values, like 1500.
        defaultSuccessBreakInRValue = 300 % MOhm, default value which notes a successful break in if the resistance drops below
        defaultMinDelayBeforeBreakIn = 5 % seconds, minimum value before starting break-in after a gigaseal is formed
        defaultMaxBreakInTime = 190 % seconds, default value of how long the break-in process can take, otherwise fail
        defaultRWindowHistoryTime = 10
        defaultLowPositivePressure = 50
        defaultHighPositivePressure = 300
        defaultLowNegativePressure = -20
        defaultHighNegativePressure = -150
        defaultForwardAxis = 'x';
        defaultBreakInPullBackAfterAttempts = 5;
        defaultBreakInPullBackDistance = 3;
        defaultClogWarningRIncrease = 2;
        defaultSealingCheckAtmosphereIncrease = false;
        defaultCheckHitReproducibility = false;
        defaultPullBackSteps = 4;
        defaultSealingProtocolRValues = [10,20,50,100,500];
        defaultSealingProtocolVoltageValues = [-20,-30,-50,-60,-70];
    end
    
    properties
        forwardAxis
        stepSize % step size per second in the hunting phase
        maxDistance % maximum distance to take in the hunting phase (um), 0 means unlimited
        minResistanceChangeForDetection
        lowPositivePressure
        highPositivePressure
        lowNegativePressure
        highNegativePressure
        initialBreakInDelay
        breakInDelayIncrease % seconds, how much should the break in delay be increased after an attempt
        gigasealRvalue % MOhm, value which is considered a gigaseal
        successBreakInRValue % MOhm, value which notes a successful break in if the resistance drops below
        
        % seconds, minimum value before starting break-in after a gigaseal is formed and after 
        % a successful break-in but before starting amplifier protocols
        minDelayBeforeBreakIn 
        maxBreakInTime % seconds, value of how long the break-in process can take, otherwise fail
        rWindowHistoryTime % how many of the resistance values should be kept, in seconds
        breakInPullBackAfterAttempts % pull back pipette in forward axis after this number of break-in attempts
        breakInPullBackDistance % pull back distance of pipette in break-in phase, used if break-in is considered slow
        clogWarningRIncrease
        sealingCheckAtmosphereIncrease
        checkHitReproducibility % check if the resistance increase is reproducible in hunting phase
        pullBackSteps % number of stepSizes to pull back the pipette when checking hit reproducibility
        sealingProtocolRValues
        sealingProtocolVoltageValues
    end
    
    properties (SetAccess = protected, SetObservable)
        status
        message
        distanceTaken
    end
    
    properties (SetAccess = protected)
        firstResistance
        breakInDelay
        pipetteAmplifierAssociation
        activePipetteIdListener
    end
    
    properties (SetAccess = immutable)
        microscope
        pressureController
        elphysProcessor
        amplifier
    end
    
    properties (Access = protected)
        resistanceHistory % history of R values which does not contain NaNs
        lastResistance % last R value which can be NaN, to indicate if measurement had problems
        maxHistoryNumel
        phase % main phase of patch clamping process
        phaseChangeTime
        subphase % subphase of any main step of the process
        subphaseChangeTime
        t
        resistanceListener
        amplifierSealingProtocolTime
        amplifierSealingLastResistance
        forwardAxisPos % known pipette position in the 'forward' axis, (re)initialized after startFromPhase called.
        randDir % Random direction to vary pipette movement in sealing phase. (Re)initialized after startFromPhase called.
        % Notes if some initialization is required in the timer callback. Required because startFromPhase might not
        % always init some values.
        initRequiredInTimer
        sealingWaitTime % How much the actual sealing subphase should take.
        breakInNumAttempts % number of break-in attempts of the current run
        breakInAlreadyPulledBack % logical
        reproducibilityCounter
        reproducibilityStartR
        sealingStartResistance
    end
    
    properties (SetObservable)
        activePipetteId
    end
    
    
    methods
        function this = AutoPatcher(microscope, pressureController, elphysProcessor, amplifier)
            assert(isa(microscope, 'MicroscopeController'));
            assert(isa(pressureController, 'PressureController'));
            assert(isa(elphysProcessor, 'ElectrophysiologySignalProcessor'));
            this.microscope = microscope;
            this.pressureController = pressureController;
            this.elphysProcessor = elphysProcessor;
            this.t = timer;
            this.t.TimerFcn = @this.timerFcn;
            this.t.Period = 1;
            this.t.ExecutionMode = 'fixedRate';
            this.t.Name = 'AutoPatcher-timer';
            this.t.BusyMode = 'drop';
            this.amplifier = amplifier;
            this.amplifier.startup();
            this.minResistanceChangeForDetection = this.defaultMinResistanceChangeForDetection;
            this.forwardAxis = this.defaultForwardAxis;
            this.stepSize = this.defaultStepSize;
            this.maxDistance = this.defaultMaxDistance;
            this.lowPositivePressure = this.defaultLowPositivePressure;
            this.highPositivePressure = this.defaultHighPositivePressure;
            this.lowNegativePressure = this.defaultLowNegativePressure;
            this.highNegativePressure = this.defaultHighNegativePressure;
            this.initialBreakInDelay = this.defaultInitialBreakInDelay;
            this.breakInDelayIncrease = this.defaultBreakInDelayIncrease;
            this.gigasealRvalue = this.defaultGigasealRvalue;
            this.successBreakInRValue = this.defaultSuccessBreakInRValue;
            this.minDelayBeforeBreakIn = this.defaultMinDelayBeforeBreakIn;
            this.maxBreakInTime = this.defaultMaxBreakInTime;
            this.rWindowHistoryTime = this.defaultRWindowHistoryTime;
            this.status = AutoPatcherStates.NotStarted;
            this.breakInNumAttempts = 0;
            this.breakInAlreadyPulledBack = false;
            this.breakInPullBackAfterAttempts = this.defaultBreakInPullBackAfterAttempts;
            this.breakInPullBackDistance = this.defaultBreakInPullBackDistance;
            this.clogWarningRIncrease = this.defaultClogWarningRIncrease;
            this.reproducibilityCounter = 0;
            this.sealingCheckAtmosphereIncrease = this.defaultSealingCheckAtmosphereIncrease;
            this.checkHitReproducibility = this.defaultCheckHitReproducibility;
            this.pullBackSteps = this.defaultPullBackSteps;
            this.sealingProtocolRValues = this.defaultSealingProtocolRValues;
            this.sealingProtocolVoltageValues = this.defaultSealingProtocolVoltageValues;
            this.activePipetteIdListener = this.addlistener('activePipetteId', 'PostSet', ...
                @(src, event) this.activePipetteIdChangeCb(src, event));
            this.pipetteAmplifierAssociation = containers.Map('KeyType', 'double', 'ValueType', 'double');
        end
        
        function delete(this)
            this.stopFunction();
            delete(this.pressureController);
            delete(this.elphysProcessor);
            delete(this.amplifier);
        end

    
        function start(this, pipetteId)
            %START(obj, pipetteId) Start the blind patch system
            %   Initializes variables, listeners and timers. Then the
            %   pipette is moved regularly, the pressure is controlled and
            %   the electrophysiology signal is monitored which can switch
            %   blind patch states from hunting to successful break in.
            %
            %   start(obj) - start blind patching using the active pipette
            %   start(obj, pipetteId) - set the active pipette ID and start
            %       blind patching
            
            if strcmp(this.t.Running, 'on')
                return
            end
            
            if nargin > 1
                this.activePipetteId = pipetteId;
            end
            assert(~isempty(this.activePipetteId), 'Active pipette ID is empty. Maybe you forgot to set it.');
            this.distanceTaken = 0;
            this.startFromPhase(1);
        end
        
        function startFromBreakIn(this)
            this.startFromPhase(3);
        end
        
        function startFromSeal(this)
            this.startFromPhase(2);
        end
            
        function stop(this)
            %STOP Stop the blind patch system
            %   stop(obj)
            
            this.stopFunction();
            this.status = AutoPatcherStates.Stopped;
        end
        
        function setupInBath(this)
            this.elphysProcessor.disableBreakInResistance();
            this.amplifier.setup();
            this.amplifier.beforeHunt();
            this.pressureController.setPressure(this.lowPositivePressure);
        end
        
        function b = isRunning(this)
            b = false;
            if this.status == AutoPatcherStates.Starting || this.status == AutoPatcherStates.Hunting || ...
                    this.status == AutoPatcherStates.Sealing || this.status == AutoPatcherStates.BreakIn
                b = true;
            end
        end
        
        function set.forwardAxis(this, value)
            assert(any(strcmpi(value, {'x', 'y', 'z'})), 'The forwardAxis can only have a value of ''x'', ''y'' or ''z''.');
            this.forwardAxis = value;
        end
        
        function set.minResistanceChangeForDetection(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>=0, 'Value should be a non-negative number.');
            this.minResistanceChangeForDetection = value;
        end
        
        function set.lowPositivePressure(this, value)
            assert(isnumeric(value) && ~isempty(value), 'Value should be a number.');
            this.lowPositivePressure = value;
        end
        
        function set.highPositivePressure(this, value)
            assert(isnumeric(value) && ~isempty(value), 'Value should be a number.');
            this.highPositivePressure = value;
        end
        
        function set.lowNegativePressure(this, value)
            assert(isnumeric(value) && ~isempty(value), 'Value should be a number.');
            this.lowNegativePressure = value;
        end
        
        function set.highNegativePressure(this, value)
            assert(isnumeric(value) && ~isempty(value), 'Value should be a number.');
            this.highNegativePressure = value;
        end
        
        function set.initialBreakInDelay(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>=0, 'Value should be a non-negative number.');
            this.initialBreakInDelay = value;
        end
        
        function set.breakInDelayIncrease(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>0, 'Value should be a positive number.');
            this.breakInDelayIncrease = value;
        end
        
        function set.stepSize(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>=0, 'Value should be a non-negative number.');
            this.stepSize = value;
        end
        
        function set.maxDistance(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>=0, 'Value should be a non-negative number.');
            this.maxDistance = value;
        end
        
        function set.gigasealRvalue(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0, 'Value should be a positive number.');
            this.gigasealRvalue = value;
        end
        
        function set.successBreakInRValue(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0, 'Value should be a positive number.');
            this.successBreakInRValue = value;
        end
        
        function set.minDelayBeforeBreakIn(this, value)
            assert(~isempty(value) && isnumeric(value) && value >= 0, 'Value should be a non-negative number.');
            this.minDelayBeforeBreakIn = value;
        end

        function set.maxBreakInTime(this, value)
            assert(~isempty(value) && isnumeric(value) && value >= 0, 'Value should be a non-negative number.');
            this.maxBreakInTime = value;
        end
        
        function set.rWindowHistoryTime(this, value)
            assert(~isempty(value) && isnumeric(value) && value==round(value) && value > 1, ...
                'Value should be an integer greater than 1.');
            this.rWindowHistoryTime = value;
        end
        
        function set.breakInPullBackAfterAttempts(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0, 'Value should be an integer greater than 0.');
            this.breakInPullBackAfterAttempts = value;
        end
        
        function set.breakInPullBackDistance(this, value)
            assert(~isempty(value) && isnumeric(value) , 'Value should be a numeric.');
            this.breakInPullBackDistance = value;
        end
        
        function set.sealingCheckAtmosphereIncrease(this, value)
            assert(islogical(value), 'Value should be a logical.');
            this.sealingCheckAtmosphereIncrease = value;
        end
        
        function set.checkHitReproducibility(this, value)
            assert(islogical(value), 'Value should be a logical.');
            this.checkHitReproducibility = value;
        end
        
        function set.pullBackSteps(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0, 'Value should be an integer greater than 0.');
            this.pullBackSteps = value;
        end
        
        function associatePipetteIdWithAmplifierNumber(this, pipetteId, amplifierNumber)
            this.pipetteAmplifierAssociation(pipetteId) = amplifierNumber;
        end
        
        function amplifierNumber = getAmplifierNumberForPipetteId(this, pipetteId)
            amplifierNumber = this.pipetteAmplifierAssociation(pipetteId);
        end
    end
       
    methods (Access = private)
        function resistanceDataChangeCallback(this)
            this.lastResistance = this.elphysProcessor.resistance;
            if ~isnan(this.lastResistance)
                if numel(this.resistanceHistory) < this.maxHistoryNumel
                    this.resistanceHistory = [this.resistanceHistory, this.lastResistance];
                else
                    this.resistanceHistory = [this.resistanceHistory(2:end), this.lastResistance];
                end
            end
            if this.phase == 4 ...% make sure that during break-in we stop pressure controller asap
                    && this.detectBreakIn() % we check if already broke-in as in timer cb
                this.pressureController.setPressure(0);
            end
        end
        
        function startFromPhase(this, phase)
            this.lastResistance = NaN;
            this.maxHistoryNumel = max(10,round(this.rWindowHistoryTime/this.elphysProcessor.getUpdateTime()));
            this.firstResistance = [];
            this.resistanceHistory = [];
            this.resistanceListener = this.elphysProcessor.addlistener('DataChange', ...
                @(src,event) this.resistanceDataChangeCallback());
            this.breakInDelay = this.initialBreakInDelay;
            this.elphysProcessor.disableBreakInResistance();
            this.message = '';
            this.initRequiredInTimer = true;
            this.status = AutoPatcherStates.Starting;
            this.phase = phase;
            this.phaseChangeTime = 0;
            this.breakInNumAttempts = 0;
            this.breakInAlreadyPulledBack = false;
            log4m.getLogger.info(['Starting blind patcher from phase: ', num2str(this.phase)]);
            start(this.t);
        end
        
   
        function timerFcn(this, ~, ~)
            resistance = this.lastResistance;
            if (isempty(this.firstResistance) || isnan(this.firstResistance)) && ~isempty(this.resistanceHistory)
                this.firstResistance = this.resistanceHistory(end);
            end
            log4m.getLogger.trace(['phase = ', num2str(this.phase),', resistance = ', num2str(resistance)]);
            if this.initRequiredInTimer
                try
                    pipette = this.microscope.getPipette(this.activePipetteId);
                    switch this.forwardAxis
                        case 'x'
                            this.forwardAxisPos = pipette.getX();
                        case 'y'
                            this.forwardAxisPos = pipette.getY();
                        case 'z'
                            this.forwardAxisPos = pipette.getZ();
                        otherwise
                            log4m.getLogger().error('Error while communicating with pipette. Stopping blind patching.');
                            this.stopFunction();
                            this.status = AutoPatcherStates.Fail;
                            this.message = 'Unsupported forward axis property.';
                    end
                    pipette.switchToAutomaticSlowSpeed();
                    pipette.switchToAutomaticFastSpeed();
                catch ex
                    log4m.getLogger().error(['Error while communicating with pipette. Stopping blind patching.', ...
                        'Cause: ', ex.message]);
                    this.stopFunction();
                    this.status = AutoPatcherStates.Fail;
                    this.message = 'Pipette communication problem.';
                end
                this.randDir = randi(2)-1;
                if this.randDir == 0
                    this.randDir = -1;
                end
                this.subphase = 0;
                this.initRequiredInTimer = false;
                if this.phase == 1
                    this.amplifier.setup();
                    this.amplifierSealingProtocolTime = 0;
                    this.amplifierSealingLastResistance = 0;
                    this.status = AutoPatcherStates.Hunting;
                elseif this.phase == 2
                    this.amplifierSealingProtocolTime = now;
                    this.status = AutoPatcherStates.Sealing;
                end
                return
            end
            
            pullBackDistance = this.stepSize*this.pullBackSteps;
            switch this.phase
                case 1
                    switch this.subphase % init
                        case 0
                            if abs(this.elphysProcessor.current) > 1000 % should not happen multiple times
                                this.amplifier.setup();
                            end
                            this.pressureController.setPressure(this.lowPositivePressure);
                            this.reproducibilityCounter = 0;
                            this.subphase = 1;
                        case 1 % push forward, hit test
                            if ~isnan(resistance) && ~isempty(this.resistanceHistory)
                                if resistance-min(this.resistanceHistory) > this.minResistanceChangeForDetection
                                    if ~this.checkHitReproducibility
                                        this.switchToSealingPhase();
                                    else
                                        this.subphase = 2;
                                        this.message = 'Checking hit reproducibility.';
                                    end
                                else
                                    if resistance - this.firstResistance > this.clogWarningRIncrease
                                        log4m.getLogger().warn('Possibly the pipette is clogged!');
                                        this.message = 'Pipette might be clogged!';
                                    end
                                    if this.maxDistance > 0 && this.distanceTaken + this.stepSize > this.maxDistance
                                        this.stopFunction();
                                        this.status = AutoPatcherStates.Fail;
                                        this.message = 'Maximum distance reached during hunting phase.';
                                    else
                                        if this.pushPipetteCondition()
                                            this.movePipetteForwardFailsafe(this.stepSize, 'fast');
                                        end
                                    end
                                end
                            end
                        case 2
                            success = this.movePipetteForwardFailsafe(-pullBackDistance, 'slow');
                            this.reproducibilityCounter = 0;
                            if success
                                this.subphase = 3;
                            end
                        case 3
                            switch this.forwardAxis
                                case 'x'
                                    moving = this.microscope.getPipette(this.activePipetteId).isMovingX();
                                case 'y'
                                    moving = this.microscope.getPipette(this.activePipetteId).isMovingY();
                                case 'z'
                                    moving = this.microscope.getPipette(this.activePipetteId).isMovingZ();
                            end
                            if ~moving
                                this.subphase = 4;
                            end
                        case 4
                            if ~isnan(resistance)
                                this.reproducibilityStartR = resistance;
                                this.subphase = 5;
                            end
                        case 5
                            if this.reproducibilityCounter < this.pullBackSteps
                                if this.pushPipetteCondition()
                                    success = this.movePipetteForwardFailsafe(this.stepSize, 'fast');
                                    if success
                                        this.reproducibilityCounter = this.reproducibilityCounter + 1;
                                    end
                                end
                            else
                                if ~isnan(resistance)
                                    if resistance - this.reproducibilityStartR > this.minResistanceChangeForDetection
                                        this.switchToSealingPhase();
                                    else
                                        this.subphase = 6;
                                        this.message = 'Hit not reproducible.';
                                        this.pressureController.setPressure(100); % TODO introduce mid pressure
                                    end
                                end
                            end
                        case 6
                            if this.pressureController.getPressure() >= this.lowPositivePressure
                                this.movePipetteForwardFailsafe(pullBackDistance, 'fast');
                                this.subphase = 7;
                            end
                        case 7
                            switch this.forwardAxis
                                case 'x'
                                    moving = this.microscope.getPipette(this.activePipetteId).isMovingX();
                                case 'y'
                                    moving = this.microscope.getPipette(this.activePipetteId).isMovingY();
                                case 'z'
                                    moving = this.microscope.getPipette(this.activePipetteId).isMovingZ();
                            end
                            if ~moving
                                this.pressureController.setPressure(this.lowPositivePressure);
                                this.subphase = 1;
                            end
                        otherwise
                            errorMsg = ['Unsupported subphase in hunting phase: ', num2str(this.subphase)];
                            this.message = errorMsg;
                            log4m.getLogger().error(errorMsg);
                            error(errorMsg);
                    end
                case 2 % sealing phase
                    if ~isnan(resistance)
                        sealingLastIdx = find(this.sealingProtocolRValues>this.amplifierSealingLastResistance,1); % can be empty
                        sealingIdx = find(this.sealingProtocolRValues>resistance,1); % can be empty
                        if ~isempty(sealingLastIdx)
                            sealingLastIdx = sealingLastIdx -1;
                        else
                            sealingLastIdx = numel(this.sealingProtocolRValues);
                        end
                        if ~isempty(sealingIdx)
                            sealingIdx = sealingIdx - 1;
                        else
                            sealingIdx = numel(this.sealingProtocolRValues);
                        end
                        if sealingIdx > sealingLastIdx
                            this.amplifier.sealing(this.sealingProtocolVoltageValues(sealingIdx));
                            this.amplifierSealingLastResistance = resistance;
                        end
                    end
                    
                    if max(this.resistanceHistory) > this.gigasealRvalue % check if a gigaseal is formed already, possible early break-in should be handled in the next phase
                        this.phase = 3;
                        this.phaseChangeTime = now;
                        this.pressureController.setPressure(0);
                    else
                        this.message = ['Sealing subphase: ', num2str(this.subphase)];
                        this.processSealingPhase();
                    end
                case 3 % 'prepare for break-in' step
                    this.status = AutoPatcherStates.BreakIn;
                    this.phase = 4;
                    this.phaseChangeTime = now;
                    this.pressureController.setPressure(0);
                    this.amplifier.beforeBreakin();
                case 4 % break-in after preparation step, if already broke-in, it should be handled correctly
                    delay = time2sec(now-this.phaseChangeTime);
                    if delay < this.maxBreakInTime && ~isempty(this.resistanceHistory(end))
                        if delay > this.minDelayBeforeBreakIn ...
                                && resistance > this.successBreakInRValue ... % we use the latest resistance value here...
                                && (this.pressureController.state ~= PressureStates.BreakIn)
                            if this.breakInNumAttempts <= this.breakInPullBackAfterAttempts ...
                                    || this.breakInAlreadyPulledBack % check if pipette should be pulled back
                                this.pressureController.breakIn(this.highNegativePressure, this.breakInDelay);
                                this.message = ['Break-in pulse length: ', num2str(this.breakInDelay), ' sec'];
                                this.breakInDelay = this.breakInDelay + this.breakInDelayIncrease;
                                this.breakInNumAttempts = this.breakInNumAttempts + 1;
                            else % pull back pipette
                                this.message = ['Pulling back pipette by ', num2str(this.breakInPullBackDistance), ' um'];
                                this.movePipetteForwardFailsafe(-this.breakInPullBackDistance, 'fast');
                                this.breakInAlreadyPulledBack = true;
                            end
                        elseif this.detectBreakIn() % ... but here if we detect by the last valid R that the cell break-in is complete, we progress
                            this.pressureController.setPressure(0); % cancel possible break-in protocol
                            this.phase = 5;
                            this.phaseChangeTime = now;
                            this.message = ['Waiting ', num2str(this.minDelayBeforeBreakIn), ' seconds before starting amplifier protocol.'];
                        end
                    else
                        this.phase = 6;
                        this.stopFunction();
                        this.status = AutoPatcherStates.Fail;
                        this.message = 'Could not break in! (timeout)';
                    end
                case 5 % give some time to the cell membrane to attach to the pipette wall
                    delay = time2sec(now-this.phaseChangeTime);
                    if delay > this.minDelayBeforeBreakIn
                        this.amplifier.afterBreakIn();
                        this.phase = 6;
                        this.phaseChangeTime = now;
                        this.stopFunction();
                        this.status = AutoPatcherStates.Success;
                        this.message = '';
                    end
                case 6
                    log4m.getLogger().warn('Patch-clamping finished, but callback is still called.');
                otherwise
                    msg = ['Unsupported phase value: ', any2str(this.phase)];
                    log4m.getLogger().error(msg);
                    this.message = msg;
                    this.stopFunction();
                    this.status = AutoPatcherStates.Fail;
            end
        end
        
        function success = movePipetteForwardFailsafe(this, step, speed)
            success = false;
            try
                switch this.forwardAxis
                    case 'x'
                        forward = this.microscope.getPipette(this.activePipetteId).x_forward;
                        this.microscope.movePipetteTo(this.activePipetteId, this.forwardAxisPos+forward*step, [], [], 'speed', speed);
                    case 'y'
                        forward = this.microscope.getPipette(this.activePipetteId).y_forward;
                        this.microscope.movePipetteTo(this.activePipetteId, [], this.forwardAxisPos+forward*step, [], 'speed', speed);
                    case 'z'
                        forward = this.microscope.getPipette(this.activePipetteId).z_forward;
                        forward = -forward;
                        this.microscope.movePipetteTo(this.activePipetteId, [], [], this.forwardAxisPos+forward*step, 'speed', speed);
                end
                this.forwardAxisPos = this.forwardAxisPos + forward*step;
                this.distanceTaken = this.distanceTaken + step;
                success = true;
            catch ex
                log4m.getLogger().error(['Could not move pipette x: ', ex.message]);
            end
        end
        
        function movePipetteFailsafe(this, dir, step, speed)
            try
                switch dir
                    case 'x'
                        this.microscope.movePipette(this.activePipetteId, step, [], [], 'speed', speed);
                    case 'y'
                        this.microscope.movePipette(this.activePipetteId, [], step, [], 'speed', speed);
                    case 'z'
                        this.microscope.movePipette(this.activePipetteId, [], [], step, 'speed', speed);
                end
            catch ex
                log4m.getLogger().error(['Could not move pipette ', dir, ': ', ex.message]);
            end
        end
        
        function processSealingPhase(this)
            previousSubphase = this.subphase;
            if this.subphase == 0
                this.sealingWaitTime = 0;
                if this.sealingCheckAtmosphereIncrease
                    this.subphase = 1;
                else
                    this.subphase = 6;
                end
            end
            
            if time2sec(now-this.subphaseChangeTime) > this.sealingWaitTime
                switch this.subphase
                    case 1
                        this.pressureController.setPressure(0);
                        this.sealingWaitTime = 10;
                        this.subphase = this.subphase + 1;
                    case 2
                        if ~isnan(this.lastResistance)
                            if this.sealingStartResistance - this.lastResistance > this.minResistanceChangeForDetection
                                this.sealingWaitTime = 0;
                                this.subphase = 7;
                            else
                                this.sealingWaitTime = 0;
                                this.subphase = this.subphase + 1;
                                this.pressureController.setPressure(100); % TODO mid pressure
                            end
                        end
                    case 3
                        if this.pressureController.getPressure() >= 100
                            this.movePipetteForwardFailsafe(this.stepSize*2, 'fast');
                            this.subphase = this.subphase + 1;
                        end
                    case 4
                        if this.pressureController.getPressure() >= 100
                            this.movePipetteForwardFailsafe(this.stepSize*2, 'fast');
                            this.subphase = this.subphase + 1;
                        end
                    case 5
                        this.phase = 1;
                        this.subphase = 1;
                        this.amplifierSealingProtocolTime = 0;
                        this.amplifierSealingLastResistance = 0;
                        this.message = 'R did not increased on atmosphere, back to Hunting.';
                        this.status = AutoPatcherStates.Hunting;
                    case 6 % normal sealing after/without atm increase check
                        this.pressureController.setPressure(0);
                        this.sealingWaitTime = 5; % seconds
                        this.subphase = this.subphase + 1;
                    case 7 % atm increase check steps here on success
                        this.pressureController.setPressure(this.lowNegativePressure);
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 0;
                    case 8
                        if this.pressureController.getPressure() <= this.lowNegativePressure % make sure vacuum is applied for at least this time
                            this.subphase = this.subphase + 1;
                            this.sealingWaitTime = 30;
                        end
                    case 9
                        this.pressureController.setPressure(this.lowNegativePressure*1.5);
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 20;
                    case 10
                        this.pressureController.setPressure(this.lowNegativePressure*2);
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 20;
                    case 11
                        this.pressureController.setPressure(this.lowNegativePressure);
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 5;
                    case 12
                        this.movePipetteFailsafe('x', this.randDir*this.stepSize, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 13
                        this.movePipetteFailsafe('x', -this.randDir*this.stepSize*2, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 14
                        this.movePipetteFailsafe('x', this.randDir*this.stepSize, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 15
                        this.movePipetteFailsafe('y', this.randDir*this.stepSize, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 16
                        this.movePipetteFailsafe('y', -this.randDir*this.stepSize*2, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 17
                        this.movePipetteFailsafe('y', this.randDir*this.stepSize, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 18
                        this.movePipetteFailsafe('z', this.randDir*this.stepSize, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 19
                        this.movePipetteFailsafe('z', -this.randDir*this.stepSize*2, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 20
                        this.movePipetteFailsafe('z', this.randDir*this.stepSize, 'slow');
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 2;
                    case 21
                        this.pressureController.setPressure(0);
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 10;
                    case 22
                        this.pressureController.setPressure(this.lowNegativePressure);
                        this.subphase = this.subphase + 1;
                        this.sealingWaitTime = 20;
                    case 23
                        this.pressureController.setPressure(0);
                        this.stopFunction();
                        this.status = AutoPatcherStates.Fail;
                        this.message = 'Could not form gigaseal!';
                    otherwise
                        this.messag = ['Unsupported subphase value: ', num2str(this.subphase)];
                end
            end
            if this.subphase ~= previousSubphase
                this.subphaseChangeTime = now;
            end
        end
        
        function stopFunction(this)
            %STOPFUNCTION Stop the blind patch system
            %   stop(obj)
            
            log4m.getLogger.info('Stopping blind patcher.');
            stop(this.t);
            delete(this.resistanceListener);
            if this.pressureController.getPressure() < 0 
                this.pressureController.setPressure(0);
            end
            this.microscope.getPipette(this.activePipetteId).switchToManualFastSpeed();
            this.microscope.getPipette(this.activePipetteId).switchToManualSlowSpeed();
        end
        
        function tf = detectBreakIn(this)
            tf = false;
            if this.resistanceHistory(end) <= this.successBreakInRValue
                tf = true;
            end
        end
        
        function switchToSealingPhase(this)
            this.pressureController.setPressure(0);
            this.phase = 2;
            this.subphase = 0;
            this.phaseChangeTime = now;
            this.sealingStartResistance = this.resistanceHistory(end);
            this.status = AutoPatcherStates.Sealing;
        end
        
        function tf = pushPipetteCondition(this)
            tf = false;
             if ~isnan(this.lastResistance) && ~isempty(this.resistanceHistory) && ...
                     this.pressureController.getPressure() >= this.lowPositivePressure && ...
                     this.pressureController.getPressure() <= this.lowPositivePressure + 10 % TODO this value should be asked from the pressure controllers error, which can be dynamic based on pressure
                tf  = true;
            end
        end
                
        function activePipetteIdChangeCb(this, ~, event)
            log4m.getLogger().info(['The activePipetteId was changed to: ', num2str(this.activePipetteId)]);
            amplifierNum = this.getAmplifierNumberForPipetteId(this.activePipetteId);
            this.amplifier.amplifierNumber = amplifierNum;
        end
    end
    
end