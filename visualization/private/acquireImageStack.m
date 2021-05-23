function acquireImageStack( handles )
%ACQUIREIMAGES Make Z-stack at the current position and show the images
%   Detailed explanation goes here

model = get(handles.mainfigure, 'UserData');
imgstack = model.microscope.captureStack(model.generalParameters.stackSize, 1, 'top');
loadGeneralImage(handles, imgstack);

end
