 classdef GuiModel < handle
    %GUIMODEL Model that contains a collection of variables used in the gui
    %   The model contains microscope part controllers, gui handlers and
    %   various variables that are necessary for functioning.
    
    properties (Constant, Hidden)
        defaultActivePipetteID = 1;
    end
    
    properties (SetAccess = immutable)
        microscope
    end
    
    properties (SetObservable)
        zslice
    end
    
    properties
        config % Config object
        generalParameters % GeneralParameters object
        fileDialogLocation
        activePipetteID % ID of the pipette associated with the microscope object that will be used for operations
        imgstack % ImageStack object to be visualized in stack mode
        originalImgstack % raw imgstack which is loaded from file or created during run
        reconstructedImgstack % reconstructed ImageStack object
        bgcorrImgstack % background corrected image stack
        sampleTop % um
        stackPredictionBoxes
        stackPredictionSelectedIndex
        autopatcher
        visualPatcher
        rsImprover
        pipetteCleaner
        visualLogger
        
        %% window position parameters
        figureOuterPosition
        visualPatcherControlPosition
        diaryGuiPosition
        
        %% handles, timers, listeners
        
        imgHandle
        boundingBoxesHandle % handles of predicted bounding boxes        
        blindPatcherFigure
        trainerFigure
        visualPatcherControl % VisualPatcherControl app
        diaryGui
        cleanGui % CleanGUI app
        predictionOptionsFigure
        predictionZsliceListener
        stackPredictionBoxesHandles
        trackerPositionUpdateListener
        trackerBoxHandles
        zsliceListener
        zlevelTimer
        liveViewTimer
        livePredictionTimer
        optionsApp
        
    end
    
    methods
        function this = GuiModel(microscope)
            assert(isa(microscope, 'MicroscopeController'), 'Input should be a MicroscopeController!');
            this.microscope = microscope;
            this.generalParameters = GeneralParameters();
            this.activePipetteID = this.defaultActivePipetteID;
            log4m.getLogger('autopatcher.log'); % init logger
        end
        
        function delete(this)
            delete(this.visualPatcher);
            deleteTimer(this.zlevelTimer);
            deleteTimer(this.liveViewTimer);
            deleteTimer(this.livePredictionTimer);
            deleteHandles(this.imgHandle);
            deleteHandles(this.boundingBoxesHandle);
            deleteFigure(this.blindPatcherFigure);
            deleteFigure(this.trainerFigure);
            deleteHandles(this.predictionZsliceListener);
            deleteHandles(this.stackPredictionBoxesHandles);
            deleteHandles(this.trackerPositionUpdateListener);
            deleteHandles(this.trackerBoxHandles);
            deleteHandles(this.zsliceListener);
            delete(this.visualPatcherControl);
            delete(this.diaryGui);
            delete(this.cleanGui);
            delete(this.pipetteCleaner);
            delete(this.predictionOptionsFigure);
            delete(this.optionsApp);
            
            delete(this.visualLogger);
            delete(this.autopatcher);
            delete(this.visualPatcher);
            delete(this.rsImprover);
            delete(this.microscope);
            delete(this.imgstack);
            delete(this.config);
        end
        
        function set.imgstack(this, imgstack)
            assert(isa(imgstack, 'ImageStack') || isempty(imgstack), 'Input should be an ImageStack object!');
            this.imgstack = imgstack;
        end
        
        function set.originalImgstack(this, originalImgstack)
            assert(isa(originalImgstack, 'ImageStack') || isempty(originalImgstack), 'Input should be an ImageStack object!');
            this.originalImgstack = originalImgstack;
        end
        
        function set.reconstructedImgstack(this, reconstructedImgstack)
            assert(isa(reconstructedImgstack, 'ImageStack') || isempty(reconstructedImgstack), 'Input should be an ImageStack object!');
            this.reconstructedImgstack = reconstructedImgstack;
        end
        
        function set.bgcorrImgstack(this, bgcorrImgstack)
            assert(isa(bgcorrImgstack, 'ImageStack') || isempty(bgcorrImgstack), 'Input should be an ImageStack object!');
            this.bgcorrImgstack = bgcorrImgstack;
        end
        
        function set.sampleTop(this, sampleTop)
            assert(isnumeric(sampleTop), 'Input should be of numeric type!');
            log4m.getLogger().info(['Sample top position set to: ', num2str(sampleTop)]);
            this.sampleTop = sampleTop;
        end
        
        function set.config(this, config)
            assert(isa(config, 'Config'), 'Input should be a Config object!');
            this.config = config;
        end
        
        function set.visualPatcher(this, visualPatcher)
            assert(isa(visualPatcher, 'VisualPatcher'), 'Input should be a VisualPatcher object!');
            this.visualPatcher = visualPatcher;
        end
        
        function set.generalParameters(this, generalParameters)
            assert(isa(generalParameters, 'GeneralParameters'), 'Input should be a GeneralParameters object!');
            this.generalParameters = generalParameters;
        end
        
        function set.pipetteCleaner(this, pipetteCleaner)
            assert(isa(pipetteCleaner, 'PipetteCleaner'), 'Input should be a PipetteCleaner object!');
            this.pipetteCleaner = pipetteCleaner;
        end
        
        function set.visualLogger(this, visualLogger)
            assert(isa(visualLogger, 'VisualLogger'), 'Input should be a VisualLogger object!');
            this.visualLogger = visualLogger;
        end
        
%         function set.diary(this, diary)
%             assert(isempty(diary) || isa(diary, 'PatchClampDiary'), 'Variable ''diary'' should be empty or a PatchClampDiary object!');
%             this.diary = diary;
%         end

    end
    
end

