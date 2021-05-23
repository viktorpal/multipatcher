classdef ImageStack < handle
    %IMAGESTACK Image stack and metadata container
    %   The class supports some validation: some meta fields are required
    %   to be present before writing it to file / after loading, otherwise
    %   the object is considered to be corrupted. The 'stack' property
    %   cannot be set directly. To set the 'stack'
    %   property, call the constructor with a single parameter containing a
    %   3d matrix, use setStack(), or setSlice(img, idx). However, the data
    %   can be accessed directly, using imagestack.stack. The class also
    %   support Gaussian pyramids 0-3 levels. Use getStack(pyrLevel) to get
    %   the required pyramid level of the contained stack for an
    %   efficient way.
    
    properties (Constant, Hidden)
        REQUIRED_META_FIELDS = {
            'Creator', ...
            'CreationTime', ...
            'width', ...
            'height', ...
            'D3Size', ...
            'pixelSizeX', ...
            'pixelSizeY', ...
            'pixelSizeZ', ...
            'stageX', ...
            'stageY', ...
            'stageZ'...
            } % additional properties that should be present: pipette(#ID)[X, Y, Z]
        MAXIMUM_PYRAMID_LEVEL = 3;
    end
    
    properties (SetAccess = private)
        stack
    end

    properties
        meta
    end

    properties (Access = private)
        pyramids = cell(ImageStack.MAXIMUM_PYRAMID_LEVEL,1);
    end
    
    methods (Access = private)
        function loadImageFile(this, path)
            assert(exist(path, 'file')==2, 'The defined path either does not exist or not a file!');
            tiffInfo = imfinfo(path);  % Get the TIFF file information
            nSlice = numel(tiffInfo);  % Get the number of images in the file
            m = tiffInfo(1).Height;
            n = tiffInfo(1).Width;
            this.stack = zeros(m, n, nSlice);
            for i = 1:nSlice
                this.stack(:,:,i) = im2double(imread(path, 'Index', i, 'Info', tiffInfo));
            end
        end
        
        function saveImage(this, path, normalizeStack)
            assert(~isempty(this.stack), 'No image data is present in the ImageStack object, cannot save it.');
            if nargin < 3
                normalizeStack = false;
            end
            [~, ~, ext] = fileparts(path);
            if isempty(ext)
                path = [path, '.tif'];
            elseif ~(strcmp(ext, '.tif') || strcmp(ext, '.tiff'))
                error('File extension should be tif or tiff!');
            end
            if normalizeStack
                stackMin = min(this.stack(:));
                stackMax = max(this.stack(:));
                imwrite((this.stack(:,:,1)-stackMin)/(stackMax-stackMin), path, 'Compression', 'deflate');
                for i = 2:size(this.stack, 3)
                    imwrite((this.stack(:,:,i)-stackMin)/(stackMax-stackMin), path, 'WriteMode', 'append', 'Compression', 'deflate');
                end
            else
                imwrite(mat2gray(this.stack(:,:,1)), path, 'Compression', 'deflate');
                for i = 2:size(this.stack, 3)
                    imwrite(mat2gray(this.stack(:,:,i)), path, 'WriteMode', 'append', 'Compression', 'deflate');
                end
            end
        end
        
        function saveMetadata(this, imgFilepath)
            [folder, fname, ext] = fileparts(imgFilepath); %#ok
            metadataFile = fullfile(folder, [fname, '_metadata.txt']);
            fid = fopen(metadataFile, 'wt');
            if fid == -1
                error('Could not open metadata file for writing!');
            end
            fields = fieldnames(this.meta);
            for i = 1:numel(fields)
                fprintf(fid, '%s : %s\n', fields{i}, any2str(this.meta.(fields{i})));
            end
            fclose(fid);
        end
        
        function loadMetadataFile(this, imgFilepath, checkCompatibility)
            this.meta = struct();
            [folder, fname, ext] = fileparts(imgFilepath); %#ok
            if ~isempty(strfind(fname, '_Camera')) % legacy Femtonics images
                metadataFile = [folder, filesep, fname(1:end-6), 'metadata.txt'];
            else
                metadataFile = [folder, filesep, fname, '_metadata.txt'];
            end
            fid = fopen(metadataFile, 'rt');
            if fid == -1
                if ~checkCompatibility
                    return
                else
                    error('Could not open metadata file!');
                end
            end
            tline = fgetl(fid);
            while ischar(tline)
                while ~isempty(tline) && strcmp(tline(1), ' ')
                    tline = tline(2:end);
                end
                k = strfind(tline, ' : ');
                if ~isempty(k)
                    if ~strcmp(tline(1), '>') && ~strcmp(tline(1), '%')
                        value = tline(k(1)+3:end);
                        numericValue = str2double(value);
                        if isnan(numericValue)
                            this.meta.(tline(1:k(1)-1)) = value;
                        else
                            this.meta.(tline(1:k(1)-1)) = numericValue;
                        end
                    end
                end
                tline = fgetl(fid);
            end
            fclose(fid);
            if checkCompatibility
                this.checkFemtonicsCompatibility();
            end
        end
        
        function checkFemtonicsCompatibility(this)
            if ~isempty(strfind(this.meta.Creator, 'Femtonics'))
                this.meta.CreationTime = this.meta.MeasurementDate;
                this.meta.width = this.meta.Width;
                this.meta.height = this.meta.Height;
                %this.meta.D3Size = % it is the same, at least for now
                this.meta.pixelSizeX = this.meta.WidthStep;
                this.meta.pixelSizeY = this.meta.HeightStep;
                this.meta.pixelSizeZ = this.meta.D3Step;
                this.meta.stageX = this.meta.LN_x;
                this.meta.stageY = this.meta.LN_y;
                this.meta.stageZ = this.meta.ObjectiveArm;
                this.meta.pipette1X = this.meta.stage2_1;
                this.meta.pipette1Y = this.meta.stage2_2;
                this.meta.pipette1Z = this.meta.stage2_3;
            end
        end
    
        function imgstack = computePyramid(this, pyramidLevel)
            imgstack = this.stack;
            for i = 1:pyramidLevel
                imgstack = impyramid(imgstack, 'reduce');
            end
        end
        
        function stack = getPyramid(this, pyramidLevel)
            if isempty(this.pyramids{pyramidLevel})
                this.pyramids{pyramidLevel} = this.computePyramid(pyramidLevel);
            end
            stack = this.pyramids{pyramidLevel};
        end
        
        function init(this)
            for i = 1:numel(this.REQUIRED_META_FIELDS)
                this.meta.(this.REQUIRED_META_FIELDS{i}) = [];
            end
        end
        
        function validate(this)
            for i = 1:numel(this.REQUIRED_META_FIELDS)
                assert(isfield(this.meta, this.REQUIRED_META_FIELDS{i}), ...
                    ['ImageStack corruption error! Required meta field ''', this.REQUIRED_META_FIELDS{i}, ...
                    ''' is missing!']);
            end
            [h, w, d] = size(this.stack);
            assert(h>0 && w>0 && d>0, 'ImageStack error! None of the dimensions can be 0!');
            assert(~isempty(this.meta.height) && h == this.meta.height ...
                && ~isempty(this.meta.width) && w == this.meta.width ...
                && ~isempty(this.meta.D3Size) && d == this.meta.D3Size, ...
                'ImageStack corruption error! Dimensions do not match with meta information!');
        end
    end % methods
    
    methods (Static)
        function obj = load(path, checkCompatibility)
            log4m.getLogger().debug(['Loading image stack: ', path]);
            if nargin < 2
                checkCompatibility = false;
            else
                assert(islogical(checkCompatibility));
            end
            obj = ImageStack();
            obj.loadImageFile(path);
            obj.loadMetadataFile(path, checkCompatibility);
            if checkCompatibility
                obj.validate();
            end
        end
    end
    
    methods
        function obj = ImageStack(stack)
            obj.init();
            if nargin == 1
                if isnumeric(stack)
                    obj.setStack(stack);
                elseif ischar(stack)
                    obj = ImageStack.load(stack);
                else
                    error(['Unsupported input type: ', class(stack)]);
                end
            end
        end
        
        function save(this, path, doValidation)
            if nargin < 3
                doValidation = true;
            end
            if doValidation
                this.validate();
            end
            this.saveImage(path);
            this.saveMetadata(path);
        end
        
        function stack = getStack(this, pyramidLevel)
            if nargin < 2 || pyramidLevel == 0
                stack = this.stack;
            elseif pyramidLevel > 3
                error('Pyramid level higher than 3 is not supported');
            else
                stack = this.getPyramid(pyramidLevel);
            end
        end
        
        function img = getLayer(this, layerIdx)
            img = this.stack(:,:,layerIdx);
        end
        
        function setStack(this, stack)
            this.stack = stack;
            [h, w, d] = size(stack);
            this.meta.height = h;
            this.meta.width = w;
            this.meta.D3Size = d;
            this.pyramids = cell(this.MAXIMUM_PYRAMID_LEVEL,1);
        end
        
        function setSlice(this, slice, idx)
            this.stack(:,:,idx) = slice;
            this.pyramids = cell(this.MAXIMUM_PYRAMID_LEVEL,1);
        end
    end % methods
end % classdef

