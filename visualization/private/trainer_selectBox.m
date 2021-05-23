function trainer_selectBox(trainerfig, vistoolModel, clickedPixel)
%TRAINER_SELECTBOX Summary of this function goes here
%   Detailed explanation goes here

trainerModel = get(trainerfig, 'UserData');
closestBoxIdx = [];
closestDistance = Inf;
zslice = vistoolModel.zslice;
boxSize = trainerModel.boxSize;
hsz = floor(boxSize(3)/2);

for i = 1:size(trainerModel.segmentedIndices, 1)
    boxPos = trainerModel.segmentedIndices(i,:); % left, top, right, bottom, z order
    left = boxPos(1);
    top = boxPos(2);
    right = boxPos(3);
    bottom = boxPos(4);
    centerZ = boxPos(5);
    boxCenter = [(left+right)/2, (top+bottom)/2, centerZ];
    if abs(zslice - centerZ) <= hsz ...
            && clickedPixel(1) >= left && clickedPixel(1) <= right && clickedPixel(2) >= top && clickedPixel(2) <= bottom

        distance = norm([clickedPixel(1), clickedPixel(2), zslice]-boxCenter);
        if distance < closestDistance
            closestBoxIdx = i;
            closestDistance = distance;
        end
    end
end

if ~isempty(closestBoxIdx)
    trainerModel.currentIndexToShow = closestBoxIdx;
end

end

