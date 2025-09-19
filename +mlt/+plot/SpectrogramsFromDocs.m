function ax = SpectrogramsFromDocs(S, options)
% SPECTROGRAMSFROMDOCS - Plot spectrograms from NDI document data for each subject.
%
%   AX = mlt.plot.SpectrogramsFromDocs(S, ...)
%
%   Plots all available spectrograms from all subjects and record types
%   ('heart', 'pylorus', 'gastric') into a single figure with multiple subplots.
%
%   The function first loops through all subjects and record types to find all
%   available spectrograms and determine the total number of subplots needed.
%   It then creates a single figure and plots each spectrogram in a separate
%   subplot. Finally, it links the axes of all subplots.
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
%
%   Outputs:
%       ax - A column vector of all created axes handles.
%
%   Example:
%       % Plot all spectrograms with a colorbar and a 'hot' colormap
%       ax = mlt.plot.SpectrogramsFromDocs(mySession, 'colorbar', true, 'colormapName', 'hot');
%
%   See also: mlt.plot.Spectrogram, mlt.doc.getSpectrogramData, mlt.ndi.getElement

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.colorbar (1,1) logical = false
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula'
end

ax = [];
record_types = {'heart', 'pylorus', 'gastric'};
plots_to_make = {};

% Find all subjects in the session
subject_docs = S.database_search(ndi.query('','isa','subject'));
if isempty(subject_docs)
    disp('No subjects found in this session.');
    return;
end

% --- Step 1: Pre-computation loop to gather data ---
for i = 1:numel(subject_docs)
    subject_name = subject_docs{i}.document_properties.subject.local_identifier;
    for j = 1:numel(record_types)
        record_type = record_types{j};

        try
            element = mlt.ndi.getElement(S, subject_name, record_type);
        catch
            continue; % Skip if element doesn't exist
        end

        [~, spectrogram_data] = mlt.doc.getSpectrogramData(S, subject_name, record_type);

        if ~isempty(spectrogram_data)
            for k = 1:numel(spectrogram_data)
                plot_info.data = spectrogram_data{k};
                plot_info.title = [subject_name ': ' element.elementstring()];
                plots_to_make{end+1} = plot_info;
            end
        end
    end
end

if isempty(plots_to_make)
    disp('No spectrograms found to plot.');
    return;
end

% --- Step 2: Create a single figure and plot all spectrograms ---
fig = figure;
total_subplots = numel(plots_to_make);

for i = 1:total_subplots
    plot_info = plots_to_make{i};

    ax(i,1) = subplot(total_subplots, 1, i);
    mlt.plot.Spectrogram(plot_info.data.spec, plot_info.data.f, plot_info.data.ts, ...
        'colorbar', options.colorbar, ...
        'maxColorPercentile', options.maxColorPercentile, ...
        'colormapName', options.colormapName);

    title(plot_info.title, 'Interpreter', 'none');
end

% --- Step 3: Link all subplot axes ---
if ~isempty(ax)
    linkaxes(ax, 'xy');
end

end