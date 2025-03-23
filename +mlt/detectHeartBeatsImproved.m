function beats = detectHeartBeatsImproved(t, d, options)
%DETECTHEARTBEATSIMPROVED Detect heartbeats in a pulsatile signal.
%
%   BEATS = DETECTHEARTBEATSIMPROVED(T, D, OPTIONS) detects heartbeats in a 
%   pulsatile signal, such as a photoplethysmography (PPG) signal. 
%   The function uses a threshold-based approach to identify 
%   individual beats and their characteristics.
%
%   Inputs:
%       T: A vector of timestamps corresponding to the signal. Can be either:
%           - Numeric vector in seconds.
%           - Datetime vector.
%       D: A vector of signal values (e.g., PPG signal).
%       OPTIONS: (Optional) A structure specifying detection parameters:
%           THRESHOLD_HIGH: Upper threshold for beat detection (default: 0.75).
%           THRESHOLD_LOW: Lower threshold for beat detection (default: -0.75).
%           REFRACT: Minimum time between consecutive beats (refractory period, default: 0.2).
%           amplitude_high_min: Minimum amplitude above THRESHOLD_HIGH (default: 0).
%           amplitude_low_min: Minimum amplitude below THRESHOLD_LOW (default: 0).
%           amplitude_min: Minimum peak-to-peak amplitude (default: 0).
%           duration_min: Minimum beat duration (default: 0).
%
%   Outputs:
%       BEATS: A structure array where each element represents a detected beat.
%           Fields include:
%               onset: Beat onset time (datetime if T is datetime, double in seconds otherwise).
%               offset: Beat offset time (datetime if T is datetime, double in seconds otherwise).
%               duty_cycle: Ratio of beat duration to the period between beats (double).
%               period: Time between consecutive beats (double in seconds).
%               instant_freq: Instantaneous heart rate (double in beats per second).
%               amplitude: Peak-to-peak amplitude (double).
%               amplitude_high: Amplitude above THRESHOLD_HIGH (double).
%               amplitude_low: Amplitude below THRESHOLD_LOW (double).
%               valid: Boolean indicating if the beat meets validity criteria.
%               up_duration: Duration of the upward slope of the beat (double in seconds).
%
%   Notes:
%   - The input signal D is assumed to be preprocessed and normalized.
%   - The algorithm detects beats by identifying upward and downward 
%     crossings of the specified thresholds.
%   - The validity of each beat is assessed based on amplitude and duration criteria.
%   - The function handles edge cases, such as incomplete beats at the end of the signal.
%   - If T is a datetime vector, the output onset and offset times will be datetime values,
%     while durations, period, and instant_freq will be double values in seconds.
%
%   Example:
%       % Load PPG data with time in seconds
%       %%%%[t_sec, d] = load_ppg_data_seconds somehow; 
%       beats_sec = detectHeartBeats(t_sec, d);
%
%       % Load PPG data with datetime values
%       %%%%%[t_datetime, d] = load_ppg_data_datetime somehow
%       beats_datetime = detectHeartBeats(t_datetime, d);

    arguments
        t (:,1) {mustBeA(t,{'double','datetime'})}
        d (:,1) double {mustBeReal, mustBeFinite, mustBeSameLength(t,d)}
        options.THRESHOLD_HIGH (1,1) double {mustBeReal} = 0.75
        options.THRESHOLD_LOW (1,1) double {mustBeReal} = -0.75
        options.REFRACT (1,1) double {mustBePositive, mustBeReal} = 0.2
        options.amplitude_high_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.amplitude_low_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.amplitude_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.duration_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
    end

    % Convert from datetime to seconds (if applicable)
    if isa(t,'datetime')
       isDateTime = true;
       datetime_t = t;
       t = seconds(datetime_t - datetime_t(1));
    else
        isDateTime = false;
    end

    % Ensure time is monotonically increasing
    if any(diff(t) <= 0)
        error('Timestamp vector ''t'' must be monotonically increasing.');
    end

    if options.THRESHOLD_LOW >= options.THRESHOLD_HIGH
       error('THRESHOLD_LOW must be strictly less than THRESHOLD_HIGH.');
    end

    THRESHOLD_HIGH = options.THRESHOLD_HIGH;
    THRESHOLD_LOW = options.THRESHOLD_LOW;
    REFRACT = options.REFRACT;
    MEAN_THRESHOLD = (THRESHOLD_HIGH + THRESHOLD_LOW) / 2;
    AMPLITUDE_HIGH_MIN = options.amplitude_high_min;
    AMPLITUDE_LOW_MIN = options.amplitude_low_min;
    AMPLITUDE_MIN = options.amplitude_min;
    DURATION_MIN = options.duration_min;

    % Get relative threshold value (0 = below low, 1 = above low, 2 = above high)
    thresh_value = (d > THRESHOLD_LOW) + (d > THRESHOLD_HIGH);
    thresh_change = diff([NaN;thresh_value]);

    % Detect increasing threshold crossings
    below_to_low = [thresh_change(2:end) > 0 & thresh_value(1:end-1) == 0;false];
    low_to_high = thresh_change > 0 & thresh_value == 2;

    % Detect decreasing threshold crossings
    high_to_low = [thresh_change(2:end) < 0 & thresh_value(1:end-1) == 2;false];
    low_to_below = thresh_change < 0 & thresh_value == 0;

    % Check for exceptions where signal declines quickly from high to below
    % then low; This is likely not a necessary step for analysis, but is 
    % required to match the output from the original code
    falseBeat = low_to_below & below_to_low & [0;high_to_low(1:end-1)];

    % Get only below_to_low crossings that immediately preceed low_to_high
    % crossings
    [C,ind] = unique([below_to_low.*~falseBeat,cumsum(low_to_high)],'rows','last');
    ind = ind(C(:,1) == 1);
    below_to_low_valid = false(size(below_to_low)); below_to_low_valid(ind) = true;

    % For every below_to_low_valid crossing, find soonest low_to_high crossing
    [C,ind] = unique([low_to_high.*~falseBeat,cumsum(below_to_low_valid)],'rows','first');
    ind = ind(C(:,1) == 1);
    low_to_high_valid = false(size(low_to_high)); low_to_high_valid(ind) = true;

    % Calculate onset time and index from midpoint of threshold crossings
    onset_low = t(below_to_low_valid);
    onset_high = t(low_to_high_valid);
    if onset_high(1)<onset_low(1), 
        onset_high = onset_high(2:end);
    end;
    if onset_low(end)>onset_high(end), 
        onset_low(end) = [];
    end;    
    onset = mean([onset_low,onset_high],2);
    onset_index = round(interp1(t,1:length(t),onset),TieBreaker='fromzero');
    % small rounding errors (+/- 1 integer) between interp1 and min 
    % functions slightly change the values of onset_index and offset_index 
    % when the calculated time is halfway between two time points

    % Get only high_to_low crossings that immediately preceed the
    % below_to_low_valid crossings
    [C,ind] = unique([high_to_low.*~falseBeat,cumsum(below_to_low_valid)],'rows','last');
    ind = ind(C(:,1) == 1 & ind > onset_index(1));
    high_to_low_valid = false(size(high_to_low)); high_to_low_valid(ind) = true;

    % For every high_to_low_valid crossing, find soonest low_to_below crossing
    [C,ind] = unique([low_to_below.*~falseBeat,cumsum(high_to_low_valid)],'rows','first');
    ind = ind(C(:,1) == 1 & ind > onset_index(1));
    low_to_below_valid = false(size(low_to_below)); low_to_below_valid(ind) = true;

    % Calculate offset time and index from midpoint of threshold crossings; if
    % offset was not observed, set to final timepoint
    offset_high = t(high_to_low_valid);
    offset_low = t(low_to_below_valid);
    if length(offset_high) < length(onset)
        offset_high = [offset_high;t(end)];
        offset_low = [offset_low;t(end)];
    elseif length(offset_low) < length(onset)
        offset_low = [offset_low;t(end)];
    end
    offset = mean([offset_low,offset_high],2);
    offset_index = round(interp1(t,1:length(t),offset),TieBreaker='fromzero');
    
    % Check refractory period and remove beat if too short; This seems like an
    % odd implementation of refractory period, but it matches the original code
    removeBeat = [NaN;onset_high(2:end) - onset(1:end-1)] < REFRACT;
    onset(removeBeat) = []; onset_index(removeBeat) = [];
    offset(removeBeat) = []; offset_index(removeBeat) = [];

    % Amplitude calculations
    beat_max = nan(size(onset)); beat_min = nan(size(onset));
    prebeat_min = nan(size(onset)); last_off = [1;offset_index(1:end-1)];
    for i = 1:length(onset)
        beat_data = d(onset_index(i):offset_index(i));
        beat_max(i) = max(beat_data);
        beat_min(i) = min(beat_data);
        prebeat_min(i) = min(d(last_off(i):onset_index(i)));
    end
    amplitude = beat_max - prebeat_min;
    amplitude_high = beat_max - MEAN_THRESHOLD;
    amplitude_high(amplitude_high < 0) = -Inf;
    amplitude_low = MEAN_THRESHOLD - beat_min;
    amplitude_low(amplitude_low < 0) = Inf;

    % Calculate up_duration
    up_duration = offset - onset;

    % Check if valid beat
    valid = amplitude_high >= AMPLITUDE_HIGH_MIN & ...
        amplitude_low >= AMPLITUDE_LOW_MIN & ...
        amplitude >= AMPLITUDE_MIN & ...
        up_duration >= DURATION_MIN;
    onset_valid = onset; onset_valid(~valid) = NaN;
    onset_valid = fillmissing(onset_valid,'previous');

    % Calculate up-duration, duty cycle, period, and frequency
    duty_cycle = up_duration./diff([NaN;offset]);
    period = [NaN;onset(2:end) - onset_valid(1:end-1)];
    instant_freq = 1./period;

    % Convert seconds to datetime (if applicable)
    if isDateTime
        onset = datetime_t(1) + seconds(onset);
        offset = datetime_t(1) + seconds(offset);
    end

    % Compile variables and convert to structure
    beats = table(onset,offset,duty_cycle,period,instant_freq,amplitude,...
        amplitude_high,amplitude_low, valid, up_duration);
    beats = table2struct(beats).';

end

function mustBeSameLength(a,b)
if ~isequal(size(a), size(b))
    eid = 'Size:notEqual';
    msg = 'Inputs must have the same size.';
    throwAsCaller(MException(eid,msg))
end
end