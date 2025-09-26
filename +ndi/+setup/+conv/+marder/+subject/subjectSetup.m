function subjectSetup(directory)
    % NDI.SETUP.CONV.MARDER.SUBJECT.SUBJECTSETUP - An interactive program to set up subject files for Marder lab conversion.
    %
    %   NDI.SETUP.CONV.MARDER.SUBJECT.SUBJECTSETUP([DIRECTORY])
    %
    %   Takes as input a directory (default: the pwd) and builds subjectN.txt files
    %   to facilitate Marder lab conversion.
    %
    %   It asks the user a few questions in a loop.
    %
    %   First, it tells the user which directory is being worked on and prints the
    %   existing contents of subjectN.txt files (for N = 1 .. whatever exists).
    %
    %   Then, it asks the user if they want to:
    %     a) Add a crab
    %     b) Add a lobster
    %     c) Exit
    %
    %   If they add a crab or lobster, it asks for the preparation number.
    %
    %   Then, it creates a text file called subjectM.txt (where M is N+1, or 1 if
    %   there are no files) that has the contents
    %   'gdy_####@marderlab.brandeis.edu', where #### expresses the preparation
    %   number as a 4 digit integer (e.g., 0013). If the subject is a lobster,
    %   then it is 'gdy_lobsterNNN@marderlab.brandeis.edu', where NNN is a 3-digit integer.
    %

    if nargin < 1 || isempty(directory)
        directory = pwd;
    end

    disp(['Working on directory: ' directory]);

    function display_subjects()
        subject_files = dir(fullfile(directory, 'subject*.txt'));

        disp(' ');
        disp('Existing subject files:');
        if isempty(subject_files)
            disp('  None');
        else
            for i = 1:numel(subject_files)
                try
                    content = strtrim(fileread(fullfile(directory, subject_files(i).name)));
                    disp(['  ' subject_files(i).name ': ' content]);
                catch
                    disp(['  Could not read ' subject_files(i).name]);
                end
            end
        end
    end

    function next_num = get_next_subject_num()
        subject_files = dir(fullfile(directory, 'subject*.txt'));
        next_num = 1;
        if ~isempty(subject_files)
            nums = [];
            for i = 1:numel(subject_files)
                [~, name, ~] = fileparts(subject_files(i).name);
                num_str = sscanf(name, 'subject%d');
                if ~isempty(num_str)
                    nums(end+1) = num_str;
                end
            end
            if ~isempty(nums)
                next_num = max(nums) + 1;
            end
        end
    end

    while true
        display_subjects();

        next_subject_num = get_next_subject_num();

        disp(' ');
        disp('Choose an option:');
        disp('  a) Add a crab');
        disp('  b) Add a lobster');
        disp('  c) Exit');

        choice = lower(input('Enter your choice: ', 's'));

        if isempty(choice) || ~ismember(choice, {'a','b','c'})
            disp('Invalid choice. Please try again.');
            continue;
        end

        if strcmp(choice, 'c')
            disp('Exiting.');
            break;
        end

        prep_num_str = input('Enter the preparation number: ', 's');
        prep_num = str2double(prep_num_str);

        if isnan(prep_num) || floor(prep_num) ~= prep_num
            disp('Invalid preparation number. Please enter an integer.');
            continue;
        end

        subject_str = '';
        if strcmp(choice, 'a') % Crab
            subject_str = sprintf('gdy_%04d@marderlab.brandeis.edu', prep_num);
        elseif strcmp(choice, 'b') % Lobster
            subject_str = sprintf('gdy_lobster%03d@marderlab.brandeis.edu', prep_num);
        end

        new_filename = fullfile(directory, sprintf('subject%d.txt', next_subject_num));

        try
            fid = fopen(new_filename, 'w');
            if fid == -1
                error(['Could not open file ' new_filename ' for writing.']);
            end
            fprintf(fid, '%s\n', subject_str);
            fclose(fid);

            disp(['Successfully created ' new_filename]);
            next_subject_num = next_subject_num + 1; % Increment for the next potential addition
        catch e
            disp(['Error creating file: ' e.message]);
        end
    end
end
