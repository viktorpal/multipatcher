classdef log4m < handle 
    %LOG4M This is a simple logger based on the idea of the popular log4j.
    %
    % Description: Log4m is designed to be relatively fast and very easy to
    % use. It has been designed to work well in a matlab environment.
    % Please contact me (info below) with any questions or suggestions!
    % 
    %
    % Modified by Krisztian Koos <koos.krisztian@gmail.com>
    %   Changelog:
    %       Caller is determined in runtime and now it should not be passed as
    %       the first input parameter. This makes the use more comfortable,
    %       but might cause errors when debug is disabled in a production
    %       code.
    %
    % Author: 
    %       Luke Winslow <lawinslow@gmail.com>
    % Heavily modified version of 'log4matlab' which can be found here:
    %       http://www.mathworks.com/matlabcentral/fileexchange/33532-log4matlab
    %
    
    %% TODO add format string and varargin to log functions for late evaluation (possibly use sprintf)
    
    properties (Constant)
        ALL = 0;
        TRACE = 1;
        DEBUG = 2;
        INFO = 3;
        WARN = 4;
        ERROR = 5;
        FATAL = 6;
        OFF = 7;
    end
    
    properties (Constant, Hidden)
        defaultFullpath = 'log4m.log'
        defaultCommandWindowLevel = log4m.ALL
        defaultLogLevel = log4m.INFO
    end

    properties(Access = protected)
        logger;
        lFile;
    end
    
    properties(SetAccess = protected)
        fullpath
        commandWindowLevel
        logLevel
    end
    
    methods (Static)
        function obj = getLogger( logPath )
            %GETLOGGER Returns instance unique logger object.
            %   PARAMS:
            %       logPath - Relative or absolute path to desired logfile.
            %   OUTPUT:
            %       obj - Reference to signular logger object.
            %
            
            persistent localObj;
            if isempty(localObj) || ~isvalid(localObj)
                if(nargin == 0)
                    logPath = 'log4m.log';
                elseif(nargin > 1)
                    error('getLogger only accepts one parameter input');
                end
                localObj = log4m(logPath);
            end
            obj = localObj;
        end
        
        function testSpeed( logPath )
            %TESTSPEED Gives a brief idea of the time required to log.
            %
            %   Description: One major concern with logging is the
            %   performance hit an application takes when heavy logging is
            %   introduced. This function does a quick speed test to give
            %   the user an idea of how various types of logging will
            %   perform on their system.
            %
            
            L = log4m.getLogger(logPath);
            
            
            disp('1e5 logs when logging only to command window');
            
            L.setCommandWindowLevel(L.TRACE);
            L.setLogLevel(L.OFF);
            tic;
            for i=1:1e5
                L.trace('test');
            end
            
            disp('1e5 logs when logging only to command window');
            toc;
            
            disp('1e6 logs when logging is off');
            
            L.setCommandWindowLevel(L.OFF);
            L.setLogLevel(L.OFF);
            tic;
            for i=1:1e6
                L.trace('test');
            end
            toc;
            
            disp('1e4 logs when logging to file');
            
            L.setCommandWindowLevel(L.OFF);
            L.setLogLevel(L.TRACE);
            tic;
            for i=1:1e4
                L.trace('test');
            end
            toc;
            
        end
        
        function caller = determineCaller()
            dbk = dbstack( 3, '-completenames' );
            if isempty( dbk )
                caller = 'base';
            else
                caller = dbk(1).name;
            end
        end
    end
    
    
%% Public Methods Section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods       
        function setFilename(this, logPath)
            %SETFILENAME Change the location of the text log file.
            %
            %   PARAMETERS:
            %       logPath - Name or full path of desired logfile
            %
            
            if ~java.io.File(logPath).isAbsolute()
                logPath = fullfile(pwd, logPath);
            end
            [fid,message] = fopen(logPath, 'a');
            
            if(fid < 0)
                error(['Problem with supplied logfile path: ' message]);
            end
            fclose(fid);
            
            this.fullpath = logPath;
        end
          
     
        function setCommandWindowLevel(this,loggerIdentifier)
            this.commandWindowLevel = loggerIdentifier;
        end


        function setLogLevel(this,logLevel)
            this.logLevel = logLevel;
        end
        

%% The public Logging methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function trace(this, message)
            %TRACE Log a message with the TRACE level
            %
            %   PARAMETERS:
            %       message - Text of message to log.
            % 
            this.writeLog(this.TRACE, message);
        end
        
        function debug(this, message)
            %TRACE Log a message with the DEBUG level
            %
            %   PARAMETERS:
            %       message - Text of message to log.
            % 
            this.writeLog(this.DEBUG, message);
        end
        
 
        function info(this, message)
            %TRACE Log a message with the INFO level
            %
            %   PARAMETERS:
            %       message - Text of message to log.
            % 
            this.writeLog(this.INFO, message);
        end
        

        function warn(this, message)
            %TRACE Log a message with the WARN level
            %
            %   PARAMETERS:
            %       message - Text of message to log.
            % 
            this.writeLog(this.WARN, message);
        end
        

        function error(this, message)
            %TRACE Log a message with the ERROR level
            %
            %   PARAMETERS:
            %       message - Text of message to log.
            % 
            this.writeLog(this.ERROR, message);
        end
        

        function fatal(this, message)
            %TRACE Log a message with the FATAL level
            %
            %   PARAMETERS:
            %       message - Text of message to log.
            % 
            this.writeLog(this.FATAL, message);
        end
        
    end

%% Private Methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Unless you're modifying this, these should be of little concern to you.
    methods (Access = private)
        
        function this = log4m(fullpath_passed)
            this.fullpath = this.defaultFullpath;
            this.commandWindowLevel = this.defaultCommandWindowLevel;
            this.logLevel = this.defaultLogLevel;
            
            if nargin > 0
                path = fullpath_passed;
            end
			this.setFilename(path);
        end
        
%% WriteToFile     
        function writeLog(this, level, message)
            scriptName = [];
            
            % If necessary write to command window
            if( this.commandWindowLevel <= level )
                scriptName = this.determineCaller();
                fprintf('%s:%s\n', scriptName, message);
            end
            
            %If currently set log level is too high, just skip this log
            if(this.logLevel > level)
                return;
            end 
            
            if isempty(scriptName)
                scriptName = this.determineCaller();
            end

            % set up our level string
            switch level
                case{this.TRACE}
                    levelStr = 'TRACE';
                case{this.DEBUG}
                    levelStr = 'DEBUG';
                case{this.INFO}
                    levelStr = 'INFO';
                case{this.WARN}
                    levelStr = 'WARN';
                case{this.ERROR}
                    levelStr = 'ERROR';
                case{this.FATAL}
                    levelStr = 'FATAL';
                otherwise
                    levelStr = 'UNKNOWN';
            end

            % Append new log to log file
            try
                fid = fopen(this.fullpath,'a');
                fprintf(fid,'%s %s %s - %s\r\n' ...
                    , datestr(now,'yyyy-mm-dd HH:MM:SS,FFF') ...
                    , levelStr ...
                    , scriptName ... % Have left this one with the '.' if it is passed
                    , message);
                fclose(fid);
            catch ME_1
                disp(ME_1);
            end
        end
    end
    
end

