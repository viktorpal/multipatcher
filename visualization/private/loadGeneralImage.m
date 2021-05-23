function loadGeneralImage( handles, target )
%LOADGENERALIMAGE Load general (eg. tissue) image stack
%   Loads an image stack, sets variables.

model = get(handles.mainfigure, 'UserData');
trainerFig = model.trainerFigure;
if nargin < 2
    defaultPath = model.fileDialogLocation;
    [filename, folder] = uigetfile({'*.tif;*.tiff', 'TIF stack files'}, 'Select an image stack file', defaultPath);
    if 0 == filename
        return;
    end
    model.fileDialogLocation = folder;
    target = fullfile(folder, filename);
end
if ~isempty(trainerFig) && ishandle(trainerFig) && strcmp(get(trainerFig, 'type'), 'figure')
    trainerModel = get(trainerFig, 'UserData');
    if trainerModel.isSaveRecommended
        trainer_saveModel(trainerModel);
    end
    trainer_resetModel(trainerModel);
    if ~isempty(trainerModel.filepath)
        trainerFolder = fileparts(trainerModel.filepath);
        [~, imgFilename] = fileparts(filename);
        labelFilepath = fullfile(trainerFolder, [imgFilename, '.mat']);
        if exist(labelFilepath, 'file')
            trainer_loadData(labelFilepath, trainerModel, model);
        end
    end
end
if nargin >= 2
    if ~isempty(trainerFig) && ishandle(trainerFig) && strcmp(get(trainerFig, 'type'), 'figure')
        close(trainerFig);
    end
end
enableDrawArea(handles);
loadAndShowImage(handles, target);

if isempty(model.imgstack.meta.stageX) || isempty(model.imgstack.meta.stageY) || isempty(model.imgstack.meta.stageZ)
    warndlg('Turret position could not be loaded! Functionality is not guaranteed.', 'Warning!');
    log4m.getLogger().warn(['Recently loaded image stack does not contain necessary meta information: ', target]);
end

end
