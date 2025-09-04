function z = movzscore(x, k, options)
%MOVZSCORE - Moving z-score calculation.
%
%   Computes the moving z-score of the input data X using a sliding window.
%   The z-score is calculated for each element by centering and scaling
%   the element with the mean and standard deviation of its k neighbors.
%
%   Syntax:
%       Z = MOVZSCORE(X, k)
%           Calculates the moving z-score using a window of length k.
%
%       Z = MOVZSCORE(X, [kb kf])
%           Calculates the moving z-score using a directional window, where
%           kb is the number of elements before and kf is the number of
%           elements after the current element.
%
%       Z = MOVZSCORE(..., Options)
%           Specifies additional options using name-value pairs.
%
%   Input Arguments:
%       X - Input data.
%           Vector, matrix, multidimensional array, table, or timetable.
%
%       k - Window length.
%           Numeric or duration scalar.
%
%       [kb kf] - Directional window length.
%           Numeric or duration row vector containing two elements.
%           kb: Number of elements before the current element.
%           kf: Number of elements after the current element.
%
%       Options - Optional parameters specified as name-value pairs.
%           'Weight'        - Weight indicator for standard deviation.
%                             0 (default): Normalization by N-1.
%                             1: Normalization by N.
%
%           'Dimension'     - Dimension to operate along.
%                             Positive integer scalar.
%
%           'NaNFlag'       - Missing value handling.
%                             'includemissing' (default) or 'includenan': Include NaN/missing values.
%                             'omitmissing' or 'omitnan': Exclude NaN/missing values.
%
%           'Endpoints'     - Method to treat leading and trailing windows.
%                             'shrink' (default): Window shrinks at edges.
%                             'discard': Discard edge values (not supported for tables).
%                             'fill': Fill edge values with NaN.
%                             Numeric or logical scalar: Fill edge values with scalar.
%
%           'SamplePoints'  - Sample points for computation.
%                             Vector.
%
%           'DataVariables' - Table or timetable variables to operate on.
%                             Table variable name, scalar, vector, cell array,
%                             pattern, function handle, or table vartype subscript.
%                             Default: Numeric variables.
%
%           'ReplaceValues' - Replace original values with z-scores.
%                             true (default) or 1: Replace original values.
%                             false or 0: Append z-scores as new variables.
%
%   Output Arguments:
%       Z - Moving z-score.
%           Same type and size as X, or table/timetable with appended z-score
%           variables depending on the 'ReplaceValues' option.
%
%   Example:
%       x = randn(100, 1);
%       z = movzscore(x, 10); % Moving z-score with window length 10.
%
%       x = table(randn(10, 2), randn(10, 2), 'VariableNames', {'A', 'B', 'C', 'D'});
%       z = movzscore(x, 3, 'DataVariables', {'A', 'C'}, 'ReplaceValues', false);
%
%   See also: MOVMEAN, MOVSTD.
%
%   Notes:
%       - When 'Endpoints' is 'discard' and X is a table, 'Endpoints' is
%         automatically set to 'fill' with a warning.
%       - If 'DataVariables' is not specified for tables, numeric variables
%         are used by default.
%
%   Error Handling:
%       - 'MOVZSCORE:endpointsDiscardTabular' : When 'Endpoints' is 'discard' and X is a table.
%       - 'MOVZSCORE:defaultDataVariables' : When DataVariables is not specified for tables.
%       - 'MOVZSCORE:invalidDataVariables' : When DataVariables is an unsupported datatype.

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
            warning('MOVZSCORE:endpointsDiscardTabular', ...
                'The ''Endpoints'' value must be ''shrink'', ''fill'', or a numeric or logical value when the data is tabular. Using ''fill'' instead.');
        else
            discard = true;
        end
    end
    otherArgs = [otherArgs, {'Endpoints', options.Endpoints}];
    if ~isempty(options.SamplePoints)
        if isdatetime(options.SamplePoints) && ~isduration(k)
            error('MOVZSCORE:inconsistentUnits', 'Window length k must be duration when "SamplePoints" are datetime.');
        elseif ~isdatetime(options.SamplePoints) && isduration(k)
            error('MOVZSCORE:inconsistentUnits', 'Window length k must be numeric when "SamplePoints" are numeric.');
        end
        otherArgs = [otherArgs, {'SamplePoints', options.SamplePoints}];
    end
    if tabular
        if isempty(options.DataVariables)
            options.DataVariables = @isnumeric;
            warning('MOVZSCORE:defaultDataVariables', ...
                ['No "DataVariables" specified. Calculating z-score on the numeric variable(s): ',...
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
            error('MOVZSCORE:invalidDataVariables', 'Unsupported data type for ''DataVariables''.');
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