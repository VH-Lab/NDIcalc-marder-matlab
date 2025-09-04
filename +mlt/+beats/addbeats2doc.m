function [doc_out] = addbeats2doc(doc_in,beats)
%ADDBEATS2DOC Adds PPG beat data from a structure to an NDI document.
%
%   DOC_OUT = ADDBEATS2DOC(DOC_IN, BEATS) takes photoplethysmogram (PPG)
%   beat information stored in a structure array BEATS and writes it to a
%   binary file ('beats.vhsb'). It then associates this file with the
%   provided NDI document object DOC_IN.
%
%   Inputs:
%       DOC_IN  - An NDI document object (`ndi.document`) to which the beat
%                 data file will be added.
%       BEATS   - A structure array where each element represents a single
%                 PPG beat. The fields of the structure include time
%                 information (i.e. 'onset', 'offset') and other metrics.
%                 Time fields represented as MATLAB `datetime` are 
%                 converted to `datenum` format before saving.
%
%   Outputs:
%       DOC_OUT - The updated NDI document object (`ndi.document`) that now
%                 includes a reference to the newly created 'beats.vhsb' file
%                 containing the beat data.
%
%   See also: MLT.DETECTHEARTBEATSIMPROVED, MLT.BEATSDOC2STRUCT,
%       VLT.FILE.CUSTOM_FILE_FORMATS.VHSB_WRITE

% Input argument validation
arguments
    doc_in (1,1) {mustBeA(doc_in,'ndi.document')}
    beats {mustBeA(beats,'struct')}
end

% Convert beat time to datenum if necessary
beats = struct2table(beats);
ind = varfun(@isdatetime,beats,'OutputFormat','uniform');
beats = convertvars(beats,ind,'datenum');
beats = table2array(beats);

% Write beats data to binary file
filePath = ndi.file.temp_name;           
vlt.file.custom_file_formats.vhsb_write(filePath,beats(:,1),beats(:,2:end),'use_filelock',0);

doc_out = doc_in.add_file('beats.vhsb',filePath);

end