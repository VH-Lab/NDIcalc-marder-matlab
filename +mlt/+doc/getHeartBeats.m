function [heartBeat_docs, heartBeat_data] = getHeartBeats(S, subject_name, record_type)
%MLT.DOC.GETHEARTBEATS Finds heart beat documents for a unique subject element.
%
%   [HEARTBEAT_DOCS, HEARTBEAT_DATA] = mlt.doc.getHeartBeats(S, SUBJECT_NAME, RECORD_TYPE)
%
%   Searches an NDI session for a UNIQUE element that corresponds to a specific
%   subject and recording location (e.g., 'heart') by calling `mlt.ndi.getElement`.
%   It then finds all associated 'ppg_beats' NDI documents for that single element.
%   If zero or more than one element matches the subject/type criteria, this function will error.
%
%   For each document found, it calls `mlt.doc.heartBeatData` to extract the
%   beat structure, performing time conversions to `datetime` objects if a
%   global clock is available for the epoch.
%
%   Inputs:
%       S               - An ndi.session or ndi.dataset object.
%       SUBJECT_NAME    - The name of the subject (e.g., 'SubjectA') as a
%                         character vector or string.
%       RECORD_TYPE     - The type of record to search for. Must be one of
%                         'heart', 'pylorus', or 'gastric'.
%
%   Outputs:
%       HEARTBEAT_DOCS  - A cell array of all matching 'ppg_beats'
%                         `ndi.document` objects for the single found element.
%       HEARTBEAT_DATA  - A cell array of the same size as HEARTBEAT_DOCS,
%                         where each cell contains the corresponding beat data
%                         structure returned by `mlt.doc.heartBeatData`.
%
%   Example:
%       % Find the heart beat records for 'SubjectB', assuming they have only one 'heart' element.
%       [docs, data] = mlt.doc.getHeartBeats(mySession, 'SubjectB', 'heart');
%
%   See also: mlt.ndi.getElement, mlt.doc.heartBeatData

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','pylorus','gastric'})}
end

% Step 1: Find the unique element using mlt.ndi.getElement
% This will error if 0 or >1 elements are found. The default element_label 'lp_whole' is used.
matching_element = mlt.ndi.getElement(S, subject_name, record_type);

% Step 2: Find all 'ppg_beats' documents associated with this single element
element_id = matching_element.id();
query = ndi.query('','isa','ppg_beats') & ndi.query('','depends_on','element_id',element_id);
heartBeat_docs = S.database_search(query);

if isempty(heartBeat_docs)
    warning('Found a matching element but no associated "ppg_beats" documents.');
    heartBeat_data = {};
    return;
end

% Step 3: Call mlt.doc.heartBeatData for each document
heartBeat_data = cell(size(heartBeat_docs));
for i = 1:numel(heartBeat_docs)
    heartBeat_data{i} = mlt.doc.heartBeatData(S, heartBeat_docs{i});
end

end