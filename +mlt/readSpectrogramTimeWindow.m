function [spectrogram_data, f, t_datetime, spectrogram_doc] = readSpectrogramTimeWindow(e, t0, t1)
%READSPECTROGRAMTIMEWINDOW Read the first matching spectrogram data and frequencies within a time window.
%
%   [SPECTROGRAM_DATA, F, T_DATETIME, SPECTROGRAM_DOC] = ...
%       READSPECTROGRAMTIMEWINDOW(E, T0, T1)
%   searches the NDI session associated with element E for 'spectrogram'
%   type documents that depend on E. It then identifies which of these
%   documents correspond to element epochs that overlap with the time range
%   specified by the Matlab datetime objects T0 and T1 (using the
%   'exp_global_time' clock). For the *first* document found whose
%   corresponding epoch overlaps, it reads the associated spectrogram data,
%   converts its time base from 'dev_local_time' to 'exp_global_time',
%   extracts the portion within [T0, T1], and returns it along with the
%   frequency vector and corresponding timestamps.
%
%   Inputs:
%       E  - An ndi.element object. The session is retrieved from e.session.
%       T0 - A Matlab datetime object representing the start time.
%       T1 - A Matlab datetime object representing the end time.
%
%   Outputs:
%       SPECTROGRAM_DATA - The portion of the spectrogram data (numeric matrix)
%                          from the first matching document that falls within
%                          the [T0, T1] time window ('exp_global_time'). Returns
%                          [] if no match is found.
%       F                - The frequency vector (numeric column vector) corresponding
%                          to the spectrogram data. Returns [] if no match found.
%       T_DATETIME       - A Matlab datetime vector corresponding to the time
%                          axis of the returned SPECTROGRAM_DATA, converted
%                          from 'exp_global_time'. Returns [] if no match is found.
%       SPECTROGRAM_DOC  - The ndi.document object from which the data in
%                          SPECTROGRAM_DATA was extracted. Returns [] if no
%                          match is found.
%
%   Logic:
%       1. Retrieves the session object from e.session.
%       2. Finds all 'spectrogram' documents depending on element E.
%       3. Retrieves the epoch table for element E.
%       4. For each spectrogram document found (in order):
%          a. Matches the document's epochid to the element's epoch table.
%          b. Checks if the 'exp_global_time' range of that epoch overlaps
%             with the requested [T0, T1].
%          c. If it overlaps, reads the full spectrogram data (ngrid).
%          d. Extracts the 'dev_local_time' coordinate vector from ngrid.
%          e. Creates an ndi.time.timereference for the local time of the epoch.
%          f. Uses S.syncgraph.time_convert to convert local times to 'exp_global_time'.
%          g. Filters the data based on whether converted timestamps fall within [T0, T1].
%          h. If data within the window exists, extracts the data subset,
%             the frequency vector, the corresponding 'exp_global_time' stamps
%             (converted to datetime), assigns outputs, and returns (exits).
%       5. If loop completes without a match, returns empty outputs.
%
%   Assumptions based on context and documentation:
%       - 'spectrogram' documents have 'epochid' and 'ngrid' as superclasses
%         or properties.
%       - Spectrogram data is stored in a binary file named
%         'spectrogram_results.ngrid'.
%       - The element E's epochtable contains entries for 'exp_global_time' clock
%         with t0_t1 values stored as Matlab datenums.
%       - The time coordinate vector within the ngrid structure corresponds to
%         the 'dev_local_time' clock for that specific epoch.
%       - The `mlt.readngrid` function is available on the Matlab path.
%       - The ndi.session associated with E has a valid ndi.time.syncgraph.

    % Validate input arguments using the arguments block
    arguments
        e (1,1) {mustBeA(e,'ndi.element')}
        t0 (1,1) {mustBeA(t0,'datetime')}
        t1 (1,1) {mustBeA(t1,'datetime')}
    end

    % Initialize outputs to empty
    spectrogram_data = [];
    f = [];
    t_datetime = [];
    spectrogram_doc = [];

    % Get session from element
    S = e.session; % 
    if isempty(S) || ~isa(S, 'ndi.session')
        error('The provided element does not have a valid ndi.session object associated with it.');
    end

    % Get element epoch table
    et = e.epochtable(); % 
    if isempty(et)
        disp('Element has no epoch table; cannot determine time ranges.');
        return;
    end

    % Convert requested time window to datenum
    t0_datenum = datenum(t0); % 
    t1_datenum = datenum(t1);

    % --- Query Construction ---
    q_type = ndi.query('','isa','spectrogram'); % 
    q_depends = ndi.query('','depends_on','element_id',e.id()); % 
    query = q_type & q_depends; %

    % --- Database Search ---
    docs = S.database_search(query); % 

    % --- Iterate, Check Time Overlap, and Filter ---
    for i=1:numel(docs)
        current_doc = docs{i};
        epoch_overlap = false; % Flag to indicate if the epoch overlaps
        time_coords_global_datenum = []; % Initialize converted time coordinates

        try
            % Get epoch id from the spectrogram document
            doc_epoch_id = current_doc.document_properties.epochid.epochid; % 

            % Find matching epoch in element's epoch table
            et_entry_index = find(strcmp({et.epoch_id}, doc_epoch_id));

            if ~isempty(et_entry_index)
                et_entry = et(et_entry_index(1)); % Use first match

                % Find 'exp_global_time' clock index in the element epoch table
                clock_index = -1;
                for k=1:numel(et_entry.epoch_clock)
                   if strcmpi(et_entry.epoch_clock{k}.type,'exp_global_time') % 
                       clock_index = k;
                       break;
                   end
                end

                if clock_index > 0
                    % Get epoch time range for 'exp_global_time' from element table
                    epoch_t0_t1 = et_entry.t0_t1{clock_index}; % 
                    epoch_t0 = epoch_t0_t1(1);
                    epoch_t1 = epoch_t0_t1(2);

                    % Check for overlap between epoch range and requested range
                    if epoch_t0 <= t1_datenum && epoch_t1 >= t0_datenum
                        epoch_overlap = true;
                    end
                else
                     warning(['Epoch ' doc_epoch_id ' for element ' e.id() ' does not have an exp_global_time clock in its epoch table. Cannot check time range. Skipping document ' current_doc.id() '.']);
                     continue;
                end
            else
                warning(['Could not find epoch ' doc_epoch_id ' in the epoch table for element ' e.id() '. Skipping document ' current_doc.id() '.']);
                continue; % Skip document if its epoch isn't in the element table
            end

            % --- Process if Epoch Overlaps ---
            if epoch_overlap
                ngrid_props = current_doc.document_properties.ngrid; % 
                spectrogram_props = current_doc.document_properties.spectrogram; % 

                % --- Read Spectrogram Data ---
                binary_doc_obj = []; % Initialize
                try
                    binary_doc_obj = S.database_openbinarydoc(current_doc, 'spectrogram_results.ngrid'); % 
                    % Assuming mlt.readngrid exists and works with file object or path
                    spectrogram_data_full = mlt.readngrid(binary_doc_obj, ngrid_props.data_dim, ngrid_props.data_type); % 
                    S.database_closebinarydoc(binary_doc_obj); % 
                    binary_doc_obj = [];
                catch ME_read
                     if ~isempty(binary_doc_obj)
                         try S.database_closebinarydoc(binary_doc_obj); catch, end; % 
                     end
                     warning(['Could not read spectrogram data for document ID ' current_doc.id() ': ' ME_read.message]);
                     continue; % Skip to the next document
                end

                % --- Extract Local Time Coordinates from NGRID ---
                time_dim = spectrogram_props.timestamp_ngrid_dim; % 
                coords_start_index_time = 1;
                for d = 1:(time_dim - 1)
                    coords_start_index_time = coords_start_index_time + ngrid_props.data_dim(d);
                end
                coords_end_index_time = coords_start_index_time + ngrid_props.data_dim(time_dim) - 1;
                time_coords_local = ngrid_props.coordinates(coords_start_index_time:coords_end_index_time); % 

                % --- Extract Frequency Coordinates from NGRID ---
                freq_dim = spectrogram_props.frequency_ngrid_dim; % 
                coords_start_index_freq = 1;
                for d = 1:(freq_dim - 1)
                    coords_start_index_freq = coords_start_index_freq + ngrid_props.data_dim(d);
                end
                coords_end_index_freq = coords_start_index_freq + ngrid_props.data_dim(freq_dim) - 1;
                f_vec = ngrid_props.coordinates(coords_start_index_freq:coords_end_index_freq); % 

                % --- Convert Time Coordinates ---
                try
                    % Create timereference for the source time (local time of the epoch)
                    timeref_in = ndi.time.timereference(e, ndi.time.clocktype('dev_local_time'), doc_epoch_id, 0); % 
                    
                    % Convert to exp_global_time (datenum format)
                    [time_coords_global_datenum, ~, msg] = S.syncgraph.time_convert(timeref_in, time_coords_local, e, ndi.time.clocktype('exp_global_time')); % 
                    
                    if isempty(time_coords_global_datenum)
                       error(['Time conversion failed: ' msg]);
                    end
                    
                catch ME_timeconvert
                    warning(['Could not convert time for document ID ' current_doc.id() ': ' ME_timeconvert.message]);
                    continue; % Skip if time conversion fails
                end

                % --- Filter by Requested Time Window ---
                time_indices = find(time_coords_global_datenum >= t0_datenum & time_coords_global_datenum <= t1_datenum);

                if ~isempty(time_indices)
                    % --- Extract Data Subset and Assign Outputs ---
                    
                    % Create subscripting structure dynamically
                    sub_indices = repmat({':'}, 1, numel(ngrid_props.data_dim));
                    sub_indices{time_dim} = time_indices;
                    
                    % Assign outputs (not cell arrays)
                    spectrogram_data = spectrogram_data_full(sub_indices{:}); 
                    f = f_vec; % Assign frequency vector
                    
                    % Get corresponding timestamps and convert to datetime
                    time_coords_global_datenum_subset = time_coords_global_datenum(time_indices);
                    t_datetime = datetime(time_coords_global_datenum_subset, 'ConvertFrom', 'datenum'); % 
                    
                    spectrogram_doc = current_doc; 
                    
                    % Found the first match, exit the loop
                    break; 
                end % if ~isempty(time_indices)
            end % if epoch_overlap

        catch ME_process
            warning(['Error processing document ID ' current_doc.id() ': ' ME_process.message '. Skipping.']);
            continue; % Skip to the next document
        end
    end % loop through documents

    if isempty(spectrogram_doc)
        disp('No spectrogram documents found matching the criteria and overlapping with the time window.');
    end

end