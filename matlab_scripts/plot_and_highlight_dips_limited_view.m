function plot_and_highlight_dips_limited_view(variables, group_name, signal_fs)
    figure('Name', [group_name ' Traces with Dips Highlighted'], 'NumberTitle', 'off');
    numVars = length(variables);
    plot_start_index = round(3000 * signal_fs / 100);  % Define the start index for plotting
    %plot_start_index = 1000; % For evening
    plot_end_index = round(16200 * signal_fs / 100);
    for i = 1:numVars
        var_name = variables{i};
        data = evalin('base', var_name);  % Retrieve full signal data

        % Set threshold using the full signal
        threshold = mean(data) - 1.3 * std(data);

        % Find points where data is below threshold
        dip_points = data < threshold;
        dip_starts = find(diff([0, dip_points]) == 1);
        dip_ends = find(diff([dip_points, 0]) == -1);

        % Plotting in a subplot
        subplot(numVars, 1, i);
        plot(data(plot_start_index:end), 'b'); % Plot the trace in blue from 1000 to end
        hold on;

        % Highlight each dip in red, but only within the plot range
        for j = 1:length(dip_starts)
            if dip_starts(j) >= plot_start_index
                % Adjust dip indices for the reduced plot range
                plot_range_start = max(dip_starts(j), plot_start_index) - plot_start_index + 1;
                plot_range_end = dip_ends(j) - plot_start_index + 1;
                plot(plot_range_start:plot_range_end, data(dip_starts(j):dip_ends(j)), 'r', 'LineWidth', 2);
            end
        end
        hold off;

        % Adjust x-axis limits based on specific variables
        if strcmp(var_name, 'ds_delta465_eve_filt5') || strcmp(var_name, 'ds_delta465_eve_filt6') || strcmp(var_name, 'ds_delta465_sal_evening_filt2')
            xlim([length(data) - plot_end_index + 1, length(data)]);
        else
            xlim([1, length(data(plot_start_index:plot_end_index))]);  % Adjust the x-axis limits to match the new plotting range
        end
        
        title(['Trace for ' var_name]);
        ylabel('Signal Intensity');
        if i == numVars
            xlabel('Time Points from 1000');
        end
    end
end
