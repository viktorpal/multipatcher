
deviceName = 'Dev2';
valve1channel = 'port0/line4';
valve2channel = 'port0/line5';
valve3channel = 'port0/line3';
valve4channel = 'port0/line1';
valve5channel = 'port0/line2';

pipetteSensorChannel = 'ai3';

sampleRate = 12000;
updateTime = 0.1;

pipetteOffset = 7.6608;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

daqreset;
valves = daq.createSession('ni');
valves.addDigitalChannel(deviceName, valve1channel, 'OutputOnly');
valves.addDigitalChannel(deviceName, valve2channel, 'OutputOnly');
valves.addDigitalChannel(deviceName, valve3channel, 'OutputOnly');
valves.addDigitalChannel(deviceName, valve4channel, 'OutputOnly');
valves.addDigitalChannel(deviceName, valve5channel, 'OutputOnly');

sensors = daq.createSession('ni');
sensors.IsContinuous = true;
sensors.Rate = sampleRate;
sensors.addAnalogInputChannel(deviceName, pipetteSensorChannel, 'Voltage');
% sensors.addAnalogInputChannel(deviceName, this.tankSensorChannel, 'Voltage');
% sensors.addAnalogInputChannel(deviceName, this.elphysSignalInChannel, 'Voltage');
% sensors.addAnalogInputChannel(deviceName, this.squareSignalMonitorChannel, 'Voltage');
sensors.NotifyWhenDataAvailableExceeds = round(sampleRate * updateTime);
dataListener = sensors.addlistener('DataAvailable', @(src,event) sensorDataAvailableCb(src,event,pipetteOffset));
sensors.startBackground();

valveStates = [false,...
               false,...
               false,...
               false,...
               false];
valves.outputSingleScan(valveStates);

function sensorDataAvailableCb(~, event, pipetteOffset)
    pipetteData = (mean(event.Data(:,1))-2.5)/2*1000;
    pipetteData = pipetteData - pipetteOffset;
    disp(num2str(pipetteData));
    %% write to file, uncomment if slow
    fid = fopen('pipette_sensor_data.csv','a');
    fprintf(fid,'%4.2f\n', pipetteData);
    fclose(fid);
end








