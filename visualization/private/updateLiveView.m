function updateLiveView(timerobj, handles ) 
%UPDATELIVEVIEW Callback function for timer object to update live view
%   

try
    model = get(handles.mainfigure, 'UserData');
    img = model.microscope.captureImage();
    model.imgHandle.CData = mat2gray(im2double(img));
%     model.imgHandle.CData = im2double(img);
%     model.imgHandle.CData = mat2gray(imadjust(im2double(img), stretchlim(img,10^-5)));
catch ME
    log4m.getLogger().trace(['Live view image handler was invalid while updating. ', ...
        'Maybe the live view was switched off while drawing a new image. Error message: ', ME.message]);
    stop(timerobj);
end

end
