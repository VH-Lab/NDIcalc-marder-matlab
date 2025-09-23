function preptemptable(S)
    % PREPTEMPTABLE - Create and save a temperature analysis table for an NDI session.
    %
    % PREPTEMPTABLE(S)
    %
    % Analyzes temperature data for all 'thermometer' probes in an NDI session.
    % For each epoch of each thermometer probe, it reads the temperature time
    % series and uses `ndi.setup.conv.marder.preptemp` to classify the
    % temperature profile as 'constant' or 'change' and identify the command
    % temperatures.
    %
    % The results are compiled into a table and saved as 'temptable.mat' in the
    % session directory.
    %
    % INPUTS:
    %   S: (ndi.session) The NDI session object.
    %
    % OUTPUTS:
    %   This function does not return any values but writes a 'temptable.mat'
    %   file in the session directory. The file contains a single table variable
    %   named 'temptable' with the following columns:
    %     - probe_id: The ID of the thermometer probe.
    %     - epoch_id: The ID of the recording epoch.
    %     - type: 'constant' or 'change'.
    %     - temp: The identified command temperature(s).
    %     - raw: The raw averaged temperature(s).
    %
    % EXAMPLE:
    %   % Assuming S is a valid NDI session with thermometer probes and data
    %   ndi.setup.conv.marder.preptemptable(S);
    %   % This will create 'temptable.mat' in the session directory.
    %   load(fullfile(S.getpath(), 'temptable.mat'));
    %   disp(temptable);
    %
    % See also: ndi.setup.conv.marder.preptemp, save, load

    dirname = S.path();

    standard_temps = [ 7:4:31] ;

    cols = {'probe_id','epoch_id','type','temp','raw'};
    datatypes = {'string','string','string','cell','cell'};

    temptable = table('size',[0 numel(cols)],'VariableNames',cols,'VariableTypes',datatypes);

    p = S.getprobes('type','thermometer');

    for P = 1:numel(p)
        et = p{P}.epochtable();
        for j=1:numel(et)
            [D,t] = p{P}.readtimeseries(et(j).epoch_id,-Inf,Inf);
            out = ndi.setup.conv.marder.preptemp(t,D,standard_temps);
            newtable = cell2table({ p{P}.id() et(j).epoch_id out.type mat2cell(out.temp,1) mat2cell(out.raw,1)},...
                'VariableNames',cols);
            temptable = cat(1,temptable,newtable);
        end
    end

    save([dirname filesep 'temptable.mat'],'temptable','-mat');
