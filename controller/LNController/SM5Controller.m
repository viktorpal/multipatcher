classdef SM5Controller < handle
    %SM5CONTROLLER Matlab implementation for controlling L&N SM5 devices
    %   
    
    properties (Constant, Hidden)
        defaultConnectionCloseTimeout = 3 % Default timeout in seconds until the SM5 device keeps the connection.
        defaultTimeout = 0.1 % Default timeout to wait for the answer of the device.
        defaultMaxAttempts = 10 % Default maximum attempts for a command to succeed. Otherwise an exception is thrown.
        nAckSignal = [21, 0, 1, 0, 0, 0]
        syncSignal = uint8(22) % synchronization signal before commands, x16 == 22
        defaultReadPollTime = 0.01 % default poll time for checking if response bytes are available
        baudRate = 38400 % The baud rate the controller operates on
    end
    
    properties
        maxAttempts % Maximum attempts for a command to succeed. Otherwise an exception is thrown.
        readPollTime % Poll time for checking if response bytes are available. The default minimum value (0.01) is recommended.
        connectionCloseTimeout % Timeout when the device closes connection if no commands are sent.
    end
    
    properties (SetAccess = immutable)
        comPort % COM port to use
    end
    
    properties (Access = private)
        ser
        timeout % timeout value used for serial communication
    end
    
    properties (Access = private)
        timeWhenEstablished
    end
    
    methods (Access = protected, Static)
        function value = convertResponse2single(resp)
            hex = dec2hex(uint8(resp(end:-1:1)));
            hex = hex';
            value = single(hexsingle2num(hex(:)'));
        end
    end
    
    methods
        
        function this = SM5Controller(comPort, timeout)
            this.comPort = comPort;
            this.maxAttempts = this.defaultMaxAttempts;
            this.readPollTime = this.defaultReadPollTime;
            this.connectionCloseTimeout = this.defaultConnectionCloseTimeout;
            if nargin < 3
                this.timeout = this.defaultTimeout; % set Timeout in s (at least 50ms needed, but can lead to read/write errors
            else
                this.timeout = timeout;
            end
            
            this.initSerialPort();
        end
        
        function delete(this)
            if time2sec(now-this.timeWhenEstablished) < this.connectionCloseTimeout
                try
                    this.clearConnection();
                catch ex
                    log4m.getLogger().error(['Could not close communication with the controller: ', ex.message]);
                end
            end
            try
                fclose(this.ser);
            catch ex
                log4m.getLogger().error(['Could not close serial port. Error message: ', ex.message]);
            end
            delete(this.ser);
        end
        
        function set.timeout(this, value)
            assert(~isempty(value) && isnumeric(value) && value > 0);
            if value < this.defaultTimeout
                warnStr = 'Lower timeout value is used in SM5Controller than the default value, which is not recommended';
                warning(warnStr);
                log4m.getLogger().warn(warnStr);
            end
            this.timeout = value;
        end
    end
       
    methods
        function speed = queryPositioningVelocityFastLinear(this, axis)
            cmdId = '0160';
            nBytesToSend = 1;
            expectedResponse = hex2dec({'06','00','01','02'});
            nExpectedBytes = 8;
            devBytes = bitget(uint8(axis),8:-1:1);
            [~, msb, lsb] = crc16(devBytes);
            cmdData = axis;
            response = this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
            speed = dec2hex(response(5:6))';
            speed = hex2dec(speed(:)');
        end
        
        function speed = queryPositioningVelocitySlowLinear(this, axis)
            cmdId = '0161';
            nBytesToSend = 1;
            expectedResponse = hex2dec({'06','00','01','02'});
            nExpectedBytes = 8;
            devBytes = bitget(uint8(axis),8:-1:1);
            [~, msb, lsb] = crc16(devBytes);
            cmdData = axis;
            response = this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
            speed = dec2hex(response(5:6))';
            speed = hex2dec(speed(:)');
        end
        
        function speed = queryFastMoveVelocity(this, axis)
            cmdId = '012f';
            nBytesToSend = 1;
            expectedResponse = hex2dec({'06','00','01','01'});
            nExpectedBytes = 7;
            devBytes = bitget(uint8(axis),8:-1:1);
            [~, msb, lsb] = crc16(devBytes);
            cmdData = axis;
            response = this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
            speed = response(5);
        end
        
        function speed = querySlowMoveVelocity(this, axis)
            cmdId = '0130';
            nBytesToSend = 1;
            expectedResponse = hex2dec({'06','00','01','01'});
            nExpectedBytes = 7;
            devBytes = bitget(uint8(axis),8:-1:1);
            [~, msb, lsb] = crc16(devBytes);
            cmdData = axis;
            response = this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
            speed = response(5);
        end
        
        function setSlowMoveVelocity(this, axis, speedStage)
            if ~isnumeric(speedStage) || speedStage <=0 || speedStage > 16
                error('Argument ''speedStage'' should be numeric and have a round value between 1-16.');
            end
            cmdId = '0135';
            nBytesToSend = 2;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytesAxis = bitget(uint8(axis),8:-1:1);
            devBytesSpeed = bitget(uint8(speedStage),8:-1:1);
            [~, msb, lsb] = crc16([devBytesAxis, devBytesSpeed]);
            cmdData = [axis, speedStage];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end

        function setFastMoveVelocity(this, axis, speedStage)
            if ~isnumeric(speedStage) || speedStage <=0 || speedStage > 16
                error('Argument ''speedStage'' should be numeric and have a round value between 1-16.');
            end
            cmdId = '0134';
            nBytesToSend = 2;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytesAxis = bitget(uint8(axis),8:-1:1);
            devBytesSpeed = bitget(uint8(speedStage),8:-1:1);
            [~, msb, lsb] = crc16([devBytesAxis, devBytesSpeed]);
            cmdData = [axis, speedStage];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end
        
        function setPositioningVelocityFast(this, axis, speedStage)
            if ~isnumeric(speedStage) || speedStage <=0 || speedStage > 16
                error('Argument ''speedStage'' should be numeric and have a round value between 1-16.');
            end
            cmdId = '0144';
            nBytesToSend = 2;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytesAxis = bitget(uint8(axis),8:-1:1);
            devBytesSpeed = bitget(uint8(speedStage),8:-1:1);
            [~, msb, lsb] = crc16([devBytesAxis, devBytesSpeed]);
            cmdData = [axis, speedStage];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end
        
        function setPositioningVelocityFastLinear(this, axis, speed)
            if ~isnumeric(speed) || speed <=0 || speed > 3000
                error('Argument ''speedStage'' should be numeric and have a round value between 0-3000.');
            end
            cmdId = '003d';
            nBytesToSend = 3;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytesAxis = bitget(uint8(axis),8:-1:1);
            position = single(speed);
            [~, ~, dec3, dec4, floatbin] = float2dec(position, 'normal', true);
            [~, msb, lsb] = crc16([devBytesAxis, floatbin(17:32)]);
            cmdData = [axis, dec3, dec4];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end
        
        function setPositioningVelocitySlowLinear(this, axis, speed)
            if ~isnumeric(speed) || speed <=0 || speed > 18000
                error('Argument ''speedStage'' should be numeric and have a round value between 0-18000.');
            end
            cmdId = '003c';
            nBytesToSend = 3;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytesAxis = bitget(uint8(axis),8:-1:1);
            position = single(speed);
            [~, ~, dec3, dec4, floatbin] = float2dec(position, 'normal', true);
            [~, msb, lsb] = crc16([devBytesAxis, floatbin(17:32)]);
            cmdData = [axis, dec3, dec4];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end
        
        function pos = getPosition_(this, axis)
            cmdId = '0101';
            nBytesToSend = 1;
            expectedResponse = hex2dec({'06','00','01','04'});
            nExpectedBytes = 10;
            devBytes = bitget(uint8(axis),8:-1:1);
            [~, msb, lsb] = crc16(devBytes);
            cmdData = axis;
            response = this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
            pos = SM5Controller.convertResponse2single(response(5:8));
        end

        function goVariableFastToAbsolutePosition(this, position, axis)
            cmdId = '0048';
            nBytesToSend = 5;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytes = bitget(uint8(axis),8:-1:1);
            position = single(position);
            [dec1, dec2, dec3, dec4, floatbin] = float2dec(position, 'swap');
            [~, msb, lsb] = crc16([devBytes, floatbin]);
            cmdData = [axis, dec1, dec2, dec3, dec4];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end

        function goVariableSlowToAbsolutePosition(this, position, axis)
            cmdId = '0049';
            nBytesToSend = 5;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            devBytes = bitget(uint8(axis),8:-1:1);
            position = single(position);
            [dec1, dec2, dec3, dec4, floatbin] = float2dec(position, 'swap');
            [~, msb, lsb] = crc16([devBytes, floatbin]);
            cmdData = [axis, dec1, dec2, dec3, dec4];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
        end
        
        function status = getMainStatusFromOutputstage(this, axis)
            cmdId = '0120';
            nBytesToSend = 1;
            expectedResponse = hex2dec({'06','00','01','07'}); % 07 -> 06 ? Or '06','04','0b'?
            nExpectedBytes = 13;
            devBytes = bitget(uint8(axis),8:-1:1);
            [~, msb, lsb] = crc16(devBytes);
            cmdData = axis;
            response = this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb);
            status = struct();
            limitSwitch = uint8(response(5));
            switch limitSwitch
                case 1
                    status.limitSwitch = -1;
                case 2
                    status.limitSwitch = 1;
                otherwise
                    status.limitSwitch = 0;
            end
            axisPower = uint8(response(6));
            switch axisPower
                case 0
                    status.axisPower = 'off';
                case 1
                    status.axisPower = 'on';
            end
            home = uint8(response(7));
            switch home
                case 0
                    status.home = 'inactive';
                case 1
                    status.home = 'proceedingNegativeSwitch';
                case 2
                    status.home = 'proceedingPositiveSwitch';
                case 3
                    status.home = 'atHomeOrInterrupted';
            end
            status.singleStepResolution = uint8(response(10));
            status.isRunning = logical(uint8(response(11)));
        end
    end
    
    methods (Access = protected)
        function response = sendCommand(this, cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponseStart, ...
                msb, lsb, skipConnectionCheck)
            %
            % nExpectedBytes - Number of expected bytes in response.
            % skipConnectionCheck - Skip cehck whether connection establishment is required.
            
            if nargin < 9
                skipConnectionCheck = false;
            end
            
            if ~skipConnectionCheck && time2sec(now-this.timeWhenEstablished) > this.connectionCloseTimeout - 0.05 % give it some time
                this.establishConnection();
            end
            if nBytesToSend ~= numel(cmdData)
                error('The number of bytes to send does not match the data!');
            end
            maxReadAttempts = ceil(this.ser.Timeout/this.readPollTime);
            
            id = [uint8(hex2dec(cmdId(1:2))), uint8(hex2dec(cmdId(3:4)))];
            sendBytes = [this.syncSignal, id, uint8(nBytesToSend), cmdData, msb, lsb];
%             log4m.getLogger().trace(['sending bytes: ', num2str(sendBytes)]);
            attempts = 0;
            notEnoughBytes = false;
            while attempts < this.maxAttempts
                if this.ser.BytesAvailable > 0 % cleanup possible previous responses
                    response = fread(this.ser, this.ser.BytesAvailable);  %#ok<NASGU>
                    log4m.getLogger().warn('There were unread bytes before sending a new command.');
                end
                
                fwrite(this.ser, sendBytes);
                this.timeWhenEstablished = now;
                readAttempts = 0;
                response = zeros(nExpectedBytes,1);
                pause(this.readPollTime); % smallest pause which is possible to speed up communication
                while this.ser.BytesAvailable < 6 && readAttempts < maxReadAttempts
                    readAttempts = readAttempts + 1;
                    pause(0.01);
                end
                bytesRead = this.ser.BytesAvailable;
                if bytesRead > 0
                    response(1:bytesRead) = fread(this.ser, bytesRead);
                    if ~all(this.nAckSignal == response(1:6))
                        if nExpectedBytes > bytesRead
                            while bytesRead + this.ser.BytesAvailable < nExpectedBytes && readAttempts < maxReadAttempts
                                readAttempts = readAttempts + 1;
                                pause(this.readPollTime);
                            end
                            if this.ser.BytesAvailable >= nExpectedBytes - bytesRead
                                response(bytesRead+1:nExpectedBytes) = fread(this.ser, nExpectedBytes - bytesRead);
                                bytesRead = nExpectedBytes;
                            end
                        end
                        if bytesRead ~= nExpectedBytes
                            notEnoughBytes = true;
                        end
%                         log4m.getLogger().trace(['response = ', num2str(response')]);
                        if this.checkResponse(response, expectedResponseStart)
                            break
                        end
                    else
                        error('Command not accepted by controller.');
                    end
                end
                
                attempts = attempts + 1;
            end
            if attempts == this.maxAttempts
                errorMsg = 'Max attempts reached while communicating with COM port.';
                if notEnoughBytes
                    errorMsg = strcat(errorMsg, ' There was at least one response with less bytes than expected.');
                end
                error(errorMsg);
            end
        end
        
        function b = checkResponse(~, response, expectedStart)
            b = false;
            if numel(response) == 4+expectedStart(4)+2 ... % <ack 1b><XXXX 2b><nBytesResp 1b><n x byte><crc 2b>
                    && all(response(1:numel(expectedStart))==expectedStart) 
                if numel(expectedStart) == 4
                    if response(4) == 0 && response(end-1) == 0 && response(end) == 0 % the device likely does not support crc checks
                        b = true;
                    else % check crc
                        data = response(5:end-2);
                        data = arrayfun(@(x) bitget(x,8:-1:1), data, 'UniformOutput', false);
                        data = horzcat(data{:});
                        [~, msb, lsb] = crc16(data);
                        if msb == response(end-1) && lsb == response(end)
                            b = true;
                        end
                    end
                else
                    b = true;
                end
            end
        end
        
        function establishConnection(this)
            cmdId = '0400';
            nBytesToSend = 0;
            expectedResponse = hex2dec({'06','04','0b','00','00','00'});
            nExpectedBytes = 6;
            msb = uint8(0);
            lsb = uint8(0);
            cmdData = [];
            this.sendCommand(cmdId, cmdData, nBytesToSend, nExpectedBytes, expectedResponse, msb, lsb, true);
        end
            
        function clearConnection(this)
            clearConnCmd = [this.syncSignal;4;1;0;0;0]; % expectedResponse = [6;4;11;0;0;0];
            fwrite(this.ser,uint8(clearConnCmd));
            pause(this.ser.Timeout);
            fread(this.ser,this.ser.BytesAvailable);
        end
        
        function initSerialPort(this)
            this.ser = serial(this.comPort);    % This has to match the comm-port on the computer!
            this.ser.BaudRate = this.baudRate;     % Baud rate
            this.ser.Timeout = this.timeout;
            try
                fopen(this.ser);               % open comm-port
            catch ex %#ok<NASGU>
                log4m.getLogger().debug('Could not open COM port connection to SM5 pipette. Force-closing previous sessions.');
                try
                    a = instrfind(this.comPort);
                    if ~isempty(a)
                        fclose(a);
                        delete(a);
                    end
                    this.ser = serial(this.comPort);
                    this.ser.BaudRate = this.baudRate;
                    this.ser.Timeout = this.timeout;
                    fopen(this.ser);
                catch ex2
                    log4m.getLogger().error(ex2.message);
                    rethrow(ex2);
                end
            end
            this.establishConnection();
        end
    end
end

