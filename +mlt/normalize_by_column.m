function normalized_matrix = normalize_by_column(input_matrix)
%NORMALIZE_BY_COLUMN Normalizes a matrix by column so that the maximum
%value in each column is 1.

% Input:
%   input_matrix: The matrix to be normalized.

% Output:
%   normalized_matrix: The normalized matrix.

% Get the size of the input matrix.
[rows, cols] = size(input_matrix);

% Initialize the normalized matrix.
normalized_matrix = zeros(rows, cols);

% Iterate over each column.
for j = 1:cols
    % Find the maximum value in the current column.
    max_val = max(input_matrix(:, j));

    % Check if the maximum value is zero to avoid division by zero.
    if max_val ~= 0
      % Normalize the current column.
      normalized_matrix(:, j) = input_matrix(:, j) / max_val;
    else
        % If the maximum value is 0, all elements in that column 
        % should also be 0 in the normalized matrix.
        normalized_matrix(:, j) = input_matrix(:, j); % Or simply leave it as 0.
        warning('Column %d has all zeros. Normalized values will also be zero.', j);

    end
end

end % End of the function
