function states = decode(rates, TRANS, EMIS, fit_info)
%DECODE Finds the most likely state sequence using the Viterbi algorithm.
%
%   STATES = mlt.hmm.decode(rates, TRANS, EMIS, fit_info)
%
%   Calculates the most likely sequence of hidden states for a discrete HMM
%   given a sequence of continuous observations ('rates').
%
%   It uses the 'fit_info' struct from mlt.hmm.fit to discretize the rate
%   data and then remaps the output states to match the sorted order
%   from the fitting step.
%
%   Inputs:
%       rates       - A vector of observed continuous rates.
%       TRANS       - An N-by-N state transition matrix from mlt.hmm.fit.
%       EMIS        - The emission probability matrix from mlt.hmm.fit.
%       fit_info    - The fit_info struct output by mlt.hmm.fit.
%
%   Outputs:
%       states      - A vector the same length as 'rates' containing the
%                     most likely sequence of hidden states (sorted 1 to N).
%
%   Example:
%       % Assume 'training_rates' and 'new_rates' are vectors of data
%
%       % 1. Fit an HMM to a training dataset
%       num_states = 4;
%       [TRANS_est, EMIS_est, fit_info] = mlt.hmm.fit(training_rates, num_states);
%
%       % 2. Decode a new sequence of rates using the fitted model
%       most_likely_states = mlt.hmm.decode(new_rates, TRANS_est, EMIS_est, fit_info);
%
%   See also mlt.hmm.fit, hmmviterbi

% --- Input Argument Validation ---
arguments
    rates {mustBeVector, mustBeNumeric, mustBeNonempty}
    TRANS (:,:) double {mustBeNumeric}
    EMIS (:,:) double {mustBeNumeric}
    fit_info (1,1) struct
end

rates = rates(:)';

% --- Step 1: Discretize Rate Data using Edges from Training ---
if ~isfield(fit_info, 'Edges')
    error('mlt:missingEdges', 'fit_info struct must contain Edges.');
end

% Use the same quantization edges that were used for training
[~, discrete_seq] = histc(rates, [-inf, fit_info.Edges, inf]);

% --- Step 2: Decode using hmmviterbi ---
M = size(EMIS, 2);
unsorted_states = hmmviterbi(discrete_seq, TRANS, EMIS, 'Symbols', 1:M);

% --- Step 3: Remap states to the sorted order ---
if isfield(fit_info, 'StateRemap') && ~isempty(fit_info.StateRemap)
    states = fit_info.StateRemap(unsorted_states);
else
    % If no remap vector exists (e.g., from an older model), return as is
    states = unsorted_states;
end

end