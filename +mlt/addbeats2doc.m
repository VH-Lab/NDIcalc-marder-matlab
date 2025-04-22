function [doc] = addbeats2doc(doc,beats)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

% Convert beat time to datenum if necessary
beats = struct2table(beats);
ind = varfun(@isdatetime,beats,'OutputFormat','uniform');
beats = convertvars(beats,ind,'datenum');
beats = table2array(beats);

% Write beats data to binary file
filePath = ndi.file.temp_name;           
vlt.file.custom_file_formats.vhsb_write(filePath,beats(:,1),beats(:,2:end),'use_filelock',0);

doc = doc.add_file('beats.vhsb',filePath);

end