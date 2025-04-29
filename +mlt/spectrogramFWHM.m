function [specData_avg, f, fwhm_val, low_cutoff, high_cutoff] = spectrogramFWHM(e, t0, t1)
%MLT.SPECTROGRAMFWHM Calculate Time-Averaged Spectrogram and its Full Width at Half Maximum.
%
%   [SPECDATA_AVG, F, FWHM_VAL, LOW_CUTOFF, HIGH_CUTOFF] = mlt.spectrogramFWHM(E, T0, T1) % Updated namespace in description
%   calculates the time-averaged power spectrum and its full width at half
%   maximum (FWHM) for a given ndi.element E within a specified time window
%   [T0, T1].
%
%   Inputs:
%       E  - An ndi.element object. The session is retrieved from e.session.
%            The element should have associated 'spectrogram' documents.
%       T0 - A Matlab datetime object representing the start time for analysis.
%       T1 - A Matlab datetime object representing the end time for analysis.
%
%   Outputs:
%       SPECDATA_AVG - A column vector representing the power spectrum averaged
%                      across the specified time window [T0, T1]. Empty if no
%                      spectrogram data is found in the window.
%       F            - The frequency vector (numeric column vector) corresponding
%                      to the spectrogram data. Returns [] if no match found.
%       FWHM_VAL     - The full width at half maximum (FWHM) of the
%                      time-averaged spectrum SPECDATA_AVG, in units of frequency.
%                      Returns NaN if FWHM cannot be calculated (e.g., data
%                      does not cross half-height).
%       LOW_CUTOFF   - The lower frequency cutoff at half maximum height.
%                      Returns NaN if not applicable.
%       HIGH_CUTOFF  - The upper frequency cutoff at half maximum height.
%                      Returns NaN if not applicable.
%
%   Details:
%       1. Calls `mlt.readSpectrogramTimeWindow(E, T0, T1)` to retrieve the
%          first available spectrogram data chunk (`spectrogram_data`), its
%          frequency vector (`f`), timestamps (`t_datetime`), and the source
%          document (`spectrogram_doc`) within the specified time window.
%       2. If data is found, it averages `spectrogram_data` across the time
%          dimension to get `specData_avg`.
%       3. It then uses `vlt.signal.fwhm(f, specData_avg)` to calculate the
%          FWHM and cutoff frequencies of the averaged spectrum.
%
%   Requires:
%       - NDI toolbox (+ndi)
%       - vhlab-toolbox-matlab (+vlt), specifically vlt.signal.fwhm
%       - NDIcalc-marder-matlab (+mlt), specifically mlt.readSpectrogramTimeWindow
%         and this function (mlt.spectrogramFWHM). % Updated Requires section
%       - Associated helper functions like `mlt.readngrid` (if not standard)

% --- Input Validation ---
arguments
    e (1,1) {mustBeA(e,'ndi.element')}
    t0 (1,1) {mustBeA(t0,'datetime')}
    t1 (1,1) {mustBeA(t1,'datetime')}
end
% --- End Input Validation ---

% Initialize outputs
specData_avg = [];
f = [];                   % Initialize new output
fwhm_val = NaN;
low_cutoff = NaN;
high_cutoff = NaN;
spectrogram_doc = [];     % Moved to last position
t_datetime = [];          % Moved position

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
            f_vec = [];          % Initialize frequency vector locally
            try
                binary_doc_obj = S.database_openbinarydoc(current_doc, 'spectrogram_results.ngrid'); % 
                % Assuming mlt.readngrid exists and works with file object or path
                spectrogram_data_full = mlt.readngrid(binary_doc_obj, ngrid_props.data_dim, ngrid_props.data_type); % 
                S.database_closebinarydoc(binary_doc_obj); % 
                binary_doc_obj = [];
                
                % --- Extract Frequency Coordinates from NGRID (do this after successful read) ---
                freq_dim = spectrogram_props.frequency_ngrid_dim; % 
                coords_start_index_freq = 1;
                for d = 1:(freq_dim - 1)
                    coords_start_index_freq = coords_start_index_freq + ngrid_props.data_dim(d);
                end
                coords_end_index_freq = coords_start_index_freq + ngrid_props.data_dim(freq_dim) - 1;
                f_vec = ngrid_props.coordinates(coords_start_index_freq:coords_end_index_freq); % 

            catch ME_read
                 if ~isempty(binary_doc_obj)
                     try S.database_closebinarydoc(binary_doc_obj); catch, end; % 
                 end
                 warning(['Could not read spectrogram data or properties for document ID ' current_doc.id() ': ' ME_read.message]);
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
                f = f_vec(:); % Assign frequency vector (ensure column)           
                
                % Get corresponding timestamps and convert to datetime
                time_coords_global_datenum_subset = time_coords_global_datenum(time_indices);
                t_datetime = datetime(time_coords_global_datenum_subset, 'ConvertFrom', 'datenum'); % 
                
                spectrogram_doc = current_doc; 
                
                % --- Calculate Time-Averaged Spectrum ---
                try
                    % Check if time_dim is valid for the *subset* data
                    if time_dim > ndims(spectrogram_data)
                       error('Timestamp dimension (%d) specified in document exceeds dimensions of returned data subset (%d).', ...
                           time_dim, ndims(spectrogram_data));
                    end
                    % Average across the time dimension
                    specData_avg = mean(spectrogram_data, time_dim);
                    specData_avg = specData_avg(:); % Ensure column vector
                catch ME_avg
                    warning('Error calculating time-averaged spectrum: %s', ME_avg.message);
                    specData_avg = []; % Ensure it's empty if calculation fails
                    % Clear other outputs as FWHM depends on this
                    fwhm_val = NaN;
                    low_cutoff = NaN;
                    high_cutoff = NaN;
                    break; % Exit loop as we can't proceed with this doc
                end

                % --- Calculate FWHM ---
                if ~isempty(specData_avg) && ~isempty(f) && numel(f) == numel(specData_avg) && numel(f) >= 2
                    try
                        % Use vlt.signal.fwhm to calculate FWHM
                        [~, fwhm_val, low_cutoff, high_cutoff] = vlt.signal.fwhm(f, specData_avg); % 
                        
                        % Handle cases where fwhm returns Inf (replace with NaN)
                        if isinf(fwhm_val), fwhm_val = NaN; end
                        if isinf(low_cutoff), low_cutoff = NaN; end
                        if isinf(high_cutoff), high_cutoff = NaN; end
                        
                    catch ME_fwhm
                        warning('Error calculating FWHM using vlt.signal.fwhm: %s', ME_fwhm.message);
                         fwhm_val = NaN; low_cutoff = NaN; high_cutoff = NaN;
                    end
                else % Conditions for FWHM not met
                    if isempty(specData_avg), warning('Time-averaged spectrum is empty, cannot calculate FWHM.');
                    elseif isempty(f), warning('Frequency vector is empty, cannot calculate FWHM.');
                    elseif numel(f)~=numel(specData_avg), warning('Frequency vector and averaged spectrum dimension mismatch (%d vs %d), cannot calculate FWHM.', numel(f), numel(specData_avg));
                    else, warning('Not enough data points in averaged spectrum (need at least 2) to calculate FWHM.');
                    end
                    fwhm_val = NaN; low_cutoff = NaN; high_cutoff = NaN;
                end

                % Found the first match and processed it, exit the loop
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
        % Ensure all outputs are empty/NaN if no doc is found
        spectrogram_data = [];
        f = [];
        t_datetime = [];
        fwhm_val = NaN;
        low_cutoff = NaN;
        high_cutoff = NaN;
    end

end % function spectrogramFWHM