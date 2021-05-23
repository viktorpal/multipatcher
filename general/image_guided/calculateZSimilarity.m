function [similarityValue, windowRef, windowCurr] = calculateZSimilarity( ty, tx, y, x, templateImage, searchImg, radius)
%CALCULATEZSIMILARITY Calculates z similarity based on variance
%   The function calculates a similarity value between the template (reference) and search images. The lower the
%   absolute value of the similarity is, the more similar they are. The value can be negative which fairly well
%   indicates an over/under focus scenario (at least for DIC images).
%   ty - y position of the tracked center point in the template iamge
%   tx - x position of the tracked center point in the template iamge
%   y  - y position of the tracked center point in the search iamge
%   x  - y position of the tracked center point in the search iamge
%   templateImage - image which is used as the template in the similarity measurement
%   radius - image which is used as the search image in the similarity measurement


[sy, sx] = size(templateImage);

windowRef = mat2gray(templateImage(max(round(ty-radius),1):min(round(ty+radius),sy), max(round(tx-radius),1):min(round(tx+radius),sx)));
windowCurr = mat2gray(searchImg(max(round(y-radius),1):min(round(y+radius),sy), max(round(x-radius),1):min(round(x+radius),sx)));

similarityValue = std2(abs(windowRef-windowCurr));

end

