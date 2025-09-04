function ax = plotInhibitoryBoutOnsetOffset(OnsetData, OffsetData, options) % Added options argument
%MLT.PLOTINHIBITORYBOUTONSETOFFSET Plot spectrogram analysis results around onset/offset.
%
%   AX = mlt.plotInhibitoryBoutOnsetOffset(ONSETDATA, OFFSETDATA, Name, Value, ...)
%
%   Creates a 3-panel figure summarizing the spectrogram analysis results
%   obtained from `mlt.spectrogramInhibitoryBoutOnsetOffsetAnalysis`.
%
%   Inputs:
%       ONSETDATA  - Structure containing results from analyzing windows before onsets:
%           .specData_matrix   - Matrix of time-averaged spectra (freq x bouts).
%           .f                 - Frequency vector (column).
%           .fwhm_vector       - Row vector of FWHM values.
%           .low_cutoff_vector - Row vector of low cutoffs.
%           .high_cutoff_vector- Row vector of high cutoffs.
%       OFFSETDATA - Structure containing results from analyzing windows after offsets
%                    (same fields as ONSETDATA).
%
%   Optional Name/Value Pair Arguments:
%       CapSize    - (Default: 15) Numeric scalar specifying the size of the
%                    error bar caps in points for the FWHM plot.
%
%   Outputs:
%       AX         - A 3x1 vector of axes handles for the three subplots created.
%
%   Figure Panels:
%       1. Top Panel: Plots the absolute value of individual time-averaged spectra
%          (gray lines) and the mean absolute spectrum (black line) for the
%          OnsetData vs. frequency. Title: 'Prior to onset'. Y-axis: 'Power'.
%          X-axis: 'Frequency (Hz)'.
%       2. Middle Panel: Plots the absolute value of individual time-averaged spectra
%          (gray lines) and the mean absolute spectrum (black line) for the
%          OffsetData vs. frequency. Title: 'After offset'. Y-axis: 'Power'.
%          X-axis: 'Frequency (Hz)'.
%       3. Bottom Panel: Bar graph comparing a modified FWHM measure
%          (high_cutoff - max(0, low_cutoff)) between OnsetData and OffsetData.
%          Individual data points are overlaid with jitter. Error bars show SEM
%          (plotted thicker, brought to front, cap size adjustable).
%          Title displays the p-value from a paired t-test between the groups.
%          Y-axis: 'FWHM (Hz)'. X-axis labels: 'Onset', 'Offset'.
%
%   Requires:
%       - NDI toolbox (+ndi)
%       - vhlab-toolbox-matlab (+vlt), specifically vlt.signal.fwhm (used by mlt.spectrogramFWHM)
%       - NDIcalc-marder-matlab (+mlt), specifically mlt.spectrogramFWHM,
%         mlt.readSpectrogramTimeWindow, and this function
%         (mlt.plotInhibitoryBoutOnsetOffset).
%       - Associated helper functions like `ndi.fun.data.readngrid` (if not standard)

% --- Input Validation ---
arguments
    OnsetData (1,1) struct {mustContainFields(OnsetData, {'specData_matrix', 'f', 'fwhm_vector', 'low_cutoff_vector', 'high_cutoff_vector'})}
    OffsetData (1,1) struct {mustContainFields(OffsetData, {'specData_matrix', 'f', 'fwhm_vector', 'low_cutoff_vector', 'high_cutoff_vector'})}
    % Optional Name-Value arguments
    options.CapSize (1,1) double {mustBeNumeric, mustBeNonnegative} = 15 % Removed mustBeScalar, (1,1) enforces it
end
% --- End Input Validation ---

% --- Check for data consistency ---
if ~isempty(OnsetData.f) && ~isempty(OffsetData.f) && ~isequal(OnsetData.f, OffsetData.f)
    warning('Frequency vectors in OnsetData and OffsetData do not match. Plotting based on OnsetData frequency vector.');
    if isempty(OnsetData.f), OnsetData.f = OffsetData.f; end
    OffsetData.f = OnsetData.f;
elseif isempty(OnsetData.f) && ~isempty(OffsetData.f)
     OnsetData.f = OffsetData.f;
elseif ~isempty(OnsetData.f) && isempty(OffsetData.f)
     OffsetData.f = OnsetData.f;
end

if isempty(OnsetData.f) && isempty(OffsetData.f)
    warning('No frequency information available in either OnsetData or OffsetData. Cannot plot spectra.');
    f = [];
else
    f = OnsetData.f; % Use the (now consistent) frequency vector
end

% --- Create Figure ---
fig = figure;
ax = gobjects(3,1); % Initialize axes handles array

