function probeTableExisting = freshen(probeTableExisting, probeTableNew)
    % FRESHEN - Updates 'firstAppears' field in an existing probe table
    %
    % PROBETABLEEXISTING = FRESHEN(PROBETABLEEXISTING, PROBETABLENEW)
    %
    % Given an existing probe table (PROBETABLEEXISTING) and a newly
    % generated one (PROBETABLENEW), this function "freshens" the existing
    % table by updating the 'firstAppears' column with the values from
    % the new table.
    %
    % The channels in the tables do not need to be in the same order, but
    % the set of channels must be identical.
    %
    % This function will raise an error if the channel lists of the two
    % tables are not identical.
    %

    channels_existing = probeTableExisting.channelName;
    channels_new = probeTableNew.channelName;

    if numel(channels_existing) ~= numel(channels_new) || ~isempty(setxor(channels_existing, channels_new))
        disp('The channel lists do not match. Cannot freshen. Displaying tables for comparison:');
        disp('Existing probe table:');
        disp(probeTableExisting);
        disp('New probe table:');
        disp(probeTableNew);
        error('The channel lists in the existing and new probe tables do not match. Cannot freshen.');
    end

    % find the mapping from the existing order to the new order
    [~, new_order_indices] = ismember(channels_existing, channels_new);

    % update 'firstAppears' using the mapping
    probeTableExisting.firstAppears = probeTableNew.firstAppears(new_order_indices);

end