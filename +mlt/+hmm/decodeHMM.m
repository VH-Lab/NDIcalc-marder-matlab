function states = decodeHMM(rates, TRANS, EMIS, fit_info)
%DECODEHMM Finds the most likely state sequence using the Viterbi algorithm.
%   states = mlt.hmm.decodeHMM(rates, TRANS, EMIS, fit_info) calculates the
%   most likely sequence of hidden states for a discrete HMM.
%
%   It uses the 'fit_info' struct from mlt.hmm.fitHMM to discretize the rate
%   data and then remaps the output states to match the sorted order
%   from the fitting step.
%
%   INPUTS:
%   rates               - A vector of observed continuous rates.
%   TRANS               - An N-by-N state transition matrix from mlt.hmm.fitHMM.
%   EMIS                - The emission probability matrix from mlt.hmm.fitHMM.
%   fit_info            - The fit_info struct output by mlt.hmm.fitHMM.
%
%   OUTPUTS:
%   states              - A vector the same length as 'rates' containing the
%                         most likely sequence of hidden states (sorted 1 to N).

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
