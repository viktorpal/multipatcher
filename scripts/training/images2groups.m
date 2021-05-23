%% put random images to a few folders - do not set params like it should put all of them to folders!

imagesFolder = '/home/koosk/Data-linux/images/stack_images/dic_images_from_stacks_for_hand_segmentation';
numberOfGroups = 5;
numberOfImages = 10;


%%%%%%%%

files = dir([imagesFolder, filesep, '*.png']);
n = numel(files);
selected = false(n,1);
for i = 1:numberOfGroups
    resultFolder = [imagesFolder, filesep, 'groups', filesep, 'group', num2str(i)];
    mkdir(resultFolder);
    for j = 1:numberOfImages
        newIdx = randi(n);
        while selected(newIdx)
            newIdx = randi(n);
        end
        selected(newIdx) = true;
        copyfile(fullfile(imagesFolder, files(newIdx).name), resultFolder);
    end
end