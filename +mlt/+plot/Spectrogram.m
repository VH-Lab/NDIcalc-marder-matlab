function gracePlotSpectrogram(spec, f, ts, options)
%MLT.PLOT.SPECTROGRAM Plots a spectrogram.
%
%   mlt.plot.Spectrogram(SPEC, F, TS, Name, Value, ...) plots a spectrogram in the current axes.
%
%   Plots the spectrogram, applying dB/linear conversions as specified.
%   Plots time in hours if TS is in seconds, or uses datetime values directly.
%
%   Input Arguments:
%       SPEC: Spectrogram data (matrix).
%       F: Frequency vector.
%       TS: Time vector (double in seconds or datetime).
%
%   Name/Value Pairs:
%       convertDBtoLinear: Logical, convert dB to linear (default true).
%       convertLinearToDB: Logical, convert linear to dB (default false).
%       shading: Shading style ('faceted', 'flat', or 'interp', default 'flat').
%       drawLabels: Logical, whether to draw axis labels (default true).
%       colorbar: Logical, whether to draw a colorbar (default false).
%       maxColorPercentile:  The percentile of data to use as
%                                       the maximum value for the color scale. (default 99).
%       colormapName: Name of the colormap to use (default 'parula').




arguments
    spec (:,:) double; % Spectrogram data (matrix)
    f (:,1) double; % Frequency vector (column vector)
    ts (:,1) {mustBeA(ts,{'double','datetime'})}; % Time vector (double or datetime)
    options.convertDBtoLinear (1,1) logical = true;
    options.convertLinearToDB (1,1) logical = false;
    options.shading (1,:) char {mustBeMember(options.shading,{'faceted','flat','interp'})} = 'flat';
    options.drawLabels (1,1) logical = true;
    options.colorbar (1,1) logical = false;
    options.maxColorPercentile (1,1) double {mustBeInRange(options.maxColorPercentile, 0, 100)} = 99;
    options.colormapName (1,:) char {mustBeMember(options.colormapName,{'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink'})} = 'parula';
    options.ylim (1,2) double = [0 5];
end

% Apply dB/linear conversions
if options.convertDBtoLinear && ~options.convertLinearToDB
    plottedSpec = 10.^(spec/10); % Convert dB to linear
    zlabelString = 'Power'; 
elseif ~options.convertDBtoLinear && options.convertLinearToDB
    plottedSpec = 10*log10(spec); % Convert linear to dB
    zlabelString = 'Power (dB)'; 
else
    plottedSpec = spec; % No conversion
    zlabelString = 'Power'; % Default z-label
end

% --- Calculate the color scale maximum ---
max_color_value = prctile(plottedSpec(:), options.maxColorPercentile);

% Plot the spectrogram
if isa(ts, 'datetime')
    surf(ts, f, plottedSpec);
else % ts is double (seconds)
    surf(ts/(60*60), f, plottedSpec); % Convert seconds to hours
end

% Set plot appearance
view(0, 90); % Top-down view
shading(options.shading); % Apply shading style

% --- Set the color axis limit ---
caxis([min(plottedSpec(:)), max_color_value]);

% --- Apply the specified colormap ---
colormap(options.colormapName);

ylim(options.ylim);

% Add labels if requested
if options.drawLabels
    if isa(ts, 'datetime')
        xlabel('Time'); % X-axis label for datetime
    else
        xlabel('Hours'); % X-axis label for seconds (converted to hours)
    end
    ylabel('Frequency');
    zlabel(zlabelString); % Set the appropriate z-label
    title('Spectrogram');
end

if options.colorbar
    colorbar;
end
