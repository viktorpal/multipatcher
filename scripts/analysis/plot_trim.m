%% This script should be run after analyzeLog.m; It can be used to trim data that are too long and plot the remaining part only.

%% plot
%% 20181114
% idx = 51; seconds2skip = 130; seconds2show = 230;
% idx = 48; seconds2skip = 620; seconds2show = 800;
%% 20181122
% idx = 6; seconds2skip = 0; seconds2show = 140;
% idx = 10; seconds2skip = 0; seconds2show = 140;
%% 20181129
% idx = 2; seconds2skip = 0; seconds2show = 350;
% idx = 5; seconds2skip = 0; seconds2show = 400;
% idx = 7; seconds2skip = 0; seconds2show = 110;
% % idx = 6; seconds2skip = 0; seconds2show = 1000;
% % idx = 14; seconds2skip = 0; seconds2show = 9999;
% idx = 23; seconds2skip = 0; seconds2show = 300;
%% 20190208
% idx = 4; seconds2skip = 0; seconds2show = 350;
% idx = 7; seconds2skip = 0; seconds2show = 250;
% idx = 10; seconds2skip = 0; seconds2show = 190;
idx = 15; seconds2skip = 0; seconds2show = 300;

%% params
% figpos = get(0, 'Screensize'); % to use current screen
figpos = get(0,'MonitorPositions'); figpos = figpos(2,:); % to use second screen
fontSize = 24;
lineWidth = 2.5;

%%
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
tstampsPressure = seconds(datetime(attempts(idx).pipettePressure.timestamp, 'ConvertFrom', 'datenum') - minTstamp);
tstampsPip = seconds(datetime(attempts(idx).pipettePositions.timestamp, 'ConvertFrom', 'datenum') - minTstamp);
tstampsRs = seconds(datetime(attempts(idx).resistance.timestamp, 'ConvertFrom', 'datenum') - minTstamp);


tsPressureIdx = tstampsPressure >= seconds2skip & tstampsPressure <= seconds2show;
tsPipIdx = tstampsPip >= seconds2skip & tstampsPip <= seconds2show;
tsRsIdx = tstampsRs >= seconds2skip & tstampsRs <= seconds2show;
tstampsPressure = tstampsPressure(tsPressureIdx);
tstampsPip = tstampsPip(tsPipIdx);
tstampsRs = tstampsRs(tsRsIdx);

tstamps = [tstampsPressure; tstampsPip; tstampsRs];
minTstamp = min(tstamps);
tstampsPressure = tstampsPressure - minTstamp;
tstampsPip = tstampsPip - minTstamp;
tstampsRs = tstampsRs - minTstamp;

% fill last pipette position
lastTstamps = zeros(3,1);
if ~isempty(tstampsPressure)
    lastTstamps(1) = tstampsPressure(end);
end
if ~isempty(tstampsPip)
    lastTstamps(2) = tstampsPip(end);
end
if ~isempty(tstampsRs)
    lastTstamps(3) = tstampsRs(end);
end
maxTstamp = max(lastTstamps);

tstampsPip = [tstampsPip; datenum(maxTstamp)];
if ~isempty(attempts(idx).pipettePositions.position)
    pos = [attempts(idx).pipettePositions.position; attempts(idx).pipettePositions.position(end,:)];
    pos = pos(tsPipIdx, :);
else
    pos = [];
end

try
    pipfig = figure;
    plot3(pos(1:end,1), pos(1:end,2), pos(1:end,3), 'LineWidth', lineWidth*1.5)
    daspect([1 1 1])
    pbaspect([1 1 1])
    hold on
    l = size(pos,1);
    xl = get(gca,'xlim');
    yl = get(gca,'ylim');
    zl = get(gca,'zlim');
    plot3(pos(1:end,1), pos(1:end,2), repmat(zl(1),l,1), 'LineWidth', lineWidth );
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

plotfig = figure;
try
    ax1 = subplot(3,1,1); p1 = plot(tstampsPip, [pos(:,3); pos(end,3)]); 
%     ax1 = subplot(3,1,1); p1 = plot(tstampsPip, [pos(:,3); attempts(idx).pipettePositions.position(end,3)]); 
    ylabel('um', 'Parent', ax1)
    title('Depth', 'Parent', ax1);
catch ex
    disp('Could not draw PIPETTE');
    ax1 = [];
end

try
%     ax2 = subplot(3,1,2); p2 = plot(tstampsPressure, attempts(idx).pipettePressure.pressure(1:numel(tstampsPressure)));
    ax2 = subplot(3,1,2); p2 = plot(tstampsPressure, attempts(idx).pipettePressure.pressure(tsPressureIdx));
    ylabel('mbar', 'Parent', ax2)
    title('Pressure', 'Parent', ax2);
catch ex
    disp('Could not draw PRESSURE');
    ax2 = [];
end

try
    ax3 = subplot(3,1,3); p3 = plot(tstampsRs, attempts(idx).resistance.resistance(tsRsIdx));
    ylabel('MOhm', 'Parent', ax3)
    xlabel('Duration (sec)', 'Parent', ax3);
    title('Resistance', 'Parent', ax3);
    ax3.YScale = 'log';
catch ex
    disp('Could not draw RS');
    ax3 = [];
end

linkaxes([ax1, ax2, ax3], 'x');

for ax = [ax1, ax2, ax3]
    ax.FontSize = fontSize;
    ax.LineWidth = 1.5;
end
for pf = [p1, p2, p3]
    if ~isempty(pf) && isvalid(pf)
        pf.LineWidth = lineWidth;
    end
end
% export

plotfig.Position = figpos ;
drawnow
pipfig.Position = figpos ;
drawnow
saveas(plotfig, [fname, '_attempt', num2str(idx), '_plot', '.png']);
saveas(pipfig, [fname, '_attempt', num2str(idx), '_pipette', '.png']);