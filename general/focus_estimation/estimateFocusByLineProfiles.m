function [x, y, z] = estimateFocusByLineProfiles( imgstack, pipetteOrientation, varargin)
%ESTIMEFOCUSBYLINEPROFILES Summary of this function goes here
%   Detailed explanation goes here

p = inputParser;
addParameter(p, 'gaussFiltSigma', 1.5, @(x) isnumeric(x) && ~isempty(x) && x>0);
addParameter(p, 'show', false, @islogical);
addParameter(p, 'percentDropCheck', 40, @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'percentile', 90, @(x) isnumeric(x) && ~isempty(x));
parse(p, varargin{:});
gaussFiltSigma = p.Results.gaussFiltSigma;
show = p.Results.show;
percentDropCheck = p.Results.percentDropCheck;
percentile = p.Results.percentile;

stack = imgstack.getStack();
stack = mat2gray(stack - median(stack,3));
minimg = min(stack, [], 3);
minimg = imgaussfilt(minimg, gaussFiltSigma);
[x, y] = calculateLineProfile(minimg, -pipetteOrientation, 'show', show, 'percentDropCheck', percentDropCheck, ...
    'percentile', percentile);

minimg = squeeze(min(stack, [], 2));
minimg = imgaussfilt(minimg, gaussFiltSigma);
[z, ~] = calculateLineProfile(minimg, 180, 'show', show);
log4m.getLogger().trace(['Line profile based pipette tip detection result: (', num2str(x), ', ', num2str(y), ', ', num2str(z), ')']);
end

function [bestX, bestY] = calculateLineProfile(minimg, orientation, varargin)
p = inputParser;
addParameter(p, 'stopWhenFound', true, @islogical);
addParameter(p, 'show', false, @islogical);
addParameter(p, 'percentDropCheck', 40, @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'percentile', 90, @(x) isnumeric(x) && ~isempty(x));
parse(p, varargin{:});
stopWhenFound = p.Results.stopWhenFound;
show = p.Results.show;
percentDropCheck = p.Results.percentDropCheck;
percentile = p.Results.percentile;

[sy, sx] = size(minimg);
lineWidth = max(sx,sy);
if show
    figure, imagesc(minimg), colormap gray
    hold on
end
h = [];
i = 0;
found = false;
e = [cosd(orientation), sind(orientation)];
if e(1) >= 0
    xStart = sx;
else
    xStart = 0;
end
if e(2) >= 0
    yStart = sy;
else
    yStart = 0;
end
v1 = (xStart - sx/2) / cosd(orientation);
v2 = (yStart - sy/2) / sind(orientation);
if ~isfinite(v1)
    s = v2;
elseif ~isfinite(v2)
    s = v1;
else
    s = min(v1,v2);
end
xStart = sx/2 + s*cosd(orientation);
yStart = sy/2 + s*sind(orientation);


while true
    i = i+1;
    xCenter = xStart - i*cosd(orientation);
    yCenter = yStart - i*sind(orientation);
    x = xCenter + lineWidth/2*cosd(orientation+90) * [1, -1];
    y = yCenter + lineWidth/2*sind(orientation+90) * [1, -1];
    delete(h);
    if xCenter < 1 || xCenter > sx || yCenter < 1 || yCenter > sy
        break
    end
    if show
        h = plot(x,y, 'color', 'blue');
    end
    drawnow % outside if to allow other callback execution
    [cx, cy, c] =  improfile(minimg, x, y);
    if ~found && min(c) < prctile(c,percentile)*(1-percentDropCheck/100)
        log4m.getLogger.debug(['Significant drop found at step: ', num2str(i), ', rate: ', num2str(percentDropCheck), '%' , ', x=', num2str(xCenter), ', y=', num2str(yCenter) ]);
        found = true;
        if stopWhenFound
            break
        end
    end
end

idx = c < prctile(c,percentile)*(1-percentDropCheck/100);
if show
    figure, plot(1:numel(c), c)
    hold on;
    plot(find(idx), c(idx), 'x')
end
bestX = mean(cx(idx));
bestY = mean(cy(idx));
if show
    figure, imagesc(minimg), colormap gray
    hold on
    plot(bestX, bestY, 'x', 'MarkerSize', 16, 'LineWidth', 2);
end

end

