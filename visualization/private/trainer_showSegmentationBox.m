function lineHandlers = trainer_showSegmentationBox(ax, idx, zSliceShown, boxSizeZ, color, isActive)
%TRAINER_SHOWSEGMENTATIONBOX Summary of this function goes here
%   Detailed explanation goes here

if nargin < 6
    isActive = true;
end
if nargin < 5
    color = [0.5, 0.5, 0.5];
end
hsz = floor(boxSizeZ/2);

left = idx(1);
top = idx(2);
right = idx(3);
bottom = idx(4);
z = idx(5);

lineHandlers = [];
zdiff = abs(z-zSliceShown);
if zdiff <= hsz
    color = color*(1 - zdiff/(hsz*3));
    if isActive
        lineWidth = 4;
        lineStyle = '--';
    else
        lineWidth = 2;
        lineStyle = '-';
    end
    lineHandlers = plot(ax, [left, right, right, left, left], [top, top, bottom, bottom, top], ...
        'Color', color, 'LineWidth', lineWidth, 'LineStyle', lineStyle, 'HitTest', 'off');
end

end

