frameRate = 2;

% tdata = Tracker2();
% % tdata.microscope = model.microscope;
% tdata.templateImage = model.microscope.camera.capture();
% origTemplate = tdata.templateImage;
% % button = questdlg('click in the center of the target cell');
% clickedPosPx = get(mainaxes, 'CurrentPoint');
% clickedPosPx = round(clickedPosPx(1,:));
% tdata.xStartPos = clickedPosPx(1);
% tdata.yStartPos = clickedPosPx(2);
% tdata.zStartPos = model.microscope.stage.getZ();
% tdata.zStep = 2;
% tdata.radius = 120;
% tdata.maxDisplacement = 20;
% tdata.distanceThreshold = 5;
% % tdata.axes = mainaxes;


tdata = Tracker3();
% tdata.microscope = model.microscope;
tdata.templateImage = model.microscope.camera.capture();
origTemplate = tdata.templateImage;
% button = questdlg('click in the center of the target cell');
clickedPosPx = get(mainaxes, 'CurrentPoint');
clickedPosPx = round(clickedPosPx(1,:));
tdata.xStartPos = clickedPosPx(1);
tdata.yStartPos = clickedPosPx(2);
tdata.zStartPos = model.microscope.stage.getZ();
tdata.zStep = 2;
tdata.radius = 120;
tdata.maxDisplacement = 20;
tdata.distanceThreshold = 5;
% tdata.axes = mainaxes;
tdata.initialize();



t = timer();
t.TimerFcn = @(obj, event) tdata.trackingCb(model.microscope, mainaxes);
t.ExecutionMode  = 'fixedRate';
t.Period = 1/frameRate;
t.BusyMode = 'drop';
t.Name = 'realtimeTrackingTest timer';
start(t);