classdef VisualPatcher < matlab.mixin.SetGet
    %VISUALPATCHER Class for visual patch-clamping control
    %   To start a visual patch clamping, use start().
    %   cellOffset - This offset is only used to orientate the pipette and later not calculated into other values. E.g.
    %   if startAutopatcherAtDistance==0 then the offset is not considered and the real distance between the cell and
    %   the pipette might be this offset value. The reason it is not counted is that then it should be checked if the
    %   pipette would still hit the cell after starting th Autopatcher or the offset is too high. Thus it is the
    %   responsibility of the user to use a reasonable offset value.
    
    properties (Constant, Hidden)
        defaultControlFrameRate = 2
        defaultPipetteStepsize = 1.5
        defaultStartAutopatcherAtDistance = 25
        defaultStopTrackingAtDistance = 20
        defaultRWindowHistoryTime = 10
        defaultDodgePullDistance = 20
        defaultDodgePassDistance = 20
        defaultDodgeDeltaR = 5
        defaultDodgeDeltaPhi = pi/4
        MaxDodgeSteps = 10
        defaultApproachingPressure = 70
        defaultAutopatcherPassDistance = 20
        defaultCellFollowerEnabled = false;
    end
    
    properties
        activePipetteId
        diary
        
        controlFrameRate % controls the pipette movement and stops the tracking when it is close to the cell
        pipetteStepsize
        startAutopatcherAtDistance
        autopatcherPassDistance % autopatcher max distance is set to startAutopatcherAtDistance plus this value
        stopTrackingAtDistance
        rWindowHistoryTime
        approachingPressure
        cellOffset % offset to the target position 
        cellFollowerEnabled
        
        % parameters for obstacle avoidance
        
        dodgePullDistance
        dodgePassDistance
        dodgeDeltaR
        dodgeDeltaPhi
    end
    
    properties (SetObservable)
        paused
    end
    
    properties (SetAccess = protected, SetObservable)
        phase % phase/status of the VisualPatcher
        subphase
        statusMessage
        targetDistance
        dodgePhase
        dodgeStep
    end
    
    properties (SetAccess = immutable)
        autopatcher % AutoPatcher object
        tracker % CellTracker object (owner, deletes)
    end
    
    properties (Access = protected)
        controlTimer
        pipette
    end
    
    properties (Access = private)
        targetXPosition % target cell's x position in the pipette coordinate system (lateral alignment is assumed)
        pipetteXDiffChangeListener
        autopatcherStatusListener
        autopatcherDistanceTakenListener
        resistanceListener
        maxHistoryNumel
        resistanceHistory % history of R values which does not contain NaNs
        dodgePullTargetPosition
        dodgeStartPipettePosition
        targetStageCoord
        sampleTop
        pausedListener
        approachOnly
    end
    
    methods
        function this = VisualPatcher(autopatcher, tracker)
            assert(~isempty(autopatcher) && isa(autopatcher, 'AutoPatcher'));
            this.autopatcher = autopatcher;
            assert(~isempty(tracker) && isa(tracker, 'CellTracker'));
            this.tracker = tracker;
            this.paused = false;
            this.controlFrameRate = this.defaultControlFrameRate;
            this.controlTimer = timer();
            this.controlTimer.TimerFcn = @(obj, event) this.controlCb();
            this.controlTimer.ExecutionMode  = 'fixedRate';
            this.controlTimer.BusyMode = 'drop';
            this.controlTimer.Name = 'Visual Patcher Control Timer';
            this.startAutopatcherAtDistance = this.defaultStartAutopatcherAtDistance;
            this.autopatcherPassDistance = this.defaultAutopatcherPassDistance;
            this.stopTrackingAtDistance = this.defaultStopTrackingAtDistance;
            this.statusMessage = '';
            this.pipetteStepsize = this.defaultPipetteStepsize;
            this.dodgePullDistance = this.defaultDodgePullDistance;
            this.dodgePassDistance = this.defaultDodgePassDistance;
            this.dodgeDeltaR = this.defaultDodgeDeltaR;
            this.dodgeDeltaPhi = this.defaultDodgeDeltaPhi;
            this.cellOffset = [0, 0, 0];
            this.pipetteXDiffChangeListener = this.tracker.addlistener('lastPipetteXDifference', 'PostSet', ...
                @(src,event) this.pipetteXDiffChange_Callback());
            this.rWindowHistoryTime = this.defaultRWindowHistoryTime;
            this.approachingPressure = this.defaultApproachingPressure;
            this.pausedListener = this.addlistener('paused', 'PostSet', @(src, event) this.pausedListenerCb());
            this.cellFollowerEnabled = this.defaultCellFollowerEnabled;
        end
        
        function delete(this)
            this.stopFunction();
            deleteTimer(this.controlTimer);
            delete(this.tracker);
            deleteHandles(this.pipetteXDiffChangeListener);
            deleteHandles(this.autopatcherStatusListener);
            deleteHandles(this.diary);
            deleteHandles(this.pausedListener);
        end
        
        %% getter/setters
        
        function set.controlFrameRate(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0);
            this.controlFrameRate = value;
        end
        
        function set.pipetteStepsize(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0);
            this.pipetteStepsize = value;
        end
        
        function set.targetXPosition(this, value)
            assert(~isempty(value) && isnumeric(value));
            this.targetXPosition = value;
        end
        
        function set.startAutopatcherAtDistance(this, value)
            assert(~isempty(value) && isnumeric(value) && value >= 0);
            this.startAutopatcherAtDistance = value;
        end
        
        function set.stopTrackingAtDistance(this, value)
            assert(~isempty(value) && isnumeric(value));% && value > 0);
            this.stopTrackingAtDistance = value;
        end
        
        function set.diary(this, diary)
            assert(isempty(diary) || isa(diary, 'PatchClampDiary'), 'Variable ''diary'' should be empty or a PatchClampDiary object!');
            this.diary = diary;
        end
        
        function set.dodgePullDistance(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.dodgePullDistance = value;
        end
        
        function set.dodgePassDistance(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>=0);
            this.dodgePassDistance = value;
        end
        
        function set.dodgeDeltaR(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.dodgeDeltaR = value;
        end
        
        function set.dodgeDeltaPhi(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.dodgeDeltaPhi = value;
        end
        
        function set.rWindowHistoryTime(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.rWindowHistoryTime = value;
        end
        
        function set.approachingPressure(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.approachingPressure = value;
        end
        
        function set.autopatcherPassDistance(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>=0);
            this.autopatcherPassDistance = value;
        end
        
        function set.paused(this, value)
            assert(islogical(value), 'Value should be a logical!');
            this.paused = value;
        end
        
        function set.cellOffset(this, value)
            assert(isnumeric(value) && ~isempty(value) && isrow(value) && numel(value)==3, ...
                'Value should be a 3 element numeric row vector.');
            this.cellOffset = value;
        end
        
        function set.cellFollowerEnabled(this, value)
            assert(islogical(value), 'Value should be a logical!');
            this.cellFollowerEnabled = value;
        end
        
        %% user functions
        
        function start(this, stageCoord, sampleTop, varargin)
        % START Start the visual patch-clamping process

            if nargin < 3
                error('Not enough input parameters: stageCoord, sampleTop. Optional named parameters: ''pipetteId'', ''approachOnly''.');
            end
        
            p = inputParser;
            addParameter(p, 'pipetteId', []);
            addParameter(p, 'approachOnly', false);
            parse(p, varargin{:});

            pipetteId = p.Results.pipetteId;
            this.approachOnly = p.Results.approachOnly;

            if isempty(pipetteId)
                pipetteMap = this.autopatcher.microscope.getPipetteList();
                if pipetteMap.length() == 0
                    errorMsg = 'No pipettes are associated to the microscope object!';
                    log4m.getLogger().error(errorMsg);
                    error(errorMsg);
                end
                pipetteId = pipetteMap.keys{1};
            end
            
            this.logDiary(['Starting targeted patch-clamp at stage location: ', num2str(stageCoord(1)), ' ', ...
                num2str(stageCoord(2)), ' ', num2str(stageCoord(3))]);
            this.activePipetteId = pipetteId;
            this.pipette = this.autopatcher.microscope.getPipette(this.activePipetteId);
            this.sampleTop = sampleTop;
            this.targetStageCoord = stageCoord;
            
            delete(this.autopatcherDistanceTakenListener)
            this.autopatcherDistanceTakenListener = [];
            this.controlTimer.Period = 1/this.controlFrameRate;
            this.phase = 0;
            this.subphase = 0;
            this.targetDistance = [];
            this.dodgePhase = 0;
            this.dodgeStep = 0;
            this.dodgePullTargetPosition = [];
            this.dodgeStartPipettePosition = [];
            this.maxHistoryNumel = max(1,round(this.rWindowHistoryTime*this.controlFrameRate));
            this.resistanceHistory = [];

            start(this.controlTimer);
        end
        
        function stop(this)
            this.stopFunction();
            this.statusMessage = 'Stopped';
            if ~isempty(this.phase) && this.autopatcher.isRunning()
                this.autopatcher.stop();
            end
        end
        
        function tf = isRunning(this)
            tf = false;
            if ~isempty(this.controlTimer)
                if strcmp(this.controlTimer.Running,'on')
                    tf = true;
                end
            end
        end
    end
    
    methods (Access = protected)
        
        function startTracking(this)
            this.tracker.start();
        end
        
        function stopTracking(this)
            this.tracker.stop();
        end
        
        function controlCb(this)
            if this.paused
                log4m.getLogger().trace('VisualPatcher control callback function called. phase = paused');
                return
            end
            
            log4m.getLogger().trace(['VisualPatcher control callback function called. phase = ', num2str(this.phase)]);
            resistance = this.autopatcher.elphysProcessor.resistance;
            log4m.getLogger().trace(['dodgePhase = ', num2str(this.dodgePhase), ', dodgeStep = ', num2str(this.dodgeStep), ', resistance = ', num2str(resistance)]);
            if ~isnan(resistance) % check if it is okay here after putting dodging in
                if numel(this.resistanceHistory) < this.maxHistoryNumel
                    this.resistanceHistory = [this.resistanceHistory, resistance];
                else
                    this.resistanceHistory = [this.resistanceHistory(2:end), resistance];
                end
            end
            if this.phase == 0
                this.performInitializationSteps();
            elseif this.phase == 1
                this.checkTrackingDistance();
                this.performApproachingSteps(resistance);
            elseif this.phase == 2
                if this.tracker.isRunning()
                    this.stopTracking();
                    this.diary.logPatchClampInfo('DistanceFromOriginalPosition', this.tracker.distanceFromOriginalPosition);
                    log4m.getLogger().warn('Tracker is running but it should have ended in the previous phase.');
                end
                this.autopatcher.pressureController.setPressure(this.autopatcher.lowPositivePressure);
                if ~this.approachOnly
                    this.phase = this.phase + 1;
                else
                    this.statusMessage = '''Approach only'' finished.';
                    this.stopFunction();
                end
            elseif this.phase == 3
                this.statusMessage = 'Starting Autopatcher';
                this.phase = this.phase + 1;
                this.subphase = 0;
                this.autopatcherDistanceTakenListener = this.autopatcher.addlistener('distanceTaken', 'PostSet', ...
                    @(src,event) this.autopatcherDistanceTakenListenerCb());
                this.createAutopatcherStatusListener();
                
                this.stopFunction(true); % continues = true to keep pipette speed
                stopMessage = 'Stopping VisualPatcher, control is left to AutoPatcher.';
                this.phase = this.phase + 1;
                this.logDiary('Starting AutoPatcher from VisualPatcher');
                this.logDiary(stopMessage);
                this.autopatcher.start(this.activePipetteId); % autopatcher.start can take some time, so the next phase is not merged to give it a moment
            end
        end
        
        function logDiary(this, message)
            try
                if ~isempty(this.diary)
                    this.diary.log(message);
                end
            catch ex
                log4m.getLogger().error(['Could not write diary entry: ', ex.message]);
            end 
        end
        
        function checkTrackingDistance(this)
            try
               log4m.getLogger().trace(['Target distance: ', num2str(this.targetDistance)]);
               if this.tracker.isRunning() && this.targetDistance <= this.stopTrackingAtDistance
                   log4m.getLogger().info('Tracking stopped, wish you the best!');
                   this.statusMessage = 'Tracking stopped.';
                   this.stopTracking();
                   this.diary.logPatchClampInfo('DistanceFromOriginalPosition', this.tracker.distanceFromOriginalPosition);
                   this.tracker.adjustPipette(true); % force adjustment
               end
            catch ex
                log4m.getLogger().debug(['Could not get pipette X position. Trying again in the next timer tick. Error: ', ex.message]);
            end
        end
    end
    
    methods (Access = private)
        function pipetteXDiffChange_Callback(this)
            lastDiffValue = this.tracker.lastPipetteXDifference;
            this.targetXPosition = this.targetXPosition + lastDiffValue;
            this.targetDistance = this.targetDistance + this.pipette.x_forward*lastDiffValue;
        end
        
        function createAutopatcherStatusListener(this)
            deleteHandles(this.autopatcherStatusListener);
            this.autopatcherStatusListener = this.autopatcher.addlistener('status', 'PostSet', ...
                @(src,event) this.autopatcherStatusChangeCallback());
        end
        
        function autopatcherStatusChangeCallback(this)
            if ~isvalid(this)
                return
            end
            if this.autopatcher.status == AutoPatcherStates.Stopped || ...
                    this.autopatcher.status == AutoPatcherStates.Sealing || ...
                    this.autopatcher.status == AutoPatcherStates.BreakIn || ...
                    this.autopatcher.status == AutoPatcherStates.Success || ...
                    this.autopatcher.status == AutoPatcherStates.Fail    
                if this.isRunning()
                    if this.autopatcher.status == AutoPatcherStates.Stopped
                        this.statusMessage = 'Stopped because Autopatcher has stopped.';
                    else
                        this.statusMessage = 'Stopped because Autopatcher has found a cell.';
                    end
                    this.stopFunction();
                end
            end
            
            apFirstResistance = [];
            breakInDelay = [];
            distanceTaken = [];
            try
                apStatus = char(this.autopatcher.status);
                apFirstResistance = this.autopatcher.firstResistance;
                breakInDelay = this.autopatcher.breakInDelay;
                distanceTaken = this.autopatcher.distanceTaken;
            catch ex
                log4m.getLogger.warn(['Could not get AutoPatcher status. It might be deleted.', ex.message]);
                apStatus = 'error getting status';
            end
            startMsg = 'VisualPatcher has finished. Autopatcher status: ';
            this.statusMessage = [startMsg, apStatus];
            diaryEntry = ['Autopatcher status changed: ', apStatus, ...
                          ', firstResistance=', num2str(apFirstResistance), ...
                          ', breakInDelay=', num2str(breakInDelay), ...
                          ', distanceTaken=' num2str(distanceTaken)];
            this.logDiary(diaryEntry);
        end
        
        function autopatcherDistanceTakenListenerCb(this)
            this.targetDistance = this.startAutopatcherAtDistance - this.autopatcher.distanceTaken;
            if this.isRunning() && (this.targetDistance < -this.autopatcherPassDistance) && (this.autopatcher.status == AutoPatcherStates.Hunting)
                this.autopatcher.stop();
                this.statusMessage = 'VisualPatcher has finished. No resistance increase was detected near the target.';
                delete(this.autopatcherDistanceTakenListener);
                this.autopatcherDistanceTakenListener = [];
            end
            
            if this.cellFollowerEnabled && ~this.isRunning() && this.targetDistance < -this.cellOffset(3)
                stageZ = this.tracker.zStartPos + this.targetDistance + this.cellOffset(3);
                this.autopatcher.microscope.stage.moveTo([], [], stageZ);
            end
        end
        
        function pausedListenerCb(this)
            if this.isRunning()
                if this.paused
                    this.statusMessage = 'Paused';
                else
                    this.statusMessage = 'Unpaused';
                end
            end
        end
        
        function performInitializationSteps(this)
            % initialization steps
            if this.subphase == 0
                if this.stopTrackingAtDistance < this.startAutopatcherAtDistance
                    this.stop();
                    this.statusMessage = 'Not supported parameter combination: ''stopTrackingAtDistance'' cannot be less than ''startAutopatcherAtDistance''';
                    return
                end
                this.statusMessage = 'Initializing';
                this.autopatcher.pressureController.setPressure(this.approachingPressure);
                this.subphase = this.subphase + 1;
            elseif this.subphase == 1
                try
                    this.autopatcher.microscope.centerCameraToCoord(this.targetStageCoord); % waits
                    [imw, imh] = this.autopatcher.microscope.camera.getResolution();
                    tartgetPx = [round(imw/2), round(imh/2)];
                    this.tracker.yStartPos = round(tartgetPx(2));
                    this.tracker.xStartPos = round(tartgetPx(1));
                    this.tracker.zStartPos = this.targetStageCoord(3);
                    this.statusMessage = 'Initializing';
                    this.subphase = this.subphase + 1;
                catch ex
                    this.statusMessage = 'Initializing (stage communication error)';
                    log4m.getLogger().warn(['Could not move stage: ', ex.message]);
                end
            elseif this.subphase == 2
                try
                    if this.targetStageCoord(3) ~= this.autopatcher.microscope.stage.getZ()
                        this.autopatcher.microscope.stage.moveTo([],[],this.targetStageCoord(3), 'speed', 'fast');
                        this.autopatcher.microscope.stage.waitForFinishedZ();
                    end
                    this.tracker.setTemplateImage(this.autopatcher.microscope.camera.capture());
                    this.statusMessage = 'Initializing';
                    this.subphase = this.subphase + 1;
                catch ex
                    this.statusMessage = 'Initializing (stage communication error)';
                    log4m.getLogger().warn(['Could not move stage: ', ex.message]);
                end
            elseif this.subphase == 3
                try
                    this.pipette.switchToAutomaticSlowSpeed();
                    this.pipette.switchToAutomaticFastSpeed();
                    this.statusMessage = 'Initializing';
                    this.subphase = this.subphase + 1;
                catch ex
                    this.statusMessage = 'Initializing (pipette communication error)';
                    log4m.getLogger().warn(['Pipette communication error: ', ex.message]);
                end
            elseif this.subphase == 4
                if this.autopatcher.pressureController.getPressure() >= this.approachingPressure
                    newPipetteCoord = this.pipette.microscope2pipette(this.targetStageCoord + this.cellOffset, 'absolute');
                    steps = this.pipette.calculateSmartMoveToSteps(newPipetteCoord(1), newPipetteCoord(2), newPipetteCoord(3), this.sampleTop);
                    lastStep = steps(end,:);
                    try
                        this.pipette.executeSmartMoveToSteps(steps(1:end-1,:));
                        if ~isnan(lastStep{1}(2)) || ~isnan(lastStep{1}(3)) % this should not be reached by intended functioning of PipetteController
                            lastLateralStep = steps(end,:);
                            lastLateralStep{1}(1) = NaN;
                            this.pipette.executeSmartMoveToSteps(lastLateralStep);
                        end
                        this.targetXPosition = lastStep{1}(1);
                        this.statusMessage = 'Initializing';
                        this.subphase = this.subphase + 1;
                    catch ex
                    this.statusMessage = 'Initializing (pipette communication error)';
                    log4m.getLogger().warn(['Pipette communication error: ', ex.message]);
                    end
                else
                    this.statusMessage = 'Initializing (waiting for pressure)';
                    log4m.getLogger().trace('Waiting 1 sec for pressure.');
                end
            elseif this.subphase == 5
                try
                    this.targetDistance = this.pipette.x_forward*(this.targetXPosition - this.pipette.getX());
                    this.logDiary(['Initializing VisualPatcher, target distance is: ', num2str(round(this.targetDistance, 2)), ...
                        ', starting AutoPatcher at distance: ', num2str(round(this.startAutopatcherAtDistance, 2)), ...
                        ', stopping cell tracking at distance: ', num2str(round(this.stopTrackingAtDistance, 2)), ...
                        ', target depth: ', num2str(round(this.sampleTop-this.targetStageCoord(3), 2))]);
                    this.startTracking();
                    this.phase = this.phase + 1;
                    this.subphase = 0;
                    this.statusMessage = 'Tracking and approaching';
                catch ex
                    log4m.getLogger().warn(['Could not get pipette X position, trying again later: ', ex.message]);
                end
            end
        end
        
        function performApproachingSteps(this, resistance)
            % 1. step: pipette movement until 'close', then start autopatcher
            movingX = true;
            try
                movingX = this.pipette.isMovingX();
            catch ex
                log4m.getLogger().warn(['Could not determine if pipette X is moving, but assuming it does and continuing. ', ...
                    'Error msg: ', ex.message]);
            end
            log4m.getLogger().trace(['Target distance is: ', num2str(this.targetDistance)]);
            if this.targetDistance > this.startAutopatcherAtDistance
                log4m.getLogger().trace(['DodgeStep: ', num2str(this.dodgeStep), ', DodgePhase: ', num2str(this.dodgePhase)]);
                validResistance = ~isnan(resistance) && ~isempty(this.resistanceHistory);
                if (validResistance && (max(this.resistanceHistory)-min(this.resistanceHistory)) < 2) || ...% no obstacle found
                        this.dodgePhase > 0
                    if this.dodgePhase == 0
                        if this.dodgeStep == 0 || ... % no obstacle (this check is not really needed, but okay)
                                (~isempty(this.dodgePullTargetPosition) && abs((this.targetXPosition - this.pipette.x_forward*this.targetDistance) - this.dodgePullTargetPosition) <= this.dodgePullDistance + this.dodgePassDistance) % or have not passed the previous yet
                            %% TODO check this logical above
                            if ~movingX
                                if this.targetDistance > this.pipetteStepsize
                                    position = this.targetXPosition - this.pipette.x_forward*this.targetDistance + this.pipette.x_forward*this.pipetteStepsize;
                                else
                                    position = this.targetXPosition;
                                end
                                try
                                    this.pipette.moveTo(position, [], [], 'speed', 'slow');
                                    this.targetDistance = this.pipette.x_forward*(this.targetXPosition - position);
                                catch ex
                                    log4m.getLogger().warn(['Could not move pipette closer to cell, trying again later. Error msg: ', ...
                                        ex.message]);
                                end
                            else
                                log4m.getLogger().debug(['The pipette is still moving. If it happens a lot, ', ...
                                    'maybe lower the control frame rate or reduce the stepsize.']);
                            end
                        else % passed obstacle, revert pipette to center, reset variables
                            if this.dodgeStep > 0
                                if ~movingX
                                    try
                                        this.pipette.moveTo([], this.dodgeStartPipettePosition(2), this.dodgeStartPipettePosition(3), 'speed', 'slow'); 
                                        this.dodgeStep = -1;
                                    catch ex
                                        log4m.getLogger().warn(['Could not move pipette laterally, trying again later. Error msg: ', ...
                                            ex.message]);
                                    end
                                end
                            else % this.dodgeStep < 0 here which means we are waiting for pipette yz
                                movingY = true;
                                movingZ = true;
                                try
                                    movingY = this.pipette.isMovingY();
                                    movingZ = this.pipette.isMovingZ();
                                catch ex
                                    log4m.getLogger().warn(['Pipette communication error, trying again later. Error: ', ex.message]);
                                end
                                if ~movingY && ~movingZ
                                    this.dodgeStep = 0;
                                    this.tracker.autoAdjust = true;
                                    this.dodgePullTargetPosition = [];
                                    this.dodgeStartPipettePosition = [];
                                end
                            end
                        end
                    elseif this.dodgePhase == 1 % pull back pipette
                        if ~movingX
                            try
                                this.pipette.moveTo(this.dodgePullTargetPosition, [], [], 'speed', 'slow');
                                this.targetDistance = this.pipette.x_forward*(this.targetXPosition - this.dodgePullTargetPosition);
                                this.dodgePhase = 2;
                            catch ex
                                log4m.getLogger().warn(['Could not move pipette, trying again later. Error msg: ', ...
                                    ex.message]);
                            end
                        end
                    elseif this.dodgePhase == 2 % wait pipette x and move laterally
                        if ~movingX
                            try
                                dr = this.dodgeDeltaR;
                                dPhi = this.dodgeDeltaPhi;
                                n = this.dodgeStep;
                                displacement = n*dr*sin(n*dPhi-pi/4)-1i*n*dr*cos(n*dPhi-pi/4);
                                displacement = [-real(displacement), imag(displacement)];
                                this.pipette.moveTo([], ...
                                    this.dodgeStartPipettePosition(2) + this.pipette.y_forward*displacement(2), ...
                                    this.dodgeStartPipettePosition(3) + this.pipette.z_forward*displacement(1), ...
                                    'speed', 'slow');
                                this.dodgePhase = 3;
                            catch ex
                                log4m.getLogger().warn(['Could not move pipette laterally, trying again later. Error msg: ', ...
                                    ex.message]);
                            end
                        end
                    elseif this.dodgePhase == 3 % wait lateral y z
                        movingY = this.pipette.isMovingY();
                        if ~movingY % check separately, because it can take time
                            movingZ = this.pipette.isMovingZ();
                            if ~movingZ
                                this.dodgePhase = 0;
                            end
                        end
                    end
                elseif validResistance % obstacle found
                    this.resistanceHistory = min(this.resistanceHistory);
                    dodgeDisabled = false;
                    if this.dodgeStep == 0
                        if this.targetDistance - this.dodgePassDistance >= this.startAutopatcherAtDistance
                            this.tracker.autoAdjust = false;
                            this.dodgePullTargetPosition = this.targetXPosition - this.pipette.x_forward*this.targetDistance - this.pipette.x_forward*this.dodgePullDistance;
                            success = false;
                            attempts = 0;
                            while ~success
                                attempts = attempts + 1;
                                if attempts >= 10
                                    log4m.getLogger().error('Could not retrieve pipette position multiple times, stopping.');
                                    this.statusMessage = 'Stopped due to pipette communication error.';
                                    this.stopFunction();
                                    this.phase = 4; % just to make sure nothing will happen if re-enters
                                    this.logDiary('Stopping VisualPatcher: could not get pipette position.');
                                    break;
                                end
                                try
                                    this.dodgeStartPipettePosition = this.pipette.getPosition();
                                    success = true;
                                catch ex
                                    log4m.getLogger().warn(['Could not retrieve pipette position, trying again. Error msg: ', ex.message]);
                                    pause(0.5);
                                end
                            end
                        else
                            dodgeDisabled = true;
                            this.statusMessage = 'Stopped due an obstacle found too close to the target.';
                            this.stopFunction();
                            this.phase = 4; % just to make sure nothing will happen if re-enters
                            this.logDiary('Stopping VisualPatcher: obstacle found too close to the target.');
                            log4m.getLogger().trace('Stopping Visual patcher, obstacle found too close to the target.');
                        end
                    end
                    if ~dodgeDisabled
                        this.dodgeStep = this.dodgeStep + 1;
                        if this.dodgeStep > this.MaxDodgeSteps
                            this.statusMessage = 'Stopped due to too many obstacles.';
                            this.stopFunction();
                            this.phase = 4; % just to make sure nothing will happen if re-enters
                            this.logDiary('Stopping VisualPatcher: could not reach target due to too many obstacles.');
                            log4m.getLogger().trace('Stopping Visual patcher, could not reach target due to too many obstacles.');
                        else
                            this.dodgePhase = 1;
                        end
                    end
                end
            elseif ~movingX
                log4m.getLogger().trace('Switching to phase 2');
                this.phase = this.phase + 1;
            end
        end
        
        function stopFunction(this, continues)
            if nargin < 2
                continues = false;
            end

            this.stopTracking();
            if this.isRunning()
                stop(this.controlTimer);
            end
            if ~continues && ~isempty(this.pipette) && isvalid(this.pipette)
                this.pipette.switchToManualFastSpeed();
                this.pipette.switchToManualSlowSpeed();
            end
        end
    end
    
end

 