function z = movzscore(x, k, options)
%MOVZSCORE - Moving z-score
%
%   Returns the local k-point centered z-score, where each z-score is
%   calculated over a sliding window of length k across neighboring
%   elements of X.
%
%   Syntax
%       Z = MOVZSCORE(X,k)
%       Z = MOVZSCORE(X,[kb kf])
%       Z = MOVZSCORE(___,Options)
%
%   Input Arguments
%       X - Input data
%         vector | matrix | multidimensional array | table | timetable
%       k - Window length
%         numeric or duration scalar
%       [kb kf] - Directional window length
%         numeric or duration row vector containing two elements
%       Options - Optional arguments specified as name-value pairs
%         Weight - Weight indicator for the standard deviation
%           0 (default) | 1
%         Dimension - Dimension to operate along
%           positive integer scalar
%         NaNFlag - Missing value condition
%           "includemissing" (default) | "includenan" | "omitmissing" |
%           "omitnan"
%         Endpoints - Method to treat leading and trailing windows
%           "shrink" (default) | "discard" | "fill" | numeric or logical scalar
%         SamplePoints - Sample points for computing minimums
%           vector
%         DataVariables - Table or timetable variables to operate on
%           table or timetable variable name | scalar | vector | cell array |
%           pattern | function handle | table vartype subscript
%         ReplaceValues - Replace values indicator
%           true or 1 (default) | false or 0
%
%   See also MOVMEAN, MOVSTD

    arguments
        x
        k {mustBeA(k,{'datetime','duration','double'}),mustBeNonempty}
        options.Weight {mustBeMember(options.Weight,[0 1])} = 0
        options.Dimension {mustBeInteger, mustBeScalarOrEmpty, mustBePositive} = []
        options.NaNFlag {mustBeMember(options.NaNFlag,{'includemissing','includenan','omitmissing','omitnan'})} = 'includemissing'
        options.Endpoints {mustBeMember(options.Endpoints,{'shrink','discard','fill'})} = 'shrink'
        options.SamplePoints = []
        options.DataVariables = []
        options.ReplaceValues (1,1) logical = true
        
    end

    % Compile arguments to pass to movmean and movstd
    tabular = istable(x);
    discard = false;
    otherArgs = {};
    if ~isempty(options.Dimension)
        otherArgs = [otherArgs, {options.Dimension}];
    end
    if ~isempty(options.NaNFlag)
        otherArgs = [otherArgs, {options.NaNFlag}];
    end
    if strcmp(options.Endpoints,'discard')
        options.Endpoints = 'fill';
        if tabular
            warning('"Endpoints" value must be "shrink", "fill", or a numeric or logical value when the data is tabular. Using "fill" instead.')
        else
            discard = true;
        end
    end
    otherArgs = [otherArgs, {'Endpoints', options.Endpoints}];
    if ~isempty(options.SamplePoints)
        otherArgs = [otherArgs, {'SamplePoints', options.SamplePoints}];
    end
    if tabular
        if isempty(options.DataVariables)
            options.DataVariables = @isnumeric;
            warning(['No "DataVariables" specified. Calculating z-score on the numeric variable(s): ',...
                strjoin(x(:,vartype('numeric')).Properties.VariableNames,','),'.'])
        end
        otherArgs = [otherArgs, {'DataVariables', options.DataVariables}];
        if isa(options.DataVariables,'vartype')
            varNames = x(:,options.DataVariables).Properties.VariableNames;
        elseif isstring(options.DataVariables) || ischar(options.DataVariables)
            varNames = cellstr(options.DataVariables);
        elseif isnumeric(options.DataVariables) || islogical(options.DataVariables)
            varNames = x.Properties.VariableNames(options.DataVariables);
        elseif isa(options.DataVariables,'function_handle')
            varNums = cellfun(options.DataVariables,table2cell(x(1,:)));
            varNames = x.Properties.VariableNames(varNums);
        elseif iscell(options.DataVariables)
            varNames = options.DataVariables;
        else
            error('Unsupported data type for "DataVariables".');
        end
    else
        varNames = [];
    end

    % Compute moving mean
    mu = movmean(x, k, otherArgs{:});

    % Compute moving standard deviation
    sigma = movstd(x, k, options.Weight, otherArgs{:});

    % Compute moving z-score
    if tabular
        z = x;
        z(:,varNames) = (x(:,varNames)-mu(:,varNames))./sigma(:,varNames);
    else
        z = (x - mu)./sigma;
    end

    % Discard endpoint values (if applicable)
    if discard
        z = z(~isnan(z));
    end

    % Append z-score to table if "ReplaceValues" is false
    if ~options.ReplaceValues
        if iscell(varNames)
            renameVars = @(v,f) cellfun(@(v) [v,'_',f],v,'UniformOutput',false);
        else
            renameVars = @(v,f) [v,'_',f];
        end
        z(:,renameVars(varNames,'movzscore')) = z(:,varNames);
        z(:,varNames) = x(:,varNames);
    end
end