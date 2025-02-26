function beats = detectHeartBeats(t, d, options)
    %DETECTHEARTBEATS Detects heartbeats in PPG data.

    arguments
        t (1,:) double {mustBeReal, mustBeFinite}
        d (1,:) double {mustBeReal, mustBeFinite, mustBeSameLength(t,d)}
        options.THRESHOLD_HIGH (1,1) double {mustBeReal} = 0.75
        options.THRESHOLD_LOW (1,1) double {mustBeReal} = -0.75
        options.REFRACT (1,1) double {mustBePositive, mustBeReal} = 0.2
        options.amplitude_high_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.amplitude_low_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.amplitude_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
        options.duration_min (1,1) double {mustBeNonnegative, mustBeReal} = 0
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

    beats = struct('onset', {}, 'offset', {}, 'duty_cycle', {}, 'period', {}, 'instant_freq', {}, 'amplitude', {}, 'amplitude_high', {}, 'amplitude_low', {}, 'valid', {}, 'up_duration', {});
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
end

function mustBeSameLength(a,b)
    if ~isequal(size(a), size(b))
        eid = 'Size:notEqual';
        msg = 'Inputs must have the same size.';
        throwAsCaller(MException(eid,msg))
    end
end
