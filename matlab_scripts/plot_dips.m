function plot_dips(variables, group_name, data_range, signal_fs)
    figure('Name', [group_name ' Traces with Dips Highlighted'], 'NumberTitle', 'off');
    numVars = length(variables);
    
    for i = 1:numVars
        var_name = variables{i};
        data = evalin('base', [var_name '(data_range)']);  % Use evalin to access the variable from the base workspace
        
        % Set threshold for dips
        threshold = mean(data) - 2 * std(data);
        
        % Find dips below threshold
        dip_points = data < threshold;
        dip_starts = find(diff([0, dip_points]) == 1);
        dip_ends = find(diff([dip_points, 0]) == -1);
        
        subplot(numVars, 1, i);
        plot(data, 'b'); % Plot the trace in blue
        hold on;
        % Highlight each dip in red
        for j = 1:length(dip_starts)
            area(dip_starts(j):dip_ends(j), data(dip_starts(j):dip_ends(j)), 'FaceColor', 'red', 'EdgeColor', 'none');
        end
        hold off;
        
        title(['Trace for ' var_name]);
        ylabel('Signal');
        if i == numVars
            xlabel('Time (data points)');
        end
        ylim([min(data) max(data)]);
    end
end
