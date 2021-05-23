classdef CellTracker < matlab.mixin.SetGet
    %CELLTRACKER Real-time cell tracking for the patch clamping process
    %   
    
    events
        PositionUpdate
    end
    
    properties (Constant, Hidden)
        defaultZstep = 1
        defaultRadius = 120
        defaultDistanceThreshold = 5
        defaultTrackerFrameRate = 1
        defaultNumZ = 7
        defaultReinitPercent = 0.1
        defaultReinitNumpoints = 10
        defaultCorrZsameMultiplier = 0.95
        defaultAutoAdjust = true
    end
    
    properties (SetAccess = immutable)
        microscope % MicroscopeController object
    end
    
    properties
        xStartPos % x position in pixels where the pipette is targeted
        yStartPos % y position in pixels where the pipette is targeted
        zStartPos % z position in um where the pipette is targeted
        zStep % step size in +/- z direction to track the cell
        radius % window size for cell tracking
        distanceThreshold % adjust pipette if the cell is detected to be at least this much um away
        trackerFrameRate % approximately how many times should the tracking function run in one second
        numZ % stack size to use for tracking in z direction
        reinitPercent % reinit feature points when percentage of valid point is less than this value compared to the initial
        reinitNumpoints % reinit feature points when number of points falls below (useful if num feature points is low)
        corrZsameMultiplier % correlation multiplier for z direction tracking, because same position corr value is usually very high (should be ~1)
        autoAdjust % toggle to automatically adjust the pipette or just track the cell
    end
    
    properties (SetAccess = protected, SetObservable)
        lastPipetteXDifference % target x change at last adjustment in pipette coordinates, which is not adjusted by the tracker
        distanceFromOriginalPosition % distance of the tracked region from the original position in um
        distanceFromTargetedPosition % distance of the tracked region from the targeted position in um
    end
    
    properties (SetAccess = protected)
        xPos % the most recent x position while tracking (px)
        yPos % the most recent y position while tracking (px)
        zPos % the most recent z position while tracking (um)
        originalXPosition % value of xStartPos when the tracker was started
        originalYPosition % value of yStartPos when the tracker was started
        originalZPosition % value of zStartPos when the tracker was started
    end
    
    properties (Access = protected)
        templateImage % initial image that will be used for tracking
        templateXStartPos % x position on the template image where the z similarity calculations should be performed
        templateYStartPos % y position on the template image where the z similarity calculations should be performed
        
        phase
        sameZImage
        belowImage
        aboveImage
        corrZSame
        corrXYSame
        corrBelow
        corrAbove
        
        points % feature point objects
        numInitialPoints
        tracker
        imgstack
        
        trackingTimer
    end
    
    methods
        function this = CellTracker(microscope)
            assert(~isempty(microscope) && isa(microscope, 'MicroscopeController'));
            this.microscope = microscope;
            this.reset();
            this.zStep = this.defaultZstep;
            this.radius = this.defaultRadius;
            this.distanceThreshold = this.defaultDistanceThreshold;
            this.trackerFrameRate = this.defaultTrackerFrameRate;
            this.numZ = this.defaultNumZ;
            this.reinitPercent = this.defaultReinitPercent;
            this.reinitNumpoints = this.defaultReinitNumpoints;
            this.corrZsameMultiplier = this.defaultCorrZsameMultiplier;
            this.autoAdjust = this.defaultAutoAdjust;
        end
        
        function delete(this)
            this.deleteTimer();
        end
        
        %% getters/setters
        
        function set.numZ(this, value)
            assert(isnumeric(value) && ~isempty(value) && value > 3 && round(value)==value);
            this.numZ = value;
        end
        
        function set.reinitPercent(this, value)
            assert(isnumeric(value) && ~isempty(value) && value>0 && value<=1);
            this.reinitPercent = value;
        end
        
        function set.reinitNumpoints(this, value)
            assert(isnumeric(value) && ~isempty(value) && round(value)==value && value > 0);
            this.reinitNumpoints = value;
        end
        
        function set.corrZsameMultiplier(this, value)
            assert(isnumeric(value) && ~isempty(value) && value > 0);
            this.corrZsameMultiplier = value;
        end
        
        function set.templateImage(this, value)
            assert(~isempty(value) && isnumeric(value));
            this.templateImage = value;
            %% for figure generation, delete later
