function anything = any2str( anything )
%ANY2STRING Converts (almost) anything to string
%   Self explanatory. Might not support some things though.

    if ischar(anything)
        return;
    end
    if isnumeric(anything)
        if numel(anything) == 1 || ~ismatrix(anything)
            anything = num2str(anything);
        elseif ismatrix(anything)
            [m, n] = size(anything);
            newValue = '[';
            for k = 1:m
                for l = 1:n
                    if l < n
                        separator = ',';
                    elseif k < m
                        separator = ';';
                    else
                        separator = '';
                    end
                    newValue = strcat(newValue, num2str(anything(k,l)), separator);
                end
            end
            newValue = strcat(newValue, ']');
            anything = newValue;
        end
    end
    if islogical(anything)
        if anything
            anything = 'true';
        else
            anything = 'false';
        end
    end
    if iscell(anything)
        if ~isempty(anything)
            anything = strjoin(cellfun(@any2str, anything, ...
                'UniformOutput', false));
        else
            anything = '';
        end
    end
    if isa(anything, 'function_handle')
        anything = strrep(func2str(anything), ',', ' ');
    end

end

