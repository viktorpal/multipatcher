function showPipetteSegmentation( handles )
%SHOWPIPETTESEGMENTATION Summary of this function goes here
%   Detailed explanation goes here

fig = handles.mainfigure;
ax = handles.mainaxes;
model = get(fig, 'UserData');
focusData = model.focusData;

if ~isempty(model.graphics.pipetteSegmentationObjects)% should already be deleted here
    model.graphics.pipetteSegmentationObjects = [];
end

p1 = focusData.points1;
p2 = focusData.points2;
np1 = focusData.outliers1;
np2 = focusData.outliers2;
V1 = focusData.linefit1;
V2 = focusData.linefit2;
avg1 = focusData.avg1;
avg2 = focusData.avg2;
numSlices = focusData.numSlices;

height = model.imgstack.meta.height;

h = scatter3(ax, [p1(:,1); p2(:,1)], height - [p1(:,2); p2(:,2)], [p1(:,3); p2(:,3)], ...
    'MarkerEdgeColor', 'blue', 'HitTest', 'off');
model.graphics.pipetteSegmentationObjects = [model.graphics.pipetteSegmentationObjects; h];
h = scatter3(ax, [np1(:,1); np2(:,1)], height - [np1(:,2); np2(:,2)], [np1(:,3); np2(:,3)], ...
    'MarkerEdgeColor', 'black', 'HitTest', 'off');
model.graphics.pipetteSegmentationObjects = [model.graphics.pipetteSegmentationObjects; h];

vec = V1(:,1);
t1s = (numSlices - avg1(3)) / vec(3);
t1e = (1-avg1(3)) / vec(3);
l1s = avg1 + t1s*vec';
l1e = avg1 + t1e*vec';
l1 = [l1s; l1e];
l1(:,2) = height - l1(:,2);
h = line(l1(:,1), l1(:,2), l1(:,3), 'color', 'red', 'linewidth', 1, 'Parent', ax, 'HitTest', 'off');
model.graphics.pipetteSegmentationObjects = [model.graphics.pipetteSegmentationObjects; h];

vec = V2(:,1);
t2s = (numSlices - avg2(3)) / vec(3);
t2e = (1-avg2(3)) / vec(3);
l2s = avg2 + t2s*vec';
l2e = avg2 + t2e*vec';
l2 = [l2s; l2e];
l2(:,2) = height - l2(:,2);
h = line(l2(:,1), l2(:,2), l2(:,3), 'color', 'red', 'linewidth', 1, 'Parent', ax, 'HitTest', 'off');
model.graphics.pipetteSegmentationObjects = [model.graphics.pipetteSegmentationObjects; h];

end

