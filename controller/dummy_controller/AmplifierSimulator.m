classdef AmplifierSimulator < AbstractAmplifier & handle
    %AMPLIFIERSIMULATOR Simple amplifier simulator that does nothing
    %   
    
    properties
        amplifierNumber
    end
    
    methods
        function startup(this)
            log4m.getLogger().trace('startup called');
        end
        
        function setup(this)
            log4m.getLogger().trace('setup called');
        end
        
        function beforeHunt(this)
            log4m.getLogger().trace('beforeHunt called');
        end
        
        function sealing(this, holdingPotential)
            log4m.getLogger().trace(['sealin called with holdingPotential=', num2str(holdingPotential)]);
        end
        
        function reset(this)
            log4m.getLogger().trace('reset called');
        end
        
        function beforeBreakin(this)
            log4m.getLogger().trace('beforeBreakin called');
        end
        
        function afterBreakIn(this)
            log4m.getLogger().trace('afterBreakin called');
        end
        
        function rsImprovementSetup(this)
            log4m.getLogger().trace('rsImprovementSetup called');
        end
        
        function rsImprovementFinished(this)
            log4m.getLogger().trace('rsImprovementFinished called');
        end
    end
    
end

