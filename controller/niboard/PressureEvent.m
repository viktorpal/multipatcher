classdef PressureEvent < event.EventData
    %PRESSUREEVENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess=private)
        % A MATLAB serial date time stamp of the absolute time of TimeStamp==0
        TriggerTime

        % An mxn array of observations where m is the number of scans, and n is the
        % number of channels
        Data

        % An mx1 array of time stamps where 0 is defined as TriggerTime
        TimeStamps
    end
    
    methods
        function this = PressureEvent(triggerTime,data,timeStamps)
            this.TriggerTime = triggerTime;
            this.Data = data;
            this.TimeStamps = timeStamps;
        end
    end
    
end

