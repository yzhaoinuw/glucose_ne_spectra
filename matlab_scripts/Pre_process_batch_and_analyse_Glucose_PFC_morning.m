%% DESCRIPTION
% In this script you load fiber photometry traces and normalize them to get
% dF/F (or Z-score). The traces will also be aligned by cutting the first
% chunk of data leading up to the first TTL pulse

%% Specify mouse data
% Below you specify input arguments for each recording. Make sure to update
% the name of the channels according to your specific recordings. Adjust
% the fitting interval used for polyfit if the plotted fit looks off.

clear all

% data structure:
    % 1) FP raw data <<<< here you put path for your FP data folder (see example format below)
    % 2) EEG raw data 
    % 3) 465 channel name
    % 4) 405 channel name
    % 5) TTL channel name
    % 6) interval used for signal normalization
    % 7) laser channel name - OPTIONAL (only used for optogenetic stimulations)
    
% mouse data
    %m1 = {'J:\CTN\NedergaardLAB\KjaerbyLab\Experimental projects\Exp1' '' 'x465A' 'x405A' 'Pu1_' (1:10000)};
    %m1 = {'H:\Fiber photometry\Rebeka_FP_2-240229-105744\Rebeka_Elise_FP2_050324' '' 'x465A' 'x405A' 'Pu1_' (1:10000)};
    FP3_PFC = {'H:\Fiber photometry\Glucose\Subject3-240322-092543_morning' '' 'x465A' 'x405A' 'Pu1_' (1:18000)};
    FP4_PFC = {'H:\Fiber photometry\Glucose\FiberPhot4_260324_morning' '' 'x465A' 'x405A' 'Pu1_' (1:18000)};
    FP5_PFC = {'H:\Fiber photometry\Glucose\Subject5-240326-090337_morning' '' 'x465A' 'x405A' 'Pu1_' (1:3600)};
    FP22_PFC = {'H:\Fiber photometry\Glucose\FiberPhot22_240324_morning' '' 'x465A' 'x405A' 'Pu1_' (1:4000)};
    FP1_PFC = {'H:\Fiber photometry\Glucose\FP1_glucose_13hours_090424' '' 'x465A' 'x405A' 'Pu1_' (1:40000)};
    FP2_PFC = {'H:\Fiber photometry\Glucose\FP2_glucose_13hours_100424' '' 'x465A' 'x405A' 'Pu1_' (1:40000)};
mouse = FP3_PFC;
mouse2 = FP4_PFC;
mouse3 = FP5_PFC;
mouse4 = FP22_PFC;
mouse5 = FP1_PFC;
mouse6 = FP2_PFC;

%% Load all

% Define the list of mice data
mice_data = {mouse, mouse2, mouse3, mouse4, mouse5, mouse6};

% Preallocate cell arrays to store signals and data structs
signal_fs_all = zeros(1, numel(mice_data));
signal_465_all = cell(1, numel(mice_data));
signal_405_all = cell(1, numel(mice_data));
data_all = cell(1, numel(mice_data));

% Load data and process for each mouse
for i = 1:numel(mice_data)
    % Load data
    eval(sprintf('data%d = TDTbin2mat(mice_data{%d}{1});', i, i));
    eval(sprintf('data_all{i} = data%d;', i));
    
    % Extract necessary information
    eval(sprintf('signal_fs%d = data%d.streams.(mice_data{%d}{3}).fs;', i, i, i));
    eval(sprintf('signal_465_all{i} = data%d.streams.(mice_data{%d}{3}).data;', i, i));
    eval(sprintf('signal_405_all{i} = data%d.streams.(mice_data{%d}{4}).data;', i, i));
    
    % Find the first TTL pulse
    TTL_onset = 1;
    first_TTL = TTL_onset(1) * eval(sprintf('signal_fs%d', i));
    
    % Cut the signals according to the first TTL pulse
    if i == 1
        eval(sprintf('signal_465 = signal_465_all{i}(first_TTL:end);'));
        eval(sprintf('signal_405 = signal_405_all{i}(first_TTL:end);'));
    else
        eval(sprintf('signal_465_%d = signal_465_all{i}(first_TTL:end);', i));
        eval(sprintf('signal_405_%d = signal_405_all{i}(first_TTL:end);', i));
    end
end

% Access each mouse's data as needed (e.g., signal_465_1, signal_465_2, etc.)

%% For loop for filtering and plots

MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder,1)/MeanFilterOrder;

% Loop through each mouse data
for i = 1:numel(mice_data)
    % Extract necessary information
    signal_fs = signal_fs1;
    signal_465 = signal_465_all{i};
    signal_405 = signal_405_all{i};
    
    % Perform calculations
    fs_signal = 1:1:length(signal_465);
    sec_signal = fs_signal / signal_fs;
    
    reg = polyfit(signal_405(round(mice_data{i}{6} * signal_fs)), signal_465(round(mice_data{i}{6} * signal_fs)), 1);
    a = reg(1);
    b = reg(2);
    controlFit_465 = a .* signal_405 + b;
    controlFit_465 = filtfilt(MeanFilter, 1, double(controlFit_465));
    normDat = (signal_465 - controlFit_465) ./ controlFit_465;
    delta_465 = normDat * 100;

    % smoothing traces
    delta465_filt = filtfilt(MeanFilter, 1, double(delta_465));
    ds_factor_FP = 100; % also used for plotting later (section 9b)

    % downsampling traces for plotting
    ds_delta465_filt = downsample(delta465_filt, ds_factor_FP);
    ds_sec_signal = downsample(sec_signal, ds_factor_FP); % for plotting
    ds_time_minutes = ds_sec_signal / 60; % Convert seconds to minutes for plotting

    % Plot filtered trace (the index 1000:end removes the first second of the recording for nicer plotting)
    figure
    plot(ds_time_minutes, ds_delta465_filt)
    title(sprintf('dF/F for Mouse %d', i));
    xlabel('Time (min)');
    ylabel('dF/F');

    % Z-score
    delta465_Zscore = (delta465_filt - mean(delta465_filt)) / std(delta465_filt);
    save(sprintf('delta465_Zscore_%d.mat', i), 'delta465_Zscore'); % Save Z-score for each mouse

    % Adjusting the plot
    if i == 5 || i == 6 % for mice 5 and 6
        xlim([-5, 800]); % Set x-axis limits
        xticks(0:100:800); % Set x-axis ticks for 100-minute increments
    else % for other mice
        xlim([-5, 300]); % Set x-axis limits
        xticks(0:50:300); % Set x-axis ticks for 50-minute increments
    end
    
    ylim([min(ds_delta465_filt), max(ds_delta465_filt)]); % Ensure data fits within the plot
    
    % Save ds_delta465_filt for each mouse with appropriate variable names
    if i == 1
        save('ds_delta465_filt.mat', 'ds_delta465_filt');
    else
        eval(sprintf('save(''ds_delta465_filt%d.mat'', ''ds_delta465_filt'');', i));
    end

    % Save ds_delta465_filt for each mouse with appropriate variable names
    if i == 1
        save('ds_time_minutes.mat', 'ds_time_minutes');
        save('signal_fs', 'signal_fs'); % Save signal_fs once
    else
        eval(sprintf('save(''ds_time_minutes%d.mat'', ''ds_time_minutes'');', i));
    end

end

% Load the first file
load('ds_delta465_filt.mat'); % Loads into variable ds_delta465_filt

% Load the rest of the files with distinct variable names
for i = 2:6
    filename = sprintf('ds_delta465_filt%d.mat', i);
    temp = load(filename); %Load into a temporary variable
    eval(sprintf('ds_delta465_filt%d = temp.ds_delta465_filt;', i)); % Assign to a variable with a unique name
end

% Load signal_fs
load('signal_fs.mat'); % Loads into variable signal_fs

% Load time variable
load('ds_time_minutes.mat'); % Loads into variable ds_time_minutes

%% Analysis - Mean signal - glucose (0-230 min)

% the desired endpoint 
endpoint = round(13200*signal_fs/100);
%endpoint = round(10200*signal_fs/100);

% mean morning glucose signal 
mean_glucose_0_230 = mean([ds_delta465_filt6(1:endpoint); ds_delta465_filt5(1:endpoint); ds_delta465_filt3(1:endpoint); ds_delta465_filt(1:endpoint)], 1);
%mean_glucose_0_230 = mean([ds_delta465_filt6(1:endpoint); ds_delta465_filt5(1:endpoint); ds_delta465_filt4(1:endpoint); ds_delta465_filt3(1:endpoint); ds_delta465_filt2(1:endpoint); ds_delta465_filt(1:endpoint)], 1);


