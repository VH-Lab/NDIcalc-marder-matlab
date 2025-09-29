function data = getHeartBeatAndSpectrogram(S_in, subject_name, record_type)
%MLT.DOC.GETHEARTBEATANDSPECTROGRAM Fetches heartbeats and spectrograms for a subject across multiple sessions.
%
%   DATA = mlt.doc.getHeartBeatAndSpectrogram(S_IN, SUBJECT_NAME, RECORD_TYPE)
%
%   This function retrieves both heart beat and spectrogram data for a single,
%   unique subject element identified by SUBJECT_NAME and RECORD_TYPE. It can
%   operate on one or more sessions.
%
%   It internally calls `mlt.doc.getHeartBeats` and `mlt.doc.getSpectrogramData`
%   to fetch the respective data and documents for each session.
%
%   The function returns a structure array with the following fields:
%   'session'                  - The ndi.session or ndi.dataset object for that entry.
%   'subject_local_identifier' - The name of the subject.
%   'recordType'               - The type of record ('heart', 'pylorus', 'gastric').
%   'HeartBeatDocs'            - Cell array of 'ppg_beats' ndi.document objects.
%   'HeartBeatData'            - Cell array of heart beat data structures.
%   'SpectrogramDocs'          - Cell array of 'spectrogram' ndi.document objects.
%   'SpectrogramData'          - Cell array of spectrogram data structures.
%
%   Inputs:
%       S_IN            - An ndi.session, ndi.dataset object, or a cell array of them.
%       SUBJECT_NAME    - The name of the subject (e.g., 'SubjectA').
%       RECORD_TYPE     - The record type (e.g., 'heart').
%
%   Outputs:
%       DATA            - A structure array containing the combined data, with one entry per session.
%
%   See also: mlt.doc.getHeartBeats, mlt.doc.getSpectrogramData

arguments
    S_in
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','pylorus','gastric'})}
end

% Ensure S_in is a cell array for consistent processing
if ~iscell(S_in)
    S_in = {S_in};
end

% Initialize an empty struct array
data = struct(...
    'session', {}, ...
    'subject_local_identifier', {}, ...
    'recordType', {}, ...
    'HeartBeatDocs', {}, ...
    'HeartBeatData', {}, ...
    'SpectrogramDocs', {}, ...
    'SpectrogramData', {} ...
);

% Loop over each session provided
for i = 1:numel(S_in)
    S = S_in{i};
    mustBeA(S, {'ndi.session', 'ndi.dataset'});

    % Fetch the heart beat data for the current session
    [hb_docs, hb_data] = mlt.doc.getHeartBeats(S, subject_name, record_type);

    % Fetch the spectrogram data for the current session
    [spec_docs, spec_data] = mlt.doc.getSpectrogramData(S, subject_name, record_type);

    % Construct a new entry for the output struct array
    new_entry = struct(...
        'session', S, ...
        'subject_local_identifier', subject_name, ...
        'recordType', record_type, ...
        'HeartBeatDocs', {hb_docs}, ...
        'HeartBeatData', {hb_data}, ...
        'SpectrogramDocs', {spec_docs}, ...
        'SpectrogramData', {spec_data} ...
    );

    % Append the new entry to the data array
    data(end+1) = new_entry;
end

end
