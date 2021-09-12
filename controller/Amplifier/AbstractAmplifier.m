classdef AbstractAmplifier < handle
    %ABSTRACTAMPLIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Abstract)
        startup(this)
        setup(this, activePipetteId)
        beforeHunt(this, activePipetteId)
        sealing(this, holdingPotential, activePipetteId)
        reset(this, activePipetteId)
        beforeBreakin(this, activePipetteId)
        afterBreakIn(this, activePipetteId)
        rsImprovementSetup(this, activePipetteId)
        rsImprovementFinished(this)
    end
    
end

