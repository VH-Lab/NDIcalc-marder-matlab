function states = decodeGauss(rates, model)
%DECODEGAUSS Finds the most likely state sequence for a Gaussian HMM.
%
%   STATES = mlt.hmm.decodeGauss(rates, model)
%
%   Calculates the most likely sequence of hidden states for an HMM with
%   Gaussian emissions using the Viterbi algorithm.
%
%   *** REQUIRES KEVIN MURPHY'S BAYES NET TOOLBOX (BNT) ***
%
%   Inputs:
%       rates   - A vector of observed continuous rates.
%       model   - The trained Gaussian HMM model struct from mlt.hmm.fitGauss.
%
%   Outputs:
%       states  - A vector of the most likely (sorted) state for each time point.
%
%   Example:
%       % Assume 'training_rates' and 'new_rates' are vectors of data
%
%       % 1. Fit a Gaussian HMM to a training dataset
%       num_states = 4;
%       model = mlt.hmm.fitGauss(training_rates, num_states);
%
%       % 2. Decode a new sequence of rates using the fitted model
%       most_likely_states = mlt.hmm.decodeGauss(new_rates, model);
%
%   See also mlt.hmm.fitGauss, viterbi_path

% --- Input Argument Validation ---
arguments
    rates (1,:) {mustBeNumeric, mustBeNonempty}
    model (1,1) struct {mustContainModelFields(model)}
end

if ~exist('viterbi_path', 'file')
    error('mlt:bntNotFound', ...
        ['Kevin Murphy''s BNT not found. Please download and add to path.\n' ...
         'See: https://github.com/bayesnet/bnt']);
end

% --- Step 1: Calculate Observation Likelihoods ---
% This is the probability of the data given each state's Gaussian model.
B = mixgauss_prob(rates(:)', model.mu, model.Sigma, model.mixmat);

% --- Step 2: Find the Most Probable Path (Viterbi) ---
unsorted_states = viterbi_path(model.prior, model.transmat, B);

% --- Step 3: Remap States to Sorted Order ---
% This ensures the state numbers are consistent with the sorted means.
states = model.StateRemap(unsorted_states);

end

function mustContainModelFields(model)
    % Custom validation function to ensure the model struct has required fields.
    requiredFields = ["mu", "Sigma", "mixmat", "prior", "transmat", "StateRemap"];
    if ~all(isfield(model, requiredFields))
        eid = 'mlt:invalidModel';
        msg = sprintf('Input struct must contain the fields: %s.', strjoin(requiredFields, ', '));
        throwAsCaller(MException(eid, msg));
    end
end