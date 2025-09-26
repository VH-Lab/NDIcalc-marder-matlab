function abfepochprobemap(S, options)
    % ABFEPOCHPROBEMAP - Create epochprobemap files from Axon Binary Files (ABF).
    %
    % ABFEPOCHPROBEMAP(S, [OPTIONS])
    %
    % Creates '.epochprobemap.txt' files for a Marder Lab NDI session by reading
    % metadata from all Axon Binary Files (*.abf) in the session directory.
    % These map files link recording channels to probe information for each epoch.
    %
    % This function assumes that the NDI session `S` has been created and that
    % the session path contains the ABF files. It also relies on 'subject*.txt'
    % files to identify the subjects for the experiment and adds them to the NDI
    % database if they do not already exist.
    %
    % INPUTS:
    %   S: An NDI_SESSION object representing the Marder Lab session.
    %   OPTIONS: (Optional) A struct with the following fields:
    %     forceIgnore2: (logical) If true, forces the function to ignore the
    %                   second character in channel names when mapping to probe
    %                   information, preventing misinterpretation as a second prep.
    %                   Default is false.
    %
    % OUTPUTS:
    %   This function does not return any values but writes a
    %   '.epochprobemap.txt' file for each ABF file in the session directory.
    %   These files define the relationship between data channels and experimental
    %   probes for each recording epoch.
    %
    % EXAMPLE:
    %   % Create a new Marder Lab session
    %   ref = 'ML001';
    %   dirname = '/path/to/marder/data';
    %   S = ndi.setup.lab('marderlab', ref, dirname);
    %   % Create the epochprobemap files
    %   ndi.setup.conv.marder.probeMap.abfepochprobemap(S);
    %
    % See also: ndi.setup.lab, ndi.epoch.epochprobemap_daqsystem, ndr.format.axon.read_abf_header
    %

    arguments
        S (1,1)
        options.forceIgnore2 = false
    end

    dirname = S.getpath();

    d = dir([dirname filesep '*.abf']);

    s = dir([dirname filesep  'subje*.txt']);

    subject = {};
    for i=1:numel(s)
        subject{i} = fileread([dirname filesep s(i).name]);
        mysub = S.database_search(ndi.query('subject.local_identifier','exact_string',subject{i}));
        if isempty(mysub)
            mysub = ndi.subject(subject{i},['Crab from Eve Marder Lab at Brandeis']);
            mysubdoc = mysub.newdocument + S.newdocument();
            S.database_add(mysubdoc);
        end
    end

    for i=1:numel(d)
        h = ndr.format.axon.read_abf_header([dirname filesep d(i).name]);
        [name,ref,daqsysstr,subjectlist] = ndi.setup.conv.marder.probeMap.channelnames2daqsystemstrings(h.recChNames,'marder_abf',subject,...
            'forceIgnore2',options.forceIgnore2);
        for j=1:numel(name)
            if j==1
                probemap = ndi.epoch.epochprobemap_daqsystem(name{j},ref(j),'n-trode',daqsysstr(j).devicestring(),subjectlist{j});
            else
                probemap(end+1) = ndi.epoch.epochprobemap_daqsystem(name{j},ref(j),'n-trode',daqsysstr(j).devicestring(),subjectlist{j});
            end
        end
        [myparent,myfile,myext] = fileparts([dirname filesep d(i).name]);
        probemap.savetofile([dirname filesep myfile '.epochprobemap.txt']);
    end
