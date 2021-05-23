%%
fpath = '/home/koosk/data/images/stack_images/tissues/20170821_normtest/tissue1.tif';
yStart = 246; xStart = 560; refSlice = 31; diameter = 2*120;
% % % yStart = 841; xStart = 582; refSlice = 34; diameter = 2*120;
% % % yStart = 582; xStart = 841; refSlice = 34; diameter = 2*120;
%%
% fpath = '/home/koosk/data/images/stack_images/tissues/20170824/tissue001.tif';
% yStart = 235; xStart = 740; refSlice = 8; diameter = 2*120;
% % yStart = 320; xStart = 775; refSlice = 8; diameter = 2*120;
% % yStart = 626; xStart = 1190; refSlice = 20; diameter = 2*120;
%%
% fpath = '/home/koosk/data/images/stack_images/tissues/20180214_human/tissue003.tif';
% % yStart = 889; xStart = 349; refSlice = 65; diameter = 2*120;
% yStart = 240; xStart = 174; refSlice = 75; diameter = 2*120;
%%
% fpath = '/home/koosk/data/images/stack_images/tissues/20180214_human/tissue016.tif';
% yStart = 294; xStart = 849; refSlice = 15; diameter = 2*120;
% % yStart = 592; xStart = 1057; refSlice = 28; diameter = 2*120;
%%
% fpath = '/home/koosk/data/images/stack_images/tissues/20170915_human/tissue068.tif';
% yStart = 585; xStart = 285; refSlice = 40; diameter = 2*120;
% % yStart = 244; xStart = 756; refSlice = 31; diameter = 2*120;
% % yStart = 730; xStart = 1192; refSlice = 80; diameter = 2*120;
%%
% fpath = '/home/koosk/data/images/stack_images/tissues/20170915_human/tissue012.tif';
% yStart = 122; xStart = 701; refSlice = 26; diameter = 2*120;
%%
% fpath = '/home/koosk/data/images/stack_images/tissues/20170915_human/tissue027.tif';
% % yStart = 402; xStart = 838; refSlice = 60; diameter = 2*120;
% yStart = 368; xStart = 468; refSlice = 24; diameter = 2*120;
%%

corrZsameMultiplier = 0.95;
showImages = true;
abDiff = 3;
showDiff = abDiff+4;

imgstack = ImageStack.load(fpath);
stack = imgstack.getStack();
[sy, sx, sz] = size(stack);
values = zeros(sz,1);
tic

refImg = imnoise(stack(:,:,refSlice), 'gaussian', 0, 1e-4); 
xShift = +randi(13)-7;
yShift = +randi(13)-7;
for i = 1:sz
    currentImage = stack(:,:,i);
    values(i) = calculateZSimilarity(yStart, xStart, yStart+yShift, xStart+xShift, refImg, currentImage, floor(diameter/2));
    %%
%     values = abs(values);
    %%
    if i == refSlice
        values(i) = values(i)*corrZsameMultiplier;
    end
end
toc

showIndices = max(1,refSlice-showDiff):min(sz,refSlice+showDiff);
showIndicesLabel = [-showDiff, showDiff];
if refSlice - showDiff < 1
    showIndicesLabel(1) = -showDiff + 1 - (refSlice-showDiff);
end
if refSlice + showDiff > sz
    showIndicesLabel(2) = showDiff - (sz - (refSlice + showDiff));
end
blue1 = [33,5,190]./255;
valfig = figure; plot(showIndicesLabel(1):showIndicesLabel(2), values(showIndices), 'Color', blue1)
valfig.OuterPosition(1:2) = [156, 703];
valfig.OuterPosition(3:4) = [252, 216];
valax = gca;
valax.XLim = showIndicesLabel;
hold on
pink1 = [149,5,137]./255;
pink2 = [187,83,171]./255;
ocean1 = [74,162,162]./255;
ocean2 = [39,106,106]./255;
minmaxVal = [min(min(values(showIndices)), 0), max(values(showIndices))];
valax.YLim = [minmaxVal(1), minmaxVal(2)*1.1];
p = plot([0, 0], valax.YLim, '--', 'Color', pink2);
p = plot([0-abDiff, 0-abDiff], valax.YLim, 'Color', pink2);
p = plot([0+abDiff, 0+abDiff], valax.YLim, 'Color', pink2);

%%
[belowMinVal, belowMinPos] = min(values(refSlice-abDiff:refSlice-1));
[aboveMinVal, aboveMinPos] = min(values(refSlice+1:refSlice+abDiff));
%%
% [belowMinVal, belowMinPos] = max(values(refSlice-abDiff:refSlice-1));
% [aboveMinVal, aboveMinPos] = max(values(refSlice+1:refSlice+abDiff));
%%
p = plot([-abDiff-1+belowMinPos, 0, 0+aboveMinPos], [belowMinVal, values(refSlice), aboveMinVal], 'x', 'Color', ocean2, 'MarkerSize', 10, 'LineWidth', 1.5);


[folder, fname, ext] = fileparts(fpath);
folders = strsplit(folder, filesep);
imgExt = '.png';
fname = strcat(fname, '_', num2str(xStart), '_', num2str(yStart), '_', num2str(refSlice));
%% decision images
belowImgName = strcat(folders{end}, '_', fname, '_below', imgExt);
focusImgName = strcat(folders{end}, '_', fname, '_focus', imgExt);
aboveImgName = strcat(folders{end}, '_', fname, '_above', imgExt);
belowMaxImage = stack(:,:,refSlice-abDiff-1+belowMinPos);
windowBelowMax = belowMaxImage(max(round(yStart-diameter/2)+yShift,1):min(round(yStart+diameter/2)+yShift,sy), max(round(xStart-diameter/2)+xShift,1):min(round(xStart+diameter/2)+xShift,sx));
imwrite(windowBelowMax, belowImgName);
windowRefImg = refImg(max(round(yStart-diameter/2),1):min(round(yStart+diameter/2),sy), max(round(xStart-diameter/2),1):min(round(xStart+diameter/2),sx));
imwrite(windowRefImg, focusImgName);
aboveMaxImage = stack(:,:,refSlice+aboveMinPos);
windowAboveMax = aboveMaxImage(max(round(yStart-diameter/2)+yShift,1):min(round(yStart+diameter/2)+yShift,sy), max(round(xStart-diameter/2)+xShift,1):min(round(xStart+diameter/2)+xShift,sx));
imwrite(windowAboveMax, aboveImgName);
%% all observed images and values
for iDiff = -abDiff:abDiff
    observedImage = stack(:,:,refSlice+iDiff);
    windowObserved = observedImage(max(round(yStart-diameter/2),1):min(round(yStart+diameter/2),sy), max(round(xStart-diameter/2),1):min(round(xStart+diameter/2),sx));
    imgWindowName = strcat(folders{end}, '_', fname, '_', sprintf('%+d', iDiff), imgExt);
    imwrite(windowObserved, imgWindowName);
end
observedValues = values(refSlice-abDiff:refSlice+abDiff);
valuesFname = strcat(folders{end}, '_', fname, '_values.csv');
csvwrite(valuesFname, observedValues);
%%
if showImages
    figure,
    subplot(1,3,1)
    imshow(windowBelowMax);
    subplot(1,3,2)
    imshow(windowRefImg);
    subplot(1,3,3)
    imshow(windowAboveMax);
end
figFname = strcat(folders{end}, '_', fname, '_plot.png');
saveas(valfig,figFname);