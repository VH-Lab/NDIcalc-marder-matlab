function abfprobetable2probemap(S,options)
% ABFPROBETABLE2PROBEMAP - Create epochprobemap files from a probe table.
%
%   ABFPROBETABLE2PROBEMAP(S, [OPTIONS])
%
%   Creates '.epochprobemap.txt' files for a Marder Lab NDI session. This function
%   reads all Axon Binary Files (*.abf) in the session directory and uses a
%   'probeTable.csv' file to map recording channels to probes and subjects for
%   each epoch.
%
%   This function is essential for linking the raw data channels in ABF files
%   to the higher-level probe and subject information managed by NDI.
%
% INPUTS:
%   S: (ndi.session or ndi.dataset) An NDI session or dataset object. The function
%      operates on the directory associated with this object.
%   OPTIONS: (Optional) A struct with the following fields:
%     acquisitionDelay: (duration) The minimum time that must have passed since
%                       an ABF file's creation to be processed. Useful for
%                       avoiding incomplete files. Default is `seconds(0)`.
%     overwrite: (logical) If true, existing epochprobemap files will be
%                overwritten. If false, they will be skipped. Default is `false`.
%
% OUTPUTS:
%   This function does not return any values but writes a '.epochprobemap.txt'
%   file for each new or specified ABF file in the session directory.
%
% EXAMPLE:
%   % Assuming S is a valid NDI session object
%   % Create epochprobemap files for all new ABF files
%   ndi.setup.conv.marder.probeMap.abfprobetable2probemap(S);
%
%   % Overwrite all existing epochprobemap files
%   ndi.setup.conv.marder.probeMap.abfprobetable2probemap(S, 'overwrite', true);
%
% See also: ndi.session, ndi.dataset, ndi.epoch.epochprobemap_daqsystem,
%   ndi.setup.conv.marder.probeMap.channelnametable2probename, ndr.format.axon.read_abf_header

% Input argument validation
arguments
    S (1,1) {mustBeA(S, ["ndi.session", "ndi.dataset"])}
    options.acquisitionDelay (1,1) duration = seconds(0)
    options.overwrite (1,1) logical = false
end

dirname = S.getpath();

probetable = readtable([dirname filesep 'probetable.csv'],'Delimiter',',');

daqname = 'marder_abf';

% Add subjects to database (if not already added or overwriting)
s = dir([dirname filesep  'subje*.txt']);
subject = cell(size(s));
for i=1:numel(s)
    subject{i} = fileread([dirname filesep s(i).name]);
    mysub = S.database_search(ndi.query('subject.local_identifier','exact_string',subject{i}));
    if options.overwrite
        S.database_rm(mysub);
        mysub = [];
    end
    if isempty(mysub)
        mysub = ndi.subject(subject{i},'Crab from Eve Marder Lab at Brandeis');
        mysubdoc = mysub.newdocument + S.newdocument();
        S.database_add(mysubdoc);
    end
end

% Find abf files that do not yet have accompanying epochprobemaps
d = dir([dirname filesep '*.abf']);
if options.overwrite
    epoch_i = 1:numel(d);
else
    epm = dir([dirname filesep '*.epochprobemap.txt']);
    epm_fileNames = {epm(:).name};
    fileNames = extractBefore(epm_fileNames,'.');
    missing = ~contains({d(:).name},fileNames);

    % Skip files that do not meet input criterion
    timeDelay = datetime('now') - datetime([d(:).datenum],'ConvertFrom','datenum');
    skip = timeDelay < options.acquisitionDelay;

    epoch_i = find(missing & ~skip);
end

% Create epochprobemaps
for i = epoch_i
    h = ndr.format.axon.read_abf_header([dirname filesep d(i).name]);
    for k=1:numel(s)
        probemap = ndi.epoch.epochprobemap_daqsystem('stimulation',k,'stimulator',...
            'marder_abf:ai1',subject{k});
    end

    for j=1:numel(h.recChNames)
        [name,ref,probeType,subjectlist] = ...
            ndi.setup.conv.marder.probeMap.channelnametable2probename(h.recChNames{j},probetable);
        daqsysstr = ndi.daq.daqsystemstring(daqname,{'ai'},j);
        for z=1:numel(name)
            probemap(end+1) = ndi.epoch.epochprobemap_daqsystem(name{z},ref(z),probeType{z},...
                daqsysstr.devicestring(),subjectlist{z});
        end
    end
    [~,myfile,~] = fileparts([dirname filesep d(i).name]);
    probemap.savetofile([dirname filesep myfile '.epochprobemap.txt']);
end
