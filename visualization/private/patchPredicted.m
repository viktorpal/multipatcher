function patchPredicted(handles)
%PATCHPREDICTED Select a prediction and start visual patch-clamping after confirmation
%   The function currently uses random ordering of the predicted bounding boxes and asks the user if the next in list is
%   alright to be patch-clamped. Later the random can be changed to some smarter ordering, eg. ascending order based on 
%   the chance of occurrence of the phenotype.

model = get(handles.mainfigure, 'UserData');
predictionPerformed = false;
if isempty(model.stackPredictionBoxes)
    predictStackCallback(handles);
    predictionPerformed = true;
end
if predictionPerformed && model.generalParameters.logFindAndPatchStack
    name = [datestr(now,'yyyy-mm-dd_HH-MM-SS,FFF_'), 'stack_findandpatch.tif'];
    stackFullpath = fullfile(model.visualLogger.folderpath, name);
    log4m.getLogger.trace(['Saving stack used for prediction: ', stackFullpath]);
    model.originalImgstack.save(stackFullpath);
end
dialogTitle = 'Targeted patch-clamp';
if isempty(model.stackPredictionBoxes)
    msgbox('No cells were detected that could be patch-clamped.', dialogTitle, 'modal');
    return
end

choiceText = 'Do you want to patch-clamp this cell?';

% nBoxes = size(model.stackPredictionBoxes,2);
% order = randperm(nBoxes); % random order

% only those with higher ProbabilityMax then Predictor's threshold
% l = [model.stackPredictionBoxes.ProbabilityMax] > model.generalParameters.predictor.predictionThreshold;
% order = find(l);
% % the above in random order:
% order = order(randperm(numel(order)));

% only those with higher ProbabilityMax then Predictor's threshold, in descending order
[prob, origIdx] = sort([model.stackPredictionBoxes.ProbabilityMax], 'descend');
order = origIdx(prob > model.generalParameters.predictor.predictionThreshold);

btnCallback = @btn_callback;
d = createChooseDialog(btnCallback);
selectedIdx = 1;
choice = [];
while true
    model.stackPredictionSelectedIndex = order(selectedIdx);
    model.zslice = model.stackPredictionBoxes(order(selectedIdx)).z;
    showPredictedBoundingBoxes_Callback(handles);
    d.UserData.text.String = [choiceText, ' (', num2str(selectedIdx), '/', num2str(numel(order)), ')'];
    drawnow;
    choice = 'Cancel';
    uiwait(d);

    switch choice
        case 'Cancel'
            return
        case 'prevBtn'
            if selectedIdx > 1
                selectedIdx = selectedIdx - 1;
            else
                selectedIdx = numel(order);
            end
        case 'nextBtn'
            if selectedIdx < numel(order)
                selectedIdx = selectedIdx + 1;
            else
                selectedIdx = 1;
            end
        case 'yesBtn'
            break
        otherwise
            error('Unsupported choice value.');
    end
end
delete(d);

props = model.stackPredictionBoxes(order(selectedIdx));
bbox = props.BoundingBox;
centerPx = [bbox(1)+bbox(3)/2, bbox(2)+bbox(4)/2];
stageZ = model.imgstack.meta.stageZ + props.z*model.imgstack.meta.pixelSizeZ;
stageXY = [model.imgstack.meta.stageX model.imgstack.meta.stageY] + [1, -1] .* centerPx .* [model.microscope.pixelSizeX, model.microscope.pixelSizeY] ;
ptStageCoord = [stageXY, stageZ];

sampleTopProblemFound = false;
if isempty(model.sampleTop)
    warndlg('The sample''s top position is not defined. It is set to the top of the stack!', ...
            'Targeted patch clamping problem');
    sampleTopProblemFound = true;
elseif ptStageCoord(3) > model.sampleTop
    warndlg('The sample''s top position is defined to be under the tartget location. It is set to the top of the stack!', ...
            'Targeted patch clamping problem');
    sampleTopProblemFound = true;
end
if sampleTopProblemFound
    model.sampleTop = model.imgstack.meta.stageZ + model.imgstack.meta.D3Size*model.imgstack.meta.pixelSizeZ;
end

if ~isempty(model.trackerPositionUpdateListener) && ishandle(model.trackerPositionUpdateListener)
    delete(model.trackerPositionUpdateListener);
end
deleteHandles(model.trackerBoxHandles);
model.trackerBoxHandles = [];
startBlindPatcherIfNotRunning(handles);
drawnow;
startVPControlIfNotRunning(handles);
drawnow;
startLiveViewIfNotRunning(handles);
pipetteId = model.autopatcher.activePipetteId;
model.trackerPositionUpdateListener = model.visualPatcher.tracker.addlistener('PositionUpdate', ...
    @(src,event) trackerPositionUpdateListenerCallback(src,event,handles));
model.visualPatcher.start(ptStageCoord, model.sampleTop, 'pipetteId', pipetteId);
model.visualPatcher.diary.logPatchClampInfo('DetectionSelectedIndex', selectedIdx);
log4m.getLogger().trace(['Chosen detection index: ', num2str(selectedIdx), ' Probability values: min: ', ...
    num2str(props.ProbabilityMin, '%0.2f'), ' max: ' num2str(props.ProbabilityMax, '%0.2f'), ...
    ' mean: ', num2str(props.ProbabilityMean, '%0.2f')]);

    function btn_callback(hObject, ~, dialogObj)
      choice = hObject.Tag;
      uiresume(dialogObj);
   end
end

function d = createChooseDialog(btnCallback)
d = dialog('Position',[300 300 400 70], 'Name','Select One', 'WindowStyle', 'normal');
txt = uicontrol('Parent',d,...
       'Style','text',...
       'Position',[20 30 300 40],...
       'String','Do you want to patch-clamp this cell? (xxx/yyy)');

prevBtn = uicontrol('Parent',d,...
   'Position',[20 15 90 25],...
   'String','<- Previous',...
   'Tag', 'prevBtn', ...
   'Callback', @(o,e) btnCallback(o, e, d));

yesBtn = uicontrol('Parent',d,...
       'Position',[120 15 90 25],...
       'String','Yes',...
       'Tag', 'yesBtn', ...
       'Callback', @(o,e) btnCallback(o, e, d));
   
nextBtn = uicontrol('Parent',d,...
       'Position',[220 15 90 25],...
       'String','Next ->',...
       'Tag', 'nextBtn', ...
       'Callback', @(o,e) btnCallback(o, e, d));
ud = struct('text', txt, 'prevBtn', prevBtn, 'nextBtn', nextBtn, 'yesBtn', yesBtn);
d.UserData = ud;
end

