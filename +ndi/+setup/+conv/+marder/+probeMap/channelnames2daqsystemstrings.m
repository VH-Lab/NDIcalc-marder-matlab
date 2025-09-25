function [name, ref, daqsysstr,subjectlist] = channelnames2daqsystemstrings(chNames, daqname, subjects, options)
    % CHANNELNAMES2DAQSYSTEMSTRINGS - Convert channel names to NDI DAQ system strings and probe info.
    %
    % [NAME, REF, DAQSYSSTR, SUBJECTLIST] = CHANNELNAMES2DAQSYSTEMSTRINGS(CHNAMES, DAQNAME, SUBJECTS, [OPTIONS])
    %
    % This function processes a list of Marder Lab channel names, converts them
    % into standardized probe names, and generates corresponding NDI DAQ system
    % strings. It also assigns subject identifiers to each channel.
    %
    % A special case is handled for 'PhysiTemp' channels: if a temperature
    % channel is found and there are multiple subjects, it is duplicated and
    % assigned to the second subject as well.
    %
    % INPUTS:
    %   chNames: (cell array of strings) The list of channel names to process.
    %   daqname: (string) The name of the DAQ system (e.g., 'marder_abf').
    %   subjects: (cell array of strings) A list of subject identifiers.
    %   OPTIONS: (Optional) A struct with the following fields:
    %     forceIgnore2: (logical) If true, ignores '2' in channel names,
    %                   assigning them to the first subject. Default is false.
    %     channelnumbers: (array) An array of channel numbers to be used for
    %                     generating DAQ system strings. If empty, it defaults
    %                     to 1:numel(chNames).
    %
    % OUTPUTS:
    %   name: (cell array of strings) The standardized probe names.
    %   ref: (array) The reference numbers for each probe (always 1).
    %   daqsysstr: (ndi.daq.daqsystemstring array) The generated DAQ system strings.
    %   subjectlist: (cell array of strings) The subject identifier for each channel.
    %
    % EXAMPLE:
    %   chNames = {'dgn1_A', 'lvn2_A', 'PhysiTemp'};
    %   daqname = 'marder_abf';
    %   subjects = {'crab1', 'crab2'};
    %   [n, r, d, s] = ndi.setup.conv.marder.probeMap.channelnames2daqsystemstrings(chNames, daqname, subjects);
    %   % This will return probe names, references, DAQ strings, and subjects
    %   % for each channel, including a duplicated PhysiTemp for the second crab.
    %
    % See also: ndi.setup.conv.marder.probeMap.channelname2probename, ndi.daq.daqsystemstring

    arguments
        chNames
        daqname
        subjects
        options.forceIgnore2 = false
        options.channelnumbers = []
    end

    name = {};
    ref = [];
    subjectlist = {};

    if isempty(options.channelnumbers)
        options.channelnumbers = 1:numel(chNames);
    end

    hasPhysio = 0;

    for i=1:numel(chNames)
        if i==1
            daqsysstr = ndi.daq.daqsystemstring(daqname, {'ai'}, options.channelnumbers(i));
        else
            daqsysstr(end+1) = ndi.daq.daqsystemstring(daqname, {'ai'}, options.channelnumbers(i));
        end
        [name{i},ref(i),subjectlist{i}] = ndi.setup.conv.marder.probeMap.channelname2probename(chNames{i},subjects,...
            'forceIgnore2',options.forceIgnore2);
        if strcmp(name{i},'PhysiTemp_1')
            hasPhysio = options.channelnumbers(i);
        end
    end

    if hasPhysio & numel(subjects)>1 % add it to any second prep
        daqsysstr(end+1) = ndi.daq.daqsystemstring(daqname, {'ai'}, hasPhysio);
        name{end+1} = 'PhysiTemp_2';
        ref(i+1) = 1;
        subjectlist{end+1} = subjects{2};
    end
