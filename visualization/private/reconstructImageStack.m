function reconstructedImageStack = reconstructImageStack(imgstack, generalParameters)
%RECONSTRUCTIMAGESTACK Summary of this function goes here
%   Detailed explanation goes here

assert(isa(imgstack, 'ImageStack'), 'Input should be an ImageStack object!');

stack = zeros(imgstack.meta.height, imgstack.meta.width, imgstack.meta.D3Size);
wbh = waitbar(0, 'Reconstructing image stack...');
drawnow;
nSlice = size(stack,3);
log4m.getLogger().trace(['Reconstructing image stack of ', num2str(nSlice), ' slices']);
iterations = generalParameters.dicIterations;
direction = generalParameters.dicDirection;
wAccept = generalParameters.dicWAccept;
wSmooth = generalParameters.dicWSmooth;
locsize = generalParameters.dicLocsize;
for i = 1:nSlice
    img = reconstructDicImage(imgstack.getLayer(i), 'iterations', iterations, 'direction', direction, ...
        'wAccept', wAccept, 'wSmooth', wSmooth, 'locsize', locsize);
    img(img<0) = 0;
    stack(:,:,i) = mat2gray(img);
    waitbar(i/nSlice, wbh);
end
reconstructedImageStack = ImageStack();
reconstructedImageStack.setStack(stack);
reconstructedImageStack.meta = imgstack.meta;
close(wbh);

end

