function trainer_addNewPositive(trainerfig, vistoolModel, clickedPixel)
%TRAINER_ADDNEWPOSITIVE Summary of this function goes here
%   Detailed explanation goes here

clickedPixel = round(clickedPixel);
if clickedPixel(1) <= 0 || clickedPixel(2) <= 0
    return
end
imgSize = size(vistoolModel.imgstack.getStack());
if imgSize(1) < clickedPixel(2) || imgSize(2) < clickedPixel(1)
    return
end
trainerModel = get(trainerfig, 'UserData');
zslice = vistoolModel.zslice;
boxSize = trainerModel.boxSize;
hsx = floor(boxSize(1)/2);
hsy = floor(boxSize(2)/2);
left = clickedPixel(1) - hsx;
right = clickedPixel(1) + hsx;
top = clickedPixel(2) - hsy;
bottom = clickedPixel(2) + hsy;
if left < 1
    left = 1;
end
if top < 1
    top = 1;
end
if right > imgSize(2)
    right = imgSize(2);
end
if bottom > imgSize(1)
    bottom = imgSize(1);
end
if ~isempty(trainerModel.currentIndexToShow)
    cidx = trainerModel.currentIndexToShow;
    trainerModel.label = [trainerModel.label(1:cidx); trainerModel.POSITIVE_LABEL; trainerModel.label(cidx+1:end,:)];
    trainerModel.segmentedIndices = [trainerModel.segmentedIndices(1:cidx,:); [left, top, right, bottom, zslice]; trainerModel.segmentedIndices(cidx+1:end,:)];
    trainerModel.currentIndexToShow = trainerModel.currentIndexToShow+1;
else
    trainerModel.label = trainerModel.POSITIVE_LABEL;
    trainerModel.segmentedIndices = [trainerModel.segmentedIndices; [left, top, right, bottom, zslice]];
    trainerModel.currentIndexToShow = size(trainerModel.segmentedIndices,1);
end

end

