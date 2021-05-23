folders = {...
    '/home/koosk/Data-linux/images/stack_images/tissues/20170915_human', ...
    '/home/koosk/Data-linux/images/stack_images/tissues/20180214_human'};
resultFolder = '/home/koosk/Data-linux/images/stack_images/dic_images_from_stacks_for_hand_segmentation';
firstImageIdx = 5;
step = 10;
dropUpperNumber = 10;
stackfileExtension = 'tif';
resultFileExt = 'png';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(stackfileExtension(1), '.')
    stackfileExtension = stackfileExtension(2:end);
end
if ~strcmp(resultFileExt(1), '.')
    resultFileExt = strcat('.', resultFileExt);
end
for folderIdx = 1:numel(folders)
    stackFiles = dir(fullfile(folders{folderIdx}, ['*.', stackfileExtension]));
    folderParts = strsplit(folders{folderIdx}, filesep);
    lastFolderName = folderParts{end};
    if isempty(lastFolderName)
        lastFolderName = folderParts(end-1);
    end
    if isempty(lastFolderName)
        warning('Could not determine stack''s folder name, but attempting to continue');
    end
    for stackFileIdx = 1:size(stackFiles, 1)
        imgstack = ImageStack.load(fullfile(stackFiles(stackFileIdx).folder, stackFiles(stackFileIdx).name));
        [~, fname, ~] = fileparts(stackFiles(stackFileIdx).name);
        stack = imgstack.getStack();
        for i = firstImageIdx:step:size(stack,3)-dropUpperNumber
            resultImageName = [lastFolderName, '_', fname, '_slice', sprintf('%03d',i)];
            resultFilepath = fullfile(resultFolder, [resultImageName, resultFileExt]);
            imwrite(stack(:,:,i), resultFilepath);
        end
    end
end