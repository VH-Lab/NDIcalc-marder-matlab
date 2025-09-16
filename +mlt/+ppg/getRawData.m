function [d, t] = getRawData(S, subject_name, record_type, element_label)
%MLT.PPG.GETRAWDATA Retrieves the raw time series data for a unique PPG element.
%
%   [D, T] = mlt.ppg.getRawData(S, SUBJECT_NAME, RECORD_TYPE, [ELEMENT_LABEL])
%
%   This function finds a unique NDI element for a given subject and record
%   type and returns its entire raw time series data. It uses
%   `mlt.ndi.getElement` to perform the search.
%
%   The function also handles time conversion. If the element's epoch is associated
%   with a global experiment clock, the output time vector 'T' will be a `datetime`
%   vector. Otherwise, it will be a numeric vector in seconds from the start of
%   the recording.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       SUBJECT_NAME  - The name of the subject (e.g., 'SubjectA').
%       RECORD_TYPE   - The type of record ('heart', 'gastric', or 'pylorus').
%       ELEMENT_LABEL - (Optional) A further label to identify the element.
%                       Defaults to 'lp_whole'.
%
%   Outputs:
%       D             - The raw data vector (unnormalized).
%       T             - The time vector (`datetime` or numeric seconds).
%
%   Example:
%       % Get the raw heart PPG data for SubjectA
%       [data, time] = mlt.ppg.getRawData(mySession, 'SubjectA', 'heart');
%
%       % Plot the raw data
%       figure;
%       plot(time, data);
%       title('Raw PPG Signal for SubjectA');
%       xlabel('Time');
%
%   See also: mlt.ndi.getElement, ndi.element.readtimeseries

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','gastric','pylorus'})}
    element_label (1,:) char = 'lp_whole'
end

% Step 1: Find the unique element for the subject and record type
e = mlt.ndi.getElement(S, subject_name, record_type, element_label);

% Step 2: Get epoch information (expects a single '_lp_whole' epoch)
et = e.epochtable();
if numel(et) ~= 1
    error('Expected a single epoch for a ''%s'' element, but found %d.', element_label, numel(et));
end
et_entry = et(1);

% Step 3: Determine time reference and read the full time series
epoch_clocks = et_entry.epoch_clock;
global_clock_ind = find(cellfun(@(x) ndi.time.clocktype.isGlobal(x), epoch_clocks), 1);

if ~isempty(global_clock_ind)
    % Global clock is present; read using global time and convert to datetime
    tr = ndi.time.timereference(e, epoch_clocks{global_clock_ind}, [], 0);
    [d, t] = e.readtimeseries(tr, et_entry.t0_t1{global_clock_ind}(1), et_entry.t0_t1{global_clock_ind}(2));
    t = datetime(t, 'ConvertFrom', 'datenum');
else
    % No global clock; read using local time
    ecs = cellfun(@(c) c.type, epoch_clocks, 'UniformOutput', false);
    local_clock_ind = find(contains(ecs, 'dev_local_time'), 1);
    if isempty(local_clock_ind)
        error('No global or local device clock found for epoch %s.', et_entry.epoch_id);
    end
    tr = ndi.time.timereference(e, epoch_clocks{local_clock_ind}, et_entry.epoch_id, 0);
    [d, t] = e.readtimeseries(tr, et_entry.t0_t1{local_clock_ind}(1), et_entry.t0_t1{local_clock_ind}(2));
end

end