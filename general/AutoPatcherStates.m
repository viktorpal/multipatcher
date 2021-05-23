classdef AutoPatcherStates
    %AUTOPATCHERSTATES Defined autopatcher states as enumeration
    %   
    
    %% TODO introduce Error state and if a hardware communication error occured which prevents moving on, enter that state
    
    enumeration
        NotStarted
        Starting
        Hunting
        Sealing
        BreakIn
        Success
        Fail
        Stopped
    end
end

