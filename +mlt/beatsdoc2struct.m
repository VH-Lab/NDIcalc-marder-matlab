function [beats] = beatsdoc2struct(S,doc)
%BEATSDOC2STRUCT Reads PPG beat data from an NDI document into a structure.
%
%   BEATS = BEATSDOC2STRUCT(S, DOC) reads photoplethysmogram (PPG) beat
%   information associated with a specific NDI document DOC within the
%   context of an NDI session or dataset S. It retrieves the beat data
%   from a binary file ('beats.vhsb'), formats it into a table based on
%   metadata in DOC, and returns the result as a structure array.
%
%   Inputs:
%       S       - An NDI session object (`ndi.session`) or NDI dataset
%                 object (`ndi.dataset`).
%       DOC     - An NDI document object (`ndi.document`) that references
%                 the PPG beat data. This document must contain the
%                 property `ppg_beats.fields` (a comma-separated string
%                 of field names).
%
%   Outputs:
%       BEATS   - A structure array where each element represents a single
%                 PPG beat. The fields of the structure include 'onset', 
%                 'offset', 'peak_time', etc.
%
%   See also: MLT.DETECTHEARTBEATSIMPROVED, MLT.ADDBEATS2DOC,
%       VLT.FILE.CUSTOM_FILE_FORMATS.VHSB_READ

% Input argument validation
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    doc (1,1) {mustBeA(doc,{'ndi.document'})}
end

% Retrieve data from document
beats_doc = database_openbinarydoc(S, doc, 'beats.vhsb');
[Y,X] = vlt.file.custom_file_formats.vhsb_read(beats_doc,-Inf,Inf,0);
database_closebinarydoc(S, beats_doc);

% Make beats table
beat_fields = split(doc.document_properties.ppg_beats.fields,',');
beats = array2table([X,Y],'VariableNames',beat_fields);
beats = table2struct(beats);

end