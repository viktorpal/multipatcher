% fpath = '/home/koosk/Data-linux/data/autopatcher/autopatch_cell_tracking/20170821/autopatcher_screencapture1.avi';
% fpath = '/home/koosk/Data-linux/data/autopatcher/autopatch_cell_tracking/20170821/autopatcher_screencapture2.avi';
fpath = '/home/koosk/Data-linux/data/autopatcher/autopatch_cell_tracking/20170821/autopatcher_screencapture3.avi';
radius = 120;

videoFileReader = vision.VideoFileReader(fpath);
vs = videoFileReader.info.VideoSize;
vfw = vision.VideoFileWriter('cell_tracker_output.avi');
vfw.FileFormat = 'AVI';
vfw.FrameRate = 10;
videoPlayer = vision.VideoPlayer('Position', [100,100,vs(1),vs(2)]);
frame = step(videoFileReader);
fig = figure; imshow(frame); 
[cx, cy] = ginput(1);
close(fig);
objectRegion = [cx-radius, cy-radius, 2*radius+1, 2*radius+1];
objectImage = insertShape(frame,'Rectangle',objectRegion,'Color','red');

points = detectMinEigenFeatures(rgb2gray(frame),'ROI',objectRegion);
% points = detectFASTFeatures(rgb2gray(objectFrame),'ROI',objectRegion);
% points = detectSURFFeatures(rgb2gray(objectFrame),'ROI',objectRegion);
% points = detectHarrisFeatures(rgb2gray(objectFrame),'ROI',objectRegion);

objectImage = insertMarker(objectImage,points.Location,'+','Color','white');
for i = 1:vfw.FrameRate*2
    step(videoPlayer,objectImage);
    step(vfw,objectImage);
end

tracker = vision.PointTracker('MaxBidirectionalError',1);
initialize(tracker,points.Location,frame);

ctr = 0;
while ~isDone(videoFileReader)
      frame = step(videoFileReader);
      [points, validity] = step(tracker,frame);
      posXY = mean(points(validity,:));
      objectRegion = [posXY(1)-radius, posXY(2)-radius, 2*radius+1, 2*radius+1];
      out = insertShape(frame,'Rectangle',objectRegion,'Color','red');
%       out = insertMarker(frame,points(validity, :),'+');
      step(videoPlayer,out);
      step(vfw,out);
end

release(videoPlayer);
release(vfw);
release(videoFileReader);

