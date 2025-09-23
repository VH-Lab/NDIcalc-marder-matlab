function makesubjects(S, n)
    % MAKESUBJECTS - Create subject text files for an NDI session.
    %
    % MAKESUBJECTS(S, N)
    %
    % Creates 'subjectN.txt' files for a specified number of subjects in the
    % NDI session directory. Each file contains a unique subject identifier based
    % on the session directory name and the subject number.
    %
    % These files are used by other setup functions to identify and link data
    % to the correct subjects.
    %
    % INPUTS:
    %   S: (ndi.session) The NDI session object.
    %   N: (integer) The number of subjects to create.
    %
    % OUTPUTS:
    %   This function does not return any values but writes 'subject1.txt',
    %   'subject2.txt', etc., to the session directory.
    %
    % EXAMPLE:
    %   % Assuming S is a valid NDI session object for a directory named 'my_exp'
    %   ndi.setup.conv.marder.makesubjects(S, 2);
    %   % This will create 'subject1.txt' with content 'my_exp_01@marderlab.brandeis.edu'
    %   % and 'subject2.txt' with content 'my_exp_02@marderlab.brandeis.edu'.
    %
    % See also: ndi.setup.conv.marder.abf2probetable, ndi.setup.conv.marder.abfepochprobemap

    dirname = S.path();

    [parentdir,this_dir] = fileparts(dirname);

    for i=1:n
        vlt.file.str2text(...
            [dirname filesep 'subject' int2str(i) '.txt'], ...
            [this_dir '_' sprintf('%.2d',i) '@marderlab.brandeis.edu']);

    end
