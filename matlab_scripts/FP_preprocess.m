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
    m1 = {'H:\Arch\RZ10_2\Subject1_nr13_240912-101747' '' 'x465C' 'x405C' 'Pu1_' (2000:14000)};
    m2 = {'J:\CTN\NedergaardLAB\Personal_folders\Rebeka\Anastasia\20220914_sleepFP_1_794_2_788' '' 'x465C' 'x405C' 'Pu1_' (1:10000)};
mouse = m1;
mouse2 = m2;
%% Load FP data - m1
% Here fiber photometry data is loaded and cut according to the first TTL
% pulse.


%mouse{6}(9050:end)=[];

data = TDTbin2mat(mouse{1});

signal_fs = data.streams.(mouse{3}).fs;

signal_465 = data.streams.(mouse{3}).data; %hSyn-NE2m
signal_405 = data.streams.(mouse{4}).data; %autofluorescence

% removing FP trace prior to first TTL pulse
% TTL_FP = data.epocs.(mouse{5}).onset;
% TTL_gap = diff(TTL_FP) > 10 + 1;
% if isempty(find(TTL_gap == 1, 1))
%    TTL_onset = TTL_FP(1);  % when TTL pulse train is only started once
% else 
%    TTL_onset = TTL_FP(find(TTL_gap==1)+1); % when TTL pulse train is started more than once
% end

TTL_onset = 1;
first_TTL = TTL_onset(1)*signal_fs; %sampling point # to start with
onset_FP = first_TTL;

signal_465 = signal_465(onset_FP:end);
signal_405 = signal_405(onset_FP:end);

%% Load FP data - m2
% Here fiber photometry data is loaded and cut according to the first TTL
% pulse.

%mouse2{6}=1:140000;

data2 = TDTbin2mat(mouse2{1});

signal_fs2 = data2.streams.(mouse2{3}).fs;

signal_465_2 = data2.streams.(mouse2{3}).data; %hSyn-NE2m
signal_405_2 = data2.streams.(mouse2{4}).data; %autofluorescence

% removing FP trace prior to first TTL pulse
% TTL_FP2 = data2.epocs.(mouse2{5}).onset;
% TTL_gap2 = diff(TTL_FP2) > 10 + 1;
% if isempty(find(TTL_gap2 == 1, 1))
%    TTL_onset2 = TTL_FP2(1);  % when TTL pulse train is only started once
% else 
%    TTL_onset2 = TTL_FP2(find(TTL_gap2==1)+1); % when TTL pulse train is started more than once
% end

TTL_onset2 = 1;
first_TTL2 = TTL_onset2(1)*signal_fs2; %sampling point # to start with
onset_FP2 = first_TTL2;

signal_465_2 = signal_465_2(onset_FP2:end);
signal_405_2 = signal_405_2(onset_FP2:end);


%% Normalize and plot - m1
% Here the fluorescence traces are normalised based on a fit of the 405 nm
% channel. This should remove the drift in the 465 nm channel. make sure to
% check the fit in the plot and adjust fitting interval if the fit is not
% working properly.

MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder,1)/MeanFilterOrder;

fs_signal = 1:1:length(signal_465);
sec_signal = fs_signal/signal_fs;

reg = polyfit(signal_405(round(mouse{6}*signal_fs)), signal_465(round(mouse{6}*signal_fs)), 1);
a = reg(1);
b = reg(2);
controlFit_465 = a.*signal_405 + b;
controlFit_465 =  filtfilt(MeanFilter,1,double(controlFit_465));
normDat = (signal_465 - controlFit_465)./controlFit_465;
delta_465 = normDat * 100;

figure

% Define time in minutes
time_minutes = sec_signal(1000:end) / 60; % Convert seconds to minutes

a = subplot(4,1,1);
plot(time_minutes, signal_405(1000:end));
ylabel('Fluorescence (a.u.)');
title('Raw Control');

b = subplot(4,1,2);
plot(time_minutes, signal_465(1000:end));
ylabel('Fluorescence (a.u.)');
title('Raw Signal');

c = subplot(4,1,3);
plot(time_minutes, signal_465(1000:end));
hold on
plot(time_minutes, controlFit_465(1000:end));
ylabel('Fluorescence (a.u.)');
title('Fitted Control');

