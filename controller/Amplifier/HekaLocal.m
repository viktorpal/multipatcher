classdef HekaLocal < AbstractHeka & handle
    %HEKALOCAL HEKA file communication on the local machine.
    %   This class is performing file communication with the HEKA hardware/PatchMaster software. The communication is
    %   blocking, that is, its functions does not return until an answer is given by PatchMaster.
    %
    %   See also HekaLocalNonblocking.
    
    properties (Constant,Hidden)
        defaultMaxAttempts = 50;
    end
    
    properties
        toPatchMasterFilepath
        fromPatchMasterFilepath
        maxAttempts
    end
    
    properties (Access = private)
        signature
    end
    
    methods
        function this = HekaLocal(toPatchMasterFilepath, fromPatchMasterFilepath)
            this.toPatchMasterFilepath = toPatchMasterFilepath;
            this.fromPatchMasterFilepath = fromPatchMasterFilepath;
            this.maxAttempts = this.defaultMaxAttempts;
            this.signature = [];
        end
        
        function answer = giveOrder(this, order)
            this.writeCommandToFile(order);
            while ~this.isAnswerReady()
                pause(0.1);
            end
            answer = this.readAnswerFromFile();
        end
    end
    
    methods (Access = protected)
        function writeCommandToFile(this, order)
            temp = dir(this.fromPatchMasterFilepath);
            if isempty(temp) %% ha nincs output file, akkor csinal input filet a patchmasternek
                outfile = fopen(this.toPatchMasterFilepath, 'wt' );
                fprintf(outfile,'%s\r\n', num2str(-112), 'acknowledgedacknowledged');
                fclose(outfile);
                outfile = fopen(this.toPatchMasterFilepath,'r+');
                fwrite(outfile, '+');
                fclose(outfile);
            end
            ctr = 0;
            while isempty(temp) %% var az output filera a patchmastertol
                if ctr > this.maxAttempts
                    errorMsg = 'Could not initialize file communication with HEKA!';
                    log4m.getLogger().error(errorMsg);
                    error(errorMsg);
                end
                pause(0.1);
                ctr = ctr + 1;
                temp = dir(this.fromPatchMasterFilepath);
            end
            %% megcsinalja az egyedi parancsazonositot, ami az elozo azonositobol jon
            temp = textread(this.fromPatchMasterFilepath,'%s');
            ctr = 0;
            while isempty(temp)
                if ctr > this.maxAttempts
                    errorMsg = 'Could not initialize file communication with HEKA!';
                    log4m.getLogger().error(errorMsg);
                    error(errorMsg);
                end
                pause(0.1);
                ctr = ctr + 1;
                temp = textread(this.fromPatchMasterFilepath,'%s');
            end
            lastsignature = str2double(temp{1});
            this.signature = lastsignature+1;
            if this.signature > 10
                this.signature = 1;
            end
            %% parancs fileba irasa
            outfile = fopen(this.toPatchMasterFilepath, 'wt');
            fprintf(outfile, '%s\n', num2str(-this.signature), order);
            fclose(outfile);
            outfile = fopen(this.toPatchMasterFilepath,'r+');
            fwrite(outfile, '+');
            fclose(outfile);
        end
        
        function tf = isAnswerReady(this)
            temp = textread(this.fromPatchMasterFilepath,'%s');
%             disp('PatchMaster answer is: ');
%             disp(temp);
            tf = true;
            if isempty(temp) || str2double(temp{1})<0 || abs(str2double(temp{1}))~=this.signature
                tf = false;
            end
        end
        
        function answer = readAnswerFromFile(this)
            temp = textread(this.fromPatchMasterFilepath,'%s');
            answer.full = temp;
            answer.signature = str2double(cell2mat(answer.full(1)));
            for i = 2:length(answer.full)
                answer.ans{i-1} = char(answer.full(i));
            end
        end
    end
    
end