%             global trackingTemplateImage
%             trackingTemplateImage = value;
            %%
        end
        
        function set.xStartPos(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0);
            this.xStartPos = value;
        end
        
        function set.yStartPos(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0);
            this.yStartPos = value;
        end
        
        function set.zStartPos(this, value)
            assert(~isempty(value) && isnumeric(value));
            this.zStartPos = value;
        end
        
        function set.zStep(this, value)
            assert(~isempty(value));
            assert(isnumeric(value));
            assert(value > 0);
            this.zStep = value;
        end
        
        function set.radius(this, value)
            assert(~isempty(value) && isnumeric(value) && value >=0);
            this.radius = value;
        end
        
        function set.distanceThreshold(this, value)
            assert(~isempty(value) && isnumeric(value) && value >0);
            this.distanceThreshold = value;
        end
        
        function set.trackerFrameRate(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0);
            this.trackerFrameRate = value;
        end
        
        function set.lastPipetteXDifference(this, value)
            assert(~isempty(value) && isnumeric(value));
            this.lastPipetteXDifference = value;
        end
        
        function set.autoAdjust(this, value)
            assert(~isempty(value) && islogical(value));
            this.autoAdjust = value;
        end
        
        %% user functions
        
        function reset(this)
            if this.isRunning()
                error('Cannot reset while running.');
            end
            this.phase = 0;
            this.xPos = [];
            this.yPos = [];
            this.zPos = [];
            this.sameZImage = [];
            this.belowImage = [];
            this.aboveImage = [];
            this.deleteTimer();
        end
        
        function initialize(this)
%             assert(~isempty(this.microscope));
            if isempty(this.templateImage)
                this.templateImage = this.microscope.camera.capture();
            end
            this.templateXStartPos = this.xStartPos;
            this.templateYStartPos = this.yStartPos;
            objectRegion = [this.xStartPos-this.radius, this.yStartPos-this.radius, 2*this.radius+1, 2*this.radius+1];
            modifiedRegion = false;
            if objectRegion(1) < 1
                objectRegion(1) = 1;
                modifiedRegion = true;
            end
            if objectRegion(2) < 1
                objectRegion(2) = 1;
                modifiedRegion = true;
            end
            [sy, sx] = size(this.templateImage);
            if sx < objectRegion(1) + objectRegion(3)
                objectRegion(3) = sx-objectRegion(1);
            end
            if sy < objectRegion(2) + objectRegion(4)
                objectRegion(2) = sy-objectRegion(2);
            end
            if modifiedRegion
                log4m.getLogger().warn('ROI was modified because it has regions outside the image. It might be too small now.');
            end
            this.points = detectMinEigenFeatures(this.templateImage,'ROI',objectRegion);
