function B = imresizeZ(A, zScale)
%IMRESIZEZ Resize image stack along z axis using linear interpolation
%   

if rem(zScale,1) ~= 0
    error('Scale should be an integer (regardless of the datatype).');
end
if zScale <= 1
    error('Scale should be greater than 1.');
end
if ndims(A) ~= 3
    error('The input image should be 3 dimensional.');
end

steps = 0:1/zScale:1-1/zScale;
[sy, sx, sz] = size(A);
B = zeros(sy, sx, sz*(zScale-1));
for i = 1:sz-1
    for j = 1:numel(steps)
        B(:,:,(i-1)*zScale+j) = A(:,:,i)*(1-steps(j)) + A(:,:,i+1)*steps(j);
    end
end
B(:,:,end) = A(:,:,end);

end

