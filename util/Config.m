classdef Config < handle
%CONFIG Config manager
%   The Config class can read an XML where object to be instantiated,
%   constructor parameters, properties to be set and methods (with
%   parameters) to be called can be defined. The config object tracks the
%   instantiated (handle) objects and can save their later state.
%    
%   Ideas for further improvement:
%       - put loaded variables into a struct so it cannot break the code (or at least not easily)
%       - auto backup functionality? backup(time) auto backups using a timer, off if time is zero
%       - Recursively process the necessary elements starting from
%       returnIDs. However, whether order matters is a question of use.
%       This way the xml might contain unused elements, but if we restrict
%       the loading / add predefined, only those needed that are required
%       in the returnIDs element and not defined in predefined elements.
    
    properties (SetAccess = protected)
        filepath
    end
    
    properties (Access = protected)
        dom
        domRefPairs % dom node and handle object pairs to track changes
        restriction % IDs that should be allowed or restricted to be loaded, depending on isExclusion
        isExclusion % determines whether restriction is exclusion or restriction to variables (default: false)
    end
    
    methods (Static)
        
        function this = createEmpty() %#ok<STOUT>
        % Creating an empty model, adding parameters, contructor or
        % function parameters is not supported yet.
        %% TODO
            error('Not implemented yet');
        end
        
        function [model, configObject] = createFromXml(filepath, predefined, trackPredefined, restriction, isExclusion)
        % Reads xml, instantiates the defined objects and returns the
        % config object as well. 
        %   Config.createFromXml(filepath) - uses empty parameters for the
        %   following
        % Restriction can either define a restriction to variables or
        % exclusion of them. It is controlled by isExclusion (default:
        % false).
        
            configObject = Config();
            configObject.filepath = filepath;
            if nargin < 2
                predefined = [];
            elseif ~isempty(predefined)
                assert(ismatrix(predefined) && size(predefined,2) == 2, ...
                    'Parameter ''predefined'' should be an n-by-2 (or empty) matrix.');
                assert(all(cellfun(@ischar, predefined(:,1))), 'The first column in ''predefined'' should consist of strings.');
            end
            if nargin < 3 || isempty(trackPredefined)
                trackPredefined = true;
            end
            if nargin >= 4 && ~isempty(restriction)
                assert(all(cellfun(@ischar, restriction)), 'Parameter ''exclude'' should be a cell array of strings.');
                configObject.restriction = restriction;
            end
            if nargin < 5 || isempty(isExclusion)
                configObject.isExclusion = false;
            else
                assert(islogical(isExclusion), 'Parameter ''isExclusion'' should be logical.');
                configObject.isExclusion = isExclusion;
            end
            model = configObject.readXml(filepath, predefined, trackPredefined);
        end
    end
    
    methods
        
        function save(this, filepath)
        % Read the property values of the instantiated objects, refreshes
        % the DOM object and writes it to file. If no input filepath is
        % specified, it updates the file that was read.
            if nargin > 1
                this.filepath = filepath;
            end
            this.updateDom();
            str = xmlwrite(this.dom);
            str = regexprep(str,'\n\s*\n', '\n'); % remove empty lines that consist of only whitespaces
            try
                fid = fopen(this.filepath, 'w');
                fprintf(fid, '%s\n', str);
                fclose(fid);
            catch ex
                log4m.getLogger().error(['Could not save config to file: ', this.filepath, ', cause: ', ex.message]);
                rethrow(ex);
            end
        end
    end
    
    methods (Access = protected)
        function model = readXml(this, filepath, predefined, trackPredefined)
            this.dom = xmlread(filepath);
            this.domRefPairs = struct();
            model = struct();
            root = this.dom.getDocumentElement();
            retids = root.getElementsByTagName('returnIDs');
            if retids.getLength() == 0
                error('The config file does not specify return values');
            else
                retids = retids.item(0).getElementsByTagName('returnID');
                if retids.getLength() == 0
                    error('The config file does not specify return values');
                end
            end
            elements = root.getElementsByTagName('elements');
            elementList = elements.item(0).getElementsByTagName('element');
            for i = 0:elementList.getLength()-1
                objectId = char(elementList.item(i).getElementsByTagName('id').item(0).getTextContent());
                
                isPredefined = false;
                if ~isempty(predefined)
                    predefinedIdx = find(cellfun(@(x) strcmp(x,objectId), predefined(:,1)));
                    if numel(predefinedIdx) > 1
                        error(['The predefined variables contain element ''', objectId,''' more than once.']);
                    elseif numel(predefinedIdx) == 1
                        isPredefined = true;
                        tmp = predefined{predefinedIdx,2}; %#ok<NASGU>
                        eval([objectId, ' = tmp;']);
                    end
                end
                
                loadAllowed = true;
                if this.isExclusion
                    if ~isempty(this.restriction) && ~isempty(find(cellfun(@(x) strcmp(x,objectId), this.restriction),1))
                        loadAllowed = false;
                    end
                else
                    if ~isempty(this.restriction) && isempty(find(cellfun(@(x) strcmp(x,objectId), this.restriction),1))
                        loadAllowed = false;
                    end
                end
                
                if ~isPredefined && loadAllowed
                    claz = char(elementList.item(i).getElementsByTagName('class').item(0).getTextContent());
                    constructorParametersText = '';
                    constructorParameters = elementList.item(i).getElementsByTagName('constructorParameters');
                    if constructorParameters.getLength() ~= 0
                        constructorParameters = constructorParameters.item(0).getElementsByTagName('parameter');
                        for j = 0:constructorParameters.getLength()-1
                            [~, value] = Config.parseParameter(constructorParameters.item(j));
                            if isempty(constructorParametersText)
                                constructorParametersText = value;
                            else
                                constructorParametersText = [constructorParametersText, ', ', value]; %#ok<AGROW>
                            end
                        end
                    end
                    command = [objectId,' = ', claz, '(', constructorParametersText,');'];
                    eval(command);

                    properties = elementList.item(i).getElementsByTagName('properties');
                    if properties.getLength() ~= 0
                        properties = properties.item(0).getElementsByTagName('parameter');
                        for j = 0:properties.getLength()-1
                            property = properties.item(j);
                            [propname, value] = Config.parseParameter(property);
                            if isempty(propname)
                                error(['Object ''', objectId, ''' has a property defined without a name.']);
                            end
                            command = [objectId, '.', propname, ' = ', value, ';'];
                            eval(command);
                        end
                    end

                    methodsToCall = elementList.item(i).getElementsByTagName('methodsToCall');
                    if methodsToCall.getLength() ~= 0
                        methods = methodsToCall.item(0).getElementsByTagName('method');
                        for j = 0:methods.getLength()-1
                            methodName = char(methods.item(j).getElementsByTagName('name').item(0).getTextContent());
                            methodParamsText = '';
                            methodParameters = methods.item(j).getElementsByTagName('parameters');
                            if methodParameters.getLength() ~= 0
                                methodParameters = methodParameters.item(0).getElementsByTagName('parameter');
                                for k = 0:methodParameters.getLength()-1
                                    [~, value] = Config.parseParameter(methodParameters.item(k));
                                    if isempty(methodParamsText)
                                        methodParamsText = value;
                                    else
                                        methodParamsText = [methodParamsText, ', ', value]; %#ok<AGROW>
                                    end
                                end
                            end
                            command = [objectId, '.', methodName, '(', methodParamsText, ');'];
                            eval(command);
                        end
                    end
                end
                
                if (isPredefined && trackPredefined) || loadAllowed
                    if isa(eval(objectId), 'handle')
                        this.domRefPairs.(objectId) = {eval(objectId), elementList.item(i)};
                    else
                        log4m.getLogger().warn(['Config is not managing value objects: ', objectId]);
                    end
                end
            end
            
            for i = 0:retids.getLength()-1
                retid = retids.item(i);
                id = char(retid.getTextContent());
                model.(id) = eval(id);
            end
        end % function
        
        function updateDom(this)
            fields = fieldnames(this.domRefPairs);
            for i = 1:numel(fields)
                field = fields{i};
                ref = this.domRefPairs.(field){1};
                element = this.domRefPairs.(field){2};
                
                properties = element.getElementsByTagName('properties');
                if properties.getLength() ~= 0
                    properties = properties.item(0).getElementsByTagName('parameter');
                    for j = 0:properties.getLength()-1
                        property = properties.item(j);
                        [propname, ~, type] = Config.parseParameter(property);
                        if isempty(propname)
                            error(['Object ''', objectId, ''' has a property defined without a name.']);
                        end
                        switch type
                            case 'char'
                                newValue = ref.(propname);
                            case 'numeric'
                                if numel(ref.(propname)) == 1
                                    newValue = num2str(ref.(propname));
                                elseif ismatrix(ref.(propname))
                                    [m, n] = size(ref.(propname));
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
                                            newValue = strcat(newValue, num2str(ref.(propname)(k,l)), separator);
                                        end
                                    end
                                    newValue = strcat(newValue, ']');
                                else
                                    error('Unsupported numeric subtype!');
                                end
                            case 'reference'
                                continue
                            case 'logical'
                                newValue = any2str(ref.(propname));
                            otherwise
                                error(['Unsupported parameter type: ', type]);
                        end
                        property.setTextContent(newValue);
                    end
                end
            end
        end % function
    end % methods
    
    methods (Access = protected, Static)
        function [name, value, type] = parseParameter(parameter)
            name = char(parameter.getAttribute('name'));
            type = char(parameter.getAttribute('type'));
            value = char(parameter.getTextContent());
            switch type
                case 'char'
                    value = ['''',value,''''];
                case 'numeric'
                case 'reference' % eval will handle it properly in this case
                case 'logical'
                    [newvalue, status] = str2num(value); %#ok<ST2NM>
                    if status
                        value = any2str(logical(newvalue));
                    elseif ~any(strcmp(value, {'true', 'false'}))
                        error(['Could not convert to logical: ', value]);
                    end
                otherwise
                    error(['Unsupported parameter type: ', type]);
            end
        end
    end
    
end

