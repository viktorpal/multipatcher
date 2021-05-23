classdef DummyPipetteController < PipetteController
    %DUMMYPIPETTECONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dummy
    end
    
    methods (Access = protected)
        function setX(this, value, ~)
            this.dummy.moveTo(value, [], []);
        end
        
        function setY(this, value, ~)
            this.dummy.moveTo([], value, []);
        end
        
        function setZ(this, value, ~)
            this.dummy.moveTo([], [], value);
        end
        
        function setPosition(this, x, y, z, speed)
            this.setX(x, speed);
            this.setY(y, speed);
            this.setZ(z);
        end
    end
    
    methods
        function obj = DummyPipetteController()
            obj.dummy = DummyStageController();
        end
        
        function x = getX(this)
            x = this.dummy.getX();
        end
        
        function y = getY(this)
            y = this.dummy.getY();
        end
        
        function z = getZ(this)
            z = this.dummy.getZ();
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
        
        function switchToManualSlowSpeed(this)
        end
        
        function switchToManualFastSpeed(this)
        end
        
        function switchToAutomaticSlowSpeed(this)
        end
        
        function switchToAutomaticFastSpeed(this)
        end
    end
    
end

