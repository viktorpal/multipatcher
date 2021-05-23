classdef CustomElphysProcessor < ElectrophysiologySignalProcessor & handle
    %CUSTOMELPHYSPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = immutable)
        system
    end
    
    properties (Access = private)
        dataListener
    end
    
    methods
        function this = CustomElphysProcessor(pressureAndElphysSystem)
            assert(isa(pressureAndElphysSystem, 'PressureAndElphysSystem'), ...
                'Input system is not a ''PressureAndElphysSystem'' object.');
            this.system = pressureAndElphysSystem;
            this.resistance = 0;
            this.dataListener = addlistener(this.system, 'ElphysDataAvailable', @this.calculateResistanceCallback);
        end
        
        function updateTime = getUpdateTime(this)
            updateTime = 2*this.system.updateTime;
        end
        
        function delete(this)
            delete(this.dataListener);
            if ~this.system.hasListener()
                delete(this.system);
            end
        end
    end
    
    methods (Access = private)
        function calculateResistanceCallback(this, ~, event)
%             disp(mean(event.Data(:,1)));
%             in = event.Data(:,1) / 0.005; % pA
            out = event.Data(:,2) / 10; % mV, amplifier multiplies the signal by 10 for better measurements
%             this.current = mean(in);
            
            numDataPoints = size(event.Data(:,2),1); % it was either 30 or 60... heka test pulse is quite slow
            outmax = max(out);
            outmin = min(out);
            ampl = abs(abs(outmax) - abs(outmin));
            avgOut = mean([outmax, outmin]);
            idx = out<avgOut;
            nnzIdx = nnz(idx);
            if ampl >= 0.0025 && ampl <= 0.010% && ... % check if somewhat square signal is present
                    %nnzIdx > numDataPoints*0.25 && (numDataPoints - nnzIdx) > numDataPoints*0.25 % and that the square signal was not interrupted
                if ~this.calculateBreakInResistance
                    in = event.Data(:,1) / 0.005; % pA
                    this.current = mean(in);
                    inAmpl = abs(median(in(idx)) - median(in(~idx))); %% TODO check mean filter for 1/3 speed improvement
                    this.resistance = 0.005/inAmpl*10^6; % we know that square signal amplitude should be 5 mV
                else
                    in = event.Data(:,1) / 0.01; % pA
                    this.current = mean(in);
                    idxChange = gradient(idx) ~= 0;
                    in2 = conv(in, [1 1 1 1 1]./5, 'same');
                    idxnew = conv(double(idxChange), [1 1 1 1 1], 'same');
                    inAmpl2 = abs(max(in2(idxnew>0)) - min(in2(idxnew>0)));
                    this.resistance = 0.01/inAmpl2*10^6;
                end
            else
                this.resistance = NaN;
            end
            notify(this, 'DataChange');
        end
    end
end