d = subplot(4,1,4);
plot(time_minutes, delta_465(1000:end));
ylabel('dF/F (z score)');
xlabel('Time (m)');
title('Normalized Signal');

% Set x-axis limits for all subplots
minTime = min(time_minutes);
maxTime = max(time_minutes);

% Adjust x-axis limits for all subplots
set(a, 'XLim', [-5, 250]);
set(b, 'XLim', [-5, 250]);
set(c, 'XLim', [-5, 250]);
set(d, 'XLim', [-5, 250]);

% Set x-axis ticks for all subplots
set(a, 'XTick', 0:60:250);
set(b, 'XTick', 0:60:250);
set(c, 'XTick', 0:60:250);
set(d, 'XTick', 0:60:250);

linkaxes([a,b,c,d],'x');



% Convert time to minutes
time_minutes = sec_signal / 60;

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
title('dF/F');

% Z-score
%delta465_Zscore = (delta465_filt - mean(delta465_filt)) / std(delta465_filt);

% Adjusting the plot to match previous figure settings
xlabel('Time (min)');
ylabel('dF/F (z score)');

% Set x-axis limits
xlim([0, 250]);
ylim([-30, 20]);
%xlim([-5,800])

% Set x-axis ticks for 10-minute increments
xticks(0:5:250);

% Ensure data fits within the plot
ylim([min(ds_delta465_filt), max(ds_delta465_filt)]);

%% Normalize and plot - m2
% Here the fluorescence traces are normalised based on a fit of the 405 nm
% channel. This should remove the drift in the 465 nm channel. make sure to
% check the fit in the plot and adjust fitting interval if the fit is not
% working properly.

MeanFilterOrder2 = 1000; % for smoothing
MeanFilter2 = ones(MeanFilterOrder2,1)/MeanFilterOrder2;

fs_signal2 = 1:1:length(signal_465_2);
sec_signal2 = fs_signal2/signal_fs2;

reg2 = polyfit(signal_405_2(round(mouse2{6}*signal_fs2)), signal_465_2(round(mouse2{6}*signal_fs2)), 1);
a2 = reg2(1);
b2 = reg2(2);
controlFit_465_2 = a2.*signal_405_2 + b2;
controlFit_465_2 =  filtfilt(MeanFilter2,1,double(controlFit_465_2));
normDat2 = (signal_465_2 - controlFit_465_2)./controlFit_465_2;
delta_465_2 = normDat2 * 100;

figure

% Define time in minutes
time_minutes = sec_signal2(1000:end) / 60; % Convert seconds to minutes

a = subplot(4,1,1);
plot(time_minutes, signal_405_2(1000:end));
ylabel('Fluorescence (a.u.)');
title('Raw Control');

b = subplot(4,1,2);
plot(time_minutes, signal_465_2(1000:end));
ylabel('Fluorescence (a.u.)');
title('Raw Signal');

c = subplot(4,1,3);
plot(time_minutes, signal_465_2(1000:end));
hold on
plot(time_minutes, controlFit_465_2(1000:end));
ylabel('Fluorescence (a.u.)');
title('Fitted Control');

d = subplot(4,1,4);
plot(time_minutes, delta_465_2(1000:end));
ylabel('dF/F (z score)');
xlabel('Time (m)');
title('Normalized Signal');

% Set x-axis limits for all subplots
minTime = min(time_minutes);
maxTime = max(time_minutes);

% Adjust x-axis limits for all subplots
set(a, 'XLim', [-5, 200]);
set(b, 'XLim', [-5, 200]);
set(c, 'XLim', [-5, 200]);
set(d, 'XLim', [-5, 200]);

% Set x-axis ticks for all subplots
set(a, 'XTick', 0:60:200);
set(b, 'XTick', 0:60:200);
set(c, 'XTick', 0:60:200);
set(d, 'XTick', 0:60:200);

linkaxes([a,b,c,d],'x');



% Convert time to minutes
time_minutes = sec_signal2 / 60;

% smoothing traces
delta465_filt2 = filtfilt(MeanFilter2, 1, double(delta_465_2));
ds_factor_FP2 = 100; % also used for plotting later (section 9b)

