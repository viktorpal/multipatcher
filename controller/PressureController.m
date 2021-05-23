classdef (Abstract) PressureController < matlab.mixin.SetGet
    %PRESSURECONTROLLER Abstract pressure controller class
    %   Pressure value can not be set using dot notation, because it would
    %   be ambiguous if there is a tank and a pipette pressure, or even
    %   when setting the desired or getting the actual value.
    
    events
        DataChange
    end
    
    properties (SetAccess = protected, SetObservable)
        state
    end
    
    methods
        setPressure(this, value);
        pressure = getPressure(this);
        breakIn(this, pressure, delay);
        updateTime = getUpdateTime(this);
        calibrate(this);
        disable(this);
    end
    
end

