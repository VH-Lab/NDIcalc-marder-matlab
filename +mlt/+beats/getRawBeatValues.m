function beats = getRawBeatValues(beats, t_raw, d_raw)
%GETRAWBEATVALUES Recalculates beat amplitudes using the raw signal.
%
%   beats_out = mlt.beats.getRawBeatValues(beats_in, t_raw, d_raw)
%
%   This function takes a 'beats' structure, whose timing was likely
%   determined from a normalized signal, and adds new amplitude fields
%   calculated from the original, un-normalized (raw) signal. This is useful
%   for recovering the true physiological amplitudes of detected beats.
%
%   Inputs:
%       beats   - A structure array of detected beats, with at least 'onset'
%                 and 'offset' time fields.
%       t_raw   - The time vector (numeric or datetime) of the raw signal.
%       d_raw   - The raw (un-normalized) signal vector.
%
%   Outputs:
%       beats   - The input 'beats' structure with the following new fields
%                 added to each element:
%                 .rawPeak: The maximum signal value during the beat.
%                 .rawTrough: The minimum signal value in the period
%                             preceding the beat onset.
%                 .rawAmplitude: The peak-to-trough amplitude (rawPeak - rawTrough).
%
%   See also mlt.beats.getRawBeatValuesFromDoc, mlt.beats.detectHeartBeatsImproved

arguments
    beats (:,1) struct
    t_raw {mustBeVector}
    d_raw {mustBeVector, mustHaveSameSize(t_raw, d_raw)}
end

% Determine if time is datetime or numeric
is_datetime = isdatetime(t_raw);
if is_datetime
    % Use interpolation to find indices for datetime arrays
    t_numeric = seconds(t_raw - t_raw(1));
    onset_times = seconds(beats(1).onset - t_raw(1)) + ...
        [0; cumsum(seconds(diff([beats.onset])))];
    offset_times = seconds(beats(1).offset - t_raw(1)) + ...
        [0; cumsum(seconds(diff([beats.offset])))];
else
    % Use interpolation for numeric time arrays
    t_numeric = t_raw;
    onset_times = [beats.onset];
    offset_times = [beats.offset];
end

% Find the sample indices in the raw signal corresponding to each beat
onset_indices = round(interp1(t_numeric, 1:numel(t_numeric), onset_times, 'linear', 'extrap'));
offset_indices = round(interp1(t_numeric, 1:numel(t_numeric), offset_times, 'linear', 'extrap'));

% Ensure indices are within the valid range
onset_indices = max(1, min(onset_indices, numel(d_raw)));
offset_indices = max(1, min(offset_indices, numel(d_raw)));

last_offset_idx = [1; offset_indices(1:end-1)];

for i = 1:numel(beats)
    % Define the current beat and pre-beat segments
    pre_beat_idx = last_offset_idx(i):onset_indices(i);
    beat_idx = onset_indices(i):offset_indices(i);
    
    % Handle edge case where indices might be invalid
    if isempty(pre_beat_idx) || isempty(beat_idx) || beat_idx(1) > beat_idx(end)
        beats(i).rawPeak = NaN;
        beats(i).rawTrough = NaN;
        beats(i).rawAmplitude = NaN;
        continue;
    end

    % Calculate raw values from the un-normalized signal
    pre_beat_segment = d_raw(pre_beat_idx);
    beat_segment = d_raw(beat_idx);
    
    beats(i).rawPeak = max(beat_segment);
    beats(i).rawTrough = min(pre_beat_segment);
    beats(i).rawAmplitude = beats(i).rawPeak - beats(i).rawTrough;
end

end

function mustHaveSameSize(a, b)
    if numel(a) ~= numel(b)
        eid = 'mlt:sizeMismatch';
        msg = 'Inputs must have the same number of elements.';
        throwAsCaller(MException(eid, msg));
    end
end

