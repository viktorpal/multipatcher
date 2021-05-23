classdef HekaLocalNonblocking < HekaLocal & handle
    %HEKALOCALNONBLOCKING Non-blocking HEKA file communication implementation
    %   The class is using a Matlab timer to act as a non blocking code. The timer runs only when an element is in the
    %   command queue thus saving computation time.
    %
    %   See also HekaLocal.
    
    properties (Constant, Hidden)
        defaultTimerPeriod = 0.05
    end
    
    properties (Access = protected)
        commandQueue
        lastCommandId
    end
    
    properties (Access = private)
        t % timer object
        waitingForAnswer
    end
    
    methods
        function this = HekaLocalNonblocking(toPatchMasterFilepath, fromPatchMasterFilepath, timerPeriod)
            this = this@HekaLocal(toPatchMasterFilepath, fromPatchMasterFilepath);
            if nargin < 3
                timerPeriod = this.defaultTimerPeriod;
            end
            this.lastCommandId = uint64(0);
            this.createEmptyCommandQueue();
            this.t = timer('Period', timerPeriod, 'TimerFcn', @this.timerCb, 'ExecutionMode', 'fixedRate', ...
                'BusyMode', 'drop', 'Name', 'HekaLocalNonblocking-timer');
            this.waitingForAnswer = false;
        end
        
        function delete(this)
            stop(this.t);
        end
        
        function answer = giveOrder(this, order)
            this.addToCommandQueue(order);
            answer = this.lastCommandId;
        end
    end
    
    methods (Access = protected)
        function id = addToCommandQueue(this, command)
            this.lastCommandId = this.lastCommandId + 1;
            id = this.lastCommandId;
            assert(ischar(command));
            this.commandQueue(end+1).id = id;
            this.commandQueue(end).command = command;
            if strcmp(this.t.Running, 'off')
                start(this.t);
            end
        end
        
        function removeFirstCommandInQueue(this)
            this.commandQueue = this.commandQueue(2:end);
        end
    end
    
    methods (Access = private)
        function createEmptyCommandQueue(this)
            this.commandQueue = struct('id', {}, 'command', {});
        end
        
        function timerCb(this, ~, ~)
            try
                if this.waitingForAnswer
                    if this.isAnswerReady()
                        this.waitingForAnswer = false;
                        this.removeFirstCommandInQueue();
                        if isempty(this.commandQueue)
                            stop(this.t);
                        end
                    end
                else %if ~isempty(this.commandQueue)
                    this.writeCommandToFile(this.commandQueue(1).command);
                    this.waitingForAnswer = true;
                end
            catch ex
                disp(ex.message);
            end
        end
    end
    
end