% downsampling traces for plotting
ds_delta465_filt2 = downsample(delta465_filt2, ds_factor_FP2);
ds_sec_signal2 = downsample(sec_signal2, ds_factor_FP2); % for plotting
ds_time_minutes2 = ds_sec_signal2 / 60; % Convert seconds to minutes for plotting

% Plot filtered trace (the index 1000:end removes the first second of the recording for nicer plotting)
figure
plot(ds_time_minutes2(1000:end), ds_delta465_filt2(1000:end))
title('dF/F');

% Z-score
delta465_Zscore2 = (delta465_filt2 - mean(delta465_filt2)) / std(delta465_filt2);

% Adjusting the plot to match previous figure settings
xlabel('Time (min)');
ylabel('dF/F (z score)');

% Set x-axis limits
%xlim([-5, 160]);
xlim([-5, 200]);
%ylim([-30, 15]);
%xlim([-5,800])

% Set x-axis ticks for 10-minute increments
xticks(0:5:200);

% Ensure data fits within the plot
ylim([min(ds_delta465_filt2), max(ds_delta465_filt2)]);


%% Overlay two figures

% Convert time to minutes for the first figure
time_minutes = sec_signal / 60;

% smoothing traces for the first figure
delta465_filt = filtfilt(MeanFilter, 1, double(delta_465));
ds_factor_FP = 100; % also used for plotting later (section 9b)

% downsampling traces for plotting for the first figure
ds_delta465_filt = downsample(delta465_filt, ds_factor_FP);
ds_sec_signal = downsample(sec_signal, ds_factor_FP); % for plotting
ds_time_minutes = ds_sec_signal / 60; % Convert seconds to minutes for plotting

% Convert time to minutes for the second figure
time_minutes2 = sec_signal2 / 60;

% smoothing traces for the second figure
delta465_filt2 = filtfilt(MeanFilter2, 1, double(delta_465_2));
ds_factor_FP2 = 100; % also used for plotting later (section 9b)

% downsampling traces for plotting for the second figure
ds_delta465_filt2 = downsample(delta465_filt2, ds_factor_FP2);
ds_sec_signal2 = downsample(sec_signal2, ds_factor_FP2); % for plotting
ds_time_minutes2 = ds_sec_signal2 / 60; % Convert seconds to minutes for plotting

% Plot filtered trace for the first figure (the index 1000:end removes the first second of the recording for nicer plotting)
figure
plot(ds_time_minutes, ds_delta465_filt, 'r') % Plot the first figure in red
hold on % Allow multiple plots on the same axes

% Plot filtered trace for the second figure
plot(ds_time_minutes2, ds_delta465_filt2, 'b') % Plot the second figure in blue

% Adjusting the plot to match previous figure settings
xlabel('Time (min)');
ylabel('dF/F (z score)');

% Set x-axis limits
%xlim([25, 135]);
%ylim([-30, 15]);
xlim([-5,185])

% Set x-axis ticks for 10-minute increments
xticks(0:10:185);

% Ensure data fits within the plot
ylim([min(min(ds_delta465_filt), min(ds_delta465_filt2)), max(max(ds_delta465_filt), max(ds_delta465_filt2))]);

% Add a legend with labels
legend('PFC', 'OC');

% Add a title
title('Mouse #3');

%% Load laser stimulations saved with the TDT data tank (OPTIONAL)
% In case you did optogenetic stimulations (or other stimulations) that are
% controlled by Synapse and saved as an epoc channel, you can load them with
% the following script. Just specify the field name of the stimulation as
% recorded in TDT data tank.

% load laser on- and offsets
laser_on = data.epocs.(mouse{7}).onset-TTL_onset;
laser_on = laser_on( laser_on>=0 );
laser_off = data.epocs.(mouse{7}).offset-TTL_onset;
laser_off = laser_off( laser_off>=0 );

% Create binary vector from on/offsets
laser_binary_vector = zeros([1, length(sec_signal)]); 
for i=1:length(laser_on)
    on = laser_on(i)*signal_fs; 
    off = laser_off(i)*signal_fs;
    %if off == inf                        % in case recording ended while laser was on
     %   off = length(signal_465);
    %end
    laser_binary_vector(on:off) = 1;
