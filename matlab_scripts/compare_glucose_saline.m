function compare_glucose_saline(saline_vars, glucose_vars, signal_fs, save_path)
    % Load or calculate dip data for each group
    saline_data = {};
    glucose_data = {};

    % Analyze each variable in the saline group
    for i = 1:length(saline_vars)
        var_name = saline_vars{i};
        full_data = evalin('base', var_name);  % Fetch data using variable name
        data_range = [36621, round(16200 * signal_fs / 100)]; % Adjust the range dynamically
        dip_data = single_variable_dip_analysis(var_name, signal_fs, data_range, full_data); % Ensure this function returns data
        saline_data{end+1} = dip_data;
    end

    % Analyze each variable in the glucose group
    for i = 1:length(glucose_vars)
        var_name = glucose_vars{i};
        full_data = evalin('base', var_name);  % Fetch data using variable name
        data_range = [36621, round(16200 * signal_fs / 100)]; % Adjust the range dynamically
        dip_data = single_variable_dip_analysis(var_name, signal_fs, data_range, full_data); % Ensure this function returns data
        glucose_data{end+1} = dip_data;
    end

    % Extract data for statistical comparison
    saline_dips = cellfun(@(x) x.Number_of_Dips, saline_data);
    glucose_dips = cellfun(@(x) x.Number_of_Dips, glucose_data);
    saline_durations = cellfun(@(x) x.Average_Duration, saline_data);
    glucose_durations = cellfun(@(x) x.Average_Duration, glucose_data);
    saline_depths = cellfun(@(x) x.Average_Depth, saline_data);
    glucose_depths = cellfun(@(x) x.Average_Depth, glucose_data);

    % Perform t-tests to compare dips, durations, and depths
    [h_dips, p_dips] = ttest2(saline_dips, glucose_dips);
    [h_durations, p_durations] = ttest2(saline_durations, glucose_durations);
    [h_depths, p_depths] = ttest2(saline_depths, glucose_depths);

    % Display results
    fprintf('Comparison of Number of Dips: p = %.3f\n', p_dips);
    fprintf('Comparison of Average Duration: p = %.3f\n', p_durations);
    fprintf('Comparison of Average Depth: p = %.3f\n', p_depths);
end
