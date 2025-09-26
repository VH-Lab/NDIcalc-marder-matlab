function docList = makeVoltageOffsets(S)
% MAKEVOLTAGEOFFSETS - Create NDI documents from a table of voltage offset values.
%
% DOCLIST = MAKEVOLTAGEOFFSETS(S)
%
% Reads a comma-separated value file named 'MEoffset.txt' from the NDI session's
% directory. This file should contain microelectrode voltage offset data. The function
% then creates 'electrode_offset_voltage' documents in the NDI database for any
% new offset values.
%
% The 'MEoffset.txt' file must have the following columns:
%   - "probeName": The name of the probe associated with the offset.
%   - "offsetV": The voltage offset value.
%   - "T": The temperature at which the offset was measured.
%
% If the file does not exist, the function issues a warning and takes no action.
%
% INPUTS:
%   S: (ndi.session) The NDI session object.
%
% OUTPUTS:
%   docList: (cell array of ndi.document) A cell array of any newly created
%            'electrode_offset_voltage' documents. These documents are also
%            added to the session's database.
%
% EXAMPLE:
%   % Create a 'MEoffset.txt' file in the session directory with the columns:
%   % probeName,offsetV,T
%   % dgn_1,0.005,22.5
%
%   % Assuming S is a valid NDI session object
%   new_docs = ndi.setup.conv.marder.probeMap.makeVoltageOffsets(S);
%
% See also: readtable, ndi.document

arguments
   S (1,1) ndi.session
end

docList = {};

filenameNoPath = 'MEoffset.txt';

filename = fullfile(S.path(),filenameNoPath);

if isfile(filename)
    t = readtable(filename,'delimiter',',')
else
    warning(['No file ' char(filename) ' found -- no action taken.']);
    return;
end

for i=1:size(t,1) % for each row
    p = S.getprobes('name',char(t{i,"probeName"}));
    assert(~isempty(p),['Unable to find probe ' char(t{i,"probeName"}) '.']);
    v = t{i,"offsetV"};
    temp = t{i,"T"};
    % see if we already have this document
    q1 = ndi.query('','isa','electrode_offset_voltage');
    q2 = ndi.query('','depends_on','probe_id',p{1}.id());
    q3 = ndi.query('electrode_offset_voltage.offset','exact_number',v);
    q = q1 & q2 & q3;
    if ~isnan(temp)
        q4 = ndi.query('electrode_offset_voltage.temperature','exact_number',temp);
        q = q & q4;
    end

    d = S.database_search(q);
    if isempty(d) % if we don't have one, make one
       electrode_offset_voltage = [];
       electrode_offset_voltage.offset = v;
       electrode_offset_voltage.temperature = temp;
       docList{end+1} = ndi.document('electrode_offset_voltage','electrode_offset_voltage',electrode_offset_voltage) +...
          S.newdocument();
       docList{end} = docList{end}.set_dependency_value('probe_id',p{1}.id());
    end

end

if ~isempty(docList)
    S.database_add(docList);
end