end

ds_laser_binary_vector = downsample(laser_binary_vector, ds_factor_FP);

figure
a = subplot(2,1,1);
    plot(ds_sec_signal, ds_delta465_filt)
    title('dF/F');
b = subplot(2,1,2);
    plot(sec_signal, laser_binary_vector)
    ylim([-1 2])
    title('laser');
linkaxes([a,b],'x');

%% Tail lift analysis
first_lift = round(45*60*signal_fs/100); %find the point of the first lift in the signal

% plot 2 min before and 2 min after lift
one_minute = round(60*signal_fs/100);
first_lift_signal = ds_delta465_filt(first_lift - 2*one_minute:first_lift + 2*one_minute);
four = length(first_lift_signal);
%four = 1;

figure
a = subplot(2,1,1);
    plot(ds_sec_signal(1:four), first_lift_signal)
    title('dF/F');




 first_lift = round(105*60*signal_fs/100); %find the point of the first lift in the signal

% plot 2 min before and 2 min after lift
one_minute = round(60*signal_fs/100);
first_lift_signal = ds_delta465_filt(first_lift - 2*one_minute:first_lift + 2*one_minute);
four = length(first_lift_signal);

figure
a = subplot(2,1,1);
    plot(ds_sec_signal(1:four), first_lift_signal)
    title('dF/F');

%% New polyfit 1
 
fs_signal = 1:1:length(signal_465);
sec_signal = fs_signal/signal_fs;


% Normalize and plot - m1
sec_signal_1_cov=sec_signal';
signal_405_1_cov=signal_405';
signal_465_1_cov=signal_465';

% Create a double exponential model
%model = fittype('a*exp(b*x) + c*exp(d*x)', 'independent', 'x', 'dependent', 'y');

% Fit the data to the double exponential model
%[aa,bb] = fit(sec_signal_1_cov, signal_405_1_cov, model);
[aa, bb] = fit(sec_signal_1_cov, signal_405_1_cov, 'exp2');
% figure();
% plot(sec_signal_1_cov,signal_405_1_cov);
% hold on;
% plot(sec_signal_1_cov,a(sec_signal_1_cov));
% hold off
reg = robustfit(aa(sec_signal_1_cov), signal_465_1_cov, 'bisquare');
lin_reg = aa(sec_signal_1_cov) * reg(2) + reg(1);
% figure();
% plot(sec_signal_1_cov,lin_reg)
MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder,1)/MeanFilterOrder;
lin_reg =  filtfilt(MeanFilter,1,double(lin_reg));
delta_465 = 100 * (signal_465_1_cov - lin_reg) ./ lin_reg;
% figure();
% plot(sec_signal_1_cov,delta_465);
delta465_filt = filtfilt(MeanFilter,1,double(delta_465));
ds_factor_FP = 100;
ds_delta_465=downsample(delta465_filt,ds_factor_FP);
ds_sec_signal_1=downsample(sec_signal_1_cov,ds_factor_FP);
figure
a = subplot(4,1,1);
    plot(sec_signal(1000:end), signal_405(1000:end));
    title('raw control');
b = subplot(4,1,2);
    plot(sec_signal(1000:end), signal_465(1000:end));
    title('raw signal');
c = subplot(4,1,3);
    plot(sec_signal(1000:end), signal_465(1000:end));
    hold on
    plot(sec_signal(1000:end), lin_reg(1000:end));
    title('fitted control');
d = subplot(4,1,4);
    plot(sec_signal(1000:end), delta_465(1000:end));
    title('normalized signal');
linkaxes([a,b,c,d],'x');

ds_time_minutes = ds_sec_signal_1 / 60; % Convert seconds to minutes for plotting

% Plot filtered trace (the index 1000:end removes the first second of the recording for nicer plotting)
figure
plot(ds_time_minutes, ds_delta_465);
title('dF/F');

% Adjusting the plot to match previous figure settings
xlabel('Time (min)');
ylabel('dF/F (z score)');

% Set x-axis limits
xlim([15, 2880]);
%ylim([-30, 15]);
%xlim([-5,800])

% Set x-axis ticks for 10-minute increments
xticks(0:60:2880);

% Ensure data fits within the plot
ylim([min(ds_delta_465), max(ds_delta_465)]);
    


%% New polyfit 
 
fs_signal2 = 1:1:length(signal_465_2);
sec_signal = fs_signal2/signal_fs2;


% Normalize and plot - m1
sec_signal_1_cov=sec_signal';
signal_405_1_cov=signal_405_2';
signal_465_1_cov=signal_465_2';

% Create a double exponential model
%model = fittype('a*exp(b*x) + c*exp(d*x)', 'independent', 'x', 'dependent', 'y');

% Fit the data to the double exponential model
%[aa,bb] = fit(sec_signal_1_cov, signal_405_1_cov, model);
[aa, bb] = fit(sec_signal_1_cov, signal_405_1_cov, 'exp2');
% figure();
% plot(sec_signal_1_cov,signal_405_1_cov);
% hold on;
% plot(sec_signal_1_cov,a(sec_signal_1_cov));
% hold off
reg = robustfit(aa(sec_signal_1_cov), signal_465_1_cov, 'bisquare');
lin_reg = aa(sec_signal_1_cov) * reg(2) + reg(1);
% figure();
% plot(sec_signal_1_cov,lin_reg)
MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder,1)/MeanFilterOrder;
lin_reg =  filtfilt(MeanFilter,1,double(lin_reg));
delta_465 = 100 * (signal_465_1_cov - lin_reg) ./ lin_reg;
% figure();
% plot(sec_signal_1_cov,delta_465);
delta465_filt = filtfilt(MeanFilter,1,double(delta_465));
ds_factor_FP = 100;
ds_delta_465=downsample(delta465_filt,ds_factor_FP);
ds_sec_signal_1=downsample(sec_signal_1_cov,ds_factor_FP);
figure
a = subplot(4,1,1);
    plot(sec_signal(1000:end), signal_405_2(1000:end));
    title('raw control');
b = subplot(4,1,2);
    plot(sec_signal(1000:end), signal_465_2(1000:end));
    title('raw signal');
c = subplot(4,1,3);
    plot(sec_signal(1000:end), signal_465_2(1000:end));
    hold on
    plot(sec_signal(1000:end), lin_reg(1000:end));
    title('fitted control');
d = subplot(4,1,4);
    plot(sec_signal(1000:end), delta_465(1000:end));
    title('normalized signal');
linkaxes([a,b,c,d],'x');

ds_time_minutes = ds_sec_signal_1 / 60; % Convert seconds to minutes for plotting

% Plot filtered trace (the index 1000:end removes the first second of the recording for nicer plotting)
figure
plot(ds_time_minutes, ds_delta_465);
title('dF/F');

% Adjusting the plot to match previous figure settings
xlabel('Time (min)');
ylabel('dF/F (z score)');

% Set x-axis limits
xlim([15, 2880]);
%ylim([-30, 15]);
%xlim([-5,800])
ylim([-15,40]);
% Set x-axis ticks for 10-minute increments
xticks(0:60:2880);

% Ensure data fits within the plot
ylim([min(ds_delta_465), max(ds_delta_465)]);

%% Save

save('48H_sal_female_COM18_signal.mat', 'ds_delta465_filt');
save('5H_GLU_FP1_signal_405', 'signal_405');
save('BL_fitting_COM12_sal_signal_6h.mat', 'ds_delta465_filt');
save('RZ10-1c_mouse2.mat', 'mouse2');
save('NEW_Intercept_polyfit_48H_sal_COM9_signal.mat', 'ds_delta_465');
save('RZ10-1c_ds_delta465_filt2.mat', 'ds_delta465_filt2');
save('RZ10-1a_ds_time_minutes.mat', 'ds_time_minutes');
save('newpoly_48H_sal_COM13_signal.mat', 'ds_delta_465');


%%


% Define parameters
MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder, 1) / MeanFilterOrder;

% Example data (replace with your actual data)
split_index = floor(length(signal_465) / 2); % Index to split data

% Create time vectors (if needed)
fs_signal = 1:1:length(signal_465);
sec_signal = fs_signal / signal_fs;

