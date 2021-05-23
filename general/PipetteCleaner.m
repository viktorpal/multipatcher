classdef PipetteCleaner < handle
    %PIPETTECLEANING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = immutable)
        autopatcher % AutoPatcher object
    end
       
    properties
        drawbackPosition %
        alconoxPosition
        acsfPosition
        turretCalibrationPosition
    end
    
    methods
        function this = PipetteCleaner(autopatcher)
            assert(isa(autopatcher, 'AutoPatcher'), 'Input should be an AutoPatcher object');
            this.autopatcher = autopatcher;
        end
        
        function set.drawbackPosition(this, value)
            assert(isnumeric(value) && numel(value)==1, 'Input should be a numeric value.');
            this.drawbackPosition = value;
        end
        
        function set.alconoxPosition(this, value)
            assert(isnumeric(value) && numel(value)==3, 'Input should be a 3-element numeric vector.');
            this.alconoxPosition = value;
        end
        
        function set.acsfPosition(this, value)
            assert(isnumeric(value) && numel(value)==3, 'Input should be a 3-element numeric vector.');
            this.acsfPosition = value;
        end
        
        function set.turretCalibrationPosition(this, value)
            assert(isnumeric(value) && numel(value)==3, 'Input should be a 3-element numeric vector.');
            this.turretCalibrationPosition = value;
        end
        
        function saveCurrentPositionForDrawback(this)
            pip = this.autopatcher.microscope.getPipette(this.autopatcher.activePipetteId);
            this.drawbackPosition = pip.getX();
        end
        
        function saveCurrentPositionForAcsf(this)
            pip = this.autopatcher.microscope.getPipette(this.autopatcher.activePipetteId);
            this.acsfPosition = pip.getPosition();
            this.turretCalibrationPosition = this.autopatcher.microscope.stage.getPosition();
        end
        
        function saveCurrentPositionForAlconox(this)
            pip = this.autopatcher.microscope.getPipette(this.autopatcher.activePipetteId);
            this.alconoxPosition = pip.getPosition();
        end
        
        function cleanPipette(this)
            log4m.getLogger().trace('Pipette cleaning started.');
            pip = this.autopatcher.microscope.getPipette(this.autopatcher.activePipetteId);
            originalPosition = pip.getPosition();
            turretPosition = this.autopatcher.microscope.stage.getPosition();
            
            pip.moveTo(this.drawbackPosition, [], [], 'speed', 'fast');
            pip.waitForFinished();
            adjustedAlconoxPosition = pip.microscope2pipette(turretPosition - this.turretCalibrationPosition, 'relative');
            adjustedAlconoxPosition = this.alconoxPosition + adjustedAlconoxPosition;
            pip.moveTo([], adjustedAlconoxPosition(2), adjustedAlconoxPosition(3), 'speed', 'fast');
            pip.waitForFinished();
            pip.moveTo(adjustedAlconoxPosition(1), [], [], 'speed', 'fast');
            pip.waitForFinished();
            
            for i = 1:4
                this.autopatcher.pressureController.setPressure(1000);
                while this.autopatcher.pressureController.getPressure() < 900
                    pause(0.2);
                end
                pause(1);
                this.autopatcher.pressureController.setPressure(0);
                pause(1);
                this.autopatcher.pressureController.setPressure(-300);
                while this.autopatcher.pressureController.getPressure() > -300
                    pause(0.2);
                end
                pause(4);
                this.autopatcher.pressureController.setPressure(0);
                pause(1);
            end
            this.autopatcher.pressureController.setPressure(1000);
            while this.autopatcher.pressureController.getPressure() < 900
                pause(0.2);
            end
            pause(1);
            this.autopatcher.pressureController.setPressure(20);
            pause(1);
            
            pip.moveTo(this.drawbackPosition, [], [], 'speed', 'fast');
            pip.waitForFinished();
            adjustedAcsfPosition = pip.microscope2pipette(turretPosition - this.turretCalibrationPosition, 'relative');
            adjustedAcsfPosition = this.acsfPosition + adjustedAcsfPosition;
            pip.moveTo([], adjustedAcsfPosition(2), adjustedAcsfPosition(3), 'speed', 'fast');
            pip.waitForFinished();
            pip.moveTo(adjustedAcsfPosition(1), [], [], 'speed', 'fast');
            pip.waitForFinished();
            
            this.autopatcher.pressureController.setPressure(1000);
            while this.autopatcher.pressureController.getPressure() < 900
                pause(0.2);
            end
            pause(10);
            this.autopatcher.pressureController.setPressure(0);
            pause(1);
            
            pip.moveTo(this.drawbackPosition, [], [], 'speed', 'fast');
            pip.waitForFinished();
            pip.moveTo([], originalPosition(2), originalPosition(3), 'speed', 'fast');
            pip.waitForFinished();
            pip.moveTo(originalPosition(1), [], [], 'speed', 'fast');
            pip.waitForFinished();
            log4m.getLogger().trace('Pipette cleaning finished.');
        end
    end
    
end

