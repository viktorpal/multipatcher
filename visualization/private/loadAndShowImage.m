function loadAndShowImage( handles, target )
%SHOWIMAGE Show an image stack and set model variables
%   
fig = handles.mainfigure;
model = get(fig, 'UserData');

if ischar(target)
    origStack = ImageStack.load(target);
elseif isa(target, 'ImageStack')
    origStack = target;
else
    error('Input should be a filepath or an ImageStack object!');
end

model.originalImgstack = origStack;
model.imgstack = [];
model.reconstructedImgstack = [];
model.bgcorrImgstack = [];
deleteHandles(model.stackPredictionBoxesHandles);
model.stackPredictionBoxesHandles = [];
model.stackPredictionBoxes = [];
model.stackPredictionSelectedIndex = [];
showImageStack(handles);

end

