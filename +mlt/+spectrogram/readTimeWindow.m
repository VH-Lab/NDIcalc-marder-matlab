function [spectrogram_data, f, t_datetime, spectrogram_doc] = readTimeWindow(e, t0, t1)
%READTIMEWINDOW Read the first matching spectrogram data within a time window.
%
%   [spectrogram_data, f, t_datetime, spectrogram_doc] = ...
%       mlt.spectrogram.readTimeWindow(e, t0, t1)
%
%   Searches an NDI session for 'spectrogram' documents associated with a
%   given ndi.element 'e'. It finds the first document that temporally
%   overlaps with the window [t0, t1], reads the spectrogram data, and
%   returns only the portion of the data that falls within the window.
%
%   Inputs:
%       e  - An ndi.element object. The session is retrieved from e.session.
%       t0 - A datetime object representing the start of the window.
%       t1 - A datetime object representing the end of the window.
%
%   Outputs:
%       spectrogram_data - The portion of the spectrogram data (numeric matrix,
%                          typically [frequency x time]) that falls within the
%                          [t0, t1] window. Returns [] if no match is found.
%       f                - The frequency vector (column vector) for the data.
%       t_datetime       - A datetime vector for the time axis of the returned data.
%       spectrogram_doc  - The ndi.document object from which the data was extracted.
%
%   Logic:
%       1. Finds all 'spectrogram' documents that depend on the element 'e'.
%       2. For each document, it checks if the document's epoch overlaps with [t0, t1].
%       3. For the first overlapping document, it reads the full ngrid data.
%       4. It converts the data's local timestamps to the session's global time clock.
%       5. It filters the data and timestamps to the requested [t0, t1] window.
%       6. It returns the filtered data and exits. If no match is found, it returns empty.
%
%   Example:
%       % Assuming 'my_element' is a valid ndi.element with spectrograms
%       t_start = datetime('2025-09-05 10:00:00');
%       t_end = datetime('2025-09-05 10:05:00');
%       [spec, freq, time] = mlt.spectrogram.readTimeWindow(my_element, t_start, t_end);
%       if ~isempty(spec)
%           imagesc(time, freq, spec);
%           set(gca, 'YDir', 'normal');
%       end
%
%   See also mlt.spectrogram.FWHM, ndi.session.database_search, ndi.time.syncgraph.time_convert

% --- Input Validation ---
arguments
    e (1,1) {mustBeA(e,'ndi.element')}
    t0 (1,1) {mustBeA(t0,'datetime')}
    t1 (1,1) {mustBeA(t1,'datetime')}
end

% --- Initialize Outputs ---
spectrogram_data = [];
f = [];
t_datetime = [];
spectrogram_doc = [];

% --- Setup ---
S = e.session;
if isempty(S) || ~isa(S, 'ndi.session')
    error('The provided element does not have a valid ndi.session object.');
end

et = e.epochtable();
if isempty(et)
    disp('Element has no epoch table; cannot determine time ranges.');
    return;
end

t0_datenum = datenum(t0);
t1_datenum = datenum(t1);

% --- Database Search ---
query = ndi.query('','isa','spectrogram') & ndi.query('','depends_on','element_id',e.id());
docs = S.database_search(query)

if isempty(docs)
    disp('No spectrogram documents found for this element.');
    return;
end

% --- Iterate Through Docs to Find First Overlapping Match ---
for i=1:numel(docs)
    current_doc = docs{i};
    try
        % Get epoch id from the doc and find its entry in the element's epoch table
        doc_epoch_id = current_doc.document_properties.epochid.epochid;
        et_entry_index = find(strcmp({et.epoch_id}, doc_epoch_id));
        
        if isempty(et_entry_index)
            warning('Could not find epoch %s in the epoch table for element %s. Skipping.', doc_epoch_id, e.id());
            continue;
        end
        et_entry = et(et_entry_index(1)); % Use first match

        % Find the 'exp_global_time' clock to check for temporal overlap
        clock_types = cellfun(@(c) c.type, et_entry.epoch_clock, 'UniformOutput', false);
        clock_index = find(strcmpi(clock_types, 'exp_global_time'), 1);
        
        if isempty(clock_index)
            warning('Epoch %s does not have an exp_global_time clock. Skipping.', doc_epoch_id);
            continue;
        end
        
        % Check for overlap between the epoch's full time range and our requested window
        epoch_t0_t1 = et_entry.t0_t1{clock_index};
        if epoch_t0_t1(1) > t1_datenum || epoch_t0_t1(2) < t0_datenum
            continue; % No overlap, skip to the next document
        end
        
        % --- Overlap found, now read and process the data ---
        
        % Read properties and binary data
        ngrid_props = current_doc.document_properties.ngrid;
        spectrogram_props = current_doc.document_properties.spectrogram;
        binary_doc_obj = S.database_openbinarydoc(current_doc, 'spectrogram_results.ngrid');
        spectrogram_data_full = ndi.fun.data.readngrid(binary_doc_obj, ngrid_props.data_dim, ngrid_props.data_type);
        S.database_closebinarydoc(binary_doc_obj);
        
        % Extract frequency and time coordinates from ngrid properties
        f_vec = ngrid_props.coordinates{spectrogram_props.frequency_ngrid_dim};
        time_coords_local = ngrid_props.coordinates{spectrogram_props.timestamp_ngrid_dim};
        
        % Convert local timestamps to global time (datenum)
        timeref_in = ndi.time.timereference(e, ndi.time.clocktype('dev_local_time'), doc_epoch_id, 0);
        [time_coords_global, ~, msg] = S.syncgraph.time_convert(timeref_in, time_coords_local, e, ndi.time.clocktype('exp_global_time'));
        if isempty(time_coords_global), error('Time conversion failed: %s', msg); end
        
        % Filter by the requested time window
        time_indices = find(time_coords_global >= t0_datenum & time_coords_global <= t1_datenum);
        
        if ~isempty(time_indices)
            % Create subscripting indices to extract the data subset
            sub_indices = repmat({':'}, 1, ndims(spectrogram_data_full));
            sub_indices{spectrogram_props.timestamp_ngrid_dim} = time_indices;
            
            % Assign outputs
            spectrogram_data = spectrogram_data_full(sub_indices{:});
            f = f_vec(:); % Ensure frequency is a column vector
            t_datetime = datetime(time_coords_global(time_indices), 'ConvertFrom', 'datenum');
            spectrogram_doc = current_doc;
            
            % Found the first valid data chunk, so we are done.
            return;
        end
        
    catch ME
        warning('Error processing document ID %s: %s. Skipping.', current_doc.id(), ME.message);
        % Ensure binary doc is closed even if an error occurred after opening
        if exist('binary_doc_obj','var') && ~isempty(binary_doc_obj), S.database_closebinarydoc(binary_doc_obj); end
        continue;
    end
end

% If we get here, no overlapping data was found
disp('No spectrogram documents with data inside the requested time window were found.');

end