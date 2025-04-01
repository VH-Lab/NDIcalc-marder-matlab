function z = movzscore(x,k,varargin)
%MOVZSCORE - Moving z-score
%
%   Returns the local k-point centered z-score, where each z-score is 
%   calculated over a sliding window of length k across neighboring 
%   elements of X.
%
%   Syntax
%       Z = MOVZSCORE(X,k)
%       Z = MOVZSCORE(X,[kb kf])     
%       Z = MOVZSCORE(___,dim)
%       Z = MOVZSCORE(___,nanflag)
%       Z = MOVZSCORE(___,Name,Value)
%
%   Input Arguments
%       X - Input data
%         vector | matrix | multidimensional array | table | timetable
%       k - Window length
%         numeric or duration scalar
%       [kb kf] - Directional window length
%         numeric or duration row vector containing two elements
%       dim - Dimension to operate along
%         positive integer scalar
%       nanflag - Missing value condition
%         "omitmissing" (default) | "omitnan" | "includemissing" |
%         "includenan"
%
%   Name-Value Arguments
%       Endpoints - Method to treat leading and trailing windows
%         "shrink" (default) | "discard" | "fill" | numeric or logical scalar
%       SamplePoints - Sample points for computing minimums
%         vector
%       DataVariables - Table or timetable variables to operate on
%         table or timetable variable name | scalar | vector | cell array |
%         pattern | function handle | table vartype subscript
%       ReplaceValues - Replace values indicator
%         true or 1 (default) | false or 0
%
%   See also MOVMEAN, MOVSTD
    
    % Check Name-Value arguments
    tabular = istable(x);
    discard = false;
    replace = true;
    for i = 1:length(varargin) - 1
        % Check for Endpoints argument
        if strcmp(varargin{i},'Endpoints') & strcmp(varargin{i+1},'discard')
            discard = true;
            varargin{i+1} = 'fill';
        end

        % Check for DataVariables argument
        if strcmp(varargin{i},'DataVariables')
            if isa(varargin{i+1},'vartype')
                varNames = x(:,vartype('numeric')).Properties.VariableNames;
            elseif isstring(varargin{i+1}) | ischar(varargin{i+1}) | ...
                    isobject(varargin{i+1})
                varNames = varargin{i+1};
            elseif isnumeric(varargin{i+1}) | islogical(varargin{i+1})
                varNames = x.Properties.VariableNames(varargin{i+1});
            elseif isa(varargin{i+1},'function_handle')
                varNums = cellfun(varargin{i+1},table2cell(x(1,:)));
                varNames = x.Properties.VariableNames(varNums);
            else
                error('Unsupported data type. Redefine ''DataVariables''.')
            end
        end

        % Check for ReplaceValues argument
        if strcmp(varargin{i},'ReplaceValues')
            replace = varargin{i+1};
            varargin{i+1} = true;
        end
    end

    % Compute moving mean
    mu = movmean(x,k,varargin{:});

    % Compute moving standard deviation
    w = 0;
    sigma = movstd(x,k,w,varargin{:});

    % Compute moving z-score
    if tabular
        z = x;
        z(:,varNames) = (x(:,varNames) - mu(:,varNames))./sigma(:,varNames);
    else
        z = (x - mu)./sigma;
    end

    % Discard endpoint values (if applicable)
    if discard
        z = z(~isnan(z));
    end

    % Append z-score to table if 'ReplaceValues' is false
    if ~replace
        if iscell(varNames)
            renameVars = @(v,f) cellfun(@(v) [v,'_',f],v,'UniformOutput',false);
        else
            renameVars = @(v,f) [v,'_',f];
        end
        z(:,renameVars(varNames,'movzscore')) = z(:,varNames);
        z(:,varNames) = x(:,varNames);
    end
end