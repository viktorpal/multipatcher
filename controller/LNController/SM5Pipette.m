classdef SM5Pipette < PipetteController & handle
    %SM5PIPETTE Luigs and Neumann SM5 pipette controller
    
    properties (Constant, Hidden)
        defaultAutomaticSlowSpeed = 5
        defaultAutomaticFastSpeed = 5
        defaultPollTime = 0.01
    end
    
    properties
        pollTime % time used to poll some values (eg. if axis is moving)
        
        % A slow speed value that might be used for automatic movements. The methods do not check if this value is set 
        % in the controller. It should be checked from code if it is required.
        automaticSlowSpeed
        
        % A fast speed value that might be used for automatic movements. The methods do not check if this value is set 
        % in the controller. It should be checked from code if it is required.
        automaticFastSpeed
    end
    
    properties (SetAccess = immutable)
        device % Device ID to use. If channels are set manually, this value will remain empty.
        x_channel % Channel number for the x motor. Default value is computed from property 'device'.
        y_channel % Channel number for the y motor. Default value is computed from property 'device'.
        z_channel % Channel number for the z motor. Default value is computed from property 'device'.
    end
    
    properties (SetAccess = protected)
        controller % SM5Controller object that might be used by multiple pipette controllers.
    end
    
    properties (Access = protected)
        originalSlowXSpeed % slow movement speed value of x channel, queried on startup
        originalSlowYSpeed % slow movement speed value of y channel, queried on startup
        originalSlowZSpeed % slow movement speed value of z channel, queried on startup
        
        originalFastXSpeed % fast movement speed value of x channel, queried on startup
        originalFastYSpeed % fast movement speed value of y channel, queried on startup
        originalFastZSpeed % fast movement speed value of z channel, queried on startup
    end
    
    methods
        function this = SM5Pipette(comPortOrController, deviceOrChannels, timeout)
            if nargin < 3
                timeout = [];
            end
            deviceErrorStr = '''deviceOrChannels'' should be a numeric value or vector of 3 values.';
            assert(isnumeric(deviceOrChannels) && any(numel(deviceOrChannels) == [1 3]), deviceErrorStr);
            if numel(deviceOrChannels) == 1
                assert(isempty(deviceOrChannels) || (isnumeric(deviceOrChannels) && deviceOrChannels==round(deviceOrChannels) ...
                    && deviceOrChannels > 0 && deviceOrChannels < 4), ...
                    'Device should be empty or a round value between 1 and 4.');
                this.device = deviceOrChannels;
                x = uint8((this.device-1)*3+1);
                y = uint8((this.device-1)*3+2);
                z = uint8((this.device-1)*3+3);
                assert(~isempty(x) && isnumeric(x) && x > 0 && x <= 9, 'x_channel should be between 1-9.');
                assert(~isempty(y) && isnumeric(y) && y > 0 && y <= 9, 'y_channel should be between 1-9.');
                assert(~isempty(z) && isnumeric(z) && z > 0 && z <= 9, 'z_channel should be between 1-9.');
                this.x_channel = x;
                this.y_channel = y;
                this.z_channel = z;
            else
                this.x_channel = uint8(deviceOrChannels(1));
                this.y_channel = uint8(deviceOrChannels(2));
                this.z_channel = uint8(deviceOrChannels(3));
            end
            
            if isa(comPortOrController, 'char')
                if isempty(timeout)
                    this.controller = SM5Controller(comPortOrController);
                else
                    this.controller = SM5Controller(comPortOrController, timeout);
                end
            elseif isa(comPortOrController, 'SM5Controller')
                this.controller = comPortOrController;
            else
                error('''comPortOrController'' should be a char array of the serial ports name or an SM5Controller object.');
            end
            
            this.pollTime = this.defaultPollTime;
            this.automaticSlowSpeed = this.defaultAutomaticSlowSpeed;
            this.automaticFastSpeed = this.defaultAutomaticFastSpeed;
            this.originalSlowXSpeed = this.controller.queryPositioningVelocitySlowLinear(this.x_channel);
            this.originalSlowYSpeed = this.controller.queryPositioningVelocitySlowLinear(this.y_channel);
            this.originalSlowZSpeed = this.controller.queryPositioningVelocitySlowLinear(this.z_channel);
            this.originalFastXSpeed = this.controller.queryFastMoveVelocity(this.x_channel);
            this.originalFastYSpeed = this.controller.queryFastMoveVelocity(this.y_channel);
            this.originalFastZSpeed = this.controller.queryFastMoveVelocity(this.z_channel);
        end
        
        function delete(this)
            try
                this.switchToManualFastSpeed();
            catch ex
                log4m.getLogger().error(['Could not revert fast pipette speed to the original. Error: ', ex.message]);
            end
            try
                this.switchToManualSlowSpeed();
            catch ex
                log4m.getLogger().error(['Could not revert slow pipette speed to the original. Error: ', ex.message]);
            end
        end
        
        
        %% Property getters/setters
        
        function set.pollTime(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0, 'Value should be a nonempty positive numeric');
            this.pollTime = value;
        end
        
        function set.controller(this, value)
            assert(isa(value, 'SM5Controller'));
            this.controller = value;
        end
        
        %% Functionality methods
        
        function x = getX(this)
            x = this.controller.getPosition_(this.x_channel);
        end
        
        function y = getY(this)
            y = this.controller.getPosition_(this.y_channel);
        end
        
        function z = getZ(this)
            z = this.controller.getPosition_(this.z_channel);
        end
        
        function [x, y, z] = getPosition(this)
            x = this.getX();
            y = this.getY();
            z = this.getZ();
            if nargout == 1 || nargout == 0
                x = [x, y, z];
            end
        end
        
        function b = isMoving(this)
            b = this.isMovingX() || this.isMovingY() || this.isMovingZ();
        end
        
        function b = isMovingX(this)
            status = this.controller.getMainStatusFromOutputstage(this.x_channel);
            b = status.isRunning;
        end
        
        function b = isMovingY(this)
            status = this.controller.getMainStatusFromOutputstage(this.y_channel);
            b = status.isRunning;
        end
        
        function b = isMovingZ(this)
            status = this.controller.getMainStatusFromOutputstage(this.z_channel);
            b = status.isRunning;
        end
        
        function waitForFinished(this)
            this.waitForFinishedX();
            this.waitForFinishedY();
            this.waitForFinishedZ();
        end
        
        function waitForFinishedX(this)
            while this.isMovingX()
                pause(this.pollTime);
            end
        end
        
        function waitForFinishedY(this)
            while this.isMovingY()
                pause(this.pollTime);
            end
        end
        
        function waitForFinishedZ(this)
            while this.isMovingZ()
                pause(this.pollTime);
            end
        end
        
        function switchToManualSlowSpeed(this)
        %SWITCHTOMANUALSLOWSPEED Switch back to original slow speed. 
        %   This function call is different from the one for fast speed,
        %   which is likely to be a documentation/functionality error made
        %   by the manufacturer.
            this.controller.setPositioningVelocitySlowLinear(this.x_channel, this.originalSlowXSpeed);
            this.controller.setPositioningVelocitySlowLinear(this.y_channel, this.originalSlowYSpeed);
            this.controller.setPositioningVelocitySlowLinear(this.z_channel, this.originalSlowZSpeed);
        end
        
        function switchToManualFastSpeed(this)
            this.controller.setFastMoveVelocity(this.x_channel, this.originalFastXSpeed);
            this.controller.setFastMoveVelocity(this.y_channel, this.originalFastYSpeed);
            this.controller.setFastMoveVelocity(this.z_channel, this.originalFastZSpeed);
        end
        
        function switchToAutomaticSlowSpeed(this)
            this.controller.setPositioningVelocitySlowLinear(this.x_channel, this.automaticSlowSpeed);
            this.controller.setPositioningVelocitySlowLinear(this.y_channel, this.automaticSlowSpeed);
            this.controller.setPositioningVelocitySlowLinear(this.z_channel, this.automaticSlowSpeed);
        end
        
        function switchToAutomaticFastSpeed(this)
            this.controller.setFastMoveVelocity(this.x_channel, this.automaticFastSpeed);
            this.controller.setFastMoveVelocity(this.y_channel, this.automaticFastSpeed);
            this.controller.setFastMoveVelocity(this.z_channel, this.automaticFastSpeed);
        end
    end
    
    methods (Access = protected)
        function setX(this, value, speed)
            if nargin < 3 || isempty(speed) || strcmp(speed, 'fast')
                this.controller.goVariableFastToAbsolutePosition(value, this.x_channel);
            else
                this.controller.goVariableSlowToAbsolutePosition(value, this.x_channel);
            end
        end
        
        function setY(this, value, speed)
            if nargin < 3 || isempty(speed) || strcmp(speed, 'fast')
                this.controller.goVariableFastToAbsolutePosition(value, this.y_channel);
            else
                this.controller.goVariableSlowToAbsolutePosition(value, this.y_channel);
            end
        end
        
        function setZ(this, value, speed)
            if nargin < 3 || isempty(speed) || strcmp(speed, 'fast')
                this.controller.goVariableFastToAbsolutePosition(value, this.z_channel);
            else
                this.controller.goVariableSlowToAbsolutePosition(value, this.z_channel);
            end
        end
        
        function setPosition(this, x, y, z, speed)
            if nargin < 5
                speed = 'fast';
            else
                expectedSpeed={'slow','fast'};
                assert(any(validatestring(speed,expectedSpeed)));
            end
            this.setX(x,speed);
            this.setY(y,speed);
            this.setZ(z,speed);
        end
    end
end