% Split the signals into two parts
signal_405_1 = signal_405(1:split_index);
signal_465_1 = signal_465(1:split_index);
signal_405_2 = signal_405(split_index+1:end);
signal_465_2 = signal_465(split_index+1:end);

% Fit a polynomial of degree 2 (quadratic fit) for each part
reg1 = polyfit(signal_405_1, signal_465_1, 2);
fitted_signal_465_1 = polyval(reg1, signal_405_1);

reg2 = polyfit(signal_405_2, signal_465_2, 2);
fitted_signal_465_2 = polyval(reg2, signal_405_2);

% Combine the fitted signals
fitted_signal_465 = [fitted_signal_465_1, fitted_signal_465_2];

% Apply the mean filter using filtfilt for zero-phase filtering
fitted_signal_465_filtered = filtfilt(MeanFilter, 1, double(fitted_signal_465));

% Normalize the data
normDat = (signal_465 - fitted_signal_465_filtered) ./ fitted_signal_465_filtered;
delta_465 = normDat * 100;

% Plot results
figure;
subplot(5, 1, 1);
plot(signal_405, 'DisplayName', 'Control Signal (405 nm)');
title('Control Signal (405 nm)');
legend;

subplot(5, 1, 2);
plot(signal_465, 'DisplayName', 'Actual Signal (465 nm)');
title('Actual Signal (465 nm)');
legend;

subplot(5, 1, 3);
plot(fitted_signal_465, 'DisplayName', 'Fitted Control Signal');
title('Fitted Control Signal');
legend;

subplot(5, 1, 4);
plot(fitted_signal_465_filtered, 'DisplayName', 'Fitted Control Signal (Filtered)');
title('Fitted Control Signal (Filtered)');
legend;

subplot(5, 1, 5);
plot(delta_465, 'DisplayName', 'Normalized Signal (ΔF/F%)');
title('Normalized Signal (ΔF/F%)');
legend;


%% EXP1

% Define parameters
MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder, 1) / MeanFilterOrder;
ds_factor_FP = 100; % Downsampling factor


% Create time vectors
fs_signal2 = 1:1:length(signal_465);
sec_signal = fs_signal2 / signal_fs;

% Normalize and plot
sec_signal_1_cov = sec_signal';
signal_405_1_cov = signal_405';
signal_465_1_cov = signal_465';

% Create a simple exponential decay model
%exp_model = fittype('a*exp(b*x) + c', 'independent', 'x', 'dependent', 'y');

% % Provide initial guesses and bounds for the parameters
% opts = fitoptions('Method', 'NonlinearLeastSquares', ...
%     'StartPoint', [max(signal_405), -1, min(signal_405)], ...
%     'Lower', [0, -Inf, -Inf], ...
%     'Upper', [Inf, 0, Inf]);

% Fit the data to the simple exponential decay model
[aa, bb] = fit(sec_signal_1_cov, signal_405_1_cov, 'exp1');

% Robust fit using the fitted exponential model
reg = robustfit(aa(sec_signal_1_cov), signal_465_1_cov, 'bisquare');
lin_reg = aa(sec_signal_1_cov) * reg(2) + reg(1);

% Apply the mean filter to the linear regression fit
lin_reg = filtfilt(MeanFilter, 1, double(lin_reg));

% Normalize the filtered actual signal using the fitted control signal
delta_465 = 100 * (signal_465_1_cov - lin_reg) ./ lin_reg;

% Apply the mean filter to the normalized signal
delta465_filt = filtfilt(MeanFilter, 1, double(delta_465));

% Downsample the filtered normalized signal for plotting
ds_delta_465 = downsample(delta465_filt, ds_factor_FP);
ds_sec_signal_1 = downsample(sec_signal_1_cov, ds_factor_FP);

% Plot raw control and signal, fitted control, and normalized signal
figure
a = subplot(4, 1, 1);
plot(sec_signal(1000:end), signal_405(1000:end));
title('Raw Control Signal (405 nm)');
b = subplot(4, 1, 2);
plot(sec_signal(1000:end), signal_465(1000:end));
title('Raw Signal (465 nm)');
c = subplot(4, 1, 3);
plot(sec_signal(1000:end), signal_465(1000:end));
hold on
plot(sec_signal(1000:end), lin_reg(1000:end));
title('Fitted Control Signal');
d = subplot(4, 1, 4);
plot(sec_signal(1000:end), delta_465(1000:end));
title('Normalized Signal (ΔF/F%)');
linkaxes([a, b, c, d], 'x');

