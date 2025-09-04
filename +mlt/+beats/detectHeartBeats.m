function beats = detectHeartBeats(t, d, options)
%DETECTHEARTBEATS Detect heartbeats in a pulsatile signal.
%
%   BEATS = DETECTHEARTBEATS(T, D, OPTIONS) detects heartbeats in a 
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
        t (1,:) {mustBeA(t,{'double','datetime'})}
        d (1,:) double {mustBeReal, mustBeFinite, mustBeSameLength(t,d)}
        options.THRESHOLD_HIGH (1,1) double {mustBeReal} = 0.75
        options.THRESHOLD_LOW (1,1) double {mustBeReal} = -0.75
        options.REFRACT (1,1) double {mustBePositive, mustBeReal} = 0.2
        options.amplitude_high_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.amplitude_low_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.amplitude_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.duration_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
    end

    isDateTime = false;

    if isa(t,'datetime'),
        isDateTime = true;
       datetime_t = t;
       t = seconds(datetime_t - datetime_t(1));
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

    beats = struct('onset', {}, 'offset', {}, 'duty_cycle', {}, 'period', {}, ...
        'instant_freq', {}, 'amplitude', {}, 'amplitude_high', {}, ...
         'amplitude_low', {}, 'valid', {}, 'up_duration', {});
    beat_count = 0;
    last_onset = -Inf;
    last_offset = -Inf;
    last_valid_onset = -Inf;
    in_beat = false;
    crossing_up = false;
    crossing_down = false;

    for i = 2:length(d)
        % Onset detection
        if ~in_beat && ~crossing_up && d(i-1) <= THRESHOLD_LOW && d(i) > THRESHOLD_LOW
            crossing_up = true;
            crossing_up_start_time = t(i-1);
        elseif crossing_up && d(i) >= THRESHOLD_HIGH
           if t(i) - last_onset > REFRACT
                beat_count = beat_count + 1;
                beats(beat_count).onset = (crossing_up_start_time + t(i))/2;

                % --- Amplitude pre-calculation (for onset and first beat) ---
                if beat_count > 1
                    [~, onset_index] = min(abs(t - beats(beat_count).onset));
                    [~, prev_offset_index] = min(abs(t - beats(beat_count - 1).offset));
                    min_val_pre_onset = min(d(prev_offset_index:onset_index));
                else  % First beat
                    [~, onset_index] = min(abs(t - beats(beat_count).onset));
                    min_val_pre_onset = min(d(1:onset_index));
                end

                beats(beat_count).amplitude = NaN;
                beats(beat_count).amplitude_high = NaN;
                beats(beat_count).amplitude_low = NaN;
                beats(beat_count).up_duration = NaN;

                % --- Period calculation (using last *valid* onset) ---
                if beat_count > 1
                    if last_valid_onset > -Inf
                         beats(beat_count).period = beats(beat_count).onset - last_valid_onset;
                         beats(beat_count).instant_freq = 1 / (beats(beat_count).onset - last_valid_onset);
                    else
                        beats(beat_count).period = NaN;
                        beats(beat_count).instant_freq = NaN;
                    end
                else
                    beats(beat_count).period = NaN;
                    beats(beat_count).instant_freq = NaN;
                end

                last_onset = beats(beat_count).onset;
                in_beat = true;
            end
            crossing_up = false;
        elseif crossing_up && d(i) < THRESHOLD_LOW
            crossing_up = false;

        % Offset detection
        elseif in_beat && ~crossing_down && d(i-1) >= THRESHOLD_HIGH && d(i) < THRESHOLD_HIGH
            crossing_down = true;
            crossing_down_start_time = t(i-1);
        elseif crossing_down && d(i) <= THRESHOLD_LOW
            beats(beat_count).offset = (crossing_down_start_time + t(i))/2;
            in_beat = false;
            crossing_down = false;

            beats(beat_count).up_duration = beats(beat_count).offset - beats(beat_count).onset;

            [~, onset_index] = min(abs(t - beats(beat_count).onset));
            [~, offset_index] = min(abs(t - beats(beat_count).offset));

            beat_data = d(onset_index:offset_index);

            max_val_in_beat = max(beat_data);
            beats(beat_count).amplitude = max_val_in_beat - min_val_pre_onset;

            beat_data_high = beat_data(beat_data >= MEAN_THRESHOLD);
            if isempty(beat_data_high)
                beats(beat_count).amplitude_high = -Inf;
            else
                beats(beat_count).amplitude_high = max(beat_data_high) - MEAN_THRESHOLD;
            end

            beat_data_low = beat_data(beat_data <= MEAN_THRESHOLD);
            if isempty(beat_data_low)
                beats(beat_count).amplitude_low = Inf;
            else
                beats(beat_count).amplitude_low = MEAN_THRESHOLD - min(beat_data_low);
            end

            beats(beat_count).valid = ...
                beats(beat_count).amplitude_high >= AMPLITUDE_HIGH_MIN && ...
                beats(beat_count).amplitude_low >= AMPLITUDE_LOW_MIN && ...
                beats(beat_count).amplitude >= AMPLITUDE_MIN && ...
                beats(beat_count).up_duration >= DURATION_MIN;

            if beats(beat_count).valid
                last_valid_onset = beats(beat_count).onset;
            end


            if beat_count > 1
                total_duration = beats(beat_count).offset - beats(beat_count - 1).offset;
                time_above_threshold = beats(beat_count).offset - beats(beat_count).onset;
                beats(beat_count).duty_cycle = time_above_threshold / total_duration;
            else
                beats(beat_count).duty_cycle = NaN;
            end

            last_offset = beats(beat_count).offset;
        elseif crossing_down && d(i) > THRESHOLD_HIGH
            crossing_down = false;
        end
    end

    if in_beat
        beats(beat_count).offset = t(end);

        [~, onset_index] = min(abs(t - beats(beat_count).onset));
        [~, offset_index] = min(abs(t - beats(beat_count).offset));
         beats(beat_count).up_duration = beats(beat_count).offset - beats(beat_count).onset;

        beat_data = d(onset_index:offset_index);

        max_val_in_beat = max(beat_data);
        beats(beat_count).amplitude = max_val_in_beat - min_val_pre_onset;

        beat_data_high = beat_data(beat_data >= MEAN_THRESHOLD);
            if isempty(beat_data_high)
                beats(beat_count).amplitude_high = -Inf;
            else
                beats(beat_count).amplitude_high = max(beat_data_high) - MEAN_THRESHOLD;
            end

        beat_data_low = beat_data(beat_data <= MEAN_THRESHOLD);
        if isempty(beat_data_low)
            beats(beat_count).amplitude_low = Inf;
        else
            beats(beat_count).amplitude_low = MEAN_THRESHOLD - min(beat_data_low);
        end

        beats(beat_count).valid = ...
            beats(beat_count).amplitude_high >= AMPLITUDE_HIGH_MIN && ...
            beats(beat_count).amplitude_low >= AMPLITUDE_LOW_MIN && ...
            beats(beat_count).amplitude >= AMPLITUDE_MIN && ...
            beats(beat_count).up_duration >= DURATION_MIN;

        if beats(beat_count).valid
            last_valid_onset = beats(beat_count).onset;
        end

        if beat_count > 1
                total_duration = beats(beat_count).offset - beats(beat_count - 1).offset;
                time_above_threshold = beats(beat_count).offset - beats(beat_count).onset;
                beats(beat_count).duty_cycle = time_above_threshold / total_duration;
        else
                beats(beat_count).duty_cycle = NaN;
        end

        last_offset = beats(beat_count).offset;
    end

    if isDateTime,
        for i=1:numel(beats),
           beats(i).onset = datetime_t(1) + seconds(beats(i).onset);
           beats(i).offset = datetime_t(1) + seconds(beats(i).offset);
        end
    end
end

function mustBeSameLength(a,b)
    if ~isequal(size(a), size(b))
        eid = 'Size:notEqual';
        msg = 'Inputs must have the same size.';
        throwAsCaller(MException(eid,msg))
    end
end
