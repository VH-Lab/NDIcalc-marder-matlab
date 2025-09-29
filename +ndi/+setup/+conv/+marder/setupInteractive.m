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

    % Step 4: Create or update the probeTable
    disp('Now, let''s create or update the probe table.');
    probeTableFileName = fullfile(dirname, 'probeTable.csv');

    if exist(probeTableFileName, 'file')
        disp('An existing probeTable.csv file was found:');
        probeTableExisting = readtable(probeTableFileName);
        disp(probeTableExisting);

        choice = '';
        while ~any(strcmpi(choice,{'a','b','c'}))
            choice = input('Choose an option: (a) keep it, (b) re-do from scratch, or (c) freshen: ', 's');
        end

        switch lower(choice)
            case 'a'
                disp('Keeping the existing probe table.');
                probeTable = probeTableExisting;
            case 'b'
                disp('Re-doing the probe table from scratch...');
                probeTable = ndi.setup.conv.marder.probeMap.abf2probetable(S,'forceIgnore2', true,'defaultProbeType','ppg');
                writetable(probeTable, probeTableFileName);
                disp('New probe table file written.');
            case 'c'
                disp('Freshening the probe table...');
                probeTableNew = ndi.setup.conv.marder.probeMap.abf2probetable(S,'forceIgnore2', true,'defaultProbeType','ppg');
                probeTable = ndi.setup.conv.marder.probeMap.freshen(probeTableExisting, probeTableNew);
                writetable(probeTable, probeTableFileName);
                disp('Freshened probe table file written.');
        end
    else
        disp('No existing probeTable.csv found. Generating a new one...');
        probeTable = ndi.setup.conv.marder.probeMap.abf2probetable(S,'forceIgnore2', true,'defaultProbeType','ppg');
        writetable(probeTable, probeTableFileName);
        if exist(probeTableFileName, 'file')
            disp(['New probe table created at: ' probeTableFileName]);
        else
            warning('ndi.setup.conv.marder.probeMap.abf2probetable did not seem to create probeTable.csv');
        end
    end

    % Step 5: Optionally edit the probe table
    editChoice = '';
    while ~any(strcmpi(editChoice,{'y','n'}))
        editChoice = input('Would you like to edit the probe table now? (y/n): ', 's');
    end

    if strcmpi(editChoice, 'y')
        disp('Opening probe table editor...');
        probeTable = ndi.setup.conv.marder.probeMap.editProbeTable(probeTable, S);
        writetable(probeTable, probeTableFileName);
        disp('Probe table changes saved.');
    else
        disp('Skipping probe table editing.');
    end

    % Step 6: exit
    disp('Interactive setup finished.');

end % function