% Truncate time vector to match the length of the mean signal
ds_time_minutes_truncated = ds_time_minutes(1:length(mean_glucose_0_230));

% Calculate standard deviation
sd_signal = std([ds_delta465_filt6(1:endpoint); ds_delta465_filt5(1:endpoint); ds_delta465_filt3(1:endpoint); ds_delta465_filt(1:endpoint)], 0, 1);
%sd_signal = std([ds_delta465_filt6(1:endpoint); ds_delta465_filt5(1:endpoint); ds_delta465_filt4(1:endpoint); ds_delta465_filt3(1:endpoint); ds_delta465_filt2(1:endpoint); ds_delta465_filt(1:endpoint)], 0, 1);

% Save variables in the current folder
save('mean_glucose_short_PFC_morning.mat', 'mean_glucose_0_230');
save('sd_glucose_short_PFC_morning.mat', 'sd_signal');
save('ds_time_short_glucose_PFC_morning.mat', 'ds_time_minutes_truncated');


% Plot mean signal and standard deviation separately
figure
hold on
% Plot mean signal
plot(ds_time_minutes_truncated(1000:end), mean_glucose_0_230(1000:end), 'LineWidth', 2)
% Plot standard deviation as shaded error bars
patch([ds_time_minutes_truncated, fliplr(ds_time_minutes_truncated)], [mean_glucose_0_230-sd_signal, fliplr(mean_glucose_0_230+sd_signal)], 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none')
% Title and labels
title('Mean dF/F Signal with Standard Deviation');
xlabel('Time (min)');
ylabel('dF/F (z score)');
% Set x-axis limits
xlim([-5, 225]);
% Set x-axis ticks for 10-minute increments
xticks(0:10:225);
% Ensure data fits within the plot
ylim([-20, max(mean_glucose_0_230+sd_signal)]);
% Legend
legend('Mean Signal', 'Standard Deviation', 'Location', 'best');
hold off
%% Analysis - calculate baseline mean

start_time = 1000;
% Set end of baseline for each mouse - time when taken out of cage 
mouse_bl_time = round(3636*signal_fs/100);
mouse2_bl_time = round(3526*signal_fs/100);
mouse3_bl_time = round(3541*signal_fs/100);
mouse4_bl_time = round(3560*signal_fs/100);
mouse5_bl_time = round(4012*signal_fs/100);
mouse6_bl_time = round(3594*signal_fs/100);

% Set baseline period signal for each mouse
mouse_bl = ds_delta465_filt(start_time:mouse_bl_time);
mouse2_bl = ds_delta465_filt2(start_time:mouse2_bl_time);
mouse3_bl = ds_delta465_filt3(start_time:mouse3_bl_time);
mouse4_bl = ds_delta465_filt4(start_time:mouse4_bl_time);
mouse5_bl = ds_delta465_filt5(start_time:mouse5_bl_time);
mouse6_bl = ds_delta465_filt6(start_time:mouse6_bl_time);

% Sanity check
plot(mouse_bl)

% Calculate mean and sd for each baseline
mean_bl = zeros(1, 5);
sd_bl = zeros(1, 5);

% Calculate mean and standard deviation for each mouse
mean_bl(1) = mean(mouse_bl);
mean_bl(2) = mean(mouse2_bl);
mean_bl(3) = mean(mouse3_bl);
mean_bl(4) = mean(mouse5_bl);
mean_bl(5) = mean(mouse6_bl);

sd_bl(1) = std(mouse_bl);
sd_bl(2) = std(mouse2_bl);
sd_bl(3) = std(mouse3_bl);
sd_bl(4) = std(mouse5_bl);
sd_bl(5) = std(mouse6_bl);

% Define mouse labels
mouse_labels = {'Mouse 1', 'Mouse 2', 'Mouse 3', 'Mouse 5', 'Mouse 6'};

% Plot mean and standard deviation for each mouse
figure;
bar(1:5, mean_bl);
hold on;
errorbar(1:5, mean_bl, sd_bl, 'k.', 'LineWidth', 1);
% Title and labels
title('Mean and Standard Deviation of Baseline');
xlabel('Mouse');
ylabel('dF/F (z score)');
% Set x-axis ticks and labels
xticks(1:5);
xticklabels(mouse_labels);
% Legend
legend('Mean', 'Standard Deviation', 'Location', 'best');
hold off;

% Calculate the grand mean and sd
Mean_BL_glucose = mean(mean_bl);
SD_BL_glucose = std(mean_bl);
% Plot
figure;
bar(Mean_BL_glucose);
hold on;
errorbar(Mean_BL_glucose, SD_BL_glucose, 'k.', 'LineWidth', 1);
hold off

% Save variables in the current folder
save('g_morning_PFC_baseline.mat', 'mouse_bl', 'mouse2_bl', 'mouse3_bl', 'mouse4_bl', 'mouse5_bl', 'mouse6_bl', 'mean_bl', 'sd_bl', 'Mean_BL_glucose', 'SD_BL_glucose');

%% Analysis - calculate mean 1 and 2 hours after injection

% Set injection time for each mouse
mouse_inj_time = round(3670*signal_fs/100);
mouse2_inj_time = round(3602*signal_fs/100);
mouse3_inj_time = round(3587*signal_fs/100);
mouse4_inj_time = round(3582*signal_fs/100);
mouse5_inj_time = round(4040*signal_fs/100);
mouse6_inj_time = round(3632*signal_fs/100);

% Set end of effect for injection
mouse_inj_end = mouse_inj_time+round(1200*signal_fs/100);
mouse2_inj_end = mouse2_inj_time+round(1200*signal_fs/100);
mouse3_inj_end = mouse3_inj_time+round(1200*signal_fs/100);
mouse4_inj_end = mouse4_inj_time+round(1200*signal_fs/100);
mouse5_inj_end = mouse5_inj_time+round(1200*signal_fs/100);
mouse6_inj_end = mouse6_inj_time+round(1200*signal_fs/100);

% Set end of 1h period
m_1h = mouse_inj_end+round(3600*signal_fs/100);
m2_1h = mouse2_inj_end+round(3600*signal_fs/100);
m3_1h = mouse3_inj_end+round(3600*signal_fs/100);
m4_1h = mouse4_inj_end+round(3600*signal_fs/100);
m5_1h = mouse5_inj_end+round(3600*signal_fs/100);
m6_1h = mouse6_inj_end+round(3600*signal_fs/100);

% Set period between injection and 1 hours later
mouse_1h = ds_delta465_filt(mouse_inj_end:m_1h);
mouse2_1h = ds_delta465_filt2(mouse2_inj_end:m2_1h);
mouse3_1h = ds_delta465_filt3(mouse3_inj_end:m3_1h);
mouse4_1h = ds_delta465_filt4(mouse4_inj_end:m4_1h);
mouse5_1h = ds_delta465_filt5(mouse5_inj_end:m5_1h);
mouse6_1h = ds_delta465_filt6(mouse6_inj_end:m6_1h);

%Sanity check
figure
plot(mouse6_1h);

% Set end of 2h period
m_2h = mouse_inj_end+round(7200*signal_fs/100);
m2_2h = mouse2_inj_end+round(7200*signal_fs/100);
m3_2h = mouse3_inj_end+round(7200*signal_fs/100);
m4_2h = mouse4_inj_end+round(7200*signal_fs/100);
m5_2h = mouse5_inj_end+round(7200*signal_fs/100);
m6_2h = mouse6_inj_end+round(7200*signal_fs/100);

% Set period for 2nd hour after injection effect is over
mouse_2h = ds_delta465_filt(m_1h:m_2h);
mouse2_2h = ds_delta465_filt2(m2_1h:m2_2h);
mouse3_2h = ds_delta465_filt3(m3_1h:m3_2h);
mouse4_2h = ds_delta465_filt4(m4_1h:m4_2h);
mouse5_2h = ds_delta465_filt5(m5_1h:m5_2h);
mouse6_2h = ds_delta465_filt6(m6_1h:m6_2h);

% Sanity check
figure
plot(mouse5_2h);

% Calculate mean and sd for each 1 h
% Calculate the mean and standard deviation for each mouse
mean_1h = zeros(1, 5);
sd_1h = zeros(1, 5);

% Calculate mean and standard deviation for each mouse
mean_1h(1) = mean(mouse_1h);
mean_1h(2) = mean(mouse2_1h);
mean_1h(3) = mean(mouse3_1h);
mean_1h(4) = mean(mouse5_1h);
mean_1h(5) = mean(mouse6_1h);

sd_1h(1) = std(mouse_1h);
sd_1h(2) = std(mouse2_1h);
sd_1h(3) = std(mouse3_1h);
sd_1h(4) = std(mouse5_1h);
sd_1h(5) = std(mouse6_1h);

% Plot mean and standard deviation for each mouse
figure;
bar(1:5, mean_1h);
hold on;
errorbar(1:5, mean_1h, sd_1h, 'k.', 'LineWidth', 1);

% Title and labels
title('Mean and Standard Deviation of 1 hour after injection');
xlabel('Mouse');
ylabel('dF/F (z score)');

% Set x-axis ticks and labels
xticks(1:5);
xticklabels(mouse_labels);

% Grid
%grid on;

% Legend
legend('Mean', 'Standard Deviation', 'Location', 'best');

hold off;

% Calculate the grand mean and sd
Mean_1h_glucose = mean(mean_1h);
SD_1h_glucose = std(mean_1h);
% Plot
figure;
bar(Mean_1h_glucose);
hold on;
errorbar(Mean_1h_glucose, SD_1h_glucose, 'k.', 'LineWidth', 1);
hold off

%% Compare baseline and 1 hour after injection
% Perform paired t-test
[h, p, ci, stats] = ttest(mean_bl, mean_1h);

% Display the results
disp(['p-value: ', num2str(p)]);
disp(['95% Confidence Interval: [', num2str(ci(1)), ', ', num2str(ci(2)), ']']);
disp(['T-statistic: ', num2str(stats.tstat)]);

% Determine the significance
if p < 0.05
    disp('The difference is statistically significant (p < 0.05).');
else
    disp('The difference is not statistically significant (p >= 0.05).');
end

% Plot

% Define mouse labels
mouse_labels = {'Mouse 1', 'Mouse 2', 'Mouse 3', 'Mouse 5', 'Mouse 6'};

% Plot grand mean of baseline and 1 hour after injection with error bars
figure;
bar(1:2, [Mean_BL_glucose, Mean_1h_glucose]);
hold on;
errorbar(1:2, [Mean_BL_glucose, Mean_1h_glucose], [SD_BL_glucose, SD_1h_glucose], 'k.', 'LineWidth', 1);
% Title and labels
title('Comparison of Grand Mean Between Baseline and 1 Hour After Injection');
xlabel('Time Point');
ylabel('Grand Mean dF/F (z score)');
% Set x-axis ticks and labels
xticks(1:2);
xticklabels({'Baseline', '1 Hour After Injection'});
% Legend
legend('Grand Mean', 'Standard Deviation', 'Location', 'best');
hold off;

% Calculate and define the significance level text
if p < 0.001
    significance_text = '***';
elseif p < 0.01
    significance_text = '**';
elseif p < 0.05
    significance_text = '*';
else
    significance_text = 'n.s.';
end

colors = lines(5);
% Plot means for each group separately with different colors for each mouse
figure;
hold on;
for i = 1:5
    scatter(1, mean_bl(i), 100, colors(i, :), 'filled');
    scatter(2, mean_1h(i), 100, colors(i, :), 'filled');
    % Draw line indicating the difference between the means
    line([1, 2], [mean_bl(i), mean_1h(i)], 'Color', colors(i, :), 'LineWidth', 1.5);
end
% Add significance level text
text(1.5, ((Mean_BL_glucose + Mean_1h_glucose) / 2)+16, significance_text, 'FontSize', 16, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
% add line
line([0,4],[0,0], 'Color', 'r', 'LineStyle', '--', 'LineWidth', .5)
% Plot grand mean and standard deviation for baseline
errorbar(1, Mean_BL_glucose, SD_BL_glucose, 'k.', 'MarkerSize', 20, 'LineWidth', 1.5);
% Plot grand mean and standard deviation for 1 hour after injection
errorbar(2, Mean_1h_glucose, SD_1h_glucose, 'k.', 'MarkerSize', 20, 'LineWidth', 1.5);
% Title and labels
title('Comparison of Baseline and 1 Hour After Injection');
xlabel('Group');
ylabel('dF/F (z score)');
% Set x-axis limits to center the groups
xlim([0.5, 2.5]);
% Set x-axis ticks and labels
xticks([1, 2]);
xticklabels({'Baseline', '1 Hour After Injection'});

%% Compare baseline and 2 hour after injection
% Calculate mean and sd for each 1 h
% Calculate the mean and standard deviation for each mouse
mean_2h = zeros(1, 5);
sd_2h = zeros(1, 5);

% Calculate mean and standard deviation for each mouse
mean_2h(1) = mean(mouse_2h);
mean_2h(2) = mean(mouse2_2h);
mean_2h(3) = mean(mouse3_2h);
mean_2h(4) = mean(mouse5_2h);
mean_2h(5) = mean(mouse6_2h);

sd_2h(1) = std(mouse_2h);
sd_2h(2) = std(mouse2_2h);
sd_2h(3) = std(mouse3_2h);
sd_2h(4) = std(mouse5_2h);
sd_2h(5) = std(mouse6_2h);

% Plot mean and standard deviation for each mouse
figure;
bar(1:5, mean_2h);
hold on;
errorbar(1:5, mean_2h, sd_2h, 'k.', 'LineWidth', 1);
% Title and labels
title('Mean and Standard Deviation of 2 hour after injection');
xlabel('Mouse');
ylabel('dF/F (z score)');
% Set x-axis ticks and labels
xticks(1:5);
xticklabels(mouse_labels);
% Legend
legend('Mean', 'Standard Deviation', 'Location', 'best');
hold off;

% Calculate the grand mean and sd
Mean_2h_glucose = mean(mean_2h);
SD_2h_glucose = std(mean_2h);
% Plot
figure;
bar(Mean_2h_glucose);
hold on;
errorbar(Mean_2h_glucose, SD_2h_glucose, 'k.', 'LineWidth', 1);
hold off

% Perform paired t-test
[h, p, ci, stats] = ttest(mean_bl, mean_2h);

% Define mouse labels
mouse_labels = {'Mouse 1', 'Mouse 2', 'Mouse 3', 'Mouse 5', 'Mouse 6'};

% Plot grand mean of baseline and 1 hour after injection with error bars
figure;
bar(1:2, [Mean_BL_glucose, Mean_2h_glucose]);
hold on;
errorbar(1:2, [Mean_BL_glucose, Mean_2h_glucose], [SD_BL_glucose, SD_2h_glucose], 'k.', 'LineWidth', 1);
% Title and labels
title('Comparison of Grand Mean Between Baseline and 2 Hours After Injection');
xlabel('Time Point');
ylabel('Grand Mean dF/F (z score)');
% Set x-axis ticks and labels
xticks(1:2);
xticklabels({'Baseline', '2 Hours After Injection'});
% Legend
legend('Grand Mean', 'Standard Deviation', 'Location', 'best');
hold off;

% Calculate the significance level text
if p < 0.001
    significance_text = '***';
elseif p < 0.01
    significance_text = '**';
elseif p < 0.05
    significance_text = '*';
else
    significance_text = 'n.s.';
end

% Plot means for each group separately with different colors for each mouse
figure;
hold on;
for i = 1:5
    scatter(1, mean_bl(i), 100, colors(i, :), 'filled');
    scatter(2, mean_2h(i), 100, colors(i, :), 'filled');
    % Draw line indicating the difference between the means
    line([1, 2], [mean_bl(i), mean_2h(i)], 'Color', colors(i, :), 'LineWidth', 1.5);
end
% Add significance level text
text(1.5, ((Mean_BL_glucose + Mean_2h_glucose) / 2)+16, significance_text, 'FontSize', 16, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
% add line
line([0,4],[0,0], 'Color', 'r', 'LineStyle', '--', 'LineWidth', .5)
% Plot grand mean and standard deviation for baseline
errorbar(1, Mean_BL_glucose, SD_BL_glucose, 'k.', 'MarkerSize', 20, 'LineWidth', 1.5);
% Plot grand mean and standard deviation for 1 hour after injection
errorbar(2, Mean_2h_glucose, SD_2h_glucose, 'k.', 'MarkerSize', 20, 'LineWidth', 1.5);
% Title and labels
title('Comparison of Baseline and 2 Hours After Injection');
xlabel('Group');
ylabel('dF/F (z score)');
% Set x-axis limits to center the groups
xlim([0.5, 2.5]);
% Set x-axis ticks and labels
xticks([1, 2]);
xticklabels({'Baseline', '2 Hours After Injection'});

%% Compare BL vs 3hours after inj
% Set end of 2h period
m_3h = mouse_inj_end+round(10800*signal_fs/100);
m2_3h = mouse2_inj_end+round(10800*signal_fs/100);
m3_3h = mouse3_inj_end+round(10800*signal_fs/100);
m4_3h = mouse4_inj_end+round(10800*signal_fs/100);
m5_3h = mouse5_inj_end+round(10800*signal_fs/100);
m6_3h = mouse6_inj_end+round(10800*signal_fs/100);

% Set period for 2nd hour after injection effect is over
mouse_3h = ds_delta465_filt(m_2h:m_3h);
mouse2_3h = ds_delta465_filt2(m2_2h:m2_3h);
mouse3_3h = ds_delta465_filt3(m3_2h:m3_3h);
mouse4_3h = ds_delta465_filt4(m4_2h:m4_3h);
mouse5_3h = ds_delta465_filt5(m5_2h:m5_3h);
mouse6_3h = ds_delta465_filt6(m6_2h:m6_3h);

% Calculate mean and sd for each 1 h
% Calculate the mean and standard deviation for each mouse
mean_3h = zeros(1, 5);
sd_3h = zeros(1, 5);

% Calculate mean and standard deviation for each mouse
mean_3h(1) = mean(mouse_3h);
mean_3h(2) = mean(mouse2_3h);
mean_3h(3) = mean(mouse3_3h);
mean_3h(4) = mean(mouse5_3h);
mean_3h(5) = mean(mouse6_3h);

sd_3h(1) = std(mouse_3h);
sd_3h(2) = std(mouse2_3h);
sd_3h(3) = std(mouse3_3h);
sd_3h(4) = std(mouse5_3h);
sd_3h(5) = std(mouse6_3h);

% Plot mean and standard deviation for each mouse
figure;
bar(1:5, mean_3h);
hold on;
errorbar(1:5, mean_3h, sd_3h, 'k.', 'LineWidth', 1);
% Title and labels
title('Mean and Standard Deviation of 3 hours after injection');
xlabel('Mouse');
ylabel('dF/F (z score)');
% Set x-axis ticks and labels
xticks(1:5);
xticklabels(mouse_labels);
% Legend
legend('Mean', 'Standard Deviation', 'Location', 'best');
hold off;

% Calculate the grand mean and sd
Mean_3h_glucose = mean(mean_3h);
SD_3h_glucose = std(mean_3h);
% Plot
figure;
bar(Mean_3h_glucose);
hold on;
errorbar(Mean_3h_glucose, SD_3h_glucose, 'k.', 'LineWidth', 1);
hold off

% Perform paired t-test
[h, p, ci, stats] = ttest(mean_bl, mean_3h);

% Plot
% Calculate the significance level text
if p < 0.001
    significance_text = '***';
elseif p < 0.01
    significance_text = '**';
elseif p < 0.05
    significance_text = '*';
else
    significance_text = 'n.s.';
end

% Define mouse labels
mouse_labels = {'Mouse 1', 'Mouse 2', 'Mouse 3', 'Mouse 5', 'Mouse 6'};

% Plot grand mean of baseline and 1 hour after injection with error bars
figure;
bar(1:2, [Mean_BL_glucose, Mean_3h_glucose]);
hold on;
errorbar(1:2, [Mean_BL_glucose, Mean_3h_glucose], [SD_BL_glucose, SD_3h_glucose], 'k.', 'LineWidth', 1);
% Title and labels
title('Comparison of Grand Mean Between Baseline and 3 Hours After Injection');
xlabel('Time Point');
ylabel('Grand Mean dF/F (z score)');
% Set x-axis ticks and labels
xticks(1:2);
xticklabels({'Baseline', '3 Hours After Injection'});
% Legend
legend('Grand Mean', 'Standard Deviation', 'Location', 'best');
hold off;

% Plot means for each group separately with different colors for each mouse
figure;
hold on;
for i = 1:5
    scatter(1, mean_bl(i), 100, colors(i, :), 'filled');
    scatter(2, mean_3h(i), 100, colors(i, :), 'filled');
    % Draw line indicating the difference between the means
    line([1, 2], [mean_bl(i), mean_3h(i)], 'Color', colors(i, :), 'LineWidth', 1.5);
end
% Add significance level text
text(1.5, ((Mean_BL_glucose + Mean_3h_glucose) / 2)+16, significance_text, 'FontSize', 16, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
% add line
line([0,4],[0,0], 'Color', 'r', 'LineStyle', '--', 'LineWidth', .5)
% Plot grand mean and standard deviation for baseline
errorbar(1, Mean_BL_glucose, SD_BL_glucose, 'k.', 'MarkerSize', 20, 'LineWidth', 1.5);
% Plot grand mean and standard deviation for 1 hour after injection
errorbar(2, Mean_3h_glucose, SD_3h_glucose, 'k.', 'MarkerSize', 20, 'LineWidth', 1.5);
% Title and labels
title('Comparison of Baseline and 2 Hours After Injection');
xlabel('Group');
ylabel('dF/F (z score)');
% Set x-axis limits to center the groups
xlim([0.5, 2.5]);
% Set x-axis ticks and labels
xticks([1, 2]);
xticklabels({'Baseline', '2 Hours After Injection'});

%% Save variables

% Save variables for 1 hour period
save('g_morning_PFC_1h.mat', 'mouse_1h', 'mouse2_1h', 'mouse3_1h', 'mouse4_1h', 'mouse5_1h', 'mouse6_1h', 'mean_1h', 'sd_1h', 'Mean_1h_glucose', 'SD_1h_glucose');
% Save variables for 2 hour period
save('g_morning_PFC_2h.mat', 'mouse_2h', 'mouse2_2h', 'mouse3_2h', 'mouse4_2h', 'mouse5_2h', 'mouse6_2h', 'mean_2h', 'sd_2h', 'Mean_2h_glucose', 'SD_2h_glucose');
% Save variables for 3 hour period
save('g_morning_PFC_3h.mat', 'mouse_3h', 'mouse2_3h', 'mouse3_3h', 'mouse4_3h', 'mouse5_3h', 'mouse6_3h', 'mean_3h', 'sd_3h', 'Mean_3h_glucose', 'SD_3h_glucose');

%% Plotting multiple timepoints

% Sample Data Setup
mouse_labels = {'Mouse 1', 'Mouse 2', 'Mouse 3', 'Mouse 5', 'Mouse 6'};
colors = lines(5); % colors for each mouse

% Calculate Grand Means and Standard Deviations for plotting
grand_means = [mean(mean_bl), mean(mean_1h), mean(mean_2h), mean(mean_3h)];
grand_stds = [std(mean_bl), std(mean_1h), std(mean_2h), std(mean_3h)];

% Define the number of comparisons
num_comparisons = 5;
bonferroni_alpha = 0.05 / num_comparisons;

% Perform t-tests for specified comparisons
[~, p_bl_1h] = ttest(mean_bl, mean_1h);
[~, p_bl_2h] = ttest(mean_bl, mean_2h);
[~, p_bl_3h] = ttest(mean_bl, mean_3h);
[~, p_1h_2h] = ttest(mean_1h, mean_2h);
[~, p_2h_3h] = ttest(mean_2h, mean_3h);

% Adjust p-values for Bonferroni correction
adjusted_p_values = [p_bl_1h, p_bl_2h, p_bl_3h, p_1h_2h, p_2h_3h] * num_comparisons;

% Ensure adjusted p-values do not exceed 1
adjusted_p_values = min(adjusted_p_values, 1);

% Plotting
figure;
hold on;
% Plot Grand Mean and Error Bars
errorbar(1:4, grand_means, grand_stds, 'ko-', 'LineWidth', 2, 'MarkerFaceColor', 'k');
% Plot individual mouse data with lines between points
for i = 1:numel(mouse_labels)
    mouse_data = [mean_bl(i), mean_1h(i), mean_2h(i), mean_3h(i)];
    scatter(1:4, mouse_data, 100, colors(i, :), 'filled');
    plot(1:4, mouse_data, 'Color', colors(i, :), 'LineWidth', 1.5);
end
% Add significance signs if adjusted p-values are below the Bonferroni-adjusted threshold
significance_y = max(grand_means + grand_stds) + 0.1; % Adjust y position for significance markers
for i = 1:4
    if adjusted_p_values(i) < bonferroni_alpha
        text(i+0.5, significance_y, '*', 'FontSize', 14, 'HorizontalAlignment', 'center')
    end
end
% add line
line([0,5],[0,0], 'Color', 'r', 'LineStyle', '--', 'LineWidth', .5)
% Customize plot for clarity
title('Grand Mean Comparison Across Time Points');
xlabel('Time Point');
ylabel('dF/F (z score)');
xticks(1:4);
xticklabels({'Baseline', '1 Hour', '2 Hours', '3 Hours'});
legend('Grand Mean ± SD', 'Mouse', 'Location', 'northeast');
hold off;