classdef GeneralParameters < matlab.mixin.SetGet
% AUTHOR:	Tamas Balassa
% DATE: 	Aug 25, 2017
% NAME: 	GeneralParameters
% 
% This class contains widely used general parameters
%    
    
    properties (Constant, Hidden)
        defaultCameraTimerPeriod = round(1/15*1000)/1000
        defaultStackSize = 60
        defaultPredictionTimerPeriod = 1
        defaultPredictionMinObjectDimension = [100,100]
        defaultPredictionMaxObjectDimension = [200,230]
        defaultPredictionMinOverlapToUnite = 0.6
        defaultPredictionMaxZdistanceToUnite = 3
        defaultLogFindAndPatchStack = true;
        defaultDicIterations = 10000
        defaultDicDirection = 0
        defaultDicWAccept = 0.25
        defaultDicWSmooth = 0.0125
        defaultDicLocsize = 64
    end

    properties
        cameraTimerPeriod
        stackSize
        
        predictionTimerPeriod
        predictionMinObjectDimension
        predictionMaxObjectDimension
        predictionMinOverlapToUnite
        predictionMaxZdistanceToUnite
        predictor
        logFindAndPatchStack
        
        dicIterations % DIC reconstruction, number of iterations
        dicDirection  % DIC reconstruction, DIC direction (from bright to dark)
        dicWAccept    % DIC reconstruction, step size weight
        dicWSmooth    % DIC reconstruction, smoothness term weight
        dicLocsize    % DIC reconstruction, number of cores in a thread group of the device
    end  
    
    
    methods
        function this = GeneralParameters()
            this.cameraTimerPeriod = this.defaultCameraTimerPeriod;
            this.stackSize = this.defaultStackSize;
            this.predictionTimerPeriod = this.defaultPredictionTimerPeriod;
            this.predictionMinObjectDimension = this.defaultPredictionMinObjectDimension;
            this.predictionMaxObjectDimension = this.defaultPredictionMaxObjectDimension;
            this.predictionMinOverlapToUnite = this.defaultPredictionMinOverlapToUnite;
            this.predictionMaxZdistanceToUnite = this.defaultPredictionMaxZdistanceToUnite;
            this.logFindAndPatchStack = this.defaultLogFindAndPatchStack;
            this.dicIterations = this.defaultDicIterations;
            this.dicDirection = this.defaultDicDirection;
            this.dicWAccept = this.defaultDicWAccept;
            this.dicWSmooth = this.defaultDicWSmooth;
            this.dicLocsize = this.defaultDicLocsize;
        end
        
        function set.cameraTimerPeriod(this,value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.cameraTimerPeriod = value;
        end
        
        function set.stackSize(this,value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.stackSize = value;
        end
        
        function set.predictionTimerPeriod(this,value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.predictionTimerPeriod = value;
        end
        
        function set.predictionMinObjectDimension(this,value)
            assert(isnumeric(value) && ~isempty(value) && all(value>0));
            this.predictionMinObjectDimension = value;
        end
        
        function set.predictionMaxObjectDimension(this,value)
            assert(isnumeric(value) && ~isempty(value) && all(value>0));
            this.predictionMaxObjectDimension = value;
        end
        
        function set.predictionMinOverlapToUnite(this,value)
            assert(isnumeric(value) && ~isempty(value) && value>0);
            this.predictionMinOverlapToUnite = value;
        end
        
        function set.predictionMaxZdistanceToUnite(this,value)
            assert(isnumeric(value) && ~isempty(value) && value>=0);
            this.predictionMaxZdistanceToUnite = value;
        end
                      
        function set.predictor(this, value)
           assert(isa(value, 'Predictor') && ~isempty(value));
           this.predictor = value;
        end
        
        function set.logFindAndPatchStack(this, value)
            assert(islogical(value));
            this.logFindAndPatchStack = value;
        end
    end
end