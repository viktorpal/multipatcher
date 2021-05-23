function [outpos, maxcorr, diff] = calculateBestMatchingPosition(y, x, referenceImg, targetImg, radius, maxdisp, corrSmoothSigma)
% CALCULATEBESTMATCHINGPOSITION - track an object between two images
% The calculated new position is based on template matching.
%
% This function is based on the corresponding source code part of
% CellTracker by Piccinini, F., Kiss, A., & Horvath, P.

if nargin < 7
    corrSmoothSigma = 15;
end

[sizeY, sizeX] = size(referenceImg);

if (y>radius) && (x>radius) && (y<sizeY-radius) && (y<sizeX-radius)
    templateImg = referenceImg(y-radius:y+radius, x-radius:x+radius);
end

outpos = [0, 0];
diff = [0, 0];
maxcorr = 0;

if (y > radius) && (y < sizeY-radius) && (x > radius) && (x < sizeX-radius)
    % mirror boundary if nescessary
    if (y < radius+maxdisp+2) || (y > sizeY-radius-maxdisp-2) || (x < radius+maxdisp+1) || (x > sizeX-radius-maxdisp-1)
        hxt = radius+maxdisp;
        hyt = radius+maxdisp;
        xi = sizeY; 
        yi = sizeX;
        mimg = zeros(sizeY + 2*hxt+1, sizeX + 2*hyt+1);
        mimg(hxt+1:hxt+xi, hyt+1:hyt+yi) = targetImg ;
        mimg(1:hxt, hyt+1:hyt+yi) = mimg(2*hxt:-1:hxt+1, hyt+1:hyt+yi);
        mimg(xi+hxt+1:xi+2*hxt, hyt+1:hyt+yi) = mimg(xi+hxt:-1:xi+1, hyt+1:hyt+yi);
        mimg(1:sizeY + 2*hxt+1, 1:hyt) = mimg(1:sizeY + 2*hxt+1, 2*hyt:-1:hyt+1);
        mimg(1:sizeY + 2*hxt+1, yi+hyt+1:yi+2*hyt) = mimg(1:sizeY + 2*hxt+1, yi+hyt:-1:yi+1);
        searchImg = mimg(y-radius-maxdisp+hxt:y+radius+maxdisp+hyt, x-radius-maxdisp+hxt:x+radius+maxdisp+hyt);
    else
        searchImg = targetImg(y-radius-maxdisp:y+radius+maxdisp, x-radius-maxdisp:x+radius+maxdisp);
    end

%         corr1 = standardCorrelation(searchImg, templateImg, 0);
        corr = xcorr_fft2(searchImg, templateImg, 'same');
%         corr = xcorr2(searchImg, templateImg);
%         corr = conv2(double(searchImg), rot90(conj(double(templateImg)),2), 'same');
    if corrSmoothSigma > 0
        H = fspecial('disk', corrSmoothSigma);
        corr = imfilter(corr, H);
    end
    
    [maxcorr, maxidx] = max(corr(:));
    [ynew, xnew] = ind2sub(size(corr), maxidx(1));
    ynew = ynew-1;
    xnew = xnew-1;
    diff = [ynew, xnew];
    
    xnew = xnew -radius-maxdisp;
    ynew = ynew -radius-maxdisp;
    x = round(x+xnew);
    y = round(y+ynew);
    if (y>radius+1) && (x>radius+1) && (y<sizeY-radius-1) && (x<sizeX-radius-1)
        outpos = [y, x];
    end
end