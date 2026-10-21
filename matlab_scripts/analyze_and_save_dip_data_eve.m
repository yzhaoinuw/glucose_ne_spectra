function dip_results = analyze_and_save_dip_data_eve(variables, group_name, signal_fs, save_path)
    numVars = length(variables);
    data_range = 1000:round(16200 * signal_fs / 100);  % Define the range for focused analysis
    dip_results = struct();  % Initialize structure to save results

    for i = 1:numVars
        var_name = variables{i};
        full_data = evalin('base', var_name); % Fetch the full signal data

        % Adjust data range for specific variables
        if strcmp(var_name, 'ds_delta465_eve_filt5') || strcmp(var_name, 'ds_delta465_eve_filt6') || strcmp(var_name, 'ds_delta465_sal_evening_filt2')
            data_range = length(full_data) - (round(17400 * signal_fs / 100) - 1):length(full_data);
        end

        % Set threshold using the full signal
        threshold = mean(full_data) - 1.5 * std(full_data);

        % Find dips in the full data
        dip_points = full_data < threshold;
        dip_starts = find(diff([0, dip_points]) == 1);
        dip_ends = find(diff([dip_points, 0]) == -1);

        % Filter dips to include only those that at least partially overlap with the range
        filtered_starts = dip_starts(dip_starts <= data_range(end) & dip_ends >= data_range(1));
        filtered_ends = dip_ends(dip_ends >= data_range(1) & dip_starts <= data_range(end));

        % Adjust starts and ends if they are out of the range
        filtered_starts(filtered_starts < data_range(1)) = data_range(1);
        filtered_ends(filtered_ends > data_range(end)) = data_range(end);

        % Calculate durations, number of dips, and depths for valid dips
        durations = (filtered_ends - filtered_starts + 1) / signal_fs;
        number_of_dips = numel(filtered_starts);
        dip_depths = arrayfun(@(s, e) min(full_data(s:e)), filtered_starts, filtered_ends);

        % Store results in the structure
        dip_results.(var_name) = struct(...
            'Number_of_Dips', number_of_dips,...
            'Average_Duration', durations,...
            'Average_Depth', dip_depths...
        );

        % Save each variable's dip data to a .mat file
        save(fullfile(save_path, [group_name '_' var_name '_dip_data.mat']), 'number_of_dips', 'durations', 'dip_depths');
    end
end
