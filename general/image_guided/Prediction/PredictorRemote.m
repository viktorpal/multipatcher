classdef PredictorRemote < Predictor
    %PREDICTORREMOTE Remote prediction using Matcaffe (legacy code)
    %   Sends tasks to the remote worker and downloads the result.
    
    properties (Access = private)
        client
    end
    
    methods
        
        function this = PredictorRemote(host, port)
            this.init(host, port);
        end
        
        function cells = predictImage(this, image)
            input_data = imresize(image,[512 704]);
            input_data = im2uint8(input_data');
            this.client.sendJob('predict',input_data);
            waitTime = 0.01;
            maxWaitTime = 20;
            currentWaitTime = 0;
            %% TODO check if job is failed and retry to avoid deadlock
            while ~this.client.isJobReady()
                if currentWaitTime > maxWaitTime
                    error(['prediction timout, operation longer than ', num2str(maxWaitTime), 'seconds']);
                end
                currentWaitTime = currentWaitTime + waitTime;
                pause(waitTime);
            end
            prob = this.client.downloadResult();
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
        
    end
    
    methods (Access = private)
       
        function init(this, host, port)
            this.client = RemoteWorker.Worker();
            this.client.host = host;
            this.client.port = port;
        end
    end
    
end

