classdef Manual3DTrainerModel < matlab.mixin.SetGet
    %MANUAL3DTRAINERMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Hidden)
        defaultBoxSize = [201, 201, 7]
        UNLABELED = 0
        POSITIVE_LABEL= 1
        NEGATIVE_LABEL = 2
        OTHER_LABEL = 3
        unlabeledColor = [237, 176, 15]./255
        positiveColor = [120, 191, 48]./255
        negativeColor = [163, 20, 46]./255
        otherColor = [217, 84, 26]./255
    end
    
    properties
        filepath % filepath of the loaded data
        config % Config object
        mainWindowGuiModel % GuiModel object of the main window
        mainFigure % figure object of the main window
        ax % axis object of the main window, where it can draw
        features % can contain arbitrary features, but currently not used
        boxHandlers % handle objects of the bounding boxes
        currentIndexToShowListener
        segmentedIndicesListener
        zSliceListener
        boxSizeListener
        mainWindowOriginalWindowKeyReleaseFcn
    end
    
    properties (SetObservable)
        currentIndexToShow
        segmentedIndices % [left, top, right, bottom, centerZ], while legacy is [centerX, centerY, centerZ]
        label % 0 - unlabeled, 1 - positive/cell, 2 - negative/not a cell
        boxSize % 3 element vector containing the width, height and depth of visual boxes
    end
    
    properties (SetAccess = private)
        isSaveRecommended
    end
    
    properties (Access = private)
        segmentedIndicesChangedRecommendSaveListener
        labelChangedRecommendSaveListener
    end
    
    methods
        function this = Manual3DTrainerModel()
            this.boxSize = this.defaultBoxSize;
            this.isSaveRecommended = false;
            this.segmentedIndicesChangedRecommendSaveListener = this.addlistener('segmentedIndices', 'PostSet', ...
                @(src,event) this.recommendSave());
            this.labelChangedRecommendSaveListener = this.addlistener('label', 'PostSet', ...
                @(src,event) this.recommendSave());
        end
        
        function delete(this)
            if ~isempty(this.boxHandlers)
                cellfun(@delete, this.boxHandlers)
            end
            delete(this.currentIndexToShowListener);
            delete(this.segmentedIndicesListener);
            delete(this.zSliceListener);
            delete(this.boxSizeListener);
            delete(this.segmentedIndicesChangedRecommendSaveListener);
            delete(this.labelChangedRecommendSaveListener);
        end
        
        function set.config(this, config)
            assert(isa(config, 'Config'), 'Input should be a Config object!');
            this.config = config;
        end
        
        function set.mainWindowGuiModel(this, value)
            assert(isa(value, 'GuiModel'));
            this.mainWindowGuiModel = value;
        end
        
        function set.filepath(this, value)
            assert(ischar(value));
            this.filepath = value;
        end
        
        function set.currentIndexToShow(this, value)
            assert(isnumeric(value));
            this.currentIndexToShow = value;
        end
        
        function set.segmentedIndices(this, value)
            assert(isnumeric(value));
            this.segmentedIndices = value;
        end
        
        function set.boxSize(this, value)
            assert(isnumeric(value) && ~isempty(value) && numel(value)==3 && all(mod(value, 2)==1));
            this.boxSize = value;
        end
        
        function markAsSaved(this)
            this.isSaveRecommended = false;
        end
    end
    
    methods (Access = private)
        function recommendSave(this)
            this.isSaveRecommended = true;
        end
    end
    
end

