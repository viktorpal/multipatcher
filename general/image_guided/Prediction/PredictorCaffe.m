classdef PredictorCaffe < Predictor
    %CAFFEPREDICTOR Detection with imported cafffe network
    %   Detect cells by importing a caffe network using Matlab functions.
    
    properties
        net
        protofile
        datafile
    end
    
    methods
        function this = PredictorCaffe(protofile, datafile)
            this.net = importCaffeNetwork(protofile, datafile, 'OutputLayerType', 'regression');
            this.protofile = protofile;
            this.datafile = datafile;
        end
        
        function cells = predictImage(this, image)
            input_data = imresize(image,[512 704]);
            input_data = input_data * 255;
            input_data = input_data-127;
            input_data = cat(3, input_data, input_data, input_data);
            pred = predict(this.net, input_data);
            probimg = imresize(im2double(pred),size(image));
            
            binary_image = probimg > this.predictionThreshold;
            props = regionprops(binary_image, 'BoundingBox', 'Area', 'PixelIdxList');
            cells = struct(...
                'BoundingBox', {}, ...
                'ProbabilityMean', {}, ...
                'ProbabilityMin', {}, ...
                'ProbabilityMax', {}, ...
                'Area', {} ...
                );
            for i = 1:size(props, 1)
                w = props(i).BoundingBox(3);
                h = props(i).BoundingBox(4);
                cells(end+1) = struct(...
                    'BoundingBox', props(i).BoundingBox, ...
                    'ProbabilityMean', mean(probimg(props(i).PixelIdxList)), ...
                    'ProbabilityMin', min(probimg(props(i).PixelIdxList)), ...
                    'ProbabilityMax', max(probimg(props(i).PixelIdxList)), ...
                    'Area', w*h ...
                    );
            end
        end
    end
end

