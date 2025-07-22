function [discrete_seq, edges] = beatRateBinQuantize(rates, NumSymbols)
%BEATRATEBINQUANTIZE Quantizes continuous rate data into discrete symbols.
%   [discrete_seq, edges] = mlt.beatRateBinQuantize(rates, NumSymbols)
%   converts a vector of continuous rate data into a sequence of integer
%   symbols from 1 to NumSymbols.
%
%   It uses the quantile function to define the bin edges, which helps
%   ensure that each symbol has a similar number of occurrences in the
%   output sequence, even if the input data is highly skewed.
%
%   INPUTS:
%   rates        - A vector of observed continuous rates.
%   NumSymbols   - The number of discrete symbols to quantize the data into.
%
%   OUTPUTS:
%   discrete_seq - A vector the same length as 'rates' containing the
%                  corresponding integer symbol for each rate.
%   edges        - The vector of bin edges used for quantization.

    % --- Input Argument Validation ---
    arguments
        rates {mustBeVector, mustBeNumeric, mustBeNonempty}
        NumSymbols (1,1) double {mustBeInteger, mustBePositive}
    end
    
    rates = rates(:)';

    % --- Quantize Continuous Data into Discrete Symbols ---
    % We use quantiles to ensure each bin has a reasonable number of data points.
    % This is more robust to skewed data distributions than using linspace.
    edges = quantile(rates, NumSymbols - 1);
    
    % Handle cases where data is constant or has low variance,
    % which can result in non-unique quantile edges.
    edges = unique(edges);
    if isempty(edges) || numel(edges) < (NumSymbols - 1)
        % Fallback to linear spacing if quantile method fails
        min_r = min(rates);
        max_r = max(rates);
        if min_r == max_r
             % Handle perfectly constant data
            edges = linspace(min_r - 1, max_r + 1, NumSymbols + 1);
        else
            edges = linspace(min_r, max_r, NumSymbols + 1);
        end
        edges = edges(2:end-1);
    end
    
    % Use histc to determine which bin each rate falls into.
    % The bins are defined by [-inf, edges, inf].
    [~, discrete_seq] = histc(rates, [-inf, edges, inf]);
end
