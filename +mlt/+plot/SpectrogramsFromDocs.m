function ax = SpectrogramsFromDocs(S, options)
% SPECTROGRAMSFROMDOCS - Plot spectrograms from NDI document data for each subject.
%
%   AX = mlt.plot.SpectrogramsFromDocs(S, ...)
%
%   Plots spectrograms for each subject and for each of the record types
%   'heart', 'pylorus', and 'gastric'. For each subject and record type,
%   this function searches for a unique NDI element. If found, it then
%   searches for all associated 'spectrogram' documents.
%
%   A new figure is created for each element, and all of its spectrograms
%   are plotted as subplots. This function uses `mlt.doc.getSpectrogramData`
%   to retrieve the data, which automatically converts time to `datetime`
%   if a global clock is available.
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

% Find all subjects in the session
subject_docs = S.database_search(ndi.query('','isa','subject'));
if isempty(subject_docs)
    disp('No subjects found in this session.');
    return;
end

% Loop through each subject and record type
for i = 1:numel(subject_docs)
    subject_name = subject_docs{i}.document_properties.subject.local_identifier;
    for j = 1:numel(record_types)
        record_type = record_types{j};
        
        % Use a narrow try/catch block specifically to check for element existence
        try
            element = mlt.ndi.getElement(S, subject_name, record_type);
        catch
            % Silently skip if a unique element is not found for this combination
            continue;
        end

        % If we proceed, the element exists. Any subsequent errors are real problems.

        % Get the spectrogram data from the document
        [docs, spectrogram_data] = mlt.doc.getSpectrogramData(S, subject_name, record_type);

        % It's possible an element exists but has no spectrogram document yet
        if isempty(docs)
            continue;
        end

        % Create a new figure for this element
        fig = figure;

        current_axes = [];
        % Plot each spectrogram in a subplot
        for k = 1:numel(spectrogram_data)
            data = spectrogram_data{k};

            ax_here = subplot(numel(spectrogram_data), 1, k);
            mlt.plot.Spectrogram(data.spec, data.f, data.ts, ...
                'colorbar', options.colorbar, ...
                'maxColorPercentile', options.maxColorPercentile, ...
                'colormapName', options.colormapName);

            current_axes(end+1,1) = ax_here;
        end

        if ~isempty(current_axes)
            linkaxes(current_axes, 'xy');
            ax = [ax; current_axes(:)];
        end

        % Add a title to the new figure using the subject name and element object
        figure(fig);
        title_str = [subject_name ': ' element.elementstring()];
        sgtitle(title_str, 'Interpreter', 'none');
    end
end
end