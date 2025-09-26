function probetable = abf2probetable(S, options)
    % ABF2PROBETABLE - Create a probetable from Axon Binary Files (ABF).
    %
    % PROBETABLE = ABF2PROBETABLE(S, [OPTIONS])
    %
    % Creates a Matlab table object ('probetable') for a Marder Lab NDI session
    % by reading metadata from all Axon Binary Files (*.abf) in the session directory.
    % The function identifies channel information, probe types, and subject
    % associations to create a comprehensive probe table.
    %
    % This function assumes that the NDI session `S` has been created and that
    % the session path contains the ABF files. It also relies on 'subject*.txt'
    % files to identify the subjects for the experiment.
    %
    % INPUTS:
    %   S: An NDI_SESSION object representing the Marder Lab session.
    %   OPTIONS: (Optional) A struct with the following fields:
    %     forceIgnore2: (logical) If true, forces the function to ignore the
    %                   second character in channel names when mapping to probe
    %                   information. Default is false.
    %     defaultProbeType: (string) The default probe type to use when a
    %                       channel cannot be identified. Can be 'n-trode' or
    %                       'ppg'. Default is 'n-trode'.
    %
    % OUTPUTS:
    %   PROBETABLE: A Matlab table with the following columns:
    %     - channelName: The name of the channel from the ABF file.
    %     - probeName: The standardized name of the probe.
    %     - probeRef: The reference number for the probe.
    %     - probeType: The type of probe (e.g., 'sharp-Vm', 'n-trode').
    %     - subject: The identifier for the subject associated with the probe.
    %     - firstAppears: The name of the ABF file where the channel first appears.
    %
    % EXAMPLE:
    %   % Create a new Marder Lab session
    %   ref = 'ML001';
    %   dirname = '/path/to/marder/data';
    %   S = ndi.setup.lab('marderlab', ref, dirname);
    %   % Create the probe table
    %   probetable = ndi.setup.conv.marder.probeMap.abf2probetable(S);
    %   % Write the table to a file
    %   writetable(probetable, [dirname filesep 'probeTable.csv']);
    %
    % See also: ndi.setup.lab, ndi.setup.conv.marder.probeMap.channelnames2daqsystemstrings
    %

    arguments
        S (1,1)
        options.forceIgnore2 = false
        options.defaultProbeType {mustBeMember(options.defaultProbeType,{'n-trode','ppg'})} = 'n-trode'
    end

    dirname = S.getpath();

    d = dir([dirname filesep '*.abf']);

    s = dir([dirname filesep  'subje*.txt']);

    subject = cell(1,numel(s));
    for i=1:numel(s)
        subject{i} = fileread([dirname filesep s(i).name]);
    end

    cols = {'channelName','probeName','probeRef','probeType','subject','firstAppears'};
    datatypes = {'string','string','double','string','string','string'};

    probetable = table('Size',[0 numel(cols)],'VariableNames',cols,'VariableTypes',datatypes);

    for i=1:numel(d)
        h = ndr.format.axon.read_abf_header([dirname filesep d(i).name]);
        [name,ref,~,subjectlist] = ndi.setup.conv.marder.probeMap.channelnames2daqsystemstrings(h.recChNames,'marder_abf',subject,...
            'forceIgnore2',options.forceIgnore2);
        for j=1:numel(name)
            if j<=numel(h.recChNames)
                if isempty(find(strcmp(h.recChNames{j},probetable.("channelName")),1))
                    if any(lower(h.recChNames{j})=='a') && any(lower(h.recChNames{j})=='v')
                        probeType = 'sharp-Vm';
                        name{j} = 'XP';
                    elseif any(lower(h.recChNames{j})=='a') && any(lower(h.recChNames{j})=='i')
                        probeType = 'sharp-Im';
                        name{j} = 'XP';
                    elseif ~isempty(findstr(lower(h.recChNames{j}),'temp'))
                        probeType = 'thermometer';
                    else
                        probeType = options.defaultProbeType;
                    end
                    probetable_new = cell2table({ h.recChNames{j} name{j} ref(j) probeType subjectlist{j} d(i).name},...
                        'VariableNames',cols);
                    probetable = cat(1,probetable,probetable_new);
                end
            % else, probetable_new = cell2table({ 'nothing' name{j} ref(j) 'unknown' subjectlist{j} d(i).name},...
            %             'VariableNames',cols);
            end
         end
    end
