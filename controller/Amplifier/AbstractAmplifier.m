classdef AbstractAmplifier < handle
    %ABSTRACTAMPLIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Abstract)
        startup(this)
        setup(this)
        beforeHunt(this)
        sealing(this, holdingPotential)
        reset(this)
        beforeBreakin(this)
        afterBreakIn(this)
        rsImprovementSetup(this)
        rsImprovementFinished(this)
    end
    
end

