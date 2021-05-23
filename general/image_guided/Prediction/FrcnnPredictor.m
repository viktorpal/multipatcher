classdef FrcnnPredictor < Predictor
    %FRCNNPREDICTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        detector
        use_gpu
    end
    
    methods
        function this = FrcnnPredictor(modelOrPath)
            if ischar(modelOrPath)
                data = load(modelOrPath);
                this.detector = data.detector;
            else
                this.detector = modelOrPath;
            end
        end
        
        function cells = predictImage(this, image)
            if this.use_gpu
                exec_env = 'gpu';
            else
                exec_env = 'cpu';
            end
            [sx, sy] = size(image);
            inputImage = imresize(image,[520 696]);
            scaleX = sx/520;
            scaleY = sy/696;
            [bbox, score, label] = detect(this.detector, inputImage, 'ExecutionEnvironment', exec_env, 'Threshold', this.predictionThreshold);
            bbox = bbox(label=='Cell', :);
            score = score(label=='Cell');
            if ~isempty(bbox)
                bbox(:, [1,3]) = bbox(:,[1,3]) * scaleX;
                bbox(:, [2,4]) = bbox(:,[2,4]) * scaleY;
            end
            cells = struct(...
                'BoundingBox', {}, ...
                'ProbabilityMean', {}, ...
                'ProbabilityMin', {}, ...
                'ProbabilityMax', {}, ...
                'Area', {} ...
                );
            disp(['Found ', num2str(size(bbox,1)), ' cells.'])
            for i = 1:size(bbox,1)
                cells(end+1) = struct(...
                    'BoundingBox', bbox(i,:), ...
                    'ProbabilityMean', score(i), ...
                    'ProbabilityMin', score(i), ...
                    'ProbabilityMax', score(i), ...
                    'Area', bbox(i, 3) * bbox(i, 4) ...
                    );
            end
            
        end
    end
end

