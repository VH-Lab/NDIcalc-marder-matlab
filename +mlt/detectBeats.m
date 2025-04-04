function beats = detectBeats(t, d, options)
%DETECTBEATS Detect heartbeats in a pulsatile signal.
%
%   BEATS = DETECTBEATS(T, D, OPTIONS) detects heartbeats in a 
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
%       beats_sec = DETECTBEATS(t_sec, d);
%
%       % Load PPG data with datetime values
%       %%%%%[t_datetime, d] = load_ppg_data_datetime somehow
%       beats_datetime = DETECTBEATS(t_datetime, d);

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

    % Ensure that d is normalized
    if mean(d) > 1e-3
        warning('Data vector does not appear to be normalized.')
    end

    % d = mlt.movzscore(d,2*0.675,'SamplePoints',t);

    THRESHOLD_HIGH = options.THRESHOLD_HIGH;
    THRESHOLD_LOW = options.THRESHOLD_LOW;
    REFRACT = options.REFRACT;
    MEAN_THRESHOLD = (THRESHOLD_HIGH + THRESHOLD_LOW) / 2;
    AMPLITUDE_HIGH_MIN = options.amplitude_high_min;
    AMPLITUDE_LOW_MIN = options.amplitude_low_min;
    AMPLITUDE_MIN = options.amplitude_min;
    DURATION_MIN = options.duration_min;
    
    % Get smoothed signal via cubic spline interpolation
    y = csaps(t,d,1-5e-4,t); % faster ways of smoothing?

    % Calculate first derivative
    dy = gradient(y,t);

    % Get peaks (above 0) and troughs (below 0)
    peaks = [dy(1:end-1) > 0 & dy(2:end) < 0; false] & y > 0;
    troughs = [dy(1:end-1) < 0 & dy(2:end) > 0; false] & y < 0;    

    % Get only peaks that immediately preceed troughs
    [C,ind] = unique([peaks,cumsum(troughs)],'rows','last');
    ind = ind(C(:,1) == 1);
    peaks_valid = false(size(y)); peaks_valid(ind) = true;

    % For every peaks_valid, find soonest trough
    [C,ind] = unique([troughs,cumsum(peaks_valid)],'rows','first');
    ind = ind(C(:,1) == 1);
    troughs_valid = false(size(y)); troughs_valid(ind) = true;
    
    % Get indices where y crosses 0
    cross_up = [y(1:end-1) < 0 & y(2:end) > 0; false];
    cross_down = [y(1:end-1) > 0 & y(2:end) < 0; false];

    % Make sure all onsets and offsets can be detected
    if find(peaks_valid,1) < find(troughs_valid,1)
        troughs_valid(1) = true;
    end
    % if find(peaks_valid,1,'last') > find(troughs_valid,1,'last')
    %     troughs_valid(end) = true;
    % end

    % Calculate onset index (based on crossing above 0)
    [C,ind] = unique([cross_up,cumsum(troughs_valid)],'rows','last');
    ind = ind(C(:,1) == 1);
    onset = false(size(y)); onset(ind) = true;

    % Calculate offset index (based on crossing below 0)
    [C,ind] = unique([cross_down,cumsum(peaks_valid)],'rows','last');
    ind = ind(C(:,1) == 1);
    offset = false(size(y)); offset(ind) = true;

    % Check that first onset is before
    if find(onset,1) > find(offset,1)
        onset(1) = true;
    end
    if find(offset,1,'last') < find(onset,1,'last')
        offset(end) = true;
    end
    if sum(onset) ~= sum(offset)
        error('# of onsets does not match # of offsets')
    end
%%
    % Amplitude calculations
    onset_index = find(onset);
    offset_index = find(offset);
    beat_max = nan(size(onset_index)); 
    beat_min = nan(size(onset_index));
    prebeat_min = nan(size(onset_index)); 
    last_off = [1;offset_index(1:end-1)];
    for i = 1:length(onset_index)
        beat_data = d(onset_index(i):offset_index(i));
        beat_max(i) = max(beat_data);
        beat_min(i) = min(beat_data);
        prebeat_min(i) = min(d(last_off(i):onset_index(i)));
    end

    amplitude = beat_max - prebeat_min;
%%
    % Calculate up_duration
    onset_time = t(onset);
    offset_time = t(offset);
    up_duration = offset_time - onset_time;

    % Check if valid beat
    % valid = up_duration >= DURATION_MIN;
    % onset_valid = onset; onset_valid(~valid) = NaN;
    % onset_valid = fillmissing(onset_valid,'previous');
    valid = true(size(onset_time));

    % Calculate duty cycle, period, and frequency
    duty_cycle = up_duration./diff([NaN;offset_time]);
    period = [NaN;onset_time(2:end) - onset_time(1:end-1)];
    instant_freq = 1./period;

    % Convert seconds to datetime (if applicable)
    if isDateTime
        onset = datetime_t(1) + seconds(onset_time);
        offset = datetime_t(1) + seconds(offset_time);
    end

    % Compile variables and convert to structure
    beats = table(onset,offset,duty_cycle,period,instant_freq,...
        amplitude,beat_max,beat_min,up_duration,valid);
    beats = table2struct(beats).';

end

function mustBeSameLength(a,b)
if ~isequal(size(a), size(b))
    eid = 'Size:notEqual';
    msg = 'Inputs must have the same size.';
    throwAsCaller(MException(eid,msg))
end
end