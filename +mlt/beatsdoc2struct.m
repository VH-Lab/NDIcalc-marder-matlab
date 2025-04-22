function [beats] = beatsdoc2struct(S,doc)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

% Retrieve data from document
beats_doc = database_openbinarydoc(S, doc, 'beats.vhsb');
[Y,X] = vlt.file.custom_file_formats.vhsb_read(beats_doc,-Inf,Inf,0);
database_closebinarydoc(S, beats_doc);

% Make beats table
beat_fields = split(doc.document_properties.ppg_beats.fields,',');
beats = array2table([X,Y],'VariableNames',beat_fields);

% Reformat onset and offset times to match clocktype
clocktype = ndi.time.clocktype(doc.document_properties.epochclocktimes.clocktype);
if ndi.time.clocktype.isGlobal(clocktype)
    beats.onset = datetime(beats.onset,'ConvertFrom','datenum');
    beats.offset = datetime(beats.offset,'ConvertFrom','datenum');
end

beats = table2struct(beats);

end