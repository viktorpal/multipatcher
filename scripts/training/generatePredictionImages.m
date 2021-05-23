% imgFilepath = '/home/koosk/Data-linux/images/stack_images/tissues/20180214_human/tissue008.tif';
resultFolder = '/home/koosk/data/images/ap_validation_set/PredictionResults/';
predictor = PredictorRemote('10.7.3.107', 7878);
predictor.predictionThreshold = 0.1;
minObjectDimension = 100;
maxObjectDimension = 250;

%%
% imgFolderToPredict = '/home/koosk/Data-linux/images/stack_images/tissues/20180214_human';
% imgFolderToPredict = '/home/koosk/Data-linux/images/stack_images/tissues/20170915_human';
imgFolderToPredict = '/home/koosk/data/images/ap_validation_set';
imgfiles = dir([imgFolderToPredict, '/*.tif']);

for iFiles = 1:numel(imgfiles)
    imgFilepath = fullfile(imgFolderToPredict, imgfiles(iFiles).name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    imgstack = ImageStack.load(imgFilepath);
    stack = imgstack.getStack();
    sz = size(stack, 3);
    regprops = cell(sz,1);
    for i = 1:sz
        img = imgstack.getLayer(i);
        [binary_image, probimg] = predictor.predictImage(img);
        props = regionprops(binary_image, 'BoundingBox', 'PixelIdxList');
        for j = 1:size(props, 1)
            w = props(j).BoundingBox(3);
            h = props(j).BoundingBox(4);

            if h <= maxObjectDimension ...
                    && w <= maxObjectDimension ...
                    && h >= minObjectDimension ...
                    && w >= minObjectDimension
                props(j).z = i;
                props(j).Confidence = max(probimg(props(j).PixelIdxList));
                regprops{i}(end+1) = props(j);
            end
        end
    end
    lastFolder = strsplit(imgFilepath,filesep);
    lastFolder = lastFolder{end-1};
    [~, fname, ~] = fileparts(imgFilepath);
    fullResultFolder = fullfile(resultFolder, lastFolder, fname);
    mkdir(fullResultFolder);
    for i = 1:sz
        propslen = size(regprops{i}, 2);
        if ~isempty(regprops{i}(:))
            bboxes = reshape([regprops{i}(:).BoundingBox], 4, propslen);
            bboxes = bboxes';
    %         labels = arrayfun(@(x) ['Confidence: ', sprintf('%.4f', x)], [regprops{i}(:).Confidence], 'UniformOutput', false);
            labels = repmat({''}, size(bboxes,1), 1);
            RGB = insertObjectAnnotation(imgstack.getLayer(i), 'rectangle', bboxes,...
                labels, 'TextBoxOpacity', 0.9, 'FontSize',18, 'Color', 'green', 'LineWidth', 1);
        else
            RGB = cat(3, imgstack.getLayer(i), imgstack.getLayer(i), imgstack.getLayer(i));
        end
        sliceFname = strcat(fname, '_slice', sprintf('%03d.png', i));
        imwrite(RGB, fullfile(fullResultFolder, sliceFname));
    end

    csvfilepath = fullfile(fullResultFolder, [fname, '_predictions.csv']);
    cells = regprops;
    fid = fopen(csvfilepath, 'w');
    fprintf(fid,'z,x,y,width,height\r\n');
    for iRegprops = 1:sz
        cells = regprops{iRegprops};
        for i = 1:numel(cells)
            fprintf(fid, '%d,%d,%d,%d,%d\r\n', cells(i).z, round(cells(i).BoundingBox(1)), round(cells(i).BoundingBox(2)), ...
                cells(i).BoundingBox(3), cells(i).BoundingBox(4));
        end
    end
    fclose(fid);
end


