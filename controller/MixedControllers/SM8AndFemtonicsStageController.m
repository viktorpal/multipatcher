classdef SM8AndFemtonicsStageController < StageController & handle
    %SM5ANDFEMTONICSCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
%     properties (SetAccess = immutable)
%         controller
%     end
    
    properties (Constant, Hidden)
        defaultPollTime = 0.01
    end
    
    properties
        pollTime % time used to poll some values (eg. if axis is moving)
    end

    properties (SetAccess = immutable)
        device % Device ID to use. If channels are set manually, this value will remain empty.
        x_channel % Channel number for the x motor. Default value is computed from property 'device'.
        y_channel % Channel number for the y motor. Default value is computed from property 'device'.
        z_channel % Channel number for the z motor. Default value is computed from property 'device'.
    end

    properties (SetAccess = protected)
        controller % SM8Controller object that might be used by multiple pipette controllers.
    end
    

    methods
        function this = SM8AndFemtonicsStageController(comPortOrController, deviceOrChannels, timeout)
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
                    this.controller = SM8Controller(comPortOrController);
                else
                    this.controller = SM8Controller(comPortOrController, timeout);
                end
            elseif isa(comPortOrController, 'SM8Controller')
                this.controller = comPortOrController;
            else
                error('''comPortOrController'' should be a char array of the serial ports name or an SM8Controller object.');
            end
            
            this.pollTime = this.defaultPollTime;
            
%             if nargin < 3
%                 timeout = SM8Controller.defaultTimeout;
%             end
%             
%             this = this@SM8Controller(comPort, device, timeout);
        end
        
        %% Property getters/setters
        
        function set.pollTime(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0, 'Value should be a nonempty positive numeric');
            this.pollTime = value;
        end
        
        function set.controller(this, value)
            assert(isa(value, 'SM8Controller'));
            this.controller = value;
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
        
        function setZ(~, value, ~)
            assert(isnumeric(value), 'Input parameter value has to be numeric.');
            setZ('absolute', value);
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
    
    methods
        function x = getX(this)
            x = this.controller.getPosition_(this.x_channel);
        end
        
        function y = getY(this)
            y = this.controller.getPosition_(this.y_channel);
        end
        
        function z = getZ(~)
            z = getZ('absolute');
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
%             status = this.getMainStatusFromOutputstage(this.z_channel);
%             b = status.isRunning;
            z1 = this.getZ();
            pause(this.pollTime);
            z2 = this.getZ();
            b = z1~=z2;
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
    end
end

