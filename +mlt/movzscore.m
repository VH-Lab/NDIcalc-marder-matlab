function z = movzscore(x, k, dim, options)
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
%         Endpoints - Method to treat leading and trailing windows
%           "shrink" (default) | "discard" | "fill" | numeric or logical scalar
%         Dimension - Dimension to operate along
%           positive integer scalar
%         NaNFlag - Missing value condition
%           "omitmissing" (default) | "omitnan" | "includemissing" |
%           "includenan"
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
        k
        options.Endpoints {mustBeMember(options.Endpoints,{'shrink','discard','fill'})} = 'shrink'
        options.Dimension {mustBeInteger, mustBeScalarOrEmpty, mustBePositive} = []
        options.NaNFlag {mustBeMember(options.NaNFlag,{'omitmissing','omitnan','includemissing','includenan'})} = 'omitmissing'
        options.SamplePoints = []
        options.DataVariables = []
        options.ReplaceValues (1,1) logical = true
    end

    tabular = istable(x);
    discard = strcmp(options.Endpoints, 'discard');
    replace = options.ReplaceValues;
    otherArgs = {};

    if ~isempty(options.Dimension)
        otherArgs = [otherArgs, {'Dimension', options.Dimension}];
    end
    if ~isempty(options.NaNFlag)
        otherArgs = [otherArgs, {'NaNFlag', options.NaNFlag}];
    end
    if ~isempty(options.SamplePoints)
        otherArgs = [otherArgs, {'SamplePoints', options.SamplePoints}];
    end
    if ~isempty(options.Endpoints) && ~strcmp(options.Endpoints, 'discard') % 'discard' is handled separately
        otherArgs = [otherArgs, {'Endpoints', options.Endpoints}];
    end

    if tabular && ~isempty(options.DataVariables)
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
            error('Unsupported data type for ''DataVariables''.');
        end
    elseif tabular
        varNames = x.Properties.VariableNames(vartype('numeric'));
    else
        varNames = [];
    end

    % Compute moving mean
    mu = movmean(x, k, otherArgs{:});

    % Compute moving standard deviation
    w = 0;
    sigma = movstd(x, k, w, otherArgs{:});

    % Compute moving z-score
    if tabular
        z = x;
        if ~isempty(varNames)
            for i = 1:numel(varNames)
                z.(varNames{i}) = (x.(varNames{i}) - mu.(varNames{i})) ./ sigma.(varNames{i});
            end
        end
    else
        z = (x - mu) ./ sigma;
    end

    % Discard endpoint values (if applicable)
    if discard
        if tabular && ~isempty(varNames)
            % Need to handle table case for discard
            sz = size(z);
            if ~isempty(options.Dimension) && options.Dimension <= ndims(z)
                idx = cell(1,ndims(z));
                for iDim = 1:ndims(z)
                    if iDim == options.Dimension
                        idx{iDim} = k(1)+1:sz(iDim)-k(end);
                    else
                        idx{iDim} = 1:sz(iDim);
                    end
                end
                z = z(idx{:});
            elseif isvector(z)
                z = z(k(1)+1:end-k(end));
            else
                warning('Discarding endpoints for tables without a specified dimension might not behave as expected.');
                % For a general table without dimension, it's hard to define what "endpoints" mean.
                % A simple approach would be to convert to array, discard, and convert back,
                % but this might lose table structure. For now, we might skip or issue a more specific warning.
            end
        else
            if isvector(z)
                z = z(k(1)+1:end-k(end));
            else
                % For multidimensional arrays, discarding without dimension is not well-defined.
                warning('Discarding endpoints for multidimensional arrays without a specified dimension might not behave as expected.');
            end
        end
    end

    % Append z-score to table if 'ReplaceValues' is false
    if tabular && ~replace && ~isempty(varNames)
        renameVars = @(v, f) cellfun(@(vv) [vv, '_', f], cellstr(v), 'UniformOutput', false);
        newVarNames = renameVars(varNames, 'movzscore');
        for i = 1:numel(varNames)
            z.(newVarNames{i}) = (x.(varNames{i}) - mu.(varNames{i})) ./ sigma.(varNames{i});
        end
    elseif tabular && ~replace && isempty(varNames)
        warning('No numeric variables found to create moving z-score columns.');
    end
end

