classdef (Abstract) PipetteController < matlab.mixin.SetGet
    %PIPETTECONTROLLER Abstract class for pipette controllers
    %   This class stores angles, focus positions and forward/backward
    %   directions of the pipettes. Smart move function is also implemented
    %   here. Only move and moveTo methods can be called. Inherited classes 
    %   should only define the set and get methodsfor which can not be 
    %   called directly. Other abstract methods are isMoving and
    %   waitForFinished functions.
    
    %% TODO support of movement by vector e.g. move([1 2 3])
    %%
    
    properties
        % focusPosition - motor positions where pipette was in focus
        focusPosition
        
        % focusTurretPosition - the pipette tip position in the stage
        % coordinate system. If focus estimation is applied, this value
        % should be the stage position when in focus plus the tip offset
        % from the _further_ bottom left corner, considering that the image 
        % coordinates are with inverted Y axis.
        focusTurretPosition
        
        % angle - tilt angle of the pipette x axis compared to xy plane, in
        % degrees. Down is negative.
        angle % alpha
        
        % orientation - This property determines the orientation of
        % the pipette x axis. It is also used when transforming stage and pipette
        % coordinates. It also tells lateral position of the pipette
        % compared to the center position of the stage, which is 180
        % degrees more then the property value. Can be NaN if x' axis does
        % not move in the xy plane.
        orientation % psi
        
        tau % rotation of y' from y on xy plane, positive rotation
        
        beta % tilt angle of y' compared to xy plane, upward is positive angle
        
        lambda % angle between z and z' axis, [0, 180]
        
        % rotation of z' on xy plane, if there is an angle between z and z' 
        % (not just showing into the opposite directions)
        delta
        
        % x_forward - forward direction of the x motor that pushes the
        % pipette deeper. Possible values are -1 and 1 (default).
        x_forward
        
        % y_forward - forward direction of the y motor that pushes the
        % pipette further from the user. In general, forward should mean
        % the direction of the standard Euclidean coordinate system's
        % positive y direction. Possible values are -1 and 1 (default).
        y_forward
        
        % z_forward - forward direction of the z motor that lifts the
        % pipette. Possible values are -1 and 1 (default).
        z_forward
    end
    
    properties (Dependent, SetAccess = private, GetAccess = public)
        % Transform matrix based on angle values that converts pipette
        % coordinates to microscope coordinates when a vector is multiplied
        % by it from right (v*T). The inverse of this matrix gives the
        % transform matrix to convert microscope coordinates to pipette
        % coordinates. Suggested use is pinv(T). During the calculation of
        % the matrix, standard Eucledian coordinate system is assumed with
        % z axis pointing up. The {x,y,z}_forward properties are then used
        % to change the sign of the calculated value if the 'forward'
        % direction of the motor is defined differently. These values
        % should be set carefully when a pipette main axes is orthogonal to
        % an Eucledean main axes (eg. x' is orthogonal to x). Furthermore,
        % the angles of the different axes has to be set separately 
        % (using set<X,Y,Z>apoAnglesFromVector functions), and if the
        % pipette can not be moved along an axis based on the current
        % settings, the matrix can be (near) singular.
        T
    end
    
    properties (Access = private)
        isValidT
        transformMatrix
    end
    
    methods (Abstract, Access = protected)
        setX(this, value, speed);
        setY(this, value, speed);
        setZ(this, value, speed);
        setPosition(this, x, y, z, speed);
    end
    
    methods (Abstract)
        x = getX(this);
        y = getY(this);
        z = getZ(this);
        [x, y, z] = getPosition(this);
        b = isMoving(this);
        b = isMovingX(this);
        b = isMovingY(this);
        b = isMovingZ(this);
        waitForFinished(this);
        waitForFinishedX(this);
        waitForFinishedY(this);
        waitForFinishedZ(this);
        switchToManualSlowSpeed(this);
        switchToManualFastSpeed(this);
        switchToAutomaticSlowSpeed(this);
        switchToAutomaticFastSpeed(this);
    end
    
    methods
        function this = PipetteController()
            this.focusPosition = zeros(1,3);
            this.focusTurretPosition = zeros(1,3);
            this.x_forward = 1;
            this.y_forward = 1;
            this.z_forward = 1;
            this.isValidT = false;
            this.angle = 0;
            this.orientation = 0;
            this.tau = 0;
            this.beta = 0;
            this.lambda = 0;
            this.delta = 0;
        end
        
        function set.focusPosition(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.focusPosition = value(:)';
        end
        
        function set.focusTurretPosition(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.focusTurretPosition = value(:)';
        end
        
        function set.angle(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.angle = value;
            this.invalidateTransformMatrix();
        end
        
        function set.orientation(this, value)
            assert(isnumeric(value) && ~isempty(value));
            this.orientation = value;
            this.invalidateTransformMatrix();
        end
        
        function set.tau(this,value)
            assert(isnumeric(value) && ~isempty(value));
            this.tau = value;
            this.invalidateTransformMatrix();
        end
        
        function set.beta(this,value)
            assert(isnumeric(value) && ~isempty(value));
            this.beta = value;
            this.invalidateTransformMatrix();
        end
        
        function set.lambda(this,value)
            assert(isnumeric(value) && ~isempty(value));
            this.lambda = value;
            this.invalidateTransformMatrix();
        end
        
        function set.delta(this,value)
            assert(isnumeric(value) && ~isempty(value));
            this.delta = value;
            this.invalidateTransformMatrix();
        end
        
        function set.x_forward(this, value)
            assert(isnumeric(value) && ~isempty(value) && (value==1 || value==-1));
            this.x_forward = value;
            this.invalidateTransformMatrix();
        end
        
        function set.y_forward(this, value)
            assert(isnumeric(value) && ~isempty(value) && (value==1 || value==-1));
            this.y_forward = value;
            this.invalidateTransformMatrix();
        end
        
        function set.z_forward(this, value)
            assert(isnumeric(value) && ~isempty(value) && (value==1 || value==-1));
            this.z_forward = value;
            this.invalidateTransformMatrix();
        end
        
        function T = get.T(this)
            if ~this.isValidT
                this.calculateTransformMatrix();
            end
            T = this.transformMatrix;
        end
        
        function move(this, x, y, z, varargin)
            %MOVE Moves the pipette relative to its current position
            %   move(this, x, y, z) - moves the pipette to x, y and z
            %   distance from the current position (micro meters).
            %   move(obj, ..., 'speed', value) - specify the speed value.
            %   The valid value might depend on the derived class
            %   instantiated, but 'slow' and 'fast' should generally be
            %   supported.
            %
            %   See also moveTo, StageController.move.

            p = inputParser;
            addRequired(p, 'x', @(x) isnumeric(x) || isempty(x));
            addRequired(p, 'y', @(x) isnumeric(x) || isempty(x));
            addRequired(p, 'z', @(x) isnumeric(x) || isempty(x));
            addParameter(p, 'speed', []);
            if numel(varargin)==1
                varargin = varargin{1};
            end
            parse(p, x, y, z, varargin{:});
            speed = p.Results.speed;

            if isempty(x) || isnan(x)
                x = 0;
            end
            if isempty(y) || isnan(y)
                y = 0;
            end
            if isempty(z) || isnan(z)
                z = 0;
            end

            toX = [];
            toY = [];
            toZ = [];
            if y ~= 0
                toY = this.getY() + y;
            end
            if z ~= 0
                toZ = this.getZ() + z;
            end
            if x ~= 0
                toX = this.getX() + x;
            end
            this.moveTo(toX, toY, toZ, 'speed', speed);
        end
        
        function moveTo(this, x, y, z, varargin)
            %MOVETO Moves the pipette to the given position
            %   This function moves the pipette to the given absolute position.
            %   move(obj, ..., 'speed', value) - specify the speed value.
            %   The valid value might depend on the derived class
            %   instantiated, but 'slow' and 'fast' should generally be
            %   supported.
            %
            %   See also move, StageController.moveTo.

            p = inputParser;
            p.addRequired('x', @(x) isnumeric(x) || isempty(x));
            p.addRequired('y', @(x) isnumeric(x) || isempty(x));
            p.addRequired('z', @(x) isnumeric(x) || isempty(x));
            p.addParameter('speed', []);
            if numel(varargin)==1
                varargin = varargin{1};
            end
            parse(p, x, y, z, varargin{:});
            speed = p.Results.speed;

            if ~isempty(y) && ~isnan(y)
                log4m.getLogger().trace(['Moving pipette Y to ', num2str(y)]);
                if isempty(speed)
                    this.setY(y);
                else
                    this.setY(y, speed);
                end
            end
            if ~isempty(z) && ~isnan(z)
                log4m.getLogger().trace(['Moving pipette Z to ', num2str(z)]);
                if isempty(speed)
                    this.setZ(z);
                else
                    this.setZ(z, speed);
                end
            end
            if ~isempty(x) && ~isnan(x)
                log4m.getLogger().trace(['Moving pipette X to ', num2str(x)]);
                if isempty(speed)
                    this.setX(x);
                else
                    this.setX(x, speed);
                end
            end
        end
        
        function smartMove(this, x, y, z, top)
            %SMARTMOVETO Smart move relatively
            % Calculates and executes 'smart move' steps so that y and z
            % movements are executed after pulling out the pipette in x
            % direction above the sample's top, and the final movement is
            % only a forward step in the x direction.
            % Parameters:
            %   x, y, z - coordinates to move relatively
            %   top - sample's top position in standard Eucledean
            %   coordinate system (turret coord. sys.).
            %
            % See also PipetteController.smartMoveTo.
            
            this.executeSmartMoveSteps(this.calculateSmartMoveSteps(x, y, z, top));
        end
        
        function smartMoveTo(this, x, y, z, top)
            %SMARTMOVETO Smart move to position
            % Calculates and executes 'smart move to' steps so that y and z
            % movements are executed after pulling out the pipette in x
            % direction above the sample's top, and the final movement is
            % only a forward step in the x direction.
            % Parameters:
            %   x, y, z - coordinates to move to
            %   top - sample's top position in standard Eucledean
            %   coordinate system (turret coord. sys.).
            %
            % See also PipetteController.smartMove.
            
            this.executeSmartMoveToSteps(this.calculateSmartMoveToSteps(x, y, z, top));
        end
        
        function setXAnglesFromVector(this, vec)
            %SETXANGLESFROMVECTOR Calculates angles for x axis
            % Calculates and sets angles that define the rotation and tilt
            % of the x axis compared to the standard Eucledean coordinat
            % system's x axis. The input vector should be considered as it
            % points from the origo to its position. (Note: the input vector 
            % is not the absolute position of the pipette after moving
            % somewhere after setting the focusPosition property.) The
            % vector should be calculated as the difference of the pipette
            % position after moving 'forward' in the given axis.
            %
            % See also PipetteController.setYAnglesFromVector,
            % PipetteController.setZAnglesFromVector
            
            this.angle = asind(vec(3) / norm(vec));
            this.orientation = atand(vec(2) / vec(1));
            if vec(1) < 0
                this.orientation = 180 + this.orientation;
            end
        end
        
        function setYAnglesFromVector(this, vec)
            %SETYANGLESFROMVECTOR Calculates angles for y axis
            % Calculates and sets angles that define the rotation and tilt
            % of the y axis compared to the standard Eucledean coordinat
            % system's y axis. The input vector should be considered as it
            % points from the origo to its position. (Note: the input vector 
            % is not the absolute position of the pipette after moving
            % somewhere after setting the focusPosition property.) The
            % vector should be calculated as the difference of the pipette
            % position after moving 'forward' in the given axis.
            %
            % See also PipetteController.setXAnglesFromVector,
            % PipetteController.setZAnglesFromVector
            
            if norm(vec(1:2)) < eps
                this.tau = 0;
            else
                this.tau = acosd(vec(2) / norm(vec(1:2)));
                if vec(1) > 0
                    this.tau = -this.tau;
                end
            end
            this.beta = asind(vec(3) / norm(vec));
        end
        
        function setZAnglesFromVector(this, vec)
            %SETZANGLESFROMVECTOR Calculates angles for z axis
            % Calculates and sets angles that define the rotation and tilt
            % of the z axis compared to the standard Eucledean coordinat
            % system's z axis. The input vector should be considered as it
            % points from the origo to its position. (Note: the input vector 
            % is not the absolute position of the pipette after moving
            % somewhere after setting the focusPosition property.) The
            % vector should be calculated as the difference of the pipette
            % position after moving 'forward' in the given axis.
            %
            % See also PipetteController.setXAnglesFromVector,
            % PipetteController.setYAnglesFromVector
            
            this.lambda = acosd(vec(3) / norm(vec));
            if norm(vec(1:2)) < eps
                this.delta = 0;
            else
                this.delta = atand(vec(2) / vec(1));
                if vec(1) < 0
                    this.delta = 180 + this.delta;
                end
            end
        end
        
        function pipettePosition = microscope2pipette(this, microscopePosition, mode)
            %MICROSCOPE2PIPETTE - Convert position to pipette coordinates
            % Converts an input vector of length of 3,
            % considered as microscope stage (turret) position to
            % pipette position. Support 'relative' (default) or 'absolute' position
            % calculations. The various angle properties, set by 
            % set<XYZ>AnglesFromVector functions are used for the calculations.
            % If 'absolute' mode is chosen, focusTurretPosition and
            % focusPosition properties of the class are also used.
            % 
            % obj.microscope2pipette(microscopePosition) - convert position
            % to pipette coordinate system.
            % obj.microscope2pipette(microscopePosition, mode) - convert
            % position using the defined mode ('relative' or 'absolute').
            %
            % See also PipetteController.pipette2microscope,
            % PipetteController.setXAnglesFromVector,
            % PipetteController.setYAnglesFromVector,
            % PipetteController.setZAnglesFromVector.
            
            if nargin < 3
                mode = 'relative';
            else
                assert(any(strcmpi(mode, {'relative', 'absolute'})));
                mode = lower(mode);
            end
            isAbsolute = false;
            if strcmp(mode, 'absolute')
                isAbsolute = true;
            end
            microscope = microscopePosition(:)';
            if isAbsolute
                microscope = microscope - this.focusTurretPosition;
            end
            pipettePosition = microscope*pinv(this.T);
            if isAbsolute
                pipettePosition = pipettePosition + this.focusPosition;
            end
        end
        
        function microscopePosition = pipette2microscope(this, pipettePosition, mode)
            %PIPETTE2MICROSCOPE - Convert position to turret coordinates
            % Converts an input vector of length of 3,
            % considered as absolute pipette position to absolute microscope 
            % stage (turret) position. The various angle properties, set by 
            % set<XYZ>AnglesFromVector functions, focusTurretPosition and
            % focusPosition properties of the class are used for the
            % calculations.
            %
            % obj.pipette2microscope(pipettePosition) - convert input pipette
            % position to microscope coordinate system.
            % obj.pipette2microscope(microscopePosition, mode) - convert
            % input microscope position using the defined mode ('relative' 
            % or 'absolute').
            %
            % See also PipetteController.microscope2pipette,
            % PipetteController.setXAnglesFromVector,
            % PipetteController.setYAnglesFromVector,
            % PipetteController.setZAnglesFromVector.
            
            if nargin < 3
                mode = 'relative';
            else
                assert(any(strcmpi(mode, {'relative', 'absolute'})));
                mode = lower(mode);
            end
            isAbsolute = false;
            if strcmp(mode, 'absolute')
                isAbsolute = true;
            end
            pipette = pipettePosition(:)';
            if isAbsolute
                pipette = pipette - this.focusPosition;
            end
            microscopePosition = pipette*this.T;
            if isAbsolute
                microscopePosition = microscopePosition + this.focusTurretPosition;
            end
        end
        
        function steps = calculateSmartMoveSteps(this, x, y, z, top, cx, cy, cz, tolerance)
            %CALCULATESMARTMOVESTEPS Calculates smart 'move' steps
            % Calculates relative movement steps in a smart way so that it
            % pulls out the pipette until the samples top, performs any y
            % and z movements and the last step is only an x movement. The
            % last movement should start from the sample's top.
            % current position can optionally be passed as last parameters.
            % Parameters:
            %   x - absolute x
            %   y - absolute y
            %   z - absolute z
            %   top - sample top position
            %   cx - current x position (optional)
            %   cy - current y position (optional)
            %   cz - current z position (optional)
            %   tolerance - value mainly used for y and z movements which is allowed to move without pulling out the pipette (optional)
            %
            % See also PipetteController.calculateSmartMoveToSteps
            
            %% Not well tested after modification. Criteria of implementation:
            % 1. If only forward movement is needed, or lateral movement is
            % not greater than tolerance, than do not pull out pipette for
            % lateral movement.
            % 2. When slow movement has to be used, switch to 'fast' when
            % moving above top. This could also be controlled by tolerance
            % (i.e. do not switch to fast if movement above top is less
            % than tolerance, because the communication with the controller
            % can unecessarily slow down the process).
            %%
            
            if isempty(x) || isnan(x)
                x = 0;
            end
            if isempty(y) || isnan(y)
                y = 0;
            end
            if isempty(z) || isnan(y)
                z = 0;
            end
            if nargin < 6 || isempty(cx) || isnan(cx)
                cx = this.getX();
            end
            if nargin < 7 || isempty(cy) || isnan(cy)
                cy = this.getY();
            end
            if nargin < 8 || isempty(cz) || isnan(cz)
                cz = this.getZ();
            end
            if nargin < 9 || isempty(tolerance) || isnan(tolerance)
                tolerance = eps;
            elseif tolerance < 0
                log4m.getLogger().warn(['Changing negative lateral tolerance (', num2str(tolerance), ') to 0.']);
                tolerance = 0;
            end
            steps = cell(0,2);
            posInTurretCoords = this.pipette2microscope([cx, cy, cz], 'absolute');
            startsUnderTop = false;
            if posInTurretCoords(3) - top < 0
                startsUnderTop = true;
            end
            finalTurretCoords = this.pipette2microscope([cx+x, cy+y, cz+z], 'absolute');
            finishesUnderTop = false;
            if finalTurretCoords(3) - top < 0
                finishesUnderTop = true;
            end
            if (abs(y) > tolerance || abs(z) > tolerance)
                zdiff = posInTurretCoords(3) - top;
                x_zdiff = 0;
                if zdiff < 0
                    x_zdiff = -zdiff/this.T(1,3);
                    steps(end+1,:) = {[x_zdiff, 0, 0], 'slow'};
                end
                tmpY = 0;
                tmpZ = 0;
                if ~isempty(y)
                    tmpY = y;
                end
                if ~isempty(z)
                    tmpZ = z;
                end
                zdiffFromyz = this.pipette2microscope([0, tmpY, tmpZ]);
                x_zdiffFromyz = 0;
                if zdiffFromyz(3) < 0
                    x_zdiffFromyz = -zdiffFromyz(3)/this.T(1,3);
                    if abs(x_zdiffFromyz) > tolerance || isempty(steps)
                        steps(end+1,:) = {[x_zdiffFromyz, 0, 0], 'fast'};
                    else
                        steps{end,1}(1) = steps{end,1}(1) + x_zdiffFromyz;
                    end
                end
                steps(end+1,:) = {[0, y, z], 'fast'};
%                 speed = 'slow';
%                 if ~finishesUnderTop
%                     speed = 'fast';
%                 end
%                 steps(end+1,:) = {[x-x_zdiffFromyz-x_zdiff, 0, 0], speed};
                
                if ~finishesUnderTop
%                     steps(end+1,:) = {[x, 0, 0], 'fast'};
                    steps(end+1,:) = {[x-x_zdiffFromyz-x_zdiff, 0, 0], 'fast'};
                else
                    xTopDistance = finalTurretCoords(3) - top;
                    x_xTopDistance = xTopDistance/this.T(1,3);
%                     steps(end+1,:) = {[x_xTopDistance-x_zdiffFromyz-x_zdiff, 0, 0], 'fast'};
%                     steps(end+1,:) = {[x-x_xTopDistance-x_zdiffFromyz-x_zdiff, 0, 0], 'slow'};
                    steps(end+1,:) = {[x-x_xTopDistance-x_zdiffFromyz-x_zdiff, 0, 0], 'fast'};
                    steps(end+1,:) = {[x_xTopDistance, 0, 0], 'slow'};
                end
                
            else
                lateralStep = {[0, y, z], 'fast'};
                if ~startsUnderTop
                    if (y~=0 || z~=0)
                        steps(end+1,:) = lateralStep;
                    end
%                     xStepGoesUnderTop = this.pipette2microscope([cx+x, cy, cz], 'absolute');
%                     xTopDistance = xStepGoesUnderTop(3) - top;
                    xTopDistance = finalTurretCoords - top;
                    if xTopDistance > 0
                        steps(end+1,:) = {[x, 0, 0], 'fast'};
                    else
                        x_xTopDistance = xTopDistance/this.T(1,3);
                        %% TODO have to test this one, but it works above
                        steps(end+1,:) = {[x-x_xTopDistance, 0, 0], 'fast'};
                        steps(end+1,:) = {[x_xTopDistance, 0, 0], 'slow'};
                    end
                else
                    if finishesUnderTop
                        steps(end+1,:) = lateralStep;
                        steps(end+1,:) = {[x, 0, 0], 'slow'};
                    else %finishes over top
                        steps(end+1,:) = {[x, 0, 0], 'fast'};
                        steps(end+1,:) = lateralStep;
                    end
                end
            end % if
        end % function
        
        function steps = calculateSmartMoveToSteps(this, x, y, z, top, cx, cy, cz, tolerance)
            %CALCULATESMARTMOVETOSTEPS Calculates smart 'move to' steps
            % The call is forwarded to CALCULATESMARTMOVESTEPS which
            % calculates relative movement steps, and the current position
            % is added to its result to get the absolute movements. NaN
            % values in the steps mean that the motor should not be moved.
            % The current position can optionally be passed as last 
            % parameters.
            % Parameters:
            %   x - absolute x
            %   y - absolute y
            %   z - absolute z
            %   top - sample top position
            %   cx - current x position (optional)
            %   cy - current y position (optional)
            %   cz - current z position (optional)
            %   tolerance - value mainly used for y and z movements which is allowed to move without pulling out the pipette (optional)
            %
            % See also PipetteController.calculateSmartMoveSteps
            
            if nargin < 6 || isempty(cx) || isnan(cx)
                cx = this.getX();
            end
            if nargin < 7 || isempty(cy) || isnan(cy)
                cy = this.getY();
            end
            if nargin < 8 || isempty(cz) || isnan(cz)
                cz = this.getZ();
            end
            if nargin < 9 || isempty(tolerance) || isnan(tolerance)
                lateralTolerance = 0;
            end
            steps = this.calculateSmartMoveSteps(x-cx, y-cy, z-cz, top, cx, cy, cz, lateralTolerance);
            lastpos = [cx, cy, cz];
            for i = 1:3
                if steps{1,1}(i) ~= 0
                    steps{1,1}(i) = steps{1,1}(i) + lastpos(i);
                    lastpos(i) = steps{1,1}(i);
                else
                    steps{1,1}(i) = NaN;
                end
            end
            for i = 2:size(steps,1)
                for j = 1:3
                    if steps{i,1}(j) ~= 0
                        steps{i,1}(j) = steps{i,1}(j) + lastpos(j);
                        lastpos(j) = steps{i,1}(j);
                    else
                        steps{i,1}(j) = NaN;
                    end
                end
            end
        end
        
        function executeSmartMoveSteps(this, steps)
            %EXECUTESMARTMOVETOSTEPS Executes smart 'move' steps
            % Executes steps which should be the output of
            % calculateSmartMoveSteps method.
            %
            % See also PipetteController.executeSmartMoveToSteps
            
            for i = 1:size(steps,1)
                this.move(steps{i,1}(1), steps{i,1}(2), steps{i,1}(3), 'speed', steps{i,2});
                this.waitForFinished();
            end
        end
        
        function executeSmartMoveToSteps(this, steps)
            %EXECUTESMARTMOVETOSTEPS Executes smart 'move to' steps
            % Executes steps which should be the output of
            % calculateSmartMoveToSteps method.
            %
            % See also PipetteController.executeSmartMoveSteps
            
            for i = 1:size(steps,1)
                log4m.getLogger().debug(['executing: ', num2str(steps{i,1}(1)), ' ', num2str(steps{i,1}(2)), ' ', num2str(steps{i,1}(3)), ', speed: ', steps{i,2}]);
                this.moveTo(steps{i,1}(1), steps{i,1}(2), steps{i,1}(3), 'speed', steps{i,2});
                this.waitForFinished();
            end
        end
    end
    
    methods (Access = private)
        function invalidateTransformMatrix(this)
            this.isValidT = false;
        end
        
        function calculateTransformMatrix(this)
            %CALCULATETRANSFORMMATRIX Calculates matrix for coord sys. tf.
            % Calculates the matrix for coordinate system transform between
            % pipette and turret coordinates. The angles of the axes should
            % be previously set. Vectors should be multiplied from right
            % with the resulting matrix or it's (pseudo) inverse.
            %
            % See also PipetteController.setXAnglesFromVector,
            % PipetteController.setYAnglesFromVector,
            % PipetteController.setZAnglesFromVector.
            if this.isValidT
                return
            end
            this.transformMatrix = ...
                [ cosd(this.angle)*cosd(this.orientation), sind(this.orientation)*cosd(this.angle), sind(this.angle); ...
                  cosd(this.beta)*sind(-this.tau),      cosd(this.tau)*cosd(this.beta),      sind(this.beta); ...
                  sind(this.lambda)*cosd(this.delta), sind(this.lambda)*sind(this.delta), cosd(this.lambda)];
            this.transformMatrix(1,:) = this.transformMatrix(1,:) * this.x_forward;
            this.transformMatrix(2,:) = this.transformMatrix(2,:) * this.y_forward;
            this.transformMatrix(3,:) = this.transformMatrix(3,:) * this.z_forward;
            this.isValidT = true;
        end
    end
    
end

