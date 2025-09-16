function beats = heartBeatData(S, ppg_beats_doc)
%MLT.DOC.HEARTBEATDATA Retrieves heart beat data from an NDI document with datetime conversion.
%
%   BEATS = mlt.doc.heartBeatData(S, PPG_BEATS_DOC)
%
%   This function accesses the beat information stored in a 'ppg_beats' NDI
%   document.
%
%   A key feature of this function is its handling of time. It inspects the
%   epoch's clock information from the element the document depends on. If a
%   global time clock (e.g., 'exp_global_time') is available for the epoch,
%   the time fields within the returned BEATS structure (e.g., '.onset', '.offset')
%   are converted to MATLAB `datetime` objects. If no global clock is found,
%   these timestamps remain as numeric values in seconds from the start of the epoch.
%
%   Inputs:
%       S               - An ndi.session or ndi.dataset object.
%       PPG_BEATS_DOC   - An 'ppg_beats' ndi.document object.
%
%   Outputs:
%       BEATS           - A structure array where each element represents a
%                         detected beat. Time-related fields will be `datetime`
%                         objects if a global clock is present, otherwise they
%                         will be numeric (seconds).
%
%   Example:
%       % Assume 'mySession' is a valid NDI session object and we have found
%       % a 'ppg_beats' document.
%
%       e = mySession.getelements('element.name', 'ppg_heart_lp_whole', 'element.reference', 1);
%       et = e{1}.epochtable();
%       ppg_beats_doc = ndi.database.fun.finddocs_elementEpochType(mySession, ...
%           e{1}.id(), et(1).epoch_id, 'ppg_beats');
%
%       if ~isempty(ppg_beats_doc)
%           beats_with_datetime = mlt.doc.heartBeatData(mySession, ppg_beats_doc{1});
%
%           % Check the class of the onset time for the first beat
%           disp(['Class of beat onset time: ' class(beats_with_datetime(1).onset)]);
%       end
%
%   See also: mlt.beats.beatsdoc2struct, ndi.time.syncgraph.time_convert

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    ppg_beats_doc (1,1) {mustBeA(ppg_beats_doc,'ndi.document')}
end

% Step 1: Extract beats data from the document
% The timestamps in this struct are initially in seconds from the epoch's local start time.
beats = mlt.beats.beatsdoc2struct(S, ppg_beats_doc);

% Step 2: Get the associated element and epoch information to check for a global clock
element_id = ppg_beats_doc.dependency_value('element_id');
e_cell = S.database_search(ndi.query('base.id','exact_string',element_id));
if isempty(e_cell)
    error(['Could not find element with id ' element_id '.']);
elseif numel(e_cell) > 1
    error(['Found multiple elements with id ' element_id '.']);
end
e = ndi.database.fun.ndi_document2ndi_object(e_cell{1},S);

epoch_id = ppg_beats_doc.document_properties.epochid.epochid;
et = e.epochtable();
et_entry_index = find(strcmp({et.epoch_id}, epoch_id));
if isempty(et_entry_index)
    error(['Could not find epoch ' epoch_id ' in the element epoch table.']);
end
et_entry = et(et_entry_index(1));

% Step 3: Check for a global clock and convert timestamps if available
epoch_clocks = et_entry.epoch_clock;
global_clock_ind = find(cellfun(@(x) ndi.time.clocktype.isGlobal(x), epoch_clocks), 1);

if ~isempty(global_clock_ind)
    % A global clock exists, so we can convert the beat times to datetime
    ecs = cellfun(@(c) c.type, epoch_clocks, 'UniformOutput', false);
    local_clock_ind = find(contains(ecs, 'dev_local_time'), 1);

    if isempty(local_clock_ind)
        warning('Global clock found, but no local device clock found for epoch %s. Cannot convert times.', epoch_id);
        return; % Return the beats struct with numeric times
    end

    % Find the global time that corresponds to the start of the local epoch time
    tr_local = ndi.time.timereference(e, epoch_clocks{local_clock_ind}, epoch_id, 0);
    t0_local_in_global = S.syncgraph.time_convert(tr_local, et_entry.t0_t1{local_clock_ind}(1),...
        e, epoch_clocks{global_clock_ind});
    t0_datetime = datetime(t0_local_in_global, 'ConvertFrom', 'datenum');

    % Convert the time fields in the beats structure
    if ~isempty(beats) && isstruct(beats)
        beats_table = struct2table(beats);
        
        % Identify time-related fields to convert
        if ismember('onset', beats_table.Properties.VariableNames)
            beats_table.onset = seconds(beats_table.onset) + t0_datetime;
        end
        if ismember('offset', beats_table.Properties.VariableNames)
            beats_table.offset = seconds(beats_table.offset) + t0_datetime;
        end
        
        beats = table2struct(beats_table);
    end
end
% If no global clock, the 'beats' struct is returned with times in seconds, as loaded.

end