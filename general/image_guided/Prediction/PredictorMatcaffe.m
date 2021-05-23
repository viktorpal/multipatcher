classdef PredictorMatcaffe < Predictor
    %PREDICTORLOCAL Matcaffe cell detection (legacy code)
    %   
    
    properties (Access = private)
        net
    end
    
    properties
        use_gpu
        networkModel
        networkWeights
    end
    
    methods
        
        function this = PredictorLocal(networkModel, networkWeights)
           this.use_gpu = true;
           this.networkModel = networkModel;
           this.networkWeights = networkWeights;
           this.init();
        end
        
        function set.use_gpu(this,value)
            assert(islogical(value) && ~isempty(value));
            this.use_gpu = value;
            if this.use_gpu
                caffe.set_mode_gpu;
            else
                caffe.set_mode_cpu;
            end
        end
        
        function cells = predictImage(this, image)
            input_data = imresize(image,[512 704]);
            input_data = im2uint8(input_data');
            input_data = cat(3,input_data,input_data,input_data);
            res = this.net.forward({input_data});
            prob = res{1};
            probimg = imresize(im2double(prob)',size(image));
            
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
        
        function set.networkModel(this,value)
            assert(ischar(value) && ~isempty(value));
            this.networkModel = value;
        end
        
        function set.networkWeights(this,value)
            assert(ischar(value) && ~isempty(value));
            this.networkWeights = value;
        end
    end
    
    methods (Access = private)
       
        function init(this)
            this.net = caffe.Net(this.networkModel, this.networkWeights, 'test');
        end
    end
    
end

