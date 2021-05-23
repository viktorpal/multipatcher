function showImageStack(handles)
%SHOWIMAGESTACK Summary of this function goes here
%   Detailed explanation goes here

stopLiveViewIfRunning(handles);
fig = handles.mainfigure;
model = get(fig, 'UserData');
if isempty(model.originalImgstack)
    errordlg('Cannot show image stack until one is loaded!', 'No image is loaded');
    return
end
if strcmp(handles.showReconstructedMenuItem.Checked, 'on') % get(handles.showStackReconstructed, 'Value')
    if isempty(model.reconstructedImgstack)
        model.reconstructedImgstack = reconstructImageStack(model.originalImgstack, model.generalParameters);
    end
    model.imgstack = model.reconstructedImgstack;
elseif strcmp(handles.showBgCorrectedMenuItem.Checked, 'on') % get(handles.showStackBgcorr, 'Value')
    if isempty(model.bgcorrImgstack)
        wbh = waitbar(0, 'Correcting bacground...');
        drawnow;
        stack = model.originalImgstack.getStack();
        bg = imgaussfilt(stack, 20);
        img = stack- bg;
        img = img - min(img(:));
        img = img ./ max(img(:));
        model.bgcorrImgstack = ImageStack(img);
        model.bgcorrImgstack.meta = model.originalImgstack.meta;
        close(wbh);
    end
    model.imgstack = model.bgcorrImgstack;
else
    model.imgstack = model.originalImgstack;
end

imgstack = model.imgstack;
stack = imgstack.getStack();
[~, ~, nSlice] = size(stack);
zslice = model.zslice;
if isempty(zslice) || zslice > nSlice
    zslice = round(nSlice/2);
    model.zslice = zslice;
end

ax = handles.mainaxes;
zSlider = handles.zSlider;
set(zSlider, 'Max', nSlice);
set(zSlider, 'Value', zslice);
set(zSlider, 'Min', 1);
smallStep = 1/(nSlice-1);
bigStep = nSlice*0.1;
if bigStep < smallStep || 0.1 < smallStep
    bigStep = smallStep;
else
    bigStep = 0.1;
end
set(zSlider, 'SliderStep', [smallStep, bigStep]);

model.imgstack = imgstack;

if isempty(model.imgHandle) || ~ishandle(model.imgHandle)
    model.imgHandle = imshow(mat2gray(stack(:,:,zslice)), 'Parent', ax);
    axis(handles.mainaxes, 'image');
else
    model.imgHandle.CData = mat2gray(stack(:,:,zslice));
end
set(model.imgHandle, 'HitTest', 'off');
end

