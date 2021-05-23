function trainer_loadData(filepath, trainerModel, vistoolModel)
%TRAINER_LOADDATA Load trainer data file
%   Does not check for save recommendation or the correctness of the loaded file.

log4m.getLogger().info(['Loading trainer data from file: ', filepath]);
data = load(filepath);
trainerModel.label = data.label;
trainerModel.features = data.features;
trainerModel.segmentedIndices = trainer_checkAndConvertLegacySegmentedIndices(data.segmentedIndices, ...
    trainerModel.boxSize, size(vistoolModel.imgstack.getStack()));
trainerModel.currentIndexToShow = data.currentIndexToShow;

trainerModel.filepath = filepath;
trainerModel.markAsSaved();

end

