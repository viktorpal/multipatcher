classdef PressureAndElphysSystem < matlab.mixin.SetGet
    %PRESSUREANDELPHYSSYSTEM Class for NI board session management
    %   All the necessary DAQ/NI board sessions for pressure and
    %   electrophysiology measurements should be initialized here. The USB
    %   board does not support multiple sessions with inputs and it is
    %   technically required to include them into a single session. Then
    %   this class partitions the incoming signal and fires events when a
    %   given type of data is available.
    %
    % SEE addlistener
    
    events
        PressureDataAvailable
        ElphysDataAvailable
    end
    
    properties
        deviceName           % Dev2
        valve1channel        % port0/line0
        valve2channel        % port0/line1
        valve3channel        % port0/line2
        valve4channel        % port0/line3
        valve5channel        % port0/line4
        VALVE1OPEN
        VALVE2OPEN
        VALVE3OPEN
        VALVE4OPEN
        VALVE5OPEN
        pipetteSensorChannel       % ai0
        tankSensorChannel          % ai1
        squareSignalMonitorChannel % ai3
        elphysSignalInChannel      % ai2
        sampleRate                 % 12000
        updateTime                 % 0.01 (seconds)
    end
    
    properties (SetAccess = private)
        valves
        sensors
    end
    
    properties (Access = private)
        inited
        isOddData
        lastData
        dataListener
        errorListener
    end

    methods
        function this = PressureAndElphysSystem()
            this.inited = false;
            this.isOddData = false;
            this.lastData = [];
            this.VALVE1OPEN = 1;
            this.VALVE2OPEN = 1;
            this.VALVE3OPEN = 1;
            this.VALVE4OPEN = 1;
            this.VALVE5OPEN = 1;
        end
        
        function init(this)
            if this.inited
                return
            end
            this.inited = true;
            
            daqreset;
            this.valves = daq.createSession('ni');
            this.valves.addDigitalChannel(this.deviceName, this.valve1channel, 'OutputOnly');
            this.valves.addDigitalChannel(this.deviceName, this.valve2channel, 'OutputOnly');
            this.valves.addDigitalChannel(this.deviceName, this.valve3channel, 'OutputOnly');
            this.valves.addDigitalChannel(this.deviceName, this.valve4channel, 'OutputOnly');
            this.valves.addDigitalChannel(this.deviceName, this.valve5channel, 'OutputOnly');
            
            this.sensors = daq.createSession('ni');
            this.sensors.IsContinuous = true;
            this.sensors.Rate = this.sampleRate;
            this.sensors.addAnalogInputChannel(this.deviceName, this.pipetteSensorChannel, 'Voltage');
            this.sensors.addAnalogInputChannel(this.deviceName, this.tankSensorChannel, 'Voltage');
            this.sensors.addAnalogInputChannel(this.deviceName, this.elphysSignalInChannel, 'Voltage');
            this.sensors.addAnalogInputChannel(this.deviceName, this.squareSignalMonitorChannel, 'Voltage');
            this.sensors.NotifyWhenDataAvailableExceeds = round(this.sampleRate * this.updateTime);
            this.dataListener = this.sensors.addlistener('DataAvailable', @this.dataAvailableListener);
            this.errorListener = this.sensors.addlistener('ErrorOccurred',@this.errorOccurredListener);
            this.sensors.startBackground();
        end
        
        function tf = hasListener(this)
            tf = false;
            if event.hasListener(this, 'PressureDataAvailable') || event.hasListener(this, 'ElphysDataAvailable')
                tf = true;
            end
        end
        
        function delete(this)
            if this.inited
                delete(this.dataListener);
                stop(this.sensors);
                delete(this.valves);
                delete(this.sensors);
            end
        end
    end
    
    methods (Access = private)
        function dataAvailableListener(this, ~, event)
            try
                pressureEvent = PressureEvent(event.TriggerTime,event.Data(:,[1,2]),event.TimeStamps);
                notify(this, 'PressureDataAvailable', pressureEvent);
                if this.isOddData
                    this.isOddData = false;
                    elphysEvent = ElphysEvent(event.TriggerTime,[this.lastData; event.Data(:,[3,4])],event.TimeStamps);
                    notify(this, 'ElphysDataAvailable', elphysEvent);
                else
                    this.lastData = event.Data(:,[3,4]);
                    this.isOddData = true;
                end
            catch ex
                disp(ex.message);
            end
        end
        
        function errorOccurredListener(this, src, event)
            disp(getReport(event.Error));
            log4m.getLogger().error(getReport(event.Error));
        end
    end
    
end

