function states = decodeHMMGauss(rates, model)
%DECODEHMMGAUSS Finds the most likely state sequence for a Gaussian HMM.
%   states = mlt.hmm.decodeHMMGauss(rates, model) calculates the most likely
%   sequence of hidden states using the Viterbi algorithm.
%
%   *** REQUIRES KEVIN MURPHY'S BAYES NET TOOLBOX (BNT) ***
%
%   INPUTS:
%   rates   - A vector of observed continuous rates.
%   model   - The trained Gaussian HMM model struct from mlt.hmm.fitHMMGauss.
%
%   OUTPUTS:
%   states  - A vector of the most likely (sorted) state for each time point.

    if ~exist('viterbi_path', 'file')
        error('mlt:bntNotFound', ...
            ['Kevin Murphy''s BNT not found. Please download and add to path.\n' ...
             'See: https://github.com/bayesnet/bnt']);
    end
    
    % Step 1: Calculate the observation likelihoods
    % This is the probability of the data given each state's Gaussian model
    B = mixgauss_prob(rates(:)', model.mu, model.Sigma, model.mixmat);
    
    % Step 2: Find the most probable path using the Viterbi algorithm
    unsorted_states = viterbi_path(model.prior, model.transmat, B);
    
    % Step 3: Remap states to the sorted order defined during fitting
    states = model.StateRemap(unsorted_states);
end
