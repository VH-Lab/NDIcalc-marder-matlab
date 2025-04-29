function [specData_matrix, f, fwhm_vector, low_cutoff_vector, high_cutoff_vector] = spectrogramInhibBoutAnalysis(e, inhibBoutTimes, skip, timeWindow)
%MLT.SPECTROGRAMINHIBBOUTANALYSIS Analyze spectrogram FWHM around inhibition bout times.
%
%   [SPECDATA_MATRIX, F, FWHM_VECTOR, LOW_CUTOFF_VECTOR, HIGH_CUTOFF_VECTOR] = ...
%       mlt.spectrogramInhibBoutAnalysis(E, INHIBBOUTTIMES, SKIP, TIMEWINDOW)
%
%   Analyzes the spectrogram associated with an ndi.element E around specified
%   inhibition bout times. For each time provided in INHIBBOUTTIMES, it defines
%   a time window starting at INHIBBOUTTIMES(i) + SKIP and lasting for
%   TIMEWINDOW seconds. It calculates the time-averaged spectrogram within that
%   window and computes its Full Width at Half Maximum (FWHM).
%
%   Inputs:
%       E              - An ndi.element object. The session is retrieved from e.session.
%                        The element should have associated 'spectrogram' documents.
%       INHIBBOUTTIMES - A vector of Matlab datetime objects indicating the
%                        start times of inhibition bouts.
%       SKIP           - A double scalar indicating the time offset in seconds
%                        relative to each inhibBoutTime to start the analysis window.
%                        Can be positive or negative.
%       TIMEWINDOW     - A double scalar indicating the duration in seconds of the
%                        analysis window. Can be positive (window goes forward
%                        from start) or negative (window goes backward from start).
%
%   Outputs:
%       SPECDATA_MATRIX   - A matrix where each column is the time-averaged
%                           power spectrum (column vector) calculated for the
%                           window corresponding to each entry in INHIBBOUTTIMES.
%                           If analysis fails for a specific bout time, the
%                           corresponding column might be omitted or filled
%                           with NaNs depending on downstream processing needs
%                           (currently, only successful results are concatenated).
%                           Returns [] if no successful analyses are performed.
%       F                 - The frequency vector (numeric column vector)
%                           corresponding to the rows of SPECDATA_MATRIX. Assumes
%                           the frequency vector is consistent across all analyses.
%                           Returns [] if no successful analyses are performed.
%       FWHM_VECTOR       - A row vector containing the FWHM value for each
%                           successfully analyzed time window. Contains NaN for
%                           windows where calculation failed or was not possible.
%       LOW_CUTOFF_VECTOR - A row vector containing the lower frequency cutoff
%                           at half maximum for each successfully analyzed window.
%                           Contains NaN for windows where calculation failed.
%       HIGH_CUTOFF_VECTOR- A row vector containing the upper frequency cutoff
%                           at half maximum for each successfully analyzed window.
%                           Contains NaN for windows where calculation failed.
%
%   Requires:
%       - NDI toolbox (+ndi)
%       - vhlab-toolbox-matlab (+vlt), specifically vlt.signal.fwhm
%       - NDIcalc-marder-matlab (+mlt), specifically mlt.readSpectrogramTimeWindow
%         and this function (mlt.spectrogramInhibBoutAnalysis).
%       - Associated helper functions like `mlt.readngrid` (if not standard)

% --- Input Validation ---
arguments
    e (1,1) {mustBeA(e,'ndi.element')}
    inhibBoutTimes (:,1) {mustBeA(inhibBoutTimes,'datetime')} % Ensure it's a column vector
    skip (1,1) double {mustBeReal}
    timeWindow (1,1) double {mustBeReal}
end
% --- End Input Validation ---

% Initialize outputs
specData_matrix = [];
f = [];
fwhm_vector = NaN(1, numel(inhibBoutTimes));       % Pre-allocate with NaN
low_cutoff_vector = NaN(1, numel(inhibBoutTimes)); % Pre-allocate with NaN
high_cutoff_vector = NaN(1, numel(inhibBoutTimes));% Pre-allocate with NaN
first_success = true; % Flag to capture the first valid frequency vector

% --- Loop through each inhibition bout time ---
for i = 1:numel(inhibBoutTimes)
    t_inhib = inhibBoutTimes(i);

    % Define time window boundaries
    t_start = t_inhib + seconds(skip);
    t_end = t_start + seconds(timeWindow);
    
    % Ensure t0 is the earlier time, t1 is the later time
    t0 = min(t_start, t_end);
    t1 = max(t_start, t_end);
    
    disp(['Analyzing window: ' datestr(t0) ' to ' datestr(t1) ' ...']);

    % --- Get Spectrogram Data and FWHM for the window ---
    try
        [specData_avg_single, f_single, fwhm_val_single, low_cutoff_single, high_cutoff_single] = ...
            mlt.spectrogramFWHM(e, t0, t1); % Call the FWHM function

        if ~isempty(specData_avg_single) && ~isempty(f_single)
            % Handle frequency vector consistency
            if first_success
                f = f_single(:); % Store the first valid frequency vector (as column)
                specData_matrix = specData_avg_single(:); % Initialize matrix with first result
                fwhm_vector(i) = fwhm_val_single;
                low_cutoff_vector(i) = low_cutoff_single;
                high_cutoff_vector(i) = high_cutoff_single;
                first_success = false;
            elseif isequal(f_single(:), f) % Check consistency with stored f
                specData_matrix = [specData_matrix, specData_avg_single(:)]; % Concatenate as new column
                fwhm_vector(i) = fwhm_val_single;
                low_cutoff_vector(i) = low_cutoff_single;
                high_cutoff_vector(i) = high_cutoff_single;
            else
                warning('Frequency vector for bout time %d is inconsistent with previous ones. Skipping this bout.', i);
                % Outputs for this index remain NaN
            end
        else
             disp(['No valid spectrogram data or FWHM found for window ' num2str(i) '.']);
             % Outputs for this index remain NaN
        end
    catch ME_bout
        warning('Error analyzing bout time %d window: %s. Skipping.', i, ME_bout.message);
        % Outputs for this index remain NaN
    end
end % loop through inhibBoutTimes

if first_success % Means no successful analysis was performed
    disp('No successful spectrogram analysis performed for any inhibition bout time window.');
    specData_matrix = [];
    f = [];
    fwhm_vector = [];
    low_cutoff_vector = [];
    high_cutoff_vector = [];
end

end % function spectrogramInhibBoutAnalysis