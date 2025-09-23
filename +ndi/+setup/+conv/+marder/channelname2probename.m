function [probename, proberef, subjectname] = channelname2probename(chName, subjects, options)
    % CHANNELNAME2PROBENAME - Convert a Marder Lab channel name to a standardized probe name.
    %
    % [PROBENAME, PROBEREF, SUBJECTNAME] = CHANNELNAME2PROBENAME(CHNAME, SUBJECTS, [OPTIONS])
    %
    % Converts a raw channel name from a Marder Lab recording (e.g., 'DGN1_A',
    % 'lvn', 'lvn2') into a standardized probe name, probe reference number, and
    % associated subject name.
    %
    % This function identifies the subject by searching for '1' or '2' in the
    % channel name. If neither is found, it defaults to the first subject.
    %
    % INPUTS:
    %   chName: (string) The channel name to be converted.
    %   subjects: (cell array of strings) A list of subject identifiers.
    %   OPTIONS: (Optional) A struct with the following fields:
    %     forceIgnore2: (logical) If true, ignores '2' in the channel name
    %                   and assigns the channel to the first subject. Default is false.
    %
    % OUTPUTS:
    %   probename: (string) The standardized probe name (e.g., 'dgn_1', 'lvn_2').
    %              If no standard name is found, it returns a MATLAB-validated
    %              version of the input channel name.
    %   proberef: (double) The reference number for the probe, always 1.
    %   subjectname: (string) The identifier of the subject associated with the channel.
    %
    % EXAMPLE:
    %   subjects = {'crab1', 'crab2'};
    %   [p_name, p_ref, s_name] = ndi.setup.conv.marder.channelname2probename('dgn2_A', subjects)
    %   % p_name = 'dgn_2'
    %   % p_ref = 1
    %   % s_name = 'crab2'
    %

    arguments
        chName
        subjects
        options.forceIgnore2 = false;
    end

    probename = '';
    proberef = 1;

    % look for a 1 or a 2

    theintegers = cellfun(@str2num,regexp(chName,'\d+','match'));

    hasone = ismember(theintegers,1);
    hastwo = ismember(theintegers,2);
    if isempty(hasone)
        hasone = false;
    end
    if isempty(hastwo)
        hastwo = false;
    end

    if hasone&hastwo
        error(['Do not know how to proceed with both 1 and 2 in string ' chName '.']);
    end

    if ~hastwo | options.forceIgnore2
        channel_str = '1';
        subjectname = subjects{1};
    elseif hastwo
        channel_str = '2';
        subjectname = subjects{2};
    end

    standard_strings = {'dgn','lgn','lvn','pdn','pyn','mvn','PhysiTemp'};

    for i=1:numel(standard_strings)
        if ~isempty(findstr(lower(chName),lower(standard_strings{i})))
            probename = [standard_strings{i} '_' channel_str];
            break;
        end
    end

    if isempty(probename) % did not match standard_string,
        probename = matlab.lang.makeValidName(chName);
    end
