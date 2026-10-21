function plot_and_highlight_dips_full(variables, group_name, signal_fs)
    figure('Name', [group_name ' Traces with Dips Highlighted'], 'NumberTitle', 'off');
    numVars = length(variables);

    for i = 1:numVars
        var_name = variables{i};
        data = evalin('base', var_name);  % Retrieve full signal data

        % Set threshold using the full signal
        threshold = mean(data) - 1.5 * std(data);

        % Find points where data is below threshold
        dip_points = data < threshold;
        dip_starts = find(diff([0, dip_points]) == 1);
        dip_ends = find(diff([dip_points, 0]) == -1);

        % Plotting in a subplot
        subplot(numVars, 1, i);
        plot(data, 'b'); % Plot the full trace in blue
        hold on;
        % Highlight each dip in red
        for j = 1:length(dip_starts)
            plot(dip_starts(j):dip_ends(j), data(dip_starts(j):dip_ends(j)), 'r', 'LineWidth', 2);
        end
        hold off;

        title(['Trace for ' var_name]);
        ylabel('Signal Intensity');
        if i == numVars
            xlabel('Time Points');
        end
    end
end
