function ax = graceHeartBeatPlot(S, options)
% GRACEHEARTBEATPLOT - Plot heart beat statistics for PPG elements in an NDI session/dataset.
%
%   AX = GRACEHEARTBEATPLOT(S) plots heart beat statistics (raw PPG signal,
%   instantaneous beat frequency, and duty cycle) for all 'ppg' probes found
%   within the ndi.session or ndi.dataset object S.  A separate figure is
%   created for *each* 'ppg' probe.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Optional Inputs:
%       options.Linewidth (1,1) double = 1;
%           The line width to use for the plots (PPG signal, beat
%           frequency, and duty cycle).
%
%   Outputs:
%       AX - A column vector of axes handles.  Each set of 3 axes handles
%            (corresponding to the 3 subplots in a figure) is concatenated
%            vertically.  So, if there are two 'ppg' probes, AX will be a
%            6x1 vector.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = graceHeartBeatPlot(mySession);
%
%   Example 2: Specifying a custom line width
%       ax = graceHeartBeatPlot(mySession, 'Linewidth', 2);
%
%   See also gracePlotHeartBeat, ndi.session, ndi.dataset

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.Linewidth (1,1) double = 1
end

p = S.getprobes('type','ppg');

path = S.path();

ax = [];

for i=1:numel(p),
    disp(['Checking to see if we have already downsampled ' p{i}.elementstring '...']);
    e = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e),
        error(['No ''_lp'' version of ' p{i}.elementstring]);
    end
    e = e{1};
    et = e.epochtable();

    % Find spectrogram document
    doc = mlt.findDocs(S,e.id(),et(1).epoch_id,'spectrogram');
    if isempty(doc)
        error(['Spectrogram document needs to be created for this session ' ...
            'prior to plotting.'])
    elseif isscalar(doc)
        doc = doc{1};
    else
        error(['More than one spectrogram document found matching the ' ...
            'element and epoch id.'])
    end
    
    ppgDoc = database_openbinarydoc(S, doc, 'beats.vhsb');
    [Y,X] = vlt.file.custom_file_formats.vhsb_read(ppgDoc,-Inf,Inf,0);

    % Load spectrogram, timestamps, and frequencies
    ngrid = doc.document_properties.ngrid;
    specProp = doc.document_properties.spectrogram;
    specDoc = database_openbinarydoc(S, doc, 'spectrogram_results.ngrid');
    spec = mlt.readngrid(specDoc,ngrid.data_dim,ngrid.data_type);
    database_closebinarydoc(S, specDoc);
    freqCoords = ngrid.data_dim(specProp.frequency_ngrid_dim);
    timeCoords = ngrid.data_dim(specProp.timestamp_ngrid_dim);
    f = ngrid.coordinates(1:freqCoords);
    ts = ngrid.coordinates(freqCoords + (1:timeCoords));

    % filename = fullfile(path,['ppg_' e{1}.name '_' int2str(e{1}.reference) '_beats.mat'])
    % load(filename,'-mat');
    ax_here = mlt.gracePlotHeartBeat(beats, d, t, 'Linewidth', options.Linewidth); % Pass Linewidth
    ax = cat(1,ax,ax_here(:));
    subplot(3,1,1);
    sgtitle([e{1}.elementstring],'interp','none');
end

