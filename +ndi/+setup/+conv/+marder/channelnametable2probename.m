function [probename, proberef, probetype, subjectname] = channelnametable2probename(chName, probetable, options)
    % CHANNELNAMETABLE2PROBENAME - Retrieve probe information from a probe table using a channel name.
    %
    % [PROBENAME, PROBEREF, PROBETYPE, SUBJECTNAME] = CHANNELNAMETABLE2PROBENAME(CHNAME, PROBETABLE)
    %
    % Searches a probe table for a given channel name and returns the corresponding
    % probe name, reference, type, and subject name.
    %
    % This function is a key component in mapping raw data channels to the
    % structured probe and subject information defined in a 'probeTable.csv' file.
    %
    % INPUTS:
    %   chName: (string) The channel name to look up in the probe table.
    %   probetable: (table) A MATLAB table containing probe information. It must
    %               include the columns "channelName", "probeName", "probeRef",
    %               "probeType", and "subject".
    %
    % OUTPUTS:
    %   probename: (string) The name of the probe.
    %   proberef: (double) The reference number of the probe.
    %   probetype: (string) The type of the probe (e.g., 'n-trode', 'sharp-Vm').
    %   subjectname: (string) The identifier of the subject associated with the probe.
    %
    % EXAMPLE:
    %   % Assume 'myProbeTable.csv' exists and is loaded into a table called 'pt'
    %   pt = readtable('myProbeTable.csv');
    %   chName = 'dgn_1';
    %   [p_name, p_ref, p_type, s_name] = ndi.setup.conv.marder.channelnametable2probename(chName, pt);
    %   % This will return the probe details for the 'dgn_1' channel.
    %
    % See also: readtable, ndi.setup.conv.marder.abf2probetable

    arguments
        chName
        probetable
        options.nothing = 0
    end

    i = find(strcmp(chName,probetable.("channelName")));

    if isempty(i)
        warning(['No match found.']);
    end

    probename = probetable{i,"probeName"};
    proberef = probetable{i,"probeRef"};
    probetype = probetable{i,"probeType"};
    subjectname = probetable{i,"subject"};
