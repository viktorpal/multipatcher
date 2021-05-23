function updateLivePrediction(timerobj, handles ) 
% AUTHOR:	Tamas Balassa
% DATE: 	Aug 22, 2017
% NAME: 	updateLivePrediction
% 
% UPDATELIVEVIEW Callback function for timer object to update live view
%
% This function is called periodically (by timerobj) and it draws and
% updates the predicted bounding boxes on the image.
%

if get(handles.livePredictionButton, 'Value')
    try
        model = get(handles.mainfigure, 'UserData');
        img = model.microscope.captureImage();
        cells = model.generalParameters.predictor.predictImage(img);

        deleteHandles(model.boundingBoxesHandle);
        model.boundingBoxesHandle = [];
        newBoxes = [];

        if ~model.microscope.stage.isMovingZ()
            for i = 1:numel(cells)
                w = cells(i).BoundingBox(3);
                h = cells(i).BoundingBox(4);

                if h <= model.generalParameters.predictionMaxObjectDimension(2)...
                        && w <= model.generalParameters.predictionMaxObjectDimension(1) ...
                        && h >= model.generalParameters.predictionMinObjectDimension(2) ...
                        && w >= model.generalParameters.predictionMinObjectDimension(1)
                    newBoxes(end+1) = rectangle('Position',[cells(i).BoundingBox(1), ...
                        cells(i).BoundingBox(2),cells(i).BoundingBox(3),cells(i).BoundingBox(4)], ...
                        'EdgeColor','r','LineWidth', 2, 'Parent', handles.mainaxes, 'Visible', 'off');
                end
            end
        end
        deleteHandles(model.boundingBoxesHandle);
        set(newBoxes, 'Visible', 'on');
        model.boundingBoxesHandle = newBoxes;

    catch ME
        log4m.getLogger().trace(['Live prediction error. ', 'Error message: ', ME.message]);
        stop(timerobj);
    end
end
end