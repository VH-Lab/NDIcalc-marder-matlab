function [OnsetData, OffsetData] = spectrogramInhibitoryBoutOnsetOffsetAnalysis(S, record_name, reference, inhibBoutOnsets, inhibBoutOffsets, skip, timeWindow)
%MLT.SPECTROGRAMINHIBITORYBOUTONSETOFFSETANALYSIS Analyze spectrogram FWHM around inhibition bout onset/offset times.
%
%   [ONSETDATA, OFFSETDATA] = mlt.spectrogramInhibitoryBoutOnsetOffsetAnalysis(S, RECORD_NAME, ...
%       REFERENCE, INHIBBOUTONSETS, INHIBBOUTOFFSETS, SKIP, TIMEWINDOW)
%
%   Analyzes the spectrogram associated with a specified PPG element ('ppg_heart_lp_whole'
%   or 'ppg_pylorus_lp_whole') within session S. It focuses on time windows
%   relative to inhibition bout onset and offset times.
%
%   This function calls `mlt.spectrogramInhibBoutAnalysis` twice:
%   1. For Onsets: It analyzes windows calculated relative to INHIBBOUTONSETS.
%      The window for onset(i) starts at onset(i) - SKIP - TIMEWINDOW and ends
%      at onset(i) - SKIP.
%   2. For Offsets: It analyzes windows calculated relative to INHIBBOUTOFFSETS.
%      The window for offset(i) starts at offset(i) + SKIP and ends at
%      offset(i) + SKIP + TIMEWINDOW.
%
%   It returns the aggregated results for the onset and offset analyses in
%   separate structures.
%
%   Inputs:
%       S                 - An ndi.session or ndi.dataset object.
%       RECORD_NAME       - Character vector or string: 'heart' or 'pylorus'.
%       REFERENCE         - Positive integer scalar: The reference number of the element.
%       INHIBBOUTONSETS   - Column vector of Matlab datetime objects indicating inhibition bout onset times.
%       INHIBBOUTOFFSETS  - Column vector of Matlab datetime objects indicating inhibition bout offset times.
%                           Must be the same size as INHIBBOUTONSETS.
%       SKIP              - Non-negative double scalar: Time offset in seconds used to define
%                           the near edge of the analysis window relative to onset/offset. Allows 0.
%       TIMEWINDOW        - Positive double scalar: Duration in seconds of the analysis window.
%
%   Outputs:
%       ONSETDATA         - Structure containing results from analyzing windows before onsets:
%           .specData_matrix   - Matrix of time-averaged spectra (freq x bouts).
%           .f                 - Frequency vector (column).
%           .fwhm_vector       - Row vector of FWHM values (NaN if failed).
%           .low_cutoff_vector - Row vector of low cutoffs (NaN if failed).
%           .high_cutoff_vector- Row vector of high cutoffs (NaN if failed).
%       OFFSETDATA        - Structure containing results from analyzing windows after offsets:
%           .specData_matrix   - Matrix of time-averaged spectra (freq x bouts).
%           .f                 - Frequency vector (column).
%           .fwhm_vector       - Row vector of FWHM values (NaN if failed).
%           .low_cutoff_vector - Row vector of low cutoffs (NaN if failed).
%           .high_cutoff_vector- Row vector of high cutoffs (NaN if failed).
%                           Returns empty structures with NaN vectors if the
%                           specified element is not found or analysis fails.
%
%   Requires:
%       - NDI toolbox (+ndi)
%       - vhlab-toolbox-matlab (+vlt), specifically vlt.signal.fwhm (used by mlt.spectrogramFWHM)
%       - NDIcalc-marder-matlab (+mlt), specifically mlt.spectrogramFWHM,
%         mlt.readSpectrogramTimeWindow, and this function
%         (mlt.spectrogramInhibitoryBoutOnsetOffsetAnalysis).
%       - Associated helper functions like `ndi.fun.data.readngrid` (if not standard)

% --- Input Validation ---
arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    record_name (1,:) char {mustBeMember(record_name,{'heart','pylorus'})}
    reference (1,1) double {mustBePositive, mustBeInteger}
    inhibBoutOnsets (:,1) datetime
    inhibBoutOffsets (:,1) datetime {mustBeSameSize(inhibBoutOnsets, inhibBoutOffsets)}
    skip (1,1) double {mustBeReal, mustBeNonnegative} % Updated validation to nonnegative
    timeWindow (1,1) double {mustBeReal, mustBePositive}
end
% --- End Input Validation ---

% --- Initialize Outputs ---
common_f = []; % To store the frequency vector and check consistency
num_bouts = numel(inhibBoutOnsets);
OnsetData = struct('specData_matrix', [], 'f', [], 'fwhm_vector', NaN(1, num_bouts), ...
                   'low_cutoff_vector', NaN(1, num_bouts), 'high_cutoff_vector', NaN(1, num_bouts));
OffsetData = struct('specData_matrix', [], 'f', [], 'fwhm_vector', NaN(1, num_bouts), ...
                    'low_cutoff_vector', NaN(1, num_bouts), 'high_cutoff_vector', NaN(1, num_bouts));
first_onset_success = true;
first_offset_success = true;

% --- Find Element ---
element_name = ['ppg_' record_name '_lp_whole'];
e_cell = S.getelements('element.name', element_name, 'element.reference', reference); % 
if isempty(e_cell)
    warning('Could not find element with name "%s" and reference %d. Returning empty structures.', element_name, reference);
    % Ensure outputs are properly initialized as empty/NaN before returning
    OnsetData.fwhm_vector = []; OnsetData.low_cutoff_vector = []; OnsetData.high_cutoff_vector = [];
    OffsetData.fwhm_vector = []; OffsetData.low_cutoff_vector = []; OffsetData.high_cutoff_vector = [];
    return;
elseif numel(e_cell) > 1
    warning('Found multiple elements with name "%s" and reference %d. Returning empty structures.', element_name, reference);
    % Ensure outputs are properly initialized as empty/NaN before returning
    OnsetData.fwhm_vector = []; OnsetData.low_cutoff_vector = []; OnsetData.high_cutoff_vector = [];
    OffsetData.fwhm_vector = []; OffsetData.low_cutoff_vector = []; OffsetData.high_cutoff_vector = [];
     return;
else
    e = e_cell{1}; % 
end

% --- Process Onsets ---
disp('--- Analyzing Onset Windows ---');
% The window should end at onset - skip
% The window should start at onset - skip - timeWindow
% So, relative to the inhibBoutOnset time, the analysis starts at an offset of (-skip - timeWindow)
% and has a duration of +timeWindow.
skip_onset = -skip - timeWindow;
timeWindow_onset = timeWindow; % Positive duration defines end relative to start

[specData_matrix_on, f_on, fwhm_vector_on, low_cutoff_vector_on, high_cutoff_vector_on] = ...
    mlt.spectrogramInhibBoutAnalysis(e, inhibBoutOnsets, skip_onset, timeWindow_onset);

% Assign to output structure
OnsetData.specData_matrix = specData_matrix_on;
OnsetData.f = f_on;
OnsetData.fwhm_vector = fwhm_vector_on;
OnsetData.low_cutoff_vector = low_cutoff_vector_on;
OnsetData.high_cutoff_vector = high_cutoff_vector_on;
% Update common_f if this was the first successful analysis
if ~isempty(f_on)
    common_f = f_on;
    first_onset_success = false; % Mark that onset analysis succeeded at least once with data
end


% --- Process Offsets ---
disp('--- Analyzing Offset Windows ---');
% The window should start at offset + skip
% The window should end at offset + skip + timeWindow
% So, relative to the inhibBoutOffset time, the analysis starts at an offset of +skip
% and has a duration of +timeWindow.
skip_offset = skip;
timeWindow_offset = timeWindow; % Positive duration defines end relative to start

[specData_matrix_off, f_off, fwhm_vector_off, low_cutoff_vector_off, high_cutoff_vector_off] = ...
    mlt.spectrogramInhibBoutAnalysis(e, inhibBoutOffsets, skip_offset, timeWindow_offset);

% Assign to output structure
OffsetData.specData_matrix = specData_matrix_off;
OffsetData.f = f_off;
OffsetData.fwhm_vector = fwhm_vector_off;
OffsetData.low_cutoff_vector = low_cutoff_vector_off;
OffsetData.high_cutoff_vector = high_cutoff_vector_off;
% Update common_f if this was the first successful analysis overall
if ~isempty(f_off) && isempty(common_f)
    common_f = f_off;
    first_offset_success = false; % Mark that offset analysis succeeded at least once with data
end

% --- Final Checks for Frequency Vector Consistency ---
if isempty(OnsetData.f) && isempty(OffsetData.f)
    disp('No successful analysis performed for any onset or offset window.');
elseif isempty(OnsetData.f) && ~isempty(OffsetData.f)
    disp('No successful analysis for onset windows.');
    OnsetData.f = OffsetData.f; % Use offset frequency if onset failed
elseif ~isempty(OnsetData.f) && isempty(OffsetData.f)
    disp('No successful analysis for offset windows.');
    OffsetData.f = OnsetData.f; % Use onset frequency if offset failed
elseif ~isequal(OnsetData.f, OffsetData.f)
    warning('Frequency vectors differ between Onset and Offset data analysis. Returning the one from Onset in both structures.');
    OffsetData.f = OnsetData.f;
end

% Ensure outputs are empty if overall no success
if isempty(common_f)
    OnsetData.specData_matrix = []; OnsetData.f = []; OnsetData.fwhm_vector = []; OnsetData.low_cutoff_vector = []; OnsetData.high_cutoff_vector = [];
    OffsetData.specData_matrix = []; OffsetData.f = []; OffsetData.fwhm_vector = []; OffsetData.low_cutoff_vector = []; OffsetData.high_cutoff_vector = [];
end


end % function spectrogramInhibitoryBoutOnsetOffsetAnalysis


% Helper function for arguments block validation
function mustBeSameSize(a,b)
    if ~isequal(size(a), size(b))
        eid = 'Size:notEqual';
        msg = 'Input datetime vectors must have the same size.';
        throwAsCaller(MException(eid,msg))
    end
end