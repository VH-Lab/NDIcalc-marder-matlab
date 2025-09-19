function ax = HeartBeatsFromDocs(S, options)
%HEARTBEATFROMDOCS - Plots beat statistics overlaid on the raw PPG signal.
%
%   AX = mlt.plot.HeartBeatFromDocs(S)
%
%   This function visualizes pre-calculated heart beat statistics for each
%   subject and record type in an NDI session. It overlays the statistics on
%   top of the **raw, unnormalized** PPG signal.
%
%   It uses helper functions to find the relevant 'ppg_beats' documents and raw
%   signal data. A separate figure is generated for each unique element found.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object containing the PPG data.
%
%   Optional Name-Value Pairs:
%       Linewidth (1,1) double = 1;
%           The line width for the plotted lines.
%
%   Outputs:
%       AX - A column vector of axes handles from all generated plots.
%
%   Example:
%       ax = mlt.plot.HeartBeatFromDocs(mySession, 'Linewidth', 1.5);
%
%   See also mlt.plot.HeartBeat, mlt.doc.getHeartBeats, mlt.ppg.getRawData

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.Linewidth (1,1) double = 1
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
        
        % Get the beat data from the document
        [docs, beats_data] = mlt.doc.getHeartBeats(S, subject_name, record_type);
        
        % It's possible an element exists but has no beat document yet
        if isempty(docs)
            continue;
        end
        
        % Get the raw PPG data
        [d, t] = mlt.ppg.getRawData(S, subject_name, record_type);
        
        % Assume the first document is the one to plot
        beats = beats_data{1};
        
        % Plot beats using the core plotting function
        ax_here = mlt.plot.HeartBeat(beats, d, t, 'Linewidth', options.Linewidth);
        ax = [ax; ax_here(:)];
        
        % Add a title to the new figure using the subject name and element object
        figure(get(ax_here(1), 'Parent'));
        title_str = [subject_name ': ' element.elementstring()];
        sgtitle(title_str, 'Interpreter', 'none');
    end
end
end