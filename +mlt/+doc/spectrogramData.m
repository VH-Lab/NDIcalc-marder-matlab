function [spec, f, ts] = spectrogramData(S, spectrogram_doc)
%MLT.DOC.SPECTROGRAMDATA Retrieves spectrogram data from an NDI document.
%
%   [SPEC, F, TS] = mlt.doc.spectrogramData(S, SPECTROGRAM_DOC)
%
%   This function extracts the full spectrogram data matrix, frequency vector, and
%   time vector from a 'spectrogram' NDI document.
%
%   A key feature of this function is its handling of time. It inspects the
%   epoch's clock information from the element the document depends on. If a
%   global time clock (e.g., 'exp_global_time') is available for the epoch, the
%   output time vector 'TS' is converted to a MATLAB `datetime` object. If no
%   global clock is found, the time vector is returned as numeric values in
%   seconds from the start of the epoch.
%
%   Inputs:
%       S               - An ndi.session or ndi.dataset object.
%       SPECTROGRAM_DOC - A 'spectrogram' ndi.document object.
%
%   Outputs:
%       SPEC            - The spectrogram data matrix, with dimensions
%                         [frequency x time].
%       F               - A column vector of frequencies (Hz) corresponding to
%                         the rows of SPEC.
%       TS              - A column vector of timestamps for the spectrogram.
%                         Will be a `datetime` vector if a global clock is
%                         present, otherwise numeric (seconds).
%
%   Example:
%       % Assume 'mySession' is a valid NDI session object and we have found
%       % a 'spectrogram' document for a pylorus element.
%
%       e_pylorus = mySession.getelements('element.name', 'ppg_pylorus_lp_whole', 'element.reference', 1);
%       et = e_pylorus{1}.epochtable();
%       spectrogram_doc = ndi.database.fun.finddocs_elementEpochType(mySession, ...
%           e_pylorus{1}.id(), et(1).epoch_id, 'spectrogram');
%
%       if ~isempty(spectrogram_doc)
%           [spec_data, freqs, times] = mlt.doc.spectrogramData(mySession, spectrogram_doc{1});
%
%           % Check the class of the time vector
%           disp(['Class of time vector TS: ' class(times)]);
%
%           % Plot the spectrogram
%           figure;
%           imagesc(times, freqs, spec_data);
%           set(gca, 'YDir', 'normal');
%           ylabel('Frequency (Hz)');
%           % datetick('x'); % Use if times are datetime
%       end
%
%   See also: ndi.fun.data.readngrid, ndi.time.syncgraph.time_convert

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    spectrogram_doc (1,1) {mustBeA(spectrogram_doc,'ndi.document')}
end

% Step 1: Read data and coordinates from the document
ngrid_props = spectrogram_doc.document_properties.ngrid;
spec_props = spectrogram_doc.document_properties.spectrogram;

binary_doc = S.database_openbinarydoc(spectrogram_doc, 'spectrogram_results.ngrid');
spec = ndi.fun.data.readngrid(binary_doc, ngrid_props.data_dim, ngrid_props.data_type);
S.database_closebinarydoc(binary_doc);

freqCoords = ngrid_props.data_dim(spec_props.frequency_ngrid_dim);
timeCoords = ngrid_props.data_dim(spec_props.timestamp_ngrid_dim);
f = ngrid_props.coordinates(1:freqCoords);
ts = ngrid_props.coordinates(freqCoords + (1:timeCoords));

f = f(:);
ts = ts(:);

% Step 2: Get element and epoch info for time conversion
element_id = spectrogram_doc.dependency_value('element_id');
e_cell = S.database_search(ndi.query('base.id','exact_string',element_id));
if isempty(e_cell)
    error(['Could not find element with id ' element_id '.']);
elseif numel(e_cell) > 1
    error(['Found multiple elements with id ' element_id '.']);
end
e = ndi.database.fun.ndi_document2ndi_object(e_cell{1},S);

epoch_id = spectrogram_doc.document_properties.epochid.epochid;
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
    % A global clock exists, so convert the time vector to datetime
    ecs = cellfun(@(c) c.type, epoch_clocks, 'UniformOutput', false);
    local_clock_ind = find(contains(ecs, 'dev_local_time'), 1);

    if isempty(local_clock_ind)
        warning('Global clock found, but no local device clock found for epoch %s. Cannot convert times.', epoch_id);
        return;
    end

    % Find the global time that corresponds to the start of the local epoch time
    tr_local = ndi.time.timereference(e, epoch_clocks{local_clock_ind}, epoch_id, 0);
    t0_local_in_global = S.syncgraph.time_convert(tr_local, et_entry.t0_t1{local_clock_ind}(1),...
        e, epoch_clocks{global_clock_ind});
    t0_datetime = datetime(t0_local_in_global, 'ConvertFrom', 'datenum');

    % Add the local time vector (in seconds) to the global datetime start
    ts = seconds(ts) + t0_datetime;
end
% If no global clock, 'ts' remains in seconds as loaded.

end