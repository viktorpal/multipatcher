% logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20181024.log';
% logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20181114.log';
% logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20181122.log';
% logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20181129.log';
% logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20181210.log';
logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20190208.log';
% logfile = '/home/koosk/data/data/autopatcher/logs/autopatcher20190219.log';
% logfile = '/home/koosk/data/data/autopatcher/logs/test_analyzelog.log';
% logfile = './autopatcher.log';


%% params
% figpos = get(0, 'Screensize'); % to use current screen
figpos = get(0,'MonitorPositions'); figpos = figpos(2,:); % to use second screen
fontSize = 24;
lineWidth = 2.5;

%%

zeroAxes = true;
thenRemoveZeros = true;

lineExpr = '(?<date>\d+-\d+-\d+) (?<time>\d+:\d+:\d+),(?<msec>\d+) (?<level>.*) (?<caller>.*) - (?<msg>.*)';
xyzExpr = 'Moving pipette (?<axis>.) to (?<position>([+-])?\d+(.\d+)?)';
pipMovetoFilter = 'PipetteController.moveTo';
pressureFilter = 'CustomPressureController.pressureRegulatorCallback';
apResistanceFilter = 'AutoPatcher.timerFcn';
vpCallbackFilter = 'VisualPatcher.controlCb';
pressureEventInterval = 0.1;
callerFilter = {pipMovetoFilter, pressureFilter, apResistanceFilter, vpCallbackFilter};
dateFilter = {};


pipette = model.microscope.getPipette(this.activePipetteId);

emptyPipettePosition = struct('position', [], 'timestamp', []);
emptyPipettePressure = struct('pressure', [], 'timestamp', []);
emptyResistance = struct('resistance', [], 'timestamp', []);
attempts = struct('firstTimestamp', {}, 'lastTimestamp', {}, ...
    'pipettePositions', emptyPipettePosition, ...
    'pipettePressure', emptyPipettePressure, ...
    'resistance', emptyResistance);
pipettePositions = emptyPipettePosition;
pipettePressure = emptyPipettePressure;
resistanceList = emptyResistance;
resistanceFilter = 'resistance = (?<rs>(([+-])?\d+(.\d+)|NaN)?)';

fid = fopen(logfile);
tline = fgetl(fid);
while ischar(tline)
    parts = regexp(tline, lineExpr, 'names');
    if ~isempty(parts) && any(strcmp(parts.caller, callerFilter)) && (isempty(dateFilter) || strcmp(parts.date, dateFilter))
        cline = struct('date', [], 'time', [], 'caller', [], 'msg', [], 'msec', []);
        cline.date = parts.date;
        cline.time = parts.time;
        cline.caller = parts.caller;
        cline.msg = parts.msg;
        cline.msec = parts.msec;
        
        datetimeStr = [cline.date, ' ', cline.time, ',', cline.msec];
        datetimeNum = datenum(datetimeStr, 'yyyy-mm-dd HH:MM:SS,FFF');
%         datetimeValue = datetime(datetimeStr, 'InputFormat', 'yyyy-MM-dd hh:mm:ss,SSS');
        switch cline.caller
            case pipMovetoFilter
                if isempty(attempts) || time2sec(datetimeNum - attempts(end).lastTimestamp) > 3*60
                    if ~isempty(attempts)
                        attempts(end).pipettePositions = pipettePositions;
                        attempts(end).pipettePressure = pipettePressure;
                        attempts(end).resistance = resistanceList;
                    end
                    attempts(end+1).firstTimestamp = datetimeNum; %#ok<SAGROW>
                    pipettePositions = emptyPipettePosition;
                    pipettePressure = emptyPipettePressure;
                    resistanceList = emptyResistance;
                end
                attempts(end).lastTimestamp = datetimeNum;
                xyzData = regexp(cline.msg, xyzExpr, 'names');
                pos = xyzData.position;
                switch xyzData.axis
                    case 'X'
                        pos = [str2double(pos), NaN, NaN];
                    case 'Y'
                        pos = [NaN, str2double(pos), NaN];
                    case 'Z'
                        pos = [NaN, NaN, str2double(pos)];
                    otherwise
                        error(['Unsupported axis value: ', xyzData.axis]);
                end
                pipettePositions.timestamp = [pipettePositions.timestamp; datetimeNum];
                pipettePositions.position = [pipettePositions.position; pos];
            case pressureFilter
                pressureExpr = 'Pipette pressures of last (?<numValues>\d+) values: (?<pipettePressures>(([+-])?\d+(.\d+)?,)+) tank pressures: (?<tankPressures>(([+-])?\d+(.\d+)?,)+)';
                pressureData = regexp(cline.msg, pressureExpr, 'names');
                commaPos = strfind(pressureData.pipettePressures, ',');
                lastCommaPos = 0;
                numValues = str2double(pressureData.numValues);
                iPressure = 0;
                if ~isempty(pipettePressure.timestamp)
                    interval = seconds(datetime(datetimeNum, 'ConvertFrom', 'datenum') - datetime(pipettePressure.timestamp(end), 'ConvertFrom', 'datenum'))/numValues;
                else
                    interval = pressureEventInterval;
                end
                
                for iPval = numValues-1:-1:0
                   iPressure = iPressure + 1;
                   pressureTimestamp = datetimeNum - datenum(duration(0,0,iPval*interval));
                   pressureValue = str2double(pressureData.pipettePressures(lastCommaPos+1:commaPos(iPressure)-1));
                   lastCommaPos = commaPos(iPressure);
                   pipettePressure.timestamp = [pipettePressure.timestamp; pressureTimestamp];
                   pipettePressure.pressure = [pipettePressure.pressure; pressureValue];
                end
            case apResistanceFilter
                rsData = regexp(cline.msg, resistanceFilter, 'names');
                if ~isempty(rsData) && ~isempty(rsData.rs)
                    resistanceList.timestamp = [resistanceList.timestamp; datetimeNum];
                    resistanceList.resistance = [resistanceList.resistance, str2double(rsData.rs)];
                end
            case vpCallbackFilter
                rsData = regexp(cline.msg, resistanceFilter, 'names');
                if ~isempty(rsData) && ~isempty(rsData.rs)
                    resistanceList.timestamp = [resistanceList.timestamp; datetimeNum];
                    resistanceList.resistance = [resistanceList.resistance, str2double(rsData.rs)];
                end
            otherwise
                error('Unhandled caller value');
        end
    end
    tline = fgetl(fid);
end
fclose(fid);
if ~isempty(attempts)
    attempts(end).pipettePositions = pipettePositions;
    attempts(end).pipettePressure = pipettePressure;
    attempts(end).resistance = resistanceList;    
end

%%
for ia = 1:numel(attempts)
    for iOrd = 1:3
        firstValid = find(~isnan(attempts(ia).pipettePositions.position(:,iOrd)),1);
        if ~isempty(firstValid)
            attempts(ia).pipettePositions.position(1,iOrd) = attempts(ia).pipettePositions.position(firstValid,iOrd);
            for ip = 2:size(attempts(ia).pipettePositions.position,1)
                if isnan(attempts(ia).pipettePositions.position(ip,iOrd))
                    attempts(ia).pipettePositions.position(ip,iOrd) = attempts(ia).pipettePositions.position(ip-1,iOrd);
                end
            end
        else
            attempts(ia).pipettePositions.position(:,iOrd) = 0;
        end
    end
    attempts(ia).firstTimestamp = datestr(attempts(ia).firstTimestamp,'yyyy-mm-dd HH:MM:SS,FFF');
    attempts(ia).lastTimestamp  = datestr(attempts(ia).lastTimestamp,'yyyy-mm-dd HH:MM:SS,FFF');
    % convert pipette positions to stage coord
    for ip = 1:size(attempts(ia).pipettePositions.position,1)
        attempts(ia).pipettePositions.position(ip,:) = pipette.pipette2microscope(attempts(ia).pipettePositions.position(ip,:));
    end
    % fill last pipette position
    lastTstamps = zeros(3,1);
    if ~isempty(attempts(ia).pipettePressure.timestamp)
        lastTstamps(1) = attempts(ia).pipettePressure.timestamp(end);
    end
    if ~isempty(attempts(ia).pipettePositions.timestamp)
        lastTstamps(2) = attempts(ia).pipettePositions.timestamp(end);
    end
    if ~isempty(attempts(ia).resistance.timestamp)
        lastTstamps(3) = attempts(ia).resistance.timestamp(end);
    end
    maxTstamp = max(lastTstamps);
    
    attempts(ia).pipettePositions.timestamp = [attempts(ia).pipettePositions.timestamp; datenum(maxTstamp)];
    attempts(ia).pipettePositions.position = [attempts(ia).pipettePositions.position; attempts(ia).pipettePositions.position(end,:)];
    if zeroAxes
        attempts(ia).pipettePositions.position = attempts(ia).pipettePositions.position - attempts(ia).pipettePositions.position(1,:);
        if thenRemoveZeros
            removeIdx = attempts(ia).pipettePositions.position == [0,0,0];
            removeIdx = removeIdx(:,1) & removeIdx(:,2) & removeIdx(:,3);
            attempts(ia).pipettePositions.position = attempts(ia).pipettePositions.position(~removeIdx,:);
            attempts(ia).pipettePositions.timestamp = attempts(ia).pipettePositions.timestamp(~removeIdx);
            if ~isempty(attempts(ia).pipettePositions.position)
                attempts(ia).pipettePositions.position = attempts(ia).pipettePositions.position - attempts(ia).pipettePositions.position(1,:);
            end
        end
    end
end


[~, fname, ~] = fileparts(logfile);
for idx = 1:numel(attempts)
    %% plot
% idx = 4;
% idx = 29;
    try
        pos = attempts(idx).pipettePositions.position; 
        pipfig = figure;
        plot3(pos(1:end,1), pos(1:end,2), pos(1:end,3), 'LineWidth', lineWidth*1.5)
        daspect([1 1 1])
        pbaspect([1 1 1])
        hold on
        l = size(pos,1);
        xl = get(gca,'xlim');
        yl = get(gca,'ylim');
        zl = get(gca,'zlim');
        plot3(pos(1:end,1), pos(1:end,2), repmat(zl(1),l,1), 'LineWidth', lineWidth);
        plot3(pos(1:end,1), repmat(yl(2),l,1), pos(1:end,3), 'LineWidth', lineWidth);
        plot3(repmat(xl(2),l,1), pos(1:end,2), pos(1:end,3), 'LineWidth', lineWidth);
        grid on;
        p3ax = gca;
        p3ax.FontSize = fontSize;
        xlabel('x')
        ylabel('y')
        zlabel('z')
        legend('Pipette position', 'X projection', 'Y projection', 'Z projection')
    catch ex
        ex
    end

    ax = gca;
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    ax.ZGrid = 'on';

    tstamps = [];
    if numel(attempts(idx).pipettePressure.timestamp) > 0
        tstamps = [tstamps, attempts(idx).pipettePressure.timestamp(1)];
    end
    if numel(attempts(idx).pipettePositions.timestamp) > 0
        tstamps = [tstamps, attempts(idx).pipettePositions.timestamp(1)];
    end
    if numel(attempts(idx).resistance.timestamp) > 0
        tstamps = [tstamps, attempts(idx).resistance.timestamp(1)];
    end
%     minTstamp = datetime(min([attempts(idx).pipettePressure.timestamp(1), attempts(idx).pipettePositions.timestamp(1), attempts(idx).resistance.timestamp(1)]), 'ConvertFrom', 'datenum');
    minTstamp = datetime(min(tstamps), 'ConvertFrom', 'datenum');
    if ~isempty(minTstamp)
        tstampsPressure = seconds(datetime(attempts(idx).pipettePressure.timestamp, 'ConvertFrom', 'datenum') - minTstamp);
        tstampsPip = seconds(datetime(attempts(idx).pipettePositions.timestamp, 'ConvertFrom', 'datenum') - minTstamp);
        tstampsRs = seconds(datetime(attempts(idx).resistance.timestamp, 'ConvertFrom', 'datenum') - minTstamp);
    else
        tstampsPressure = [];
        tstampsPip = [];
        tstampsRs = [];
    end

    plotfig = figure;
    try
        ax1 = subplot(3,1,1); p1 = plot(tstampsPip, attempts(idx).pipettePositions.position(:,3)); 
        ylabel('um', 'Parent', ax1)
        title('Depth', 'Parent', ax1);
    catch ex
        ax1 = [];
    end

    try
        ax2 = subplot(3,1,2); p2 = plot(tstampsPressure, attempts(idx).pipettePressure.pressure);
        ylabel('mbar', 'Parent', ax2)
        title('Pressure', 'Parent', ax2);
    catch ex
        ax2 = [];
    end

    try
        ax3 = subplot(3,1,3); p3 = plot(tstampsRs, attempts(idx).resistance.resistance);
        ylabel('MOhm', 'Parent', ax3)
        xlabel('Duration (sec)', 'Parent', ax3);
        title('Resistance', 'Parent', ax3);
        ax3.YScale = 'log';
    catch ex
        ax3 = [];
    end

    linkaxes([ax1, ax2, ax3], 'x');
    
    for ax = [ax1, ax2, ax3]
        ax.FontSize = fontSize;
        ax.LineWidth = 1.5;
    end
    for pf = [p1, p2, p3]
        if ~isempty(pf)
            pf.LineWidth = lineWidth;
        end
    end

    % export

    plotfig.Position = figpos;
    drawnow
    pipfig.Position = figpos;
    drawnow
    %%
    saveas(plotfig, [fname, '_attempt', num2str(idx), '_plot', '.png']);
    saveas(pipfig, [fname, '_attempt', num2str(idx), '_pipette', '.png']);

    out = struct('Pipette_position_timestamp_second', tstampsPip, ...
        'Pipette_position_stagecoord_um', attempts(idx).pipettePositions.position, ...
        'Pressure_timestamp_second', tstampsPressure, ...
        'Pressure_mbar', attempts(idx).pipettePressure.pressure, ...
        'RS_timestamp_second', tstampsRs, ...
        'RS_MOhm', attempts(idx).resistance.resistance');
    struct2csv(out, [fname, '_attempt', num2str(idx), '.csv'])
    close(pipfig);
    close(plotfig);
end
%%
save([fname, '_attempts.mat'], 'attempts');