%             this.points = detectHarrisFeatures(this.templateImage,'ROI',objectRegion);
            this.points = this.points.Location;
            this.numInitialPoints = size(this.points,1);
            this.tracker = vision.PointTracker('MaxBidirectionalError',1);
            initialize(this.tracker,this.points,im2double(this.templateImage));
            this.lastPipetteXDifference = 0;
            this.originalXPosition = this.xStartPos;
            this.originalYPosition = this.yStartPos;
            this.originalZPosition = this.zStartPos;
            this.distanceFromOriginalPosition = 0;
            this.distanceFromTargetedPosition = 0;
        end
        
        function setTemplateImage(this, templateImage)
            if this.isRunning()
                error('Setting the template image is not allowed from outside while the tracker is running.');
            end
            this.templateImage = templateImage;
        end
        
        function start(this)
            if ~this.isRunning()
                this.reset();
                this.initialize();
                if isempty(this.trackingTimer)
                    this.trackingTimer = timer();
                    this.trackingTimer.TimerFcn = @(obj, event) this.trackingCb();
                    this.trackingTimer.ExecutionMode  = 'fixedRate';
                    this.trackingTimer.Period = 1/this.trackerFrameRate;
                    this.trackingTimer.BusyMode = 'drop';
                    this.trackingTimer.Name = 'Tracking timer';
                    start(this.trackingTimer);
                elseif strcmp(this.trackingTimer.Running, 'off')
                    start(this.trackingTimer);
                end
            end
        end
        
        function stop(this)
            if this.isRunning()
                stop(this.trackingTimer);
                notify(this,'PositionUpdate');
            end
        end
        
        function tf = isRunning(this)
            tf = false;
            if ~isempty(this.trackingTimer)
                if strcmp(this.trackingTimer.Running,'on')
                    tf = true;
                end
            end
        end
        %%
        
        function lineHandles = drawOnAxis(this, axes)
        %DRAWONAXIS Draw current status on the input axes
        %   If the tracker is running, draws the tracked region's bounding box on the input axes. If the tracker is
        %   stopped, it does not draw. This way the bounding boxes can be deleted when the tracking is stopped, because
        %   the stop function fires a PositionUpdate event.
        
            if this.isRunning()
                topleft = [max(1,this.xPos-this.radius), max(1,this.yPos-this.radius)];
                [sy, sx] = size(this.imgstack(:,:,1));
                if sy ~= 0
                    botright = [min(sx,this.xPos+this.radius), min(sy, this.yPos+this.radius)];
                else
                    botright = [this.xPos+this.radius, this.yPos+this.radius];
                end
                lineHandles = plot([topleft(1), topleft(1), botright(1), botright(1), topleft(1)], ...
                                    [topleft(2), botright(2), botright(2), topleft(2), topleft(2)], ...
                                    'LineWidth', 1.5, 'Color', 'red', 'Parent', axes);
            else
                lineHandles = [];
            end
        end
        
        function adjustPipette(this, force)
            if nargin < 2
                force = false;
            end
            if force
                this.trackingCb();
            end
            origPosDiff = [(this.xPos - this.originalXPosition)*this.microscope.pixelSizeX, ...
                           -(this.yPos - this.originalYPosition)*this.microscope.pixelSizeY, ...
                           this.zPos - this.originalZPosition];
            this.distanceFromOriginalPosition = sqrt(sum(origPosDiff.^2));
            
            bestPosDiff = [(this.xPos - this.xStartPos)*this.microscope.pixelSizeX, ...
                           -(this.yPos - this.yStartPos)*this.microscope.pixelSizeY, ...
                           this.zPos - this.zStartPos];
            this.distanceFromTargetedPosition = sqrt(sum(bestPosDiff.^2));
            pipette = this.microscope.getPipette(this.activePipetteId);
            bestPosDiffPip = pipette.microscope2pipette(bestPosDiff, 'relative');
            distanceLateral = sqrt(sum(bestPosDiffPip(2:3).^2));
%             distanceTotal = sqrt(sum(bestPosDiffPip.^2));
            log4m.getLogger().trace(num2str((this.xPos - this.xStartPos)))
            log4m.getLogger().trace(num2str((this.yPos - this.yStartPos)))
            log4m.getLogger().trace(['Tracking, (pipette) distance is: ', num2str(distanceLateral)]);
            if (distanceLateral > this.distanceThreshold) || force
                log4m.getLogger().debug(['Moving pipette in lateral direction: 0, ', num2str(bestPosDiffPip(2)), ', ', num2str(bestPosDiffPip(3))]);
                pipette.move([], bestPosDiffPip(2), bestPosDiffPip(3), 'speed', 'slow');

                this.xStartPos = this.xPos;
                this.yStartPos = this.yPos;
                this.zStartPos = this.zPos;
                this.lastPipetteXDifference = bestPosDiffPip(1);
            end
        end
    end
    
    
    methods (Access = protected)
        function trackingCb(this)
            % when called, it moves the focus plane, takes an image, when
            % it happened in every different focus level, runs the tracking
            % algorithm and makes a decision whether to move the pipette in
            % lateral direction. Z tracking is separated into 2 steps that are not next to each other to ease the
            % flickering due to time consuming operations

            this.phase = this.phase + 1;
            if this.phase > 5
                this.phase = 1;
            end
            
            if isempty(this.xPos)
                this.xPos = this.xStartPos;
                this.yPos = this.yStartPos;
                this.zPos = this.zStartPos;
                notify(this,'PositionUpdate');
            end
            
            if this.phase == 1
                 this.microscope.stage.moveTo([], [], this.zPos);
                 this.imgstack = this.microscope.captureStack(this.numZ, 1, 'center', 'generateMeta', false);
                 %% for figure generation, delete later
