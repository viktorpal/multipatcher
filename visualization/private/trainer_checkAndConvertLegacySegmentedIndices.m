function s = trainer_checkAndConvertLegacySegmentedIndices( s, boxSize, stackSize )
%TRAINER_CHECKANDCONVERTLEGACYSEGMENTEDINDICES Summary of this function goes here
%   Detailed explanation goes here

if size(s,2) == 3
    log4m.getLogger().info('Legacy segmented indices variable detected, now converting to bounding boxes.');
    hsx = floor(boxSize(1)/2);
    hsy = floor(boxSize(2)/2);
    s(end, [4,5]) = [0, 0];
    for i = 1:size(s,1)
        left = s(i,1)-hsx;
        if left < 1
            left = 1;
        end
        right = s(i,1)+hsx;
        if right > stackSize(2)
            right = stackSize(2);
        end
        top = s(i,2)-hsy;
        if top < 1
            top = 1;
        end
        bottom = s(i,2)+hsy;
        if bottom > stackSize(1)
            bottom = stackSize(1);
        end
        s(i,:) = [left, top, right, bottom, s(i,3)];
    end
else
    log4m.getLogger().debug('Segmented indices conversion is not needed.');
end

end

