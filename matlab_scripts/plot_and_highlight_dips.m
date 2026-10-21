function plot_and_highlight_dips(variables, group_name, data_range, signal_fs)
    figure('Name', [group_name ' Traces with Dips Highlighted'], 'NumberTitle', 'off');
    numVars = length(variables);

    for i = 1:numVars
        var_name = variables{i};
        full_data = evalin('base', var_name); % Fetch entire signal for threshold calculation

        % Set threshold using the entire signal
        threshold = mean(full_data) - 1.5 * std(full_data);

        % Isolate the segment for dip analysis
        data_segment = full_data(data_range);

        % Find points where the segment is below threshold
        dip_points_segment = data_segment < threshold;
        dip_starts_segment = find(diff([0, dip_points_segment]) == 1);
        dip_ends_segment = find(diff([dip_points_segment, 0]) == -1);

        % Adjust indices for global plotting, aligning with the full dataset
        dip_starts = dip_starts_segment + data_range(1) - 1;
        dip_ends = dip_ends_segment + data_range(1) - 1;

        % Plotting
        subplot(numVars, 1, i);
        plot(full_data, 'b'); % Plot the full trace in blue
        hold on;
        % Highlight each dip in red
        for j = 1:length(dip_starts)
            plot(dip_starts(j):dip_ends(j), full_data(dip_starts(j):dip_ends(j)), 'r', 'LineWidth', 2);
        end
        hold off;

        title(['Trace for ' var_name]);
        ylabel('Signal Intensity');
        if i == numVars
            xlabel('Time Points');
        end
    end
end