%                  global trackingStacks
%                  trackingStacks{end+1} = this.imgstack;
                 %%
                 this.imgstack = this.imgstack.getStack();
            end
            
            if this.phase == 2
                zsimilarities = zeros(this.numZ,1);
                for i = 1:this.numZ
                    zsimilarities(i) = calculateZSimilarity(this.templateYStartPos, this.templateXStartPos, ...
                        this.yPos, this.xPos, this.templateImage, this.imgstack(:,:,i), this.radius);
                end
                this.corrAbove = min(zsimilarities(this.numZ-floor(this.numZ/2)+1:this.numZ));
                this.corrZSame = zsimilarities(ceil(this.numZ/2));
                this.corrBelow = min(zsimilarities(1:floor(this.numZ/2)));
                
                this.perform2dTracking(this.imgstack(:,:,ceil(this.numZ/2)));
            end
            
            if this.phase > 2
                this.perform2dTracking();
            end
            
            if this.phase == 3
                [~, minSimilarityIdx] = min(abs([this.corrAbove, this.corrZSame*this.corrZsameMultiplier, this.corrBelow]));
                log4m.getLogger().trace(['Z similarity values (a,s,b): ', num2str(this.corrAbove), ' ', num2str(this.corrZSame), ' ', num2str(this.corrBelow)]);
                switch minSimilarityIdx
                    case 1
                        bestZ = this.zStep;
                        this.zPos = this.zPos + bestZ;
                        log4m.getLogger().trace('new template image: above');
                    case 2
                        bestZ = 0;
                        this.zPos = this.zPos + bestZ;
                        log4m.getLogger().trace('new template image: same Z');
                    case 3
                        bestZ = -this.zStep;
                        this.zPos = this.zPos + bestZ;
                        log4m.getLogger().trace('new template image: below');
                end
            end
            
            if this.phase >= 2 && this.autoAdjust
                this.adjustPipette();
            end
        end
        
        function deleteTimer(this)
            deleteTimer(this.trackingTimer);
            this.trackingTimer = [];
        end
        
        function reinitPoints(this, img)
            objectRegion = [this.xPos-this.radius, this.yPos-this.radius, 2*this.radius+1, 2*this.radius+1];
            this.points = detectMinEigenFeatures(img,'ROI',objectRegion);
            this.points = this.points.Location;
            this.numInitialPoints = size(this.points,1);
            this.tracker.setPoints(this.points);
        end
        
        function perform2dTracking(this, img)
            if nargin < 2
                img = this.microscope.captureImage();
            end
            [this.points, validity] = this.tracker.step(im2double(img));
            if sum(validity) >= max(this.numInitialPoints*this.reinitPercent,this.reinitNumpoints)
                posXY = mean(this.points(validity,:));
                this.xPos = posXY(1);
                this.yPos = posXY(2);
                notify(this,'PositionUpdate');
                log4m.getLogger().trace(['num valid feature points: ', num2str(sum(validity))]);
                log4m.getLogger().trace(['new xy positions: ', num2str(posXY(1)), ' ', num2str(posXY(2))]);
            else
                this.reinitPoints(img);
            end
        end
    end
    
end

