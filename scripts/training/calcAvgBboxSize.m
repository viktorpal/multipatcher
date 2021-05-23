traindataFolders = {...
    '/home/koosk/data/data/autopatcher/traindata/201704/20170424_1-50', ...
    '/home/koosk/data/data/autopatcher/traindata/201704/20170424_51-133', ...
    '/home/koosk/data/data/autopatcher/traindata/201704/20170425_1-50', ...
    '/home/koosk/data/data/autopatcher/traindata/201704/20170425_51-100' ...
    '/home/koosk/data/data/autopatcher/traindata/human/20170530', ...
    '/home/koosk/data/data/autopatcher/traindata/human/20170622', ...
    '/home/koosk/data/data/autopatcher/traindata/human/20170915'...
    };

bboxDims = zeros(0,2);
objectCtr = 0;
for folderIdx = 1:numel(traindataFolders)
    traindataFolder = traindataFolders{folderIdx};
    trainerFiles = dir(fullfile(traindataFolder, '*.mat'));
    for fileIdx = 1:numel(trainerFiles)
        trainerData = load(fullfile(traindataFolder, trainerFiles(fileIdx).name));
        objectCtr = objectCtr + nnz(trainerData.label==1) + nnz(trainerData.label==2);
        for entryIdx = 1:numel(trainerData.label)
            bbox = trainerData.segmentedIndices(entryIdx, 1:4);
            w = bbox(3) - bbox(1);
            h = bbox(4) - bbox(2);
            bboxDims(end+1, :) = [w, h];
        end
    end
    
    
end