% Convert seconds to minutes for plotting
ds_time_minutes = ds_sec_signal_1 / 60;

% Plot filtered trace
figure
plot(ds_time_minutes, ds_delta_465);
title('dF/F');
xlabel('Time (min)');
ylabel('dF/F (%)');
xlim([min(ds_time_minutes), max(ds_time_minutes)]);
ylim([-15, 40]);
xticks(0:60:max(ds_time_minutes));

% Ensure data fits within the plot
ylim([min(ds_delta_465), max(ds_delta_465)]);

%% change intercept of control signal

% Define parameters
MeanFilterOrder = 1000; % for smoothing
MeanFilter = ones(MeanFilterOrder, 1) / MeanFilterOrder;
ds_factor_FP = 100; % Downsampling factor

% Create time vectors
fs_signal2 = 1:1:length(signal_465_2);
sec_signal = fs_signal2 / signal_fs2;

% Normalize and plot
sec_signal_1_cov = sec_signal';
signal_405_1_cov = signal_405_2';
signal_465_1_cov = signal_465_2';

% Cut off initial noise
sec_signal_1_cov = sec_signal_1_cov;
signal_405_1_cov = signal_405_1_cov;
signal_465_1_cov = signal_465_1_cov;

% Fit the data to the double exponential model ('exp2')
[aa, bb] = fit(sec_signal_1_cov, signal_405_1_cov, 'exp2');

% Evaluate the fitted control signal
fitted_control_signal = aa(sec_signal_1_cov);

% Calculate the intercept difference between the actual signal and the fitted control signal
intercept_diff = signal_465_1_cov(1) - fitted_control_signal(1);

% Shift the fitted control signal by the intercept difference
aligned_fitted_control_signal = fitted_control_signal + intercept_diff;

% Apply the mean filter to the actual signal
signal_465_filtered = filtfilt(MeanFilter, 1, double(signal_465_1_cov));

% Normalize the filtered actual signal using the aligned fitted control signal
delta_465 = 100 * (signal_465_filtered - aligned_fitted_control_signal) ./ aligned_fitted_control_signal;

% Check for Inf or NaN values in delta_465 and replace them with finite values
delta_465(~isfinite(delta_465)) = nanmean(delta_465);

% Apply the mean filter to the normalized signal
delta465_filt = filtfilt(MeanFilter, 1, double(delta_465));

% Downsample the filtered normalized signal for plotting
ds_delta_465 = downsample(delta465_filt, ds_factor_FP);
ds_sec_signal_1 = downsample(sec_signal_1_cov, ds_factor_FP);

% Plot raw control and signal, fitted control, and normalized signal
figure
a = subplot(4, 1, 1);
plot(sec_signal(1000:end), signal_405_2(1000:end));
title('Raw Control Signal (405 nm)');
b = subplot(4, 1, 2);
plot(sec_signal(1000:end), signal_465_2(1000:end));
title('Raw Signal (465 nm)');
c = subplot(4, 1, 3);
plot(sec_signal(1000:end), signal_465_2(1000:end));
hold on
plot(sec_signal(1000:end), aligned_fitted_control_signal(1000:end));
title('Fitted Control Signal');
d = subplot(4, 1, 4);
plot(sec_signal(1000:end), delta_465(1000:end));
title('Normalized Signal (ΔF/F%)');
linkaxes([a, b, c, d], 'x');

% Convert seconds to minutes for plotting
ds_time_minutes = ds_sec_signal_1 / 60;

% Plot filtered trace
figure
plot(ds_time_minutes, ds_delta_465);
title('dF/F');
xlabel('Time (min)');
ylabel('dF/F (%)');
xlim([min(ds_time_minutes), max(ds_time_minutes)]);
ylim([-15, 40]);
xticks(0:60:max(ds_time_minutes));

% Ensure data fits within the plot
ylim([min(ds_delta_465), max(ds_delta_465)]);
