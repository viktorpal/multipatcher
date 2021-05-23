function ima = standardCorrelation(ima1,ima2, avgI)
% AUTHOR: Peter Horvath
 
% CellTracker Toolbox
% Copyright (C) 2015 Peter Horvath, Filippo Piccinini
% Synthetic and Systems Biology Unit
% Hungarian Academia of Sciences, BRC, Szeged. All rights reserved.
%
% This program is free software; you can redistribute it and/or modify it 
% under the terms of the GNU General Public License version 3 (or higher) 
% as published by the Free Software Foundation. This program is 
% distributed WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
% General Public License for more details.

% Reads in both images
% ima1= double(ima1); avg1 = mean(mean(ima1)); ima1= ima1-avg1;
% ima2= double(ima2); avg2 = mean(mean(ima2)); ima2= ima2-avg1;
% ima1 = ima1./max(abs(ima1(:)));
% ima2 = ima2./max(abs(ima2(:)));
s1 = size(ima1);
s2 = size(ima2);

% Find the max size of the images
s = max(s1,s2);

% Allocates it to the output image
sx = s(1);
sy = s(2);

% Copy original images into bigger images
image1 = zeros(sx,sy);
image1(sx/2-s1(1)/2+1:sx/2+s1(1)/2,sy/2+1-s1(2)/2:sy/2+s1(2)/2) = ima1;
image2 = zeros(sx,sy);
image2(sx/2-s2(1)/2+1:sx/2+s2(1)/2,sy/2+1-s2(2)/2:sy/2+s2(2)/2) = ima2;

% Calculates FFT of bith images
f1 = fft2(fftshift(image1));
f2 = fft2(fftshift(image2));

% Calculates correlation
corr = fftshift(ifft2(f1.*conj(f2)));

% Normalises it with autocorrelation
corr = corr ./ max(max(ifft2(f2.*conj(f2))));

ima = abs(corr);
    
    