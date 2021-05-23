function trainer_saveModel( trainerModel )
%TRAINER_SAVEMODEL Ask for filename and save trainer model file
%   Does not check if save is recommended.

[fileName, pathName] = uiputfile('*.mat','Save training set as (.mat)', trainerModel.filepath);
if pathName == 0
    return
end
filepath = [pathName, fileName];

label = trainerModel.label; %#ok<NASGU>
features = trainerModel.features; %#ok<NASGU>
segmentedIndices = trainerModel.segmentedIndices; %#ok<NASGU>
currentIndexToShow = trainerModel.currentIndexToShow; %#ok<NASGU>

save(filepath, 'label', 'features', 'segmentedIndices', 'currentIndexToShow');
trainerModel.filepath = filepath;
trainerModel.markAsSaved();
log4m.getLogger().info(['Saved trainer data to file: ', filepath]);

end

