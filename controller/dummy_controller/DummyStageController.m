classdef DummyStageController < StageController
    %DUMMYSTAGECONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        x
        y
        z
    end
    
    methods (Access = protected)
        function setX(this, value, ~)
            this.x = value;
        end
        
        function setY(this, value, ~)
            this.y = value;
        end
        
        function setZ(this, value)
            this.z = value;
        end
        
        function setPosition(this, x, y, z, speed)
            this.setX(x, speed);
            this.setY(y, speed);
            this.setZ(z);
        end
    end
    
    methods
        function this = DummyStageController()
            this.x = 0;
            this.y = 0;
            this.z = 0;
        end
        
        function x = getX(this)
            x = this.x;
        end
        
        function y = getY(this)
            y = this.y;
        end
        
        function z = getZ(this)
            z = this.z;
        end
        
        function [x, y, z] = getPosition(this)
            x = this.getX();
            y = this.getY();
            z = this.getZ();
            if nargout == 1 || nargout == 0
                x = [x, y, z];
            end
        end
        
        function b = isMoving(this)
            b = this.isMovingX() || this.isMovingY() || this.isMovingZ();
        end
        
        function b = isMovingX(this)
            b = false;
        end
        
        function b = isMovingY(this)
            b = false;
        end
            
        function b = isMovingZ(this)
            b = false;
        end
        
        function waitForFinished(this)
            this.waitForFinishedX();
            this.waitForFinishedY();
            this.waitForFinishedZ();
        end
        
        function waitForFinishedX(this)
        end
        
        function waitForFinishedY(this)
        end
        
        function waitForFinishedZ(this)
        end
    end % methods
end % classdef 

