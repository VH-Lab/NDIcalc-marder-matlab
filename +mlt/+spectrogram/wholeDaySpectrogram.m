function [spec,f,ts] = wholeDaySpectrogram(S, options)
%WHOLEDAYSPECTROGRAM Computes a spectrogram for a complete NDI element recording.
%
%   [SPEC, F, TS] = mlt.spectrogram.wholeDaySpectrogram(S, Name, Value, ...)
%
%   Calculates a spectrogram for the entire duration of a specified
%   ndi.element. The function has two primary modes of operation based on
%   the time clocks available for the element's first epoch.
%
%   1.  **Global Clock Mode**: If an 'exp_global_time' clock is found, the
%       function reads the entire time series at once. It then applies a
%       Z-score normalization (either moving or global) to the signal before
%       computing the spectrogram with `mlt.util.computeSpectrogram`.
%
%   2.  **Epoch-by-Epoch Mode**: If no global clock is found, the function
%       iterates through each epoch of the element individually. It computes a
%       spectrogram for each epoch using `mlt.util.makeSpectrogram`, optionally
%       downsamples the result, and concatenates the pieces to form a single,
%       continuous output.
%
%   Inputs:
%       S - An ndi.session or ndi.dataset object.
%
%   Optional Name-Value Pairs:
%       e_name ('ppg_heart_lp')
%           The name of the ndi.element to analyze.
%       e_reference (1)
%           The reference number of the ndi.element.
%       f (0.1:0.1:10)
%           A vector of frequencies (Hz) to analyze in the spectrogram.
%       windowTime (10)
%           The duration of the sliding window (in seconds) used for the
%           spectrogram calculation.
%       downSample (2)
%           (Epoch-by-Epoch Mode Only) The factor by which to downsample the
%           time dimension of the spectrogram for each epoch. For example, a
%           value of 2 keeps every other time point.
%       zscoreWindowTime (3600)
%           (Global Clock Mode Only) The duration of the moving window (in
%           seconds) for z-score normalization. If set to 0, a global z-score
%           is applied across the entire signal.
%
%   Outputs:
%       spec - The computed spectrogram data matrix ([frequency x time]).
%       f    - The frequency vector (Hz) corresponding to the rows of 'spec'.
%       ts   - The time vector corresponding to the columns of 'spec'. The
%              units are datenum in Global Clock Mode and seconds from the
%              start in Epoch-by-Epoch Mode.
%
%   Example:
%       % Calculate a spectrogram for a specific element
%       [spec, f, ts] = mlt.spectrogram.wholeDaySpectrogram(mySession, ...
%           'e_name', 'ppg_pylorus_lp_whole', 'e_reference', 1);
%
%       % Plot the result
%       figure;
%       imagesc(ts, f, spec);
%       set(gca, 'YDir', 'normal');
%       xlabel('Time');
%       ylabel('Frequency (Hz)');
%
%   See also mlt.util.computeSpectrogram, mlt.util.makeSpectrogram, mlt.util.movzscore, ndi.element

arguments
    S (1,1) {mustBeA(S,{'ndi.session','ndi.dataset'})}
    options.e_name (1,:) char {mustBeTextScalar} = 'ppg_heart_lp'
    options.e_reference (1,1) double {mustBePositive, mustBeInteger} = 1
    options.f (1,:) double = 0.1:0.1:10
    options.windowTime (1,1) double = 10
    options.downSample (1,1) double = 2
    options.zscoreWindowTime (1,1) double {mustBeNonnegative} = 3600
end

e = S.getelements('element.name',options.e_name,'element.reference',options.e_reference);
if numel(e)~=1,
    error(['Could not find a single element.name ' options.e_name ' with reference ' int2str(options.e_reference) '.']);
end
e = e{1};
et = e.epochtable();

spec = [];
ts = [];
nextTime = 0;

wb = waitbar(0,"Working on whole day spectrogram");

idx = cellfun(@(x) eq(x,ndi.time.clocktype('exp_global_time')),et(1).epoch_clock);

if isempty(idx) % no global time
    for i=1:numel(et)
        [sd,f,ts_here] = mlt.util.makeSpectrogram(e,et(i).epoch_id, options.f, options.windowTime);
        waitbar(i/numel(et),wb,['Working on whole day spectrogram: ' int2str(i) ' of ' int2str(numel(et))]);
        spec = cat(2,spec,sd(:,1:options.downSample:end));
        ts = cat(2,ts,nextTime + ts_here(1:options.downSample:end)); % make a giant row
        nextTime = nextTime + ts_here(end) + (ts_here(2)-ts_here(1));
    end
else
    t0t1 = et(1).t0_t1{idx};
    tr = ndi.time.timereference(e,ndi.time.clocktype('exp_global_time'),[],0);
    [d,t] = e.readtimeseries(tr,t0t1(1),t0t1(2));
    if options.zscoreWindowTime == 0
        d = zscore(d);
    else
        t_date = datetime(t,'convertFrom','datenum');
        d = mlt.util.movzscore(d,seconds(options.zscoreWindowTime),'SamplePoints',t_date);
    end
    [spec,f,ts] = mlt.util.computeChunkedSpectrogram(d,t_date,'frequencies',options.f, ...
        'windowSizeTime', options.windowTime,'timeIsDatenum',false);
end

waitbar(1,wb,"Working on whole day spectrogram");
close(wb);