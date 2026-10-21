function compare_saved_dip_data(saline_vars, glucose_vars, save_path)
    % Initialize arrays to store aggregated data
    saline_durations = [];
    saline_depths = [];
    glucose_durations = [];
    glucose_depths = [];
    saline_dips = [];
    glucose_dips = [];
    
    % Load and aggregate data for saline group
    for i = 1:length(saline_vars)
        file_name = fullfile(save_path, ['Saline_' saline_vars{i} '_dip_data.mat']);
        if exist(file_name, 'file')
            loaded_data = load(file_name);
            % Remove NaN values
            loaded_data.durations(isnan(loaded_data.durations)) = [];
            loaded_data.dip_depths(isnan(loaded_data.dip_depths)) = [];
            saline_durations = [saline_durations; loaded_data.durations(:)];
            saline_depths = [saline_depths; loaded_data.dip_depths(:)];
            saline_dips = [saline_dips; loaded_data.number_of_dips(:)];
        else
            warning('File not found: %s', file_name);
        end
    end
    
    % Load and aggregate data for glucose group
    for i = 1:length(glucose_vars)
        file_name = fullfile(save_path, ['Glucose_' glucose_vars{i} '_dip_data.mat']);
        if exist(file_name, 'file')
            loaded_data = load(file_name);
            % Remove NaN values
            loaded_data.durations(isnan(loaded_data.durations)) = [];
            loaded_data.dip_depths(isnan(loaded_data.dip_depths)) = [];
            glucose_durations = [glucose_durations; loaded_data.durations(:)];
            glucose_depths = [glucose_depths; loaded_data.dip_depths(:)];
            glucose_dips = [glucose_dips; loaded_data.number_of_dips(:)];
        else
            warning('File not found: %s', file_name);
        end
    end

    % Perform statistical comparison and plot results
    compare_and_plot('Duration', saline_durations, glucose_durations, 'Duration Comparison');
    compare_and_plot('Depth', saline_depths, glucose_depths, 'Depth Comparison');
    compare_and_plot('Number of Dips', saline_dips, glucose_dips, 'Number of Dips Comparison');
end

function compare_and_plot(metric_name, saline_data, glucose_data, plot_title)
    % Define colors for boxplots
    boxplot_colors = [0.2 0.2 1; 1 0.2 0.2]; % Blue for saline, red for glucose

    % Calculate boxplot positions
    positions = [1, 2]; % Positions for boxplots

    % Create figure
    figure;
    hold on;

    % Scatter individual data points for saline and glucose
    scatter(ones(size(saline_data)), saline_data, 40, 'b', 'filled');
    scatter(2 * ones(size(glucose_data)), glucose_data, 40, 'r', 'filled');

    % Overlay boxplots for saline data
    boxplot(saline_data, 'Positions', positions(1), 'Colors', boxplot_colors(1, :), 'Widths', 0.3);

    % Overlay boxplots for glucose data
    boxplot(glucose_data, 'Positions', positions(2), 'Colors', boxplot_colors(2, :), 'Widths', 0.3);

    % Perform statistical comparison
    if length(saline_data) > 1 && length(glucose_data) > 1
        [~, p_value] = ttest2(saline_data, glucose_data);
    else
        [~, p_value] = ranksum(saline_data, glucose_data); % Use Wilcoxon rank-sum test for small sample sizes
    end

    % Display p-value
    text(1.5, max([max(saline_data), max(glucose_data)]) + 0.05, sprintf('p = %.3f', p_value), 'FontSize', 12, 'HorizontalAlignment', 'center');

    % Draw a line at y = 0
    line([0, 3], [0, 0], 'Color', 'red', 'LineStyle', '--', 'LineWidth', 0.5);

    % Customize plot for clarity
    ylabel(metric_name);
    xlim([0.5 2.5]);
    set(gca, 'XTick', positions, 'XTickLabel', {'Saline', 'Glucose'});
    title(plot_title);
    hold off;
end
