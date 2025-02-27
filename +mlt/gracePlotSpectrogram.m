function gracePlotSpectrogram(spec, f, ts, options)
%GRACEPLOTSPECTROGRAM Plots a spectrogram.
%
%   gracePlotSpectrogram(SPEC, F, TS, OPTIONS) plots a spectrogram in the current axes.
%
%   Plots the spectrogram, applying dB/linear conversions as specified in OPTIONS.
%   Plots time in hours if TS is in seconds, or uses datetime values directly.
%
%   Input Arguments:
%       SPEC: Spectrogram data (matrix).
%       F: Frequency vector.
%       TS: Time vector (double in seconds or datetime).
%       OPTIONS: (Optional) Structure containing options.
%           OPTIONS.convertDBtoLinear: Logical, convert dB to linear (default true).
%           OPTIONS.convertLinearToDB: Logical, convert linear to dB (default false).
%           OPTIONS.shading: Shading style ('faceted', 'flat', or 'interp', default 'flat').
%           OPTIONS.drawLabels: Logical, whether to draw axis labels (default true).

arguments
    spec (:,:) double; % Spectrogram data (matrix)
    f (:,1) double; % Frequency vector (column vector)
    ts (:,1) {mustBeA(ts,{'double','datetime'})}; % Time vector (double or datetime)
    options.convertDBtoLinear (1,1) logical = true;
    options.convertLinearToDB (1,1) logical = false;
    options.shading (1,:) char {mustBeMember(options.shading,{'faceted','flat','interp'})} = 'flat';
    options.drawLabels (1,1) logical = true;
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

% Plot the spectrogram
if isa(ts, 'datetime')
    surf(ts, f, plottedSpec);
else % ts is double (seconds)
    surf(ts/(60*60), f, plottedSpec); % Convert seconds to hours
end

% Set plot appearance
view(0, 90); % Top-down view
shading(options.shading); % Apply shading style

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

