classdef (Abstract) Predictor < handle
    %PREDICTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        predictionThreshold
    end
    
    methods (Abstract)
        % cells = predictImage(this, image)
        % Returns a structure of the predicted cells with the following
        % fields: 'BoundingBox', 'ProbabilityMean', 'ProbabilityMin',
        % 'ProbabilityMax', 'Area'.
        cells = predictImage(this, image) % msg
    end
    
    methods
        function this = Predictor()
            this.predictionThreshold = 0;
        end
        
        function set.predictionThreshold(this,value)
            assert(isnumeric(value) && ~isempty(value));
            this.predictionThreshold = value;
        end
        
    end
    
end

