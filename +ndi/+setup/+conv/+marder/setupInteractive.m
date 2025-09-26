function S = setupInteractive(dirname)
    % SETUPINTERACTIVE - an interactive version of presetup
    %
    % S = SETUPINTERACTIVE(DIRNAME)
    %
    % Interactively sets up a Marderlab directory for import using NDI methods.
    %
    % Inputs:
    %   DIRNAME - The full path to the directory to be set up. Must be a valid folder.
    %             If not provided, the current working directory is used.
    %
    % Outputs:
    %   S - The NDI session object for the created/configured directory.
    %

    if nargin < 1 || isempty(dirname)
        dirname = pwd;
    end

    mustBeFolder(dirname);

    % Step 1: Create an NDI session
    [parentdir,this_dir] = fileparts(dirname);
    disp(['Setting up NDI session for directory: ' this_dir ' in ' parentdir]);
    S = ndi.setup.lab('marderlab',this_dir,dirname);
    disp('NDI session object created.');

    % Step 2: Call the subjectSetup method to set up subjects
    disp('Beginning interactive subject setup...');
    ndi.setup.conv.marder.subject.subjectSetup(dirname);
    disp('Interactive subject setup complete.');

    % Step 3: Leave space for NDI subjectMaker
    % TODO: Add NDI subjectMaker here

    % Step 4: Create the probeTable
    disp('Now, let''s create the probe table.');
    n_str = input('Enter the experiment number (e.g., 1): ', 's');
    n = str2double(n_str);
    if isnan(n) || floor(n) ~= n || n < 1
        error('Invalid experiment number. Please enter an integer >= 1.');
    end
    disp('Generating probeTable.csv...');
    ndi.setup.conv.marder.probeMap.abf2probetable(S,'forceIgnore2', n==1);
    probeTablePath = fullfile(dirname, 'probeTable.csv');
    if exist(probeTablePath, 'file')
        disp(['Probe table created at: ' probeTablePath]);
    else
        warning('ndi.setup.conv.marder.probeMap.abf2probetable did not seem to create probeTable.csv');
    end

    % Step 5: Leave space for an interactive editor for the probe table
    % TODO: Add interactive probe table editor here

    disp('Opening probeTable.csv for editing...');
    edit(probeTablePath);

    % Step 6: exit
    disp('Interactive setup finished.');

end % function