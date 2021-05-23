%%
% mov = VideoReader('/home/koosk/BRC/data/autopatch_cell_tracking/autopatcher_screencapture7.avi');
% yStart = 533;
% xStart = 990;
% offset = 24;
%%
% mov = VideoReader('/home/koosk/Data-linux/data/autopatch_cell_tracking/20170715/autopatcher_screencapture.avi');
% yStart = 542;
% xStart = 780;
% offset = 10;
%%
mov = VideoReader('/home/koosk/Data-linux/data/autopatcher/autopatch_cell_tracking/20170821/autopatcher_screencapture1.avi');
yStart = 525;
xStart = 730;
offset = 0;
%%

diameter = 120;
maxDisplacement = 20;
corrSmoothSigma = 0;

% stack = zeros(mov.Height, mov.Width, mov.Duration*mov.FrameRate); 
% i = 1; 
% while hasFrame(mov)
%     stack(:,:,i) = rgb2gray(readFrame(mov));
%     i = i+1;
% end
% clear i

trackedPos = [yStart, xStart, 0, 0, 0];
sz = mov.Duration*mov.FrameRate;
tic

for i = 1:offset
    readFrame(mov);
end
currentImage = rgb2gray(readFrame(mov));
firstImage = currentImage;

while hasFrame(mov)
    refImg = currentImage;
    currentImage = rgb2gray(readFrame(mov));
    [endPos, maxcorr, smallPos] = calculateBestMatchingPosition(trackedPos(end,1), trackedPos(end,2), refImg, currentImage, diameter/2, maxDisplacement, corrSmoothSigma);
%     refImg = stack(:,:,offset);
%     [endPos, maxcorr, smallPos] = calculateBestMatchingPosition(trackedPos(end,1), trackedPos(end,2), refImg, stack(:,:,offset+i), diameter/2, maxDisplacement);
    if all(endPos)
        trackedPos(end+1,:) = [endPos, maxcorr, smallPos];
    else
        trackedPos(end+1,:) = trackedPos(end,:);
    end
end
toc