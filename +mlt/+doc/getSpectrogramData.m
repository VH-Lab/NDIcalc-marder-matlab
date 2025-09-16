function [spectrogram_docs, spectrogram_data] = getSpectrogramData(S, subject_name, record_type)
%MLT.DOC.GETSPECTROGRAMDATA Finds spectrogram documents for a unique subject element.
%
%   [SPECTROGRAM_DOCS, SPECTROGRAM_DATA] = mlt.doc.getSpectrogramData(S, SUBJECT_NAME, RECORD_TYPE)
%
%   Searches an NDI session for a UNIQUE element that corresponds to a specific
%   subject and recording location (e.g., 'heart') by calling `mlt.ndi.getElement`.
%   It then finds all associated 'spectrogram' NDI documents for that single element.
%   If zero or more than one element matches the subject/type criteria, this function will error.
%
%   For each document found, it calls `mlt.doc.spectrogramData` to extract the
%   spectrogram matrix, frequency vector, and time vector, performing time
%   conversions to `datetime` objects if a global clock is available.
%
%   Inputs:
%       S               - An ndi.session or ndi.dataset object.
%       SUBJECT_NAME    - The name of the subject (e.g., 'SubjectA') as a
%                         character vector or string.
%       RECORD_TYPE     - The type of record to search for. Must be one of
%                         'heart', 'pylorus', or 'gastric'.
%
%   Outputs:
%       SPECTROGRAM_DOCS - A cell array of all matching 'spectrogram'
%                          `ndi.document` objects for the single found element.
%       SPECTROGRAM_DATA - A cell array of the same size as SPECTROGRAM_DOCS.
%                          Each cell contains a structure with the fields:
%                          .spec - The spectrogram data matrix
%                          .f    - The frequency vector
%                          .ts   - The time vector (`datetime` or numeric)
%
%   Example:
%       % Find the spectrogram records for 'SubjectB', assuming they have only one 'heart' element.
%       [docs, data] = mlt.doc.getSpectrogramData(mySession, 'SubjectB', 'heart');
%
%   See also: mlt.ndi.getElement, mlt.doc.spectrogramData

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','pylorus','gastric'})}
end

% Step 1: Find the unique element using mlt.ndi.getElement
% This will error if 0 or >1 elements are found. The default element_label 'lp_whole' is used.
matching_element = mlt.ndi.getElement(S, subject_name, record_type);

% Step 2: Find all 'spectrogram' documents associated with this single element
element_id = matching_element.id();
query = ndi.query('','isa','spectrogram') & ndi.query('','depends_on','element_id',element_id);
spectrogram_docs = S.database_search(query);

if isempty(spectrogram_docs)
    warning('Found a matching element but no associated "spectrogram" documents.');
    spectrogram_data = {};
    return;
end

% Step 3: Call mlt.doc.spectrogramData for each document
spectrogram_data = cell(size(spectrogram_docs));
for i = 1:numel(spectrogram_docs)
    [spec, f, ts] = mlt.doc.spectrogramData(S, spectrogram_docs{i});
    spectrogram_data{i} = struct('spec', spec, 'f', f, 'ts', ts);
end

end