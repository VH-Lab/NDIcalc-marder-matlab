function [rates, bin_centers] = beatRateBins(beat_times, options)
%BEATRATEBINS Estimates beat rate in regularly spaced time bins.
%   [rates, bin_centers] = mlt.beats.beatRateBins(beat_times) estimates the heart
%   rate from a vector of beat times (beat_times). The function uses a
%   sliding window approach to calculate the rate at regular intervals.
%
%   The input beat_times can be a numeric vector (assumed to be in seconds)
%   or a datetime vector. The output bin_centers will be of the same type.
%
%   This function is part of the mlt (Marder Lab Tools) namespace.
%
%   SYNTAX:
%   [rates, bin_centers] = mlt.beats.beatRateBins(beat_times)
%   [rates, bin_centers] = mlt.beats.beatRateBins(beat_times, 'deltaT', dt, 'W', w)
%
%   INPUTS:
%   beat_times          - A vector of beat times. Can be a numeric vector
%                         (e.g., seconds from the start of a recording) or a
%                         datetime vector. Must be sorted chronologically.
%
%   OPTIONAL NAME-VALUE PAIR ARGUMENTS:
%   'deltaT'            - The time step (in seconds) between the centers of
%                         consecutive bins.
%                         Default: 0.5 seconds.
%   'W'                 - The total width of the sliding window (in seconds)
%                         used to count beats for each bin.
%                         Default: 5 seconds.
%
%   OUTPUTS:
%   rates               - A vector of the calculated beat rates in beats
%                         per second (Hz) for each bin.
%   bin_centers         - A vector of the timestamps for the center of each
%                         bin. The data type will match the input
%                         'beat_times' (double or datetime).
%
%   EXAMPLE:
%       % Generate some noisy, simulated beat data where rate changes
%       true_rate = @(t) 2 + 0.5 * sin(2*pi*t/60); % Rate oscillates over time
%       t_sim = 0:0.01:120; % 120 seconds of simulation time
%       beats = [];
%       next_beat = 0;
%       while next_beat < 120
%           current_rate = true_rate(next_beat);
%           ibi = 1/current_rate * (1 + 0.1*(rand-0.5)); % Add noise to inter-beat interval
%           next_beat = next_beat + ibi;
%           beats(end+1) = next_beat;
%       end
%
%       % 1. Calculate beat rate with default parameters
%       [rates, centers] = mlt.beats.beatRateBins(beats);
%
%       % 2. Calculate with custom window and step size
%       [rates_custom, centers_custom] = mlt.beats.beatRateBins(beats, 'deltaT', 1, 'W', 10);
%
%       % Plot results
%       figure;
%       plot(beats(2:end), 1./diff(beats), '.', 'Color', [0.7 0.7 0.7], 'DisplayName', 'Instantaneous Rate');
%       hold on;
%       plot(centers, rates, 'b-o', 'LineWidth', 1.5, 'DisplayName', 'Binned Rate (W=5, deltaT=0.5)');
%       plot(centers_custom, rates_custom, 'r-s', 'LineWidth', 1.5, 'DisplayName', 'Binned Rate (W=10, deltaT=1)');
%       plot(t_sim, true_rate(t_sim), 'k--', 'LineWidth', 2, 'DisplayName', 'True Rate');
%       hold off;
%       xlabel('Time (s)');
%       ylabel('Beat Rate (Hz)');
%       title('Heart Beat Rate Estimation');
%       legend;
%       grid on;

    % --- Input Argument Validation ---
    arguments
        beat_times {mustBeVector, mustBeNonempty, mustBeSorted, mustBeA(beat_times, ["double", "datetime"])}
        options.deltaT (1,1) double {mustBePositive} = 0.5
        options.W (1,1) double {mustBePositive} = 5
    end

    % --- Preparation ---
    is_datetime_input = isdatetime(beat_times);
    
    % Convert datetime to seconds for easier calculation
    if is_datetime_input
        t0 = beat_times(1);
        t_numeric = seconds(beat_times - t0);
    else
        t_numeric = beat_times;
    end

    % Ensure the input is a column vector for consistency
    t_numeric = t_numeric(:);

    % --- Binning and Rate Calculation ---
    
    % Define the centers of the time bins
    % We start from the first beat and go to the last beat
    bin_centers_numeric = (t_numeric(1) : options.deltaT : t_numeric(end))';

    num_bins = numel(bin_centers_numeric);
    rates = zeros(num_bins, 1);
    
    half_window = options.W / 2;

    % Loop through each bin to calculate the rate
    for i = 1:num_bins
        % Define the start and end of the window for the current bin
        win_start = bin_centers_numeric(i) - half_window;
        win_end = bin_centers_numeric(i) + half_window;
        
        % Count how many beats fall within this window
        % This is faster than using find() or logical indexing inside the loop
        % for large datasets, as it uses a single pass through the data.
        % However, for clarity and compatibility, a simple logical index is used here.
        beats_in_window = sum(t_numeric >= win_start & t_numeric < win_end);
        
        % Calculate rate as beats per second
        rates(i) = beats_in_window / options.W;
    end

    % --- Format Output ---
    
    % Convert bin centers back to datetime if that was the input format
    if is_datetime_input
        bin_centers = t0 + seconds(bin_centers_numeric);
    else
        bin_centers = bin_centers_numeric;
    end
end

function mustBeSorted(a)
    % Custom validation function to ensure time is chronological
    if ~issorted(a)
        eid = 'mlt:notStrictlySorted';
        msg = 'Input beat_times vector must be strictly increasing.';
        throwAsCaller(MException(eid, msg));
    end
end
