classdef (Abstract) StageController < handle
    %STAGECONTROLLER Stage and objective position controller
    %   set* - speed: 'slow' or 'fast'
    
    methods (Abstract, Access = protected)
        setX(this, value, speed);
        setY(this, value, speed);
        setZ(this, value);
        setPosition(this, x, y, z, speed);
    end
    
    methods (Abstract)
        x = getX(this);
        y = getY(this);
        z = getZ(this);
        [x, y, z] = getPosition(this);
        b = isMoving(this);
        b = isMovingX(this);
        b = isMovingY(this);
        b = isMovingZ(this);
        waitForFinished(this);
        waitForFinishedX(this);
        waitForFinishedY(this);
        waitForFinishedZ(this);
    end
    
    methods
        function move(this, x, y, z, varargin)
            %MOVE Move the field of view relative to the current position
            %
            %   See also MOVETO, MOVEPIPETTE.

            p = inputParser;
            p.addRequired('x', @(x) isnumeric(x) || isempty(x));
            p.addRequired('y', @(x) isnumeric(x) || isempty(x));
            p.addRequired('z', @(x) isnumeric(x) || isempty(x));
            p.addParameter('speed', []);
            if numel(varargin)==1
                varargin = varargin{1};
            end
            p.parse(x, y, z, varargin{:});
            speed = p.Results.speed;

            toX = [];
            toY = [];
            toZ = [];
            if ~isempty(x)
                cx = this.getX();
                toX = cx + x;
            end
            if ~isempty(y)
                cy = this.getY();
                toY = cy + y;
            end
            if ~isempty(z)
                cz = this.getZ();
                toZ = cz + z;
            end
            
            this.moveTo(toX, toY, toZ, 'speed', speed);
        end
        
        function moveTo(this, x, y, z, varargin)
            %MOVETO Moves the stage to the given position
            %   This function moves the microscope stage to the given absolute position
            %   by forwarding the call to the low level abstract functions
            %
            %   See also move, PipetteController.moveTo.

            p = inputParser;
            p.addRequired('x', @(x) isnumeric(x) || isempty(x));
            p.addRequired('y', @(x) isnumeric(x) || isempty(x));
            p.addRequired('z', @(x) isnumeric(x) || isempty(x));
            p.addParameter('speed', []);
            if numel(varargin)==1
                varargin = varargin{1};
            end
            parse(p, x, y, z, varargin{:});
            speed = p.Results.speed;
            
            if ~isempty(x) && ~isnan(x)
                this.setX(x, speed);
            end
            if ~isempty(y) && ~isnan(y)
                this.setY(y, speed);
            end
            if ~isempty(z) && ~isnan(z)
                this.setZ(z);
            end

        end
    end % methods
end % classdef

