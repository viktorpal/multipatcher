classdef PatchClampDiary < handle
    %PATCHCLAMPDIARY Writes entries to a patch clamp diary
    %   
    
    % Ideas for improvement: if stage is not initialized but manual patch clamping is performed, save pipette
    % coordinates. At least the forward axis of the pipette (usually X) should be initialized.
    %
    % Manually starting autopatcher does not log currently, because VP has a listener for it's status change. PCDiary
    % should be redesigned and AP and VP could be registered.
    %
    % Line entries could be json lines and conversion would be easier, changes in properties (removed ones, new ones to
    % come) would not result in an error.
    
    properties (Constant, Hidden)
        defaultFilepath = ['.', filesep, 'PatchClampDiary.log']
        defaultCommandWindowLog = false
        emptyPcEntry = struct('StartDate', [], 'StartTime', [], 'TargetX', [], 'TargetY', [], 'TargetZ', [], ...
                'TargetDepth', [], 'TargetDistance', [], 'FirstResistance', [], ...
                'StartAPdistance', [], 'StopTrackDistance', [], 'APStopped', false, 'Hunting', false, 'Sealing', false, ...
                'BreakIn', false, 'Result', 'Fail', 'ResultSetManually', false, 'lastBreakinDelay', [], ...
                'HuntingStartTime', [], 'SealingStartTime', [], 'BreakInStartTime', [], 'ResultTime', [], 'APStoppedTime', [], ...
                'DetectionSelectedIndex', [], 'DistanceFromOriginalPosition', [] ...
                );
        emptyJemBasicEntry = struct(...
            'approach', struct(...
                'sliceHealth', '5', ...
                'cellHealth', '5', ...
                'creCell', 'None', ...
                'pilotName', 'None' ...
                ),...
            'recording', struct(...
                'timeStart', [], ... % "15:49:11 +01:00",
                'pipetteR', 0, ...
                'timeWholeCellStart', [], ... % "15:49:14 +01:00"
                'humanCellTypePrediction', [] ... % 'FS Interneuron', 'Pyramidal', 'Spindle Shaped', 'Unknown', 'Unknown Interneuron'
                ),...
            'status', [],...
            'depth', 0,...
            'autoRoi', 'None',...
            'manualRoi', 'FCx'... %possible pairs: {{FCx, [1,2,3,4,5,6]}, {TCx, [1,2,3,4,5,6]}, {VISp, [1,2/3,4,5,6a,6b]}, {TEa, [1,2/3,4,5,6a,6b]}, {dLGN, ['Magnocellular, Parvocellular]}}
            );
        lineExpression = '(?<date>\d+-\d+-\d+) (?<time>\d+:\d+:\d+),(?<msec>\d+) (?<msg>.*)';
        targetExpression = '(.*): (?<x>([+-])?\d+(.\d+)?) (?<y>([+-])?\d+(.\d+)?) (?<z>([+-])?\d+(.\d+)?)';
        initVPExpression = ['(.*): (?<targetDistance>([+-])?\d+(.\d+)?)', ...
            ', starting AutoPatcher.*: (?<startAPDistance>([+-])?\d+(.\d+)?)', ...
            ', stopping.*: (?<stopTrackDistance>([+-])?\d+(.\d+)?)', ...
            ', target depth: (?<targetDepth>([+-])?\d+(.\d+)?)'];
        apStatusExpression = '(.*): (?<status>\w*), .*=(?<firstR>(([+-])?\d+(.\d+)?)||(NaN)), .*=(?<breakInDelay>(([+-])?\d+(.\d+)?)||(NaN)), .*=(?<distanceTaken>([+-])?\d+(.\d+)?)';
        holderposExpression = '(.*): (?<x>([+-])?\d+(.\d+)?) (?<y>([+-])?\d+(.\d+)?) (?<z>([+-])?\d+(.\d+)?)';
        samplesideposExpression = '(.*): (?<x>([+-])?\d+(.\d+)?) (?<y>([+-])?\d+(.\d+)?) (?<z>([+-])?\d+(.\d+)?)';
        jemGeneralExpression = 'JEM general.(?<fieldname>\w+) (?<value>.*)';
        jemPipetteFailureExpression = 'JEM pipette.failure.(?<fieldnamechain>[\w.]+) (?<value>.*)';
        jemPipetteSuccessExpression = 'JEM pipette.success.(?<fieldnamechain>[\w.]+) (?<value>.*)';
        manualResultExpression = '(.*): (?<status>\w*)';
        pcInfoExpression = 'Patch Clamp Info: (?<property>[\w.]+) (?<value>.*)';
    end
    
    properties (Constant)
        emptyJemGeneralData = struct(...
            'formVersion', '2.0.3', ...
            'rigOperator', 'autopatcher', ...
            'rigNumber', 'autopatcherRig', ...
            'date', [], ... % eg "2018-02-21 15:45:44 +01:00",
            'limsSpecName', [], ... %slice ID based on description on lab wall
            'acsfProductionDate', [], ... % eg. '2018-02-21'
            'blankFillDate', [], ...
            'internalFillDate', [], ...
            'flipped', 'No', ...
            'sliceQuality', 'Good', ...
            'sliceNotes', '' ...
            );
        emptyJemFailureData = PatchClampDiary.generateEmptyJemFailureData();
        emptyJemSuccessData = PatchClampDiary.generateEmptyJemSuccessData();
    end
    
    properties
        filepath
        commandWindowLog
    end
    
    methods (Static)
        function [data, jem] = analyzeDiaryFile(fpath, resultFpath)
            % ANALYZEDIARYFILE - Create a table of a patch-clamp log file
            %   data = ANALYZEDIARYFILE(fpath) returns a struct array of the analyzed patch clamp log file and saves it
            %       to a file to the same path as the input concatenated with '-extracted'.
            %
            %   data = ANALYZEDIARYFILE(fpath, resultFpath) returns and saves the analyzed data as a csv file.
            %
             
            %% analyze
            jemGeneralData = PatchClampDiary.emptyJemGeneralData;
            pcFields = fieldnames(PatchClampDiary.emptyPcEntry)';
            pcData = pcFields;
            pcData{2,1} = {};
            pcData = struct(pcData{:});
            jemData = {};
            emptyHolderEntry = struct('x', [], 'y', [], 'z', []);
            holderData = fieldnames(emptyHolderEntry)';
            holderData{2,1} = {};
            holderData = struct(holderData{:});
            emptySampleSideEntry = struct('x', [], 'y', [], 'z', []);
            sampleSideData = fieldnames(emptySampleSideEntry)';
            sampleSideData{2,1} = {};
            sampleSideData = struct(sampleSideData{:});
            if ~exist(fpath, 'file')
                error('The specified file does not exist!');
            end
            fid = fopen(fpath, 'r');
            pcEntry = [];
            jemFailureEntry = [];
            jemSuccessEntry = [];
            tline = fgetl(fid);
            while ~isnumeric(tline) || tline~=-1
                lineparts = regexp(tline,PatchClampDiary.lineExpression,'names');
                
                if startsWith(lineparts.msg, 'Starting targeted patch-clamp at stage location:') ...
                        || startsWith(lineparts.msg, 'Starting AutoPatcher manually at location:')
                    if ~isempty(pcEntry) 
                        if isempty(setxor(fieldnames(pcEntry),fieldnames(pcData))) % we have to check also if it is a complete pcEntry, ie. we had a 'Starting' line before other fields.
                            pcEntry = PatchClampDiary.postprocessPcentry(pcEntry);
                            pcData(end+1) = pcEntry; %#ok<AGROW>

                            jemEntry = PatchClampDiary.postprocessJemEntry(jemFailureEntry, jemSuccessEntry, pcEntry);
                            jemData{end+1} = jemEntry; %#ok<AGROW>
                        else
                            log4m.getLogger().warn('There were patch clamping data before a ''starting'' entry was found. These are not included to any statistics.');
                        end
                    end
                    pcEntry = PatchClampDiary.emptyPcEntry;
                    pcEntry.StartDate = lineparts.date;
                    pcEntry.StartTime = lineparts.time;
                    target = regexp(lineparts.msg, PatchClampDiary.targetExpression, 'names');
                    pcEntry.TargetX = target.x;
                    pcEntry.TargetY = target.y;
                    pcEntry.TargetZ = target.z;
                    jemFailureEntry = [];
                    jemSuccessEntry = [];
                elseif startsWith(lineparts.msg, 'Initializing VisualPatcher')
                    vpParams = regexp(lineparts.msg, PatchClampDiary.initVPExpression, 'names');
                    pcEntry.TargetDepth = vpParams.targetDepth;
                    pcEntry.TargetDistance = vpParams.targetDistance;
                    pcEntry.StartAPdistance = vpParams.startAPDistance;
                    pcEntry.StopTrackDistance = vpParams.stopTrackDistance;
                elseif startsWith(lineparts.msg, 'Autopatcher status changed:')
                    apStatus = regexp(lineparts.msg, PatchClampDiary.apStatusExpression, 'names');
                    switch apStatus.status
                        case 'Starting'
                        case 'Hunting'
                            pcEntry.Hunting = true;
                            pcEntry.HuntingStartTime = lineparts.time;
                        case 'Sealing'
                            pcEntry.Sealing = true;
                            pcEntry.SealingStartTime = lineparts.time;
                        case 'BreakIn'
                            pcEntry.BreakIn = true;
                            pcEntry.BreakInStartTime = lineparts.time;
                        case 'Stopped'
                            pcEntry.APStopped = true;
                            pcEntry.APStoppedTime = lineparts.time;
                        case 'Success'
                            if ~pcEntry.ResultSetManually
                                pcEntry.Result = apStatus.status;
                                pcEntry.ResultTime = lineparts.time;
                            end
                        case 'Fail'
                            if ~pcEntry.ResultSetManually
                                pcEntry.Result = apStatus.status;
                                pcEntry.ResultTime = lineparts.time;
                            end
                        otherwise
                            warning(['Unrecognized Autopatcher status: ', apStatus.status]);
                    end
                    if isempty(pcEntry.FirstResistance) || isnan(pcEntry.FirstResistance)
                        pcEntry.FirstResistance = str2double(apStatus.firstR);
                    end
                    pcEntry.lastBreakinDelay = apStatus.breakInDelay; % update every time
                elseif startsWith(lineparts.msg, 'Holder position: ')
                    holderPos = regexp(lineparts.msg, PatchClampDiary.holderposExpression, 'names');
                    holderData(end+1).x = holderPos.x; %#ok<AGROW>
                    holderData(end).y = holderPos.y;
                    holderData(end).z = holderPos.z;
                elseif startsWith(lineparts.msg, 'Sample side position: ')
                    sampleSidePos = regexp(lineparts.msg, PatchClampDiary.samplesideposExpression, 'names');
                    sampleSideData(end+1).x = sampleSidePos.x; %#ok<AGROW>
                    sampleSideData(end).y = sampleSidePos.y;
                    sampleSideData(end).z = sampleSidePos.z;
                elseif startsWith(lineparts.msg, 'JEM ')
                    if startsWith(lineparts.msg, 'JEM general.')
                        jemGeneralData = PatchClampDiary.processJemGeneralEntry(jemGeneralData, lineparts.msg);
                    elseif startsWith(lineparts.msg, 'JEM pipette.failure.')
                        if ~isempty(jemSuccessEntry)
                            log4m.getLogger.warn('JEM success entry was not empty when adding a failure entry.');
                            jemSuccessEntry = [];
                        end
                        if isempty(jemFailureEntry)
                            jemFailureEntry = PatchClampDiary.emptyJemFailureData;
                        end
                        jemFailureEntry = PatchClampDiary.processJemFailureEntry(jemFailureEntry, lineparts.msg);
                    elseif startsWith(lineparts.msg, 'JEM pipette.success.')
                        if ~isempty(jemFailureEntry)
                            log4m.getLogger.warn('JEM failure entry was not empty when adding a success entry.');
                            jemFailureEntry = [];
                        end
                        if isempty(jemSuccessEntry)
                            jemSuccessEntry = PatchClampDiary.emptyJemSuccessData;
                        end
                        jemSuccessEntry = PatchClampDiary.processJemSuccessEntry(jemSuccessEntry, lineparts.msg);
                    end
                elseif startsWith(lineparts.msg, 'Manual Result: ')
                    manualResult = regexp(lineparts.msg, PatchClampDiary.manualResultExpression, 'names');
                    pcEntry.Result = manualResult.status;
                    pcEntry.ResultSetManually = true;
                    pcEntry.ResultTime = lineparts.time;
                elseif startsWith(lineparts.msg, 'Patch Clamp Info: ')
                    pcInfo = regexp(lineparts.msg, PatchClampDiary.pcInfoExpression, 'names');
                    pcEntry.(pcInfo.property) = pcInfo.value;
                end
                
                tline = fgetl(fid);
            end
            if ~isempty(pcEntry)
                pcEntry = PatchClampDiary.postprocessPcentry(pcEntry);
                pcData(end+1) = pcEntry;

                jemEntry = PatchClampDiary.postprocessJemEntry(jemFailureEntry, jemSuccessEntry, pcEntry);
                jemData{end+1} = jemEntry;
            end
            
            fclose(fid);
            
            %% write to file
            if nargin > 1
                [folder, fname, ext] = fileparts(resultFpath);
                if isempty(ext)
                    ext = '.csv';
                end
                if isempty(fname)
                    fname = 'PatchClampDiary-extracted';
                end
                if isempty(folder)
                    folder = '.';
                end
                resultFpath = fullfile(folder, [fname, ext]);
            else
                [folder, fname, ~] = fileparts(fpath);
                resultFpath = fullfile(folder, [fname, '-extracted.csv']);
            end
            
            fid = fopen(resultFpath, 'w');
            %% patch clamp related entries
            for i = 1:numel(pcFields)
                if i ~= 1
                    fprintf(fid, ',');
                end
                fprintf(fid, '%s', pcFields{i});
            end
            fprintf(fid, '\n');
            for i = 1:numel(pcData)
                for j = 1:numel(pcFields)
                    if j ~= 1
                        fprintf(fid, ',');
                    end
                    fprintf(fid, '%s', any2str(pcData(i).(pcFields{j})));
                end
                fprintf(fid, '\n');
            end
            %% holder and sample side positions
            fprintf(fid, '\nHolderX,HolderY,HolderZ\n');
            for i = 1:numel(holderData)
                fprintf(fid, '%s,%s,%s\n', holderData(i).x, holderData(i).y, holderData(i).z);
            end
            fprintf(fid, '\nSampleSideX,SampleSideY,SampleSideZ\n');
            for i = 1:numel(sampleSideData)
                fprintf(fid, '%s,%s,%s\n', sampleSideData(i).x, sampleSideData(i).y, sampleSideData(i).z);
            end
            fclose(fid);
            
            if nargout > 0
                for i = 1:numel(pcData)
                    pcData(i).TargetX = str2double(pcData(i).TargetX);
                    pcData(i).TargetY = str2double(pcData(i).TargetY);
                    pcData(i).TargetZ = str2double(pcData(i).TargetZ);
                    pcData(i).TargetDepth = str2double(pcData(i).TargetDepth);
                    pcData(i).TargetDistance = str2double(pcData(i).TargetDistance);
                    pcData(i).FirstResistance = str2double(pcData(i).FirstResistance);
                    pcData(i).StartAPdistance = str2double(pcData(i).StartAPdistance);
                    pcData(i).StopTrackDistance = str2double(pcData(i).StopTrackDistance);
                    pcData(i).lastBreakinDelay = str2double(pcData(i).lastBreakinDelay);
                    pcData(i).DetectionSelectedIndex = str2double(pcData(i).DetectionSelectedIndex);
                    pcData(i).DistanceFromOriginalPosition = str2double(pcData(i).DistanceFromOriginalPosition);
                end
                for i = 1:numel(holderData)
                    holderData(i).x = str2double(holderData(i).x);
                    holderData(i).y = str2double(holderData(i).y);
                    holderData(i).z = str2double(holderData(i).z);
                end
                for i = 1:numel(sampleSideData)
                    sampleSideData(i).x = str2double(sampleSideData(i).x);
                    sampleSideData(i).y = str2double(sampleSideData(i).y);
                    sampleSideData(i).z = str2double(sampleSideData(i).z);
                end
                data = struct('pcData', pcData, 'holder', holderData, 'sampleSide', sampleSideData);
            end
            jemGeneralData.pipettes = jemData;
            jem = PatchClampDiary.prettyJson(jsonencode(jemGeneralData));
            jem = strrep(jem, char(10), [char(13), char(10)]); %#ok<CHARTEN>
            %% write jem json to file
            [folder, ~, ~] = fileparts(resultFpath);
            ext = '.json';
            if isempty(folder)
                folder = '.';
            end
            jemFname = jemGeneralData.limsSpecName;
            if isempty(jemFname)
                jemFname = 'PatchClampDiary-JEM';
            end
            jemFpath = fullfile(folder, [jemFname, ext]);
            fid = fopen(jemFpath, 'w');
            fprintf(fid, '%s\n', jem);
            fclose(fid);
        end
    end
    
    methods (Static, Access = private)
        
        function emptyJemFailureEntry = generateEmptyJemFailureData()
            emptyJemFailureEntry = PatchClampDiary.emptyJemBasicEntry;
            emptyJemFailureEntry.status = 'FAILURE';
            emptyJemFailureEntry.failureNotes = [];% Seal Failed,Other
            emptyJemFailureEntry.freeFailureNotes = [];% 'extraFailureNote'
        end
        
        function emptyJemSuccessEntry = generateEmptyJemSuccessData()
            emptyJemSuccessEntry = PatchClampDiary.emptyJemBasicEntry;
            emptyJemSuccessEntry.status = 'SUCCESS';
            emptyJemSuccessEntry.successNotes = []; % Patch/Cell Unstable,Patch Became Leaky,Access Resistance Increased,Cell Depolarized,Cell Hyperpolarized,Blowout Voltage Out of Range,Rheobase Changed,Ended After C1,'Wave of Death',Training/Practice,Rig/Software Problems", not present if empty
            emptyJemSuccessEntry.qcNotes = []; %"qc notes come here", not present if empty
            emptyJemSuccessEntry.badSweeps = []; % "bad sweeps come here", not present if empty
            emptyJemSuccessEntry.extraction = struct(... % for timezone offset: sprintf('%s', tzoffset(datetime('now', 'TimeZone', 'local')))
                'pressureApplied', 0, ... % -100, ...
                'retractionPressureApplied', [], ... %-20, ...
                'timeExtractionStart', [], ... %"15:49:31 +01:00", ...
                'timeExtractionEnd', [], ... %"15:50:40 +01:00", ...
                'timeRetractionEnd', [], ... %"15:50:42 +01:00", ...
                'postPatch', [], ... %"nucleus_present", ...
                'endPipetteR', 0, ... % 400, ...
                'nucleus', [], ... %"intentionally", ...
                'tubeID', [], ... %"PatchedCellContainerComesHere", ...
                'extractionNotes', [], ... %"extraExtractionNote", not present if empty
                'extractionObservations', [], ... %"Fluorescence in Pipette", not present if empty
                'sampleObservations', [] ... % "No Bubbles", not present if empty
                );
        end
        
        function s = removeNewlines(s)
            
            % This is a bit useless, because any2str adds a space and strjoin might be a better one, though I leave
            % it here for now
            s = regexprep(s,'[\n\r]+',' ');
        end
        
        function s = prettyJson(s)
            s = char(py.json.dumps(py.json.loads(s), pyargs('sort_keys',true, 'indent', int32(4), 'separators', py.tuple({',', ': '})) ));
        end
    end
    
    methods
        function this = PatchClampDiary()
            this.filepath = this.defaultFilepath;
            this.commandWindowLog = this.defaultCommandWindowLog;
        end
        
        function set.filepath(this, value)
            assert(~isempty(value) && ischar(value));
            if ~java.io.File(value).isAbsolute()
                value = fullfile(pwd, value);
            end
            this.filepath = value;
        end
        
        function set.commandWindowLog(this, value)
            assert(~isempty(value) && islogical(value));
            this.commandWindowLog = value;
        end
        
        function log(this, message)
            entry = sprintf('%s %s\r\n', datestr(now,'yyyy-mm-dd HH:MM:SS,FFF'), message);
            if this.commandWindowLog
                fprintf('%s\n', entry);
            end
            fid = fopen(this.filepath, 'a');
            fprintf(fid, entry);
            fclose(fid);
        end
        
        function logJemGeneral(this, jemGeneral)
            this.log(['JEM general.formVersion',  ' ', any2str(jemGeneral.formVersion)]);
            this.log(['JEM general.rigOperator',  ' ', any2str(jemGeneral.rigOperator)]);
            this.log(['JEM general.rigNumber',  ' ', any2str(jemGeneral.rigNumber)]);
            this.log(['JEM general.date',  ' ', any2str(jemGeneral.date)]);
            this.log(['JEM general.limsSpecName', ' ', any2str(jemGeneral.limsSpecName)]);
            this.log(['JEM general.acsfProductionDate', ' ', any2str(jemGeneral.acsfProductionDate)]);
            this.log(['JEM general.blankFillDate', ' ', any2str(jemGeneral.blankFillDate)]);
            this.log(['JEM general.internalFillDate', ' ', any2str(jemGeneral.internalFillDate)]);
            this.log(['JEM general.flipped', ' ', any2str(jemGeneral.flipped)]);
            this.log(['JEM general.sliceQuality', ' ', any2str(jemGeneral.sliceQuality)]);
            this.log(['JEM general.sliceNotes', ' ', PatchClampDiary.removeNewlines(any2str(jemGeneral.sliceNotes))]);
        end
        
        function logJemFailure(this, jem)
            this.logManualFailure();
            this.logJemBasicPatchSeq(jem, 'failure');
            this.logJemPatchSeqFailureExclusive(jem);
        end
        
        function logJemSuccess(this, jem)
            this.logManualSuccess();
            this.logJemBasicPatchSeq(jem, 'success');
            this.logJemPatchSeqSuccessExclusive(jem);
        end
        
        function logManualAutopatcherStart(this, stageX, stageY, stageZ)
            this.log(['Starting AutoPatcher manually at location: ', num2str(stageX), ' ', num2str(stageY), ' ', num2str(stageZ)]);
        end
        
        function logManualFailure(this)
            this.log('Manual Result: Fail');
        end
        
        function logManualSuccess(this)
            this.log('Manual Result: Success');
        end
        
        function logPatchClampInfo(this, propertyName, value)
            assert(~isempty(propertyName), '''propertyName'' cannot be empty.');
            assert(ischar(propertyName), '''propertyName'' should be of char type.');
            this.log(['Patch Clamp Info: ', propertyName, ' ', any2str(value)]);
        end
        
        function logHolderPosition(this, stageX, stageY, stageZ)
            this.log(['Holder position: ', num2str(stageX), ' ', num2str(stageY), ' ', num2str(stageZ)]);
        end
        
        function logSampleSidePosition(this, stageX, stageY, stageZ)
            this.log(['Sample side position: ', num2str(stageX), ' ', num2str(stageY), ' ', num2str(stageZ)]);
        end
    end
    
    methods (Access = protected, Static)
        function jemFailureEntry = generateJemFailureNote(pcEntry, jemFailureEntry)
            
            % possible "failureNotes" in jem: "Seal Failed,Unstable Seal,Breakin Failed,Access Resistance Out of Range,Vrest Out of Range,'Wave of Death',Other",
            failureNote = 'Other';
            if ~pcEntry.Hunting
                failureNote = 'Other';
            elseif ~pcEntry.Sealing
                failureNote = 'Seal Failed';
            elseif ~pcEntry.BreakIn
                failureNote = 'Breakin Failed';
            end
            
            if isempty(jemFailureEntry.failureNotes)
                jemFailureEntry.failureNotes = failureNote;
            elseif ~strcmp(failureNote, 'Other') || isempty(strfind(jemFailureEntry.failureNotes, 'Other'))
                jemFailureEntry.failureNotes = [jemFailureEntry.failureNotes, ', ', failureNote];
            end
        end
        
        function pcEntry = postprocessPcentry(pcEntry)
%             if isempty(pcEntry.Result) && pcEntry.APStopped
%                 pcEntry.Result = 'Stopped';
%             end
        end
        
        function jem = postprocessJemEntry(jemFailureEntry, jemSuccessEntry, pcEntry)
            jem = [];
            if strcmp(pcEntry.Result, 'Fail') % even if Result is set manually, we accept it
                if isempty(jemFailureEntry)
                    jemFailureEntry = PatchClampDiary.emptyJemFailureData;
                end
                jem = PatchClampDiary.generateJemFailureNote(pcEntry, jemFailureEntry);
                if isempty(jem.failureNotes)
                    jem.failureNotes = 'Other';
                end
                if isempty(jem.freeFailureNotes)
                    jem = rmfield(jem, 'freeFailureNotes');
                end
            elseif strcmp(pcEntry.Result, 'Success')
                if isempty(jemSuccessEntry)
                    jemSuccessEntry = PatchClampDiary.emptyJemSuccessData;
                end
                jem = jemSuccessEntry;
                optionalFields = {'successNotes', 'qcNotes', 'badSweeps'};
                nOpt = numel(optionalFields);
                fieldIndicesToRemove = false(nOpt, 1);
                for i = 1:nOpt
                    if isempty(jem.(optionalFields{i}))
                        fieldIndicesToRemove(i) = true;
                    end
                end
                fieldsToRemove = optionalFields(fieldIndicesToRemove);
                jem = rmfield(jem, fieldsToRemove);
                
                %% subfields under 'extraction'
                optionalFields = {'nucleus', 'extractionNotes', 'extractionObservations', 'sampleObservations'};
                nOpt = numel(optionalFields);
                fieldIndicesToRemove = false(nOpt, 1);
                for i = 1:nOpt
                    if isempty(jem.extraction.(optionalFields{i}))
                        fieldIndicesToRemove(i) = true;
                    end
                end
                fieldsToRemove = optionalFields(fieldIndicesToRemove);
                jem.extraction = rmfield(jem.extraction, fieldsToRemove);
            else
                warning(['Unsupported pcEntry result value: ', pcEntry.Result]);
            end
            if isempty(jem.recording.humanCellTypePrediction) || strcmp(jem.recording.humanCellTypePrediction, 'None')
                jem.recording = rmfield(jem.recording, 'humanCellTypePrediction');
            end
            jem = PatchClampDiary.fillBasicJemValues(pcEntry, jem);
        end
        
        function jemEntry = fillBasicJemValues(pcEntry, jemEntry)
            jemEntry.recording.timeStart = [pcEntry.StartTime, ' ', PatchClampDiary.getTzChar()];
            jemEntry.recording.pipetteR = pcEntry.FirstResistance;
            timeWholeCellStart = pcEntry.SealingStartTime;
            if isempty(timeWholeCellStart)
                timeWholeCellStart = pcEntry.HuntingStartTime;
            end
            if isempty(timeWholeCellStart)
                timeWholeCellStart = pcEntry.APStoppedTime;
            end
            if isempty(timeWholeCellStart)
                timeWholeCellStart = pcEntry.ResultTime;
            end
            jemEntry.recording.timeWholeCellStart = [timeWholeCellStart, ' ', PatchClampDiary.getTzChar()];
            jemEntry.depth = pcEntry.TargetDepth;
        end
        
        function jemGeneral = processJemGeneralEntry(jemGeneral, linemsg)
            jemGeneralLine = regexp(linemsg, PatchClampDiary.jemGeneralExpression, 'names');
            if ~isempty(jemGeneralLine.value)
                jemGeneral.(jemGeneralLine.fieldname) = jemGeneralLine.value;
            else
                jemGeneral.(jemGeneralLine.fieldname) = '';
            end
        end
        
        function [jem, found] = processJemPipetteBaiscEntry(jem, jemline)
            found = true;
            switch jemline.fieldnamechain
                case 'approach.sliceHealth'
                    jem.approach.sliceHealth = jemline.value;
                case 'approach.cellHealth'
                    jem.approach.cellHealth = jemline.value;
                case 'approach.creCell'
                    jem.approach.creCell = jemline.value;
                case 'approach.pilotName'
                    jem.approach.pilotName = jemline.value;
                case 'recording.timeStart'
                    jem.recording.timeStart = jemline.value;
                case 'recording.pipetteR'
                    jem.recording.pipetteR = str2double(jemline.value);
                case 'recording.timeWholeCellStart'
                    jem.recording.timeWholeCellStart = jemline.value;
                case 'recording.humanCellTypePrediction'
                    jem.recording.humanCellTypePrediction = jemline.value;
                case 'status'
                    jem.status = jemline.value;
                case 'depth'
                    jem.depth = str2double(jemline.value);
                case 'autoRoi'
                    jem.autoRoi = jemline.value;
                case 'manualRoi'
                    jem.manualRoi = jemline.value;
                otherwise
                    found = false;
            end
        end
        
        function jemFailureEntry = processJemFailureEntry(jemFailureEntry, linemsg)
            jemline = regexp(linemsg, PatchClampDiary.jemPipetteFailureExpression, 'names');
            if isempty(jemline.fieldnamechain)
                log4m.getLogger.warn('Empty field found in a JEM failure entry.');
                return
            end
            [jemFailureEntry, found] = PatchClampDiary.processJemPipetteBaiscEntry(jemFailureEntry, jemline);
            
            if ~found
                switch jemline.fieldnamechain
                    case 'failureNotes'
                        jemFailureEntry.failureNotes = jemline.value;
                    case 'freeFailureNotes'
                        jemFailureEntry.freeFailureNotes = jemline.value;
                    otherwise
                        errorMsg = ['Unsupported JEM pipette failure field: ', jemline.fieldnamechain];
                        log4m.getLogger().error(errorMsg);
                        error(errorMsg);
                end
            end
        end
        
        function jemSuccessEntry = processJemSuccessEntry(jemSuccessEntry, linemsg)
            jemline = regexp(linemsg, PatchClampDiary.jemPipetteSuccessExpression, 'names');
            if isempty(jemline.fieldnamechain)
                log4m.getLogger.warn('Empty field found in a JEM success entry.');
                return
            end
            [jemSuccessEntry, found] = PatchClampDiary.processJemPipetteBaiscEntry(jemSuccessEntry, jemline);
            
            if ~found
                switch jemline.fieldnamechain
                    case 'successNotes'
                        jemSuccessEntry.successNotes = jemline.value;
                    case 'qcNotes'
                        jemSuccessEntry.qcNotes = jemline.value;
                    case 'badSweeps'
                        jemSuccessEntry.badSweeps = jemline.value;
                    case 'extraction.pressureApplied'
                        jemSuccessEntry.extraction.pressureApplied = str2double(jemline.value);
                    case 'extraction.retractionPressureApplied'
                        jemSuccessEntry.extraction.retractionPressureApplied = str2double(jemline.value);
                    case 'extraction.timeExtractionStart'
                        jemSuccessEntry.extraction.timeExtractionStart = jemline.value;
                    case 'extraction.timeExtractionEnd'
                        jemSuccessEntry.extraction.timeExtractionEnd = jemline.value;
                    case 'extraction.timeRetractionEnd'
                        jemSuccessEntry.extraction.timeRetractionEnd = jemline.value;
                    case 'extraction.postPatch'
                        jemSuccessEntry.extraction.postPatch = jemline.value;
                    case 'extraction.endPipetteR'
                        jemSuccessEntry.extraction.endPipetteR = str2double(jemline.value);
                    case 'extraction.nucleus'
                        jemSuccessEntry.extraction.nucleus = jemline.value;
                    case 'extraction.tubeID'
                        jemSuccessEntry.extraction.tubeID = jemline.value;
                    case 'extraction.extractionNotes'
                        jemSuccessEntry.extraction.extractionNotes = jemline.value;
                    case 'extraction.extractionObservations'
                        jemSuccessEntry.extraction.extractionObservations = jemline.value;
                    case 'extraction.sampleObservations'
                        jemSuccessEntry.extraction.sampleObservations = jemline.value;
                    otherwise
                        errorMsg = ['Unsupported JEM pipette success field: ', jemline.fieldnamechain];
                        log4m.getLogger().error(errorMsg);
                        error(errorMsg);
                end
            end
        end
        
        function tz = getTzChar()
            tz = sprintf('%s', tzoffset(datetime('now', 'TimeZone', 'local')));
            if '-' ~= tz(1)
                tz = strcat('+', tz);
            end
        end
    end
    
    methods (Access = protected)
        function logJemBasicPatchSeq(this, jem, prefix)
            assert(any(strcmp(prefix, {'failure', 'success'})), 'prefix should be ''success'' or ''failure''.');
            this.log(['JEM pipette.', prefix, '.approach.sliceHealth ', any2str(jem.approach.sliceHealth)]);
            this.log(['JEM pipette.', prefix, '.approach.cellHealth ', any2str(jem.approach.cellHealth)]);
            this.log(['JEM pipette.', prefix, '.approach.creCell ', any2str(jem.approach.creCell)]);
            this.log(['JEM pipette.', prefix, '.approach.pilotName ', any2str(jem.approach.pilotName)]);
            this.log(['JEM pipette.', prefix, '.recording.timeStart ', any2str(jem.recording.timeStart)]);
            this.log(['JEM pipette.', prefix, '.recording.pipetteR ', any2str(jem.recording.pipetteR)]);
            this.log(['JEM pipette.', prefix, '.recording.timeWholeCellStart ', any2str(jem.recording.timeWholeCellStart)]);
            this.log(['JEM pipette.', prefix, '.recording.humanCellTypePrediction ', any2str(jem.recording.humanCellTypePrediction)]);
            this.log(['JEM pipette.', prefix, '.status ', any2str(jem.status)]);
            this.log(['JEM pipette.', prefix, '.depth ', any2str(jem.depth)]);
            this.log(['JEM pipette.', prefix, '.autoRoi ', any2str(jem.autoRoi)]);
            this.log(['JEM pipette.', prefix, '.manualRoi ', any2str(jem.manualRoi)]);
        end
        
        function logJemPatchSeqFailureExclusive(this, jem)
        % LOGJEMPATCHSEQFAILUREEXCLUSIVE Logs fields that are present in a failure entry but not in a success.
            this.log(['JEM pipette.failure.failureNotes ', any2str(jem.failureNotes)]);
            this.log(['JEM pipette.failure.freeFailureNotes ', PatchClampDiary.removeNewlines(any2str(jem.freeFailureNotes))]);
        end
        
        function logJemPatchSeqSuccessExclusive(this, jem)
        % LOGJEMPATCHSEQFAILUREEXCLUSIVE Logs fields that are present in a success entry but not in a failure.
            this.log(['JEM pipette.success.successNotes ', any2str(jem.successNotes)]);
            this.log(['JEM pipette.success.qcNotes ', any2str(jem.qcNotes)]);
            this.log(['JEM pipette.success.badSweeps ', any2str(jem.badSweeps)]);
            this.log(['JEM pipette.success.extraction.pressureApplied ', any2str(jem.extraction.pressureApplied)]);
            this.log(['JEM pipette.success.extraction.retractionPressureApplied ', any2str(jem.extraction.retractionPressureApplied)]);
            this.log(['JEM pipette.success.extraction.timeExtractionStart ', any2str(jem.extraction.timeExtractionStart)]);
            this.log(['JEM pipette.success.extraction.timeExtractionEnd ', any2str(jem.extraction.timeExtractionEnd)]);
            this.log(['JEM pipette.success.extraction.timeRetractionEnd ', any2str(jem.extraction.timeRetractionEnd)]);
            this.log(['JEM pipette.success.extraction.postPatch ', any2str(jem.extraction.postPatch)]);
            this.log(['JEM pipette.success.extraction.endPipetteR ', any2str(jem.extraction.endPipetteR)]);
            this.log(['JEM pipette.success.extraction.nucleus ', any2str(jem.extraction.nucleus)]);
            this.log(['JEM pipette.success.extraction.tubeID ', any2str(jem.extraction.tubeID)]);
            this.log(['JEM pipette.success.extraction.extractionNotes ', PatchClampDiary.removeNewlines(any2str(jem.extraction.extractionNotes))]);
            this.log(['JEM pipette.success.extraction.extractionObservations ', any2str(jem.extraction.extractionObservations)]);
            this.log(['JEM pipette.success.extraction.sampleObservations ', any2str(jem.extraction.sampleObservations)]);
        end
    end
    
end