% --- Panel 1: Onset Data Spectrum ---
ax(1) = subplot(3, 1, 1);
hold on;
if ~isempty(OnsetData.specData_matrix) && ~isempty(f)
    plot(f, abs(OnsetData.specData_matrix), 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    meanOnsetSpec = mean(abs(OnsetData.specData_matrix), 2, 'omitnan');
    plot(f, meanOnsetSpec, 'k', 'LineWidth', 2);
    ylabel('Power');
    title('Prior to onset');
    box off;
else
    title('Prior to onset (No Data)');
    ylabel('Power');
    box off;
end
xlabel('Frequency (Hz)');
set(gca,'XTickLabel',[]);
hold off;

% --- Panel 2: Offset Data Spectrum ---
ax(2) = subplot(3, 1, 2);
hold on;
if ~isempty(OffsetData.specData_matrix) && ~isempty(f)
    plot(f, abs(OffsetData.specData_matrix), 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    meanOffsetSpec = mean(abs(OffsetData.specData_matrix), 2, 'omitnan');
    plot(f, meanOffsetSpec, 'k', 'LineWidth', 2);
    ylabel('Power');
    title('After offset');
    box off;
else
    title('After offset (No Data)');
    ylabel('Power');
    box off;
end
xlabel('Frequency (Hz)');
set(gca,'XTickLabel',[]);
hold off;

% --- Panel 3: FWHM Comparison ---
ax(3) = subplot(3, 1, 3);
hold on;

% Calculate modified FWHM
fwhm_mod_onset = OnsetData.high_cutoff_vector - max(0, OnsetData.low_cutoff_vector);
fwhm_mod_offset = OffsetData.high_cutoff_vector - max(0, OffsetData.low_cutoff_vector);
fwhm_mod_onset = fwhm_mod_onset(:)'; % Ensure row vector
fwhm_mod_offset = fwhm_mod_offset(:)';

% Identify valid paired data
valid_paired = ~isnan(fwhm_mod_onset) & ~isnan(fwhm_mod_offset);
fwhm_onset_paired = fwhm_mod_onset(valid_paired);
fwhm_offset_paired = fwhm_mod_offset(valid_paired);

bar_means = [NaN, NaN];
bar_sems = [NaN, NaN];
p_value = NaN;
eb_h = []; % Initialize error bar handle

if sum(valid_paired) >= 2 % Need at least 2 pairs for stats and t-test
    bar_means = [mean(fwhm_onset_paired), mean(fwhm_offset_paired)];
    bar_sems = [std(fwhm_onset_paired)/sqrt(sum(valid_paired)), std(fwhm_offset_paired)/sqrt(sum(valid_paired))];

    % Paired t-test
    [~, p_value] = ttest(fwhm_onset_paired, fwhm_offset_paired);

    % Plot Bar Graph
    bar_h = bar([1 2], bar_means, 0.6);
    bar_h.FaceColor = 'flat';
    bar_h.CData(1,:) = [0.5 0.5 0.5];
    bar_h.CData(2,:) = [0.2 0.2 0.2];

    % Plot Scatter Points with Jitter (before error bars)
    num_points = sum(valid_paired);
    x_jitter_onset = 1 + (rand(1, num_points) - 0.5) * 0.4;
    x_jitter_offset = 2 + (rand(1, num_points) - 0.5) * 0.4;
    plot(x_jitter_onset, fwhm_onset_paired, 'o', 'MarkerSize', 5, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', 'k');
    plot(x_jitter_offset, fwhm_offset_paired, 'o', 'MarkerSize', 5, 'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerEdgeColor', 'k');

    % Plot Error Bars (thicker, specified cap size)
    eb_h = errorbar([1 2], bar_means, bar_sems, 'k.', 'LineWidth', 2, 'CapSize', options.CapSize); % Use options.CapSize

    title_str = ['Paired t-test p = ' num2str(p_value, '%.3g')];
else
    warning('Not enough valid paired data points (need at least 2) for statistics or t-test.');
     % Still plot bars if means are calculable (N>=1)
     valid_onset_indices = ~isnan(fwhm_mod_onset);
     valid_offset_indices = ~isnan(fwhm_mod_offset);
     if sum(valid_onset_indices)>0, bar_means(1) = mean(fwhm_mod_onset(valid_onset_indices)); end
     if sum(valid_offset_indices)>0, bar_means(2) = mean(fwhm_mod_offset(valid_offset_indices)); end
     bar_h = bar([1 2], bar_means, 0.6);
     bar_h.FaceColor = 'flat';
     bar_h.CData(1,:) = [0.5 0.5 0.5];
     bar_h.CData(2,:) = [0.2 0.2 0.2];
     title_str = 'FWHM Comparison (paired t-test N/A)';
end

% Bring error bars to front if they were plotted
if ~isempty(eb_h) && ishandle(eb_h)
    uistack(eb_h, 'top');
end

% Set Axes Properties for Panel 3
set(gca, 'XTick', [1 2], 'XTickLabel', {'Onset', 'Offset'});
ylabel('FWHM (Hz)');
xlim([0.5 2.5]);
title(title_str);
box off;
hold off;

% Link x-axes of top two plots if they have data
if ~isempty(ax(1).Children) && ~isempty(ax(2).Children)
   linkaxes(ax(1:2),'x');
end

end % function plotInhibitoryBoutOnsetOffset


% --- Local Validation Function ---
function mustContainFields(value, requiredFields)
%MUSTCONTAINFIELDS Custom validation function for arguments block.
%   Checks if the input structure 'value' contains all fields listed in
%   the cell array 'requiredFields'. Throws an error if any field is missing.

    if ~isstruct(value) || ~isscalar(value)
        error('Input must be a scalar structure.');
    end

    missingFields = {};
    for i = 1:numel(requiredFields)
        if ~isfield(value, requiredFields{i})
            missingFields{end+1} = requiredFields{i};
        end
    end

    if ~isempty(missingFields)
        error('Input structure is missing required field(s): %s', strjoin(missingFields, ', '));
    end
end

% Helper function for arguments block validation
function mustBeSameSize(a,b)
    if ~isequal(size(a), size(b))
        eid = 'Size:notEqual';
        msg = 'Input datetime vectors must have the same size.';
        throwAsCaller(MException(eid,msg))
    end
end