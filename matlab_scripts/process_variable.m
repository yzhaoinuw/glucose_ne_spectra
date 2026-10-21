function results = process_variable(var_name, data, data_range, signal_fs)
    % Slice the data for defined range
    data = data(data_range);
    
    % Set threshold for dips
    threshold = mean(data) - 1.5 * std(data);
    
    % Find dips below threshold
    dip_points = data < threshold;
    dip_starts = find(diff([0, dip_points]) == 1);
    dip_ends = find(diff([dip_points, 0]) == -1);
    
    % Quantify dips
    durations = (dip_ends - dip_starts + 1) / signal_fs;
    number_of_dips = numel(dip_starts);
    dip_depths = arrayfun(@(s, e) min(data(s:e)), dip_starts, dip_ends);

    % Store results in a table
    results = table({var_name}, number_of_dips, mean(durations), mean(dip_depths), ...
                     'VariableNames', {'Variable', 'Number_of_Dips', 'Average_Duration', 'Average_Depth'});
end
