function [spectrogram_data, f, t_s] = computeChunkedSpectrogram(data, t, options)
%COMPUTECHUNKEDSPECTROGRAM Calculates a spectrogram for discontinuously sampled data.
%
%   [spectrogram_data, f, t_s] = computeChunkedSpectrogram(data, t, ...)
%
%   This function is designed to compute a spectrogram for time-series data
%   that may contain gaps or discontinuities in its sampling. It works by
%   identifying large jumps in the time vector, splitting the data into
%   continuous chunks, computing a spectrogram for each chunk, and then
%   concatenating the results.
%
%   This preserves the temporal integrity of the recording, and the output
%   time vector 't_s' will reflect the original gaps.
%
%   Inputs:
%       data - A numeric column vector of time-series data.
%       t    - A numeric or datetime column vector of timestamps for the data.
%
%   Optional Name-Value Pair Arguments:
%       frequencies (1,:) double = 0.1:0.1:10
%           A vector of frequencies (Hz) to evaluate in the spectrogram.
%       windowSizeTime (1,1) double = 10
%           The duration of the sliding window in seconds.
%       useDecibels (1,1) logical = true
%           If true, converts the output power spectrogram to decibels (10*log10(P)).
%       timeIsDatenum (1,1) logical = false
%           If true, the input time vector 't' is treated as MATLAB datenum values.
%       gapThresholdFactor (1,1) double = 2
%           A factor that is multiplied by the median sample interval to
%           determine the time difference that constitutes a gap. Any jump
%           in time greater than this threshold will split the data.
%
%   Outputs:
%       spectrogram_data - The concatenated spectrogram data matrix ([frequency x time]).
%       f                - The frequency vector (Hz) corresponding to the rows.
%       t_s              - The concatenated time vector for the columns. Its type
%                          (numeric or datetime) matches the input time vector 't'
%                          and it will contain the same time gaps.
%
%   See also spectrogram, diff, median

arguments
    data (:,1) double
    t (:,1)
    options.frequencies (1,:) double = 0.1:0.1:10
    options.windowSizeTime (1,1) double = 10
    options.useDecibels (1,1) logical = true
    options.timeIsDatenum (1,1) logical = false
    options.gapThresholdFactor (1,1) double {mustBePositive} = 2
end

% --- 1. Prepare Time and Identify Gaps ---
is_datetime = isa(t, 'datetime');
if options.timeIsDatenum
    t = datetime(t, 'ConvertFrom', 'datenum');
    is_datetime = true;
end

if numel(t) < 2
    error('Time vector must have at least 2 elements to detect gaps.');
end

if is_datetime
    time_diffs_sec = seconds(diff(t));
else
    time_diffs_sec = diff(t);
end

median_interval = median(time_diffs_sec);
gap_threshold = options.gapThresholdFactor * median_interval;

gap_indices = find(time_diffs_sec > gap_threshold);

% Define the start and end indices of each continuous chunk
start_indices = [1; gap_indices + 1];
end_indices = [gap_indices; numel(data)];

num_chunks = numel(start_indices);
fprintf('Found %d data gaps. Processing data in %d continuous chunks.\n', numel(gap_indices), num_chunks);

% --- 2. Process Each Chunk in a Loop ---
spec_chunks = cell(num_chunks, 1);
ts_chunks = cell(num_chunks, 1);
f = []; % Will be populated from the first valid chunk

for i = 1:num_chunks
    chunk_indices = start_indices(i):end_indices(i);

    if numel(chunk_indices) < 2
        % This chunk is too short to have a sample rate, skip it
        continue;
    end

    data_chunk = data(chunk_indices);
    t_chunk = t(chunk_indices);

    % --- Core calculation for the chunk (imitating computeSpectrogram) ---
    if is_datetime
        sr = 1 / seconds(t_chunk(2) - t_chunk(1));
    else
        sr = 1 / (t_chunk(2) - t_chunk(1));
    end
    windowSizeSamples = round(options.windowSizeTime * sr);

    % Check if the chunk is long enough for at least one window
    if numel(data_chunk) < windowSizeSamples
        fprintf('Skipping chunk %d because it is shorter than the window size.\n', i);
        continue;
    end

    [s_chunk, f_chunk, t_s_relative_chunk] = spectrogram(data_chunk, windowSizeSamples, 0, options.frequencies, sr);

    if isempty(f) % Store frequency vector from the first chunk
        f = f_chunk;
    end

    % --- Post-Processing for the chunk ---
    if options.useDecibels
        epsilon = 1e-10;
        s_chunk = 10 * log10(abs(s_chunk).^2 + epsilon);
    end

    % Convert relative time vector to absolute time
    if is_datetime
        ts_chunks{i} = t_chunk(1) + seconds(t_s_relative_chunk);
    else
        ts_chunks{i} = t_chunk(1) + t_s_relative_chunk;
    end
    spec_chunks{i} = s_chunk;
end

% --- 3. Concatenate Results ---
fprintf('Concatenating results from all chunks...\n');

% Filter out empty cells from skipped chunks
valid_chunks = ~cellfun('isempty', spec_chunks);
spec_chunks = spec_chunks(valid_chunks);
ts_chunks = ts_chunks(valid_chunks);

if isempty(spec_chunks)
    warning('No data chunks were long enough to produce a spectrogram.');
    spectrogram_data = [];
    t_s = [];
    return;
end

spectrogram_data = horzcat(spec_chunks{:});
t_s_row = horzcat(ts_chunks{:});
t_s = t_s_row(:); % Ensure output is a column vector

end
