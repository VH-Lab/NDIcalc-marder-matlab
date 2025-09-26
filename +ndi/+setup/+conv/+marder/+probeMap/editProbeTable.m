function editProbeTable(S)
    % An interactive probe table editor for probe tables created by abf2probetable.m
    % This script allows users to edit a probe table through a text-based interface.

    arguments
        S (1,1) ndi.session
    end

    sessionPath = S.path;

    % Construct the probe table file path
    probeTableFile = fullfile(sessionPath, 'probeTable.csv');

    if ~exist(probeTableFile, 'file')
        error('probeTable.csv not found in %s. Please create it first.', sessionPath);
    end

    % Read the probe table, specifying the delimiter
    probeTable = readtable(probeTableFile, 'Delimiter', ',');

    % Find and read all subject files (subject1.txt, subject2.txt, etc.)
    subjectFiles = dir(fullfile(sessionPath, 'subject*.txt'));
    subjects = {};
    for i = 1:numel(subjectFiles)
        subjects = [subjects; readlines(fullfile(sessionPath, subjectFiles(i).name))];
    end
    % remove any empty lines and duplicates
    subjects = subjects(strlength(subjects) > 0);
    subjects = unique(subjects, 'stable');

    if isempty(subjects)
        warning('No subjects found in subject*.txt files in %s.', sessionPath);
    end


    % Main interactive loop
    while true
        % Display the table with line numbers
        disp('Current Probe Table:');
        % Create a sequence of numbers from 1 to the number of rows
        rowNumbers = 1:height(probeTable);
        % Convert numbers to a cell array of strings and assign as RowNames
        probeTable.Properties.RowNames = cellstr(num2str(rowNumbers'));
        disp(probeTable);

        % Ask the user what to do
        fprintf('\nWhat would you like to do?\n');
        fprintf('  e - Edit a line\n');
        fprintf('  s - Save and quit\n');
        fprintf('  q - Quit without saving\n');
        choice = input('Enter your choice: ', 's');

        switch lower(choice)
            case 'e'
                % Edit a line
                probeTable = editLine(probeTable, subjects);
            case 's'
                % Save and quit
                writetable(probeTable, probeTableFile);
                disp('Table saved. Exiting.');
                break;
            case 'q'
                % Quit without saving
                disp('Exiting without saving. Changes are not saved.');
                break;
            otherwise
                disp('Invalid choice. Please try again.');
        end
    end
end

function probeTable = editLine(probeTable, subjects)
    % Get the line number to edit
    lineNumStr = input('Enter the line number to edit: ', 's');
    lineNum = str2double(lineNumStr);

    % Validate the line number
    if isnan(lineNum) || lineNum < 1 || lineNum > height(probeTable)
        disp('Invalid line number.');
        return;
    end

    % Check if the probe is a stimulator
    if strcmp(probeTable.probeName{lineNum}, 'stimulator')
        disp('Stimulator probes are not editable.');
        return;
    end

    % Loop for editing options
    while true
        fprintf('\nEditing line %d:\n', lineNum);
        T_temp = probeTable(lineNum, :);
        T_temp.Properties.RowNames = {num2str(lineNum)};
        disp(T_temp);
        fprintf('  a) Set the subject\n');
        fprintf('  b) Set the probe name\n');
        fprintf('  c) Set the probe reference number\n');
        fprintf('  d) Set the probe type\n');
        fprintf('  e) Exit to the table viewer\n');
        editChoice = input('Enter your choice: ', 's');

        switch lower(editChoice)
            case 'a'
                % Set the subject
                probeTable = setSubject(probeTable, lineNum, subjects);
            case 'b'
                % Set the probe name
                probeTable = setProbeName(probeTable, lineNum);
            case 'c'
                % Set the probe reference number
                probeTable = setProbeRefNum(probeTable, lineNum);
            case 'd'
                % Set the probe type
                probeTable = setProbeType(probeTable, lineNum);
            case 'e'
                % Exit to table viewer
                return;
            otherwise
                disp('Invalid choice. Please try again.');
        end
    end
end

function probeTable = setSubject(probeTable, lineNum, subjects)
    disp('Available subjects:');
    for i = 1:numel(subjects)
        fprintf('  %d) %s\n', i, subjects{i});
    end
    subjectChoiceStr = input('Choose a subject: ', 's');
    subjectChoice = str2double(subjectChoiceStr);

    if ~isnan(subjectChoice) && subjectChoice >= 1 && subjectChoice <= numel(subjects)
        probeTable.subject{lineNum} = subjects{subjectChoice};
        disp('Subject updated.');
    else
        disp('Invalid choice.');
    end
end

function probeTable = setProbeName(probeTable, lineNum)
    probeNames = {'ppg_heart', 'ppg_pylorus', 'ppg_gastric'};
    disp('Available probe names:');
    for i = 1:numel(probeNames)
        fprintf('  %d) %s\n', i, probeNames{i});
    end
    nameChoiceStr = input('Choose a probe name: ', 's');
    nameChoice = str2double(nameChoiceStr);

    if ~isnan(nameChoice) && nameChoice >= 1 && nameChoice <= numel(probeNames)
        probeTable.probeName{lineNum} = probeNames{nameChoice};
        disp('Probe name updated.');
    else
        disp('Invalid choice.');
    end
end

function probeTable = setProbeRefNum(probeTable, lineNum)
    refNumStr = input('Enter a new reference number (must be an integer > 0): ', 's');
    refNum = str2double(refNumStr);

    if ~isnan(refNum) && refNum > 0 && floor(refNum) == refNum
        probeTable.probeRef(lineNum) = refNum;
        disp('Reference number updated.');
    else
        disp('Invalid reference number.');
    end
end

function probeTable = setProbeType(probeTable, lineNum)
    probeTypes = {'n-trode', 'ppg'};
    disp('Available probe types:');
    for i = 1:numel(probeTypes)
        fprintf('  %d) %s\n', i, probeTypes{i});
    end
    typeChoiceStr = input('Choose a probe type: ', 's');
    typeChoice = str2double(typeChoiceStr);

    if ~isnan(typeChoice) && typeChoice >= 1 && typeChoice <= numel(probeTypes)
        probeTable.probeType{lineNum} = probeTypes{typeChoice};
        disp('Probe type updated.');
    else
        disp('Invalid choice.');
    end
end