%%
videoPath = '/home/koosk/data/data/autopatcher/autopatch_cell_tracking/20170821/autopatcher_screencapture4.avi';
mov = VideoReader(videoPath);
yStart = 521; xStart = 698;
%%

diameter = 250;
maxDisplacement = 0;
corrSmoothSigma = 0;
isHistogramMatching = true;

% stack = imgstack.getStack();
% [sy, sx, sz] = size(stack);
sz = mov.Duration*mov.FrameRate;
sy = mov.Height;
sx = mov.Width;
trackedPos = zeros(sz,5);
trackedPos(1,:) = [yStart, xStart, 0, 0, 0];
values = zeros(sz,1);
tic

refImg = rgb2gray(readFrame(mov));
% currentImage = refImg;
ctr = 0;
while hasFrame(mov)
    ctr = ctr + 1;
%     currentImage = stack(:,:,i);
%     refImg = currentImage;
    currentImage = rgb2gray(readFrame(mov));
    
%     [endPos, maxcorr, smallPos] = calculateBestMatchingPosition(yStart, xStart, ...
%         refImg, currentImage, diameter/2, maxDisplacement, corrSmoothSigma, isHistogramMatching);
%     trackedPos(i,:) = [endPos, maxcorr, smallPos];
    
    windowRef = refImg(max(round(yStart-diameter/2),1):min(round(yStart+diameter/2),sy), max(round(xStart-diameter/2),1):min(round(xStart+diameter/2),sx));
    windowCurr = currentImage(max(round(yStart-diameter/2),1):min(round(yStart+diameter/2),sy), max(round(xStart-diameter/2),1):min(round(xStart+diameter/2),sx));
    
    refValue = std2(windowRef);
    currValue = std2(windowCurr);
    values(ctr) = refValue - currValue;
    
%     refValue = mean2(windowRef);
%     currValue = mean2(windowCurr);
%     values(ctr) = currValue - refValue;

%     kernel = [-1, -1, -1, -1, 8, -1, -1, -1]/8;
%     refDiff = conv2(double(windowRef), kernel, 'same');
%     refcpp = mean2(refDiff);
%     currDiff = conv2(double(windowCurr), kernel, 'same');
%     currcpp = mean2(currDiff);
%     values(ctr) = currcpp - refcpp;
end
toc





