function data = getHeartBeatAndSpectrogram(S, subject_name, record_type)
%MLT.DOC.GETHEARTBEATANDSPECTROGRAM Fetches heartbeats and spectrograms for a subject.
%
%   DATA = mlt.doc.getHeartBeatAndSpectrogram(S, SUBJECT_NAME, RECORD_TYPE)
%
%   This function retrieves both heart beat and spectrogram data for a single,
%   unique subject element identified by SUBJECT_NAME and RECORD_TYPE.
%
%   It internally calls `mlt.doc.getHeartBeats` and `mlt.doc.getSpectrogramData`
%   to fetch the respective data and documents.
%
%   The function returns a structure with the following fields:
%   'subject_local_identifier' - The name of the subject.
%   'recordType'               - The type of record ('heart', 'pylorus', 'gastric').
%   'HeartBeatDocs'            - Cell array of 'ppg_beats' ndi.document objects.
%   'HeartBeatData'            - Cell array of heart beat data structures.
%   'SpectrogramDocs'          - Cell array of 'spectrogram' ndi.document objects.
%   'SpectrogramData'          - Cell array of spectrogram data structures.
%
%   Inputs:
%       S               - An ndi.session or ndi.dataset object.
%       SUBJECT_NAME    - The name of the subject (e.g., 'SubjectA').
%       RECORD_TYPE     - The record type (e.g., 'heart').
%
%   Outputs:
%       DATA            - A structure containing the combined data.
%
%   See also: mlt.doc.getHeartBeats, mlt.doc.getSpectrogramData

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','pylorus','gastric'})}
end

% Fetch the heart beat data
[hb_docs, hb_data] = mlt.doc.getHeartBeats(S, subject_name, record_type);

% Fetch the spectrogram data
[spec_docs, spec_data] = mlt.doc.getSpectrogramData(S, subject_name, record_type);

% Construct the output structure
data = struct(...
    'subject_local_identifier', subject_name, ...
    'recordType', record_type, ...
    'HeartBeatDocs', {hb_docs}, ...
    'HeartBeatData', {hb_data}, ...
    'SpectrogramDocs', {spec_docs}, ...
    'SpectrogramData', {spec_data} ...
);

end
