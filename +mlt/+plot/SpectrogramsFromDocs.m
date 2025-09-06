function ax = SpectrogramsFromDocs(S, options)
%SPECTROGRAMSFROMDOCS - Plot spectrograms from NDI document data.
%
%   AX = mlt.plot.SpectrogramsFromDocs(S)
%
%   Plots spectrograms for all 'ppg' probes found within an ndi.session or
%   ndi.dataset object S. The spectrograms for all probes are plotted as
%   subplots within a single figure.
%
%   This function queries the NDI database for documents of type 'spectrogram'
%   associated with each PPG element. It then reads the spectrogram data,
%   frequency vector, and time vector directly from the NDI document and
%   its associated binary data store.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Optional Name-Value Pairs:
%       colorbar (1,1) logical = false
%           Set to true to display a color bar for each spectrogram.
%       maxColorPercentile (1,1) double = 99
%           The percentile of the data to use as the maximum value for the
%           color scale, clipping extreme values. Must be between 0 and 100.
%       colormapName (1,:) char = 'parula'
%           The name of the colormap to use (e.g., 'jet', 'hot', 'gray').
%       numSubplots (1,1) double = 4
%           The number of vertical subplots to prepare in the figure.
%
%   Outputs:
%       ax - A column vector of axes handles for the generated subplots.
%
%   Example 1: Basic usage
%       % Assuming 'mySession' is an ndi.session object
%       ax = mlt.plot.SpectrogramsFromDocs(mySession);
%
%   Example 2: Plot with 8 subplots and a different colormap
%       ax = mlt.plot.SpectrogramsFromDocs(mySession, 'numSubplots', 8, 'colormapName', 'jet');
%
%   See also mlt.plot.Spectrogram, ndi.session, ndi.document

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
    options.numSubplots (1,1) double = 4
end

p = S.getprobes('type','ppg');

if isempty(p)
    disp('No PPG probes found in the session.');
    ax = [];
    return;
end

fig = figure;
ax = [];

for i=1:numel(p)
    disp(['Processing element ' p{i}.elementstring '...']);
    e_cell = S.getelements('element.name',[p{i}.name '_lp_whole'],'element.reference',p{i}.reference);
    if isempty(e_cell)
        warning(['No ''_lp_whole'' version of ' p{i}.elementstring ' found. Skipping.']);
        continue;
    end
    e = e_cell{1};
    et = e.epochtable();
    
    % Find spectrogram document
    doc = ndi.database.fun.finddocs_elementEpochType(S,e.id(),et(1).epoch_id,'spectrogram');
    if isempty(doc)
        warning(['Spectrogram document not found for ' p{i}.elementstring '. Skipping.']);
        continue;
    elseif isscalar(doc)
        doc = doc{1};
    else
        warning(['More than one spectrogram document found for ' p{i}.elementstring '. Skipping.']);
        continue;
    end
    
    % Load spectrogram, timestamps, and frequencies from document
    ngrid = doc.document_properties.ngrid;
    specProp = doc.document_properties.spectrogram;
    specDoc = database_openbinarydoc(S, doc, 'spectrogram_results.ngrid');
    spec = ndi.fun.data.readngrid(specDoc,ngrid.data_dim,ngrid.data_type);
    database_closebinarydoc(S, specDoc);
    
    freqCoords = ngrid.data_dim(specProp.frequency_ngrid_dim);
    timeCoords = ngrid.data_dim(specProp.timestamp_ngrid_dim);
    f = ngrid.coordinates(1:freqCoords);
    ts = ngrid.coordinates(freqCoords + (1:timeCoords));
    
    % Plot spectrogram
    figure(fig);
    ax(end+1,1) = subplot(options.numSubplots, 1, i);
    mlt.plot.Spectrogram(spec, f, ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName);
        
    title(e.elementstring, 'Interpreter', 'none');
end

if ~isempty(ax)
    linkaxes(ax,'xy');
end

end