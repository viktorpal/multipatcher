frameRate = 5;

%%
videoFname = 'autopatcher_screencapture.avi';
zposFname = 'autopatcher_screencapture_zpositions.csv';
if 2 == exist(videoFname, 'file')
    [~, tmpName] = fileparts(tempname);
    copyfile(videoFname, ['autopatcher_screencapture_', tmpName, '.avi']);
    copyfile(zposFname, ['autopatcher_screencapture_zpositions_', tmpName, '.csv'];
end

vw = VideoWriter(videoFname);
vw.FrameRate = frameRate;
vw.open();
global zPositions
zPositions = [];
t = timer();
t.TimerFcn = @(obj, event) captureVideoCb(vw,model);
t.StopFcn = @(obj,event) captureVideoStopFcn(vw,zposFname);
t.ExecutionMode  = 'fixedRate';
t.Period = 1/frameRate;
t.BusyMode = 'drop';
t.Name = 'captureVideoExample timer';
start(t);


function captureVideoCb(vw,model)
    global zPositions
    vw.writeVideo(model.microscope.camera.capture());
    zPositions = [zPositions; model.microscope.getStageZ()];
end

function captureVideoStopFcn(vw,zposFname)
    vw.close();
    global zPositions
    csvwrite(zposFname, zPositions);
end
