function stop = saveStats(info, checkpointFolder)
%SAVESTATS Summary of this function goes here
%   Detailed explanation goes here

stop = false;
statsFile = [checkpointFolder, 'stats.csv'];
f = fopen(statsFile, 'a');
fprintf(f, '%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%s\n', info.Epoch, into.Iteration, info.TimeSinceStart, info.TrainingLoss, info.ValidationLoss, info.BaseLearnRate,...
    info.TrainingAccuracy, info.TrainingRMSE, info.ValidationAccuracy, info.ValidationRMSE, info.State);
fclose(f);

end

