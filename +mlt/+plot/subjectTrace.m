function ax = subjectTrace(S, subject_name, record_type, options)
%SUBJECTTRACE Plots a detailed summary trace for a single subject and record.
%
%   AX = mlt.plot.subjectTrace(S, subject_name, record_type)
%
%   Generates a comprehensive 4-panel plot for a single recording from a
%   specific subject. It loads the pre-calculated spectrogram and heart beat
%   data from their respective NDI documents and visualizes them together.
%
%   The layout consists of:
%   - Top Panel (50%): Spectrogram with instantaneous beat frequency overlaid.
%   - Bottom Panels: Three plots showing beat amplitude, duty cycle, and
%     beat duration over time.
%
%   All four plot axes are linked horizontally for synchronized zooming and panning.
%
%   Inputs:
%       S             - An ndi.session or ndi.dataset object.
%       subject_name  - The name of the subject (e.g., 'SubjectA').
%       record_type   - The type of record ('heart', 'gastric', or 'pylorus').
%
%   Optional Name-Value Pair Arguments:
%       Linewidth (1,1) double = 1.5
%           Line width for the time-series plots.
%       ColormapName (1,:) char = 'parula'
%           Colormap for the spectrogram.
%
%   Outputs:
%       ax - A struct containing the handles to the four subplot axes.
%
%   Example:
%       % Plot a summary for Subject A's heart recording
%       ax = mlt.plot.subjectTrace(mySession, 'SubjectA', 'heart');
%
%   See also mlt.probe.getProbe, mlt.spectrogram.readTimeWindow, mlt.beats.beatsdoc2struct

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    subject_name (1,:) char
    record_type (1,:) char {mustBeMember(record_type, {'heart','gastric','pylorus'})}
    options.Linewidth (1,1) double {mustBePositive} = 1.5
    options.ColormapName (1,:) char = 'parula'
end

% --- Step 1: Find the correct probe and element ---
disp('Finding probe and element...');
probe = mlt.probe.getProbe(S, subject_name, record_type);
if isempty(probe)
    error('Could not find a unique probe for subject "%s" and record type "%s".', subject_name, record_type);
end

e = S.getelements('element.name',[probe.name '_lp_whole'],'element.reference',probe.reference);
if isempty(e)
    error('Could not find the ''_lp_whole'' element for probe %s.', probe.elementstring);
end
e = e{1};
et = e.epochtable();
if isempty(et)
    error('Element %s has no epoch table.', e.elementstring);
end
epoch_id = et(1).epoch_id;

% --- Step 2: Load Spectrogram and Beats Documents ---
disp('Loading data from NDI documents...');
% Load Spectrogram
spec_doc = ndi.database.fun.finddocs_elementEpochType(S, e.id(), epoch_id, 'spectrogram');
if isempty(spec_doc), error('Could not find spectrogram document for %s.', e.elementstring); end
[spec, f, ts_spec] = mlt.spectrogram.readTimeWindow(e, datetime(0,'ConvertFrom','datenum'), datetime(inf,'ConvertFrom','datenum'));

% Load Beats
beats_doc = ndi.database.fun.finddocs_elementEpochType(S, e.id(), epoch_id, 'ppg_beats');
if isempty(beats_doc), error('Could not find ppg_beats document for %s.', e.elementstring); end
beats = mlt.beats.beatsdoc2struct(S, beats_doc{1});

% --- Step 3: Prepare Data for Plotting ---
disp('Preparing data for plotting...');
beats_valid = beats([beats.valid]);
onset_times = [beats_valid.onset];

% --- Step 4: Create Plots ---
disp('Generating plots...');
figure('Position', [100 100 1200 800]); % Create a larger figure window

% To make the top plot take up the top half and the bottom three take up the
% bottom half, we can use a 6-row subplot grid.
% Top plot will span rows 1-3. Bottom plots will be in rows 4, 5, and 6.

% PLOT 1: Spectrogram with Beat Frequency Overlay
ax.Spectrogram = subplot(6,1,1:3);
imagesc(ts_spec, f, spec);
set(gca, 'YDir', 'normal');
colormap(gca, options.ColormapName);
ylabel('Frequency (Hz)');
hold on;
% Use plot3 to overlay the frequency trace on top of the 2D image
z_level = max(spec(:)) * ones(size(onset_times)); % Ensure it's on top
plot3(onset_times, [beats_valid.instant_freq], z_level, 'r-', 'LineWidth', options.Linewidth);
hold off;
title_str = sprintf('Subject: %s, Record: %s', subject_name, record_type);
title(title_str, 'Interpreter', 'none');
grid on;

% PLOT 2: Beat Amplitude
ax.Amplitude = subplot(6,1,4);
plot(onset_times, [beats_valid.amplitude], 'b-', 'LineWidth', options.Linewidth);
ylabel('Beat Amplitude');
grid on;

% PLOT 3: Duty Cycle
ax.DutyCycle = subplot(6,1,5);
plot(onset_times, [beats_valid.duty_cycle], 'g-', 'LineWidth', options.Linewidth);
ylabel('Duty Cycle');
grid on;

% PLOT 4: Beat Duration
ax.Duration = subplot(6,1,6);
plot(onset_times, [beats_valid.up_duration], 'm-', 'LineWidth', options.Linewidth);
ylabel('Beat Duration (s)');
xlabel('Time');
grid on;

% Link all axes horizontally
linkaxes([ax.Spectrogram, ax.Amplitude, ax.DutyCycle, ax.Duration], 'x');

% Set a reasonable x-limit to start
if ~isempty(onset_times)
    xlim(ax.Spectrogram, [onset_times(1), onset_times(end)]);
end
disp('Plot generation complete.');

end

