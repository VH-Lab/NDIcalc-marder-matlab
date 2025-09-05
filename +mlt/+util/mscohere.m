function [cxy, f] = mscohere(X, Y, dt, options)
%MLT.MSCOHERE Computes magnitude-squared coherence with convenient defaults.
%
%   [cxy, f] = mlt.util.mscohere(X, Y, dt) computes the magnitude-squared
%   coherence estimate between time series X and Y. It is a wrapper for
%   the built-in MATLAB `mscohere` function from the Signal Processing
%   Toolbox, tailored for ease of use with specific defaults.
%
%   SYNTAX:
%   [cxy, f] = mlt.util.mscohere(X, Y, dt)
%   [cxy, f] = mlt.util.mscohere(X, Y, dt, Name, Value, ...)
%
%   INPUTS:
%   X           - First time series, specified as a column vector.
%   Y           - Second time series, specified as a column vector. Must be
%                 the same length as X.
%   dt          - The time step (sampling interval) of the time series, in
%                 seconds. The sampling frequency is calculated as 1/dt.
%
%   OPTIONAL NAME-VALUE PAIR INPUTS:
%   'window_length' - Length of the windowing function. The frequency
%                     resolution is determined by Fs/window_length.
%                     Default: 256
%
%   'n_overlap'     - Number of samples by which consecutive windows overlap.
%                     A 50% overlap is generally a good choice.
%                     Default: 128
%
%   'n_fft'         - Number of points for the Fast Fourier Transform.
%                     Note: This function specifies the exact frequencies
%                     to compute via 'freq_vector', so 'n_fft' is not
%                     passed to the underlying MATLAB function. It is
%                     retained here as a parameter for documentation and
%                     potential future use.
%                     Default: 256
%
%   'freq_vector'   - A column vector of frequencies (in Hz) at which to
%                     compute the coherence. This provides direct control
%                     over the output frequency range.
%                     Default: (0:0.1:10)'
%
%   OUTPUTS:
%   cxy         - The magnitude-squared coherence, returned as a column
%                 vector. Values range from 0 to 1.
%   f           - The vector of frequencies (in Hz) corresponding to the
%                 coherence estimates in cxy.
%
%   EXAMPLE:
%   % Create two signals with a common component at 5 Hz
%   Fs = 200;               % Sampling frequency
%   dt = 1/Fs;              % Time step
%   t = (0:dt:10-dt)';      % Time vector (10 seconds)
%
%   common_signal = 0.5 * sin(2*pi*5*t);
%   noise1 = 0.8 * randn(size(t));
%   noise2 = 0.8 * randn(size(t));
%
%   x = common_signal + noise1;
%   y = common_signal + noise2;
%
%   % Compute coherence using the function's defaults (0-10 Hz)
%   [cxy, f] = mlt.util.mscohere(x, y, dt);
%
%   % Plot the results
%   figure;
%   plot(f, cxy, 'LineWidth', 1.5);
%   grid on;
%   title('Coherence between two noisy signals');
%   xlabel('Frequency (Hz)');
%   ylabel('Magnitude-Squared Coherence');
%   ylim([0 1.05]);

% --- Input Validation and Default Handling ---
arguments
    X (:,1) double
    Y (:,1) double
    dt (1,1) {mustBeNumeric, mustBePositive}
    options.window_length (1,1) {mustBeInteger, mustBePositive} = 256
    options.n_overlap (1,1) {mustBeInteger, mustBeNonnegative} = 128
    options.n_fft (1,1) {mustBeInteger, mustBePositive} = 256
    options.freq_vector (:,1) double = (0:0.1:10)'
end

% Perform custom validation checks that arguments block cannot handle alone.
if length(X) ~= length(Y)
    error('Inputs X and Y must be vectors of the same length.');
end

if options.n_overlap >= options.window_length
    error('The number of overlapping samples (n_overlap) must be less than the window length.');
end

% --- Core Calculation ---

% 1. Calculate the sampling frequency from the time step.
Fs = 1 / dt;

% 2. Define the windowing function for segmenting the data.
%    A Hamming window is a good general-purpose choice.
window = hamming(options.window_length);

% 3. Call MATLAB's built-in mscohere function.
%    We use the syntax that allows specifying the exact frequency vector,
%    which gives precise control over the output range.
[cxy, f] = mscohere(X, Y, window, options.n_overlap, options.freq_vector, Fs);

end
