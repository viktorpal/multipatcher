function trainer_resetModel( trainerModel )
%TRAINER_RESETMODEL Resets trainer model
%   Resets variables that should trigger events to clear the visualization. This function should be used when a new
%   image is loaded and the same effect is wanted as if the trainer window was closed and then reopened.

trainerModel.currentIndexToShow = [];
trainerModel.segmentedIndices = [];
trainerModel.label = [];
trainerModel.markAsSaved();

end

