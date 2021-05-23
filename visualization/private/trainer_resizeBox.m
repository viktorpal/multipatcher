function trainer_resizeBox( vistoolfig, vistoolaxes, trainerfig, vistoolModel, mode )
%TRAINER_RESIZEBOX Summary of this function goes here
%   Detailed explanation goes here

persistent closestBoxIdx
persistent closestSideFlags

if nargin < 5
    mode = 'start';
end

LATERAL_DISTANCE_THRESHOLD = 20;
MINIMUM_SIDE_LENGTH = 50;

pt = vistoolaxes.CurrentPoint(1,1:2);

if strcmp(mode, 'start')
    trainerModel = get(trainerfig, 'UserData');
    closestBoxIdx = [];
    closestDistance = [];
    closestSideFlags = [];
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
        if abs(zslice - centerZ) <= hsz ...
                && left - LATERAL_DISTANCE_THRESHOLD <= pt(1) && right + LATERAL_DISTANCE_THRESHOLD >= pt(1) ...
                && top - LATERAL_DISTANCE_THRESHOLD <= pt(2) && bottom + LATERAL_DISTANCE_THRESHOLD >= pt(2)
            leftDistance = abs(pt(1) - left);
            rightDistance = abs(pt(1) - right);
            topDistance = abs(pt(2) - top);
            bottomDistance = abs(pt(2) - bottom);
            leftClose = false;
            rightClose = false;
            topClose = false;
            bottomClose = false;
            if leftDistance <= LATERAL_DISTANCE_THRESHOLD
                leftClose = true;
            end
            if rightDistance <= LATERAL_DISTANCE_THRESHOLD
                rightClose = true;
            end
            if topDistance <= LATERAL_DISTANCE_THRESHOLD
                topClose = true;
            end
            if bottomDistance <= LATERAL_DISTANCE_THRESHOLD
                bottomClose = true;
            end
            
            if leftClose || rightClose || topClose || bottomClose
                minDistance = min([leftDistance, rightDistance, topDistance, bottomDistance]);
                if isempty(closestBoxIdx) || minDistance < closestDistance
                    closestBoxIdx = i;
                    closestDistance = minDistance;
                    closestSideFlags = [leftClose, topClose, rightClose, bottomClose];
                end
            end
        end
    end
    if ~isempty(closestBoxIdx)
%         disp([num2str(closestBoxIdx), ', ', num2str(closestDistance)]);
        vistoolfig.WindowButtonMotionFcn = @(~,~,~) trainer_resizeBox(vistoolfig, vistoolaxes, trainerfig, vistoolModel, 'motion');
        vistoolfig.WindowButtonUpFcn = @(~,~,~) trainer_resizeBox(vistoolfig, vistoolaxes, trainerfig, vistoolModel, 'end');
    end
    
elseif strcmp(mode, 'motion')
    trainerModel = get(trainerfig, 'UserData');
    stackSize = size(vistoolModel.imgstack.getStack());
    if pt(1) < 1
        pt(1) = 1;
    end
    if pt(2) < 1
        pt(2) = 1;
    end
    if pt(1) > stackSize(2)
        pt(1) = stackSize(2);
    end
    if pt(2) > stackSize(1)
        pt(2) = stackSize(1);
    end
    
    if closestSideFlags(1)
        if trainerModel.segmentedIndices(closestBoxIdx,3) - pt(1) > MINIMUM_SIDE_LENGTH
            trainerModel.segmentedIndices(closestBoxIdx,1) = pt(1);
        else
            trainerModel.segmentedIndices(closestBoxIdx,1) = trainerModel.segmentedIndices(closestBoxIdx,3) - MINIMUM_SIDE_LENGTH;
        end
    end
    if closestSideFlags(2)
        if trainerModel.segmentedIndices(closestBoxIdx,4) - pt(2) > MINIMUM_SIDE_LENGTH
            trainerModel.segmentedIndices(closestBoxIdx,2) = pt(2);
        else
            trainerModel.segmentedIndices(closestBoxIdx,2) = trainerModel.segmentedIndices(closestBoxIdx,4) - MINIMUM_SIDE_LENGTH;
        end
    end
    if closestSideFlags(3)
        if pt(1) - trainerModel.segmentedIndices(closestBoxIdx,1) > MINIMUM_SIDE_LENGTH
            trainerModel.segmentedIndices(closestBoxIdx,3) = pt(1);
        else
            trainerModel.segmentedIndices(closestBoxIdx,3) = trainerModel.segmentedIndices(closestBoxIdx,1) + MINIMUM_SIDE_LENGTH;
        end
    end
    if closestSideFlags(4)
        if pt(2) - trainerModel.segmentedIndices(closestBoxIdx,2) > MINIMUM_SIDE_LENGTH
            trainerModel.segmentedIndices(closestBoxIdx,4) = pt(2);
        else
            trainerModel.segmentedIndices(closestBoxIdx,4) = trainerModel.segmentedIndices(closestBoxIdx,2) + MINIMUM_SIDE_LENGTH;
        end
    end
elseif strcmp(mode, 'end')
    vistoolfig.WindowButtonMotionFcn = [];
    vistoolfig.WindowButtonUpFcn = [];
else
    log4m.getLogger().error(['unsupported mode: ', mode]);
end

end

