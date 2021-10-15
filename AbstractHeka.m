classdef AbstractHeka < AbstractAmplifier & handle
    %HEKA HEKA controller class
    %   Predefined batch commands are included for different phases of
    %   patch-clamping.
    
    properties
        amplifierNumber
    end
    
    methods (Abstract)
        answer = giveOrder(this, order)
    end
    
    methods
        function this = AbstractHeka()
        end
        
        function startup(this)
            this.giveOrder('OpenOnlineFile multipatcher2.onl');
            this.giveOrder('OpenPgfFile multipatcher2.pgf');
            this.giveOrder('OpenProtFile multipatcher2.pro');
        end
        
        function setup(this, activePipetteId, reset)
            if nargin < 3
                reset = true;
            end
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder(['Set E Ampl', num2str(this.amplifierNumber), ' TRUE']); % select channel
            this.giveOrder('Set E Mode 3'); % select voltage clamp mode
            this.giveOrder('Set E Gain 10'); % set gain to 5 mV/pA
            this.giveOrder('Set E VHold 0'); % set holding potential to zero
            this.giveOrder('Set E PulseOn TRUE'); % turn on test pulse
            this.giveOrder('Set E PulseMode 1'); % set single pulse
            this.giveOrder('Set E AutoCFast'); % fast capacitive compensation
            this.giveOrder('Set E AutoZero'); % V0 offset correction
            if reset
                this.giveOrder(['ExecuteProtocol RESET',num2str(activePipetteId)]);
            end
        end
        
        function beforeHunt(this, activePipetteId)
            this.setup(false);
            this.giveOrder(['ExecuteProtocol bHunt',num2str(activePipetteId)]);
        end
        
        function sealing(this, holdingPotential, activePipetteId)
            if nargin < 2
                holdingPotential = -60; 
            end
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder(['Set E VHold ', num2str(holdingPotential)]); % set holding potential to -60 mV or the requested value
            this.giveOrder('Set N  Store FALSE'); % don't store recording
            this.giveOrder(['ExecuteProtocol RESET',num2str(activePipetteId)]);
        end
        
        function reset(this, activePipetteId)
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder('Set E VHold 0'); % set holding potential to 0 mV
            this.giveOrder('Set E Gain 10'); % set gain to 5 mV/pA
            this.giveOrder(['ExecuteProtocol RESET',num2str(activePipetteId)]);
        end
        
        function beforeBreakin(this, activePipetteId)
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder('Set E VHold -70'); % set holding potential to -60 mV
            this.giveOrder('Set E AutoCFast'); % fast capacitive compensation
            this.giveOrder('Set N  Store FALSE'); % don't store recording
            this.giveOrder(['ExecuteProtocol bBreakin',num2str(activePipetteId)]);
        end
        
        function afterBreakIn(this, activePipetteId)
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder('Set E Gain 11');  % set gain to 10 mV/pA
            this.giveOrder('Set E Mode 4'); % select current clamp mode
            this.giveOrder('Set E IHold 0'); % set 
            this.giveOrder('Set N  Store TRUE'); % store recording
            this.giveOrder(['ExecuteProtocol aBreakin',num2str(activePipetteId)]);
        end
        
        function rsImprovementSetup(this, activePipetteId)
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder('Set E Gain 11');  % set gain to 10 mV/pA
            this.giveOrder('Set E Mode 3'); % select voltage clamp mode
            this.giveOrder('Set N  Store FALSE'); % don't store recording
            this.giveOrder(['ExecuteProtocol RESET',num2str(activePipetteId)]);
        end
        
        function rsImprovementFinished(this)
            this.giveOrder('Set N  Break'); % stop stimulus
            this.giveOrder('Set E Gain 10');  % set gain to 5 mV/pA
            this.giveOrder('Set E Mode 3'); % select voltage clamp mode
            this.giveOrder('Set N  Store TRUE'); % store future recording
        end
    end
    
end

