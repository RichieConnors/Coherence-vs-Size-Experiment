%% Creates all relevant output information

%% Directory to save each participant in a separate folder
saveDir = sprintf('Output Files/Participant_ID_%s', participant_ID);
if ~exist(saveDir, 'dir') 
    mkdir(saveDir);  % Creates folder if new participant number
else
    fprintf(2,"\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" + ...
        "Data not saved! " + ...
        "\nCheck participant ID was correct and not reused.\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    return;
end

%% Cutoff values and transformations for data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ogResponseTimes = responseTimeStore;
writematrix(ogResponseTimes, fullfile(saveDir, sprintf('OriginalRTs_ID_%s.txt', participant_ID)));
% Stores Elapsed Time
writematrix(round(MotorRT, 4), fullfile(saveDir, sprintf('MotorRT_ID_%s.txt', participant_ID)));
responseTimeStore(:) = responseTimeStore(:) - MotorRT;
RT_Cutoff = .2; % Cutoff for lower bound of RT in ms
for i = 1:size(responseTimeStore)
    if responseTimeStore(i) <= RT_Cutoff 
        responseTimeStore(i) = NaN;
    end
end

% Log RT
logresponseTimeStore = log(responseTimeStore);

% Convert target to size in deg (diameter)
targetinDeg = round((RDK_Radius_Array .* 2 / ppd), 1); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Store participant information

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

participant_Information = {participant_ID, participant_Name, participant_Age, participant_Sex}; % Stores all participant info in array
p = cell2table(participant_Information); % Converts the cell array of pariticpant information into table 
p.Properties.VariableNames(1:size(participant_Information, 2)) = {'ID', 'Name', 'Age', 'Sex'}; % Give the correct names in the table
writetable(p, fullfile(saveDir, sprintf('ParticipantInformation_ID_%s.csv', participant_ID))); % Save table to output files called ParticipantInformation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Store all trial parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters = [{coherencePercentageArray}, noDots, dotSize, {RDK_Radius_Sizes}, {RDK_Radius_Sizes_Deg}, ...
        dotColour(1), background_Colour(1), dotVelocity, frameRate]; % All parameters to be saved
m = array2table(parameters);
m.Properties.VariableNames(1:size(parameters, 2)) = {'Coherence Levels', 'Num Dots', 'Dot Size', ... 
    'RDK Radius', 'RDK Radius (°)', 'Dot Colour', 'Background Colour', 'Dot Velocity', 'Frame Rate (hz)'}; % This is the names given to the variables stored
writetable(m, fullfile(saveDir, sprintf('TrialParameters_ID_%s.csv', participant_ID)));

% Creates an array based on main responses and stores into a txt file
dataArray = [motionDirectionStore, keyResponseStore, num2cell(accuracy), num2cell(coherenceStore), num2cell(RDK_Radius_Array), num2cell(targetinDeg), num2cell(responseTimeStore)];
finishedTable = array2table(dataArray); % All data vars to be saved
finishedTable.Properties.VariableNames(1:size(dataArray, 2)) = {'Motion Direction', 'Key Response', 'Accuracy', 'Coherence Amount', ...
    'Size of Radius (px)', 'Size of Target (°)', 'Response Time'};
writetable(finishedTable, fullfile(saveDir, sprintf('Output_ExpandingCircles_ID_%s.txt', participant_ID)));

% Stores size, coherence, location, and response time data into a csv file
% (this is essentially a file with just all raw data thrown into it)
writematrix([RDK_Radius_Array, coherenceStore, Location_Array, responseTimeStore], fullfile(saveDir, sprintf('RDK_Radius&Coherence_Array_ID_%s.csv', participant_ID)));

% Stores Elapsed Time
writematrix(round(elapsedTime, 2), fullfile(saveDir, sprintf('ElapsedTime_ID_%s.txt', participant_ID)));

% Combines both the accuracy, coherence level, and size into a matrix
thresholdTable = table(coherenceStore, RDK_Radius_Array, targetinDeg, accuracy, responseTimeStore, logresponseTimeStore, 'VariableNames', ...
    {'Coherence', 'Size (r in px)', 'Size (°)', 'Accuracy', 'ResponseTime', 'LogRT'});

% Compute the average response time for each unique combination of Coherence and Size
summaryTable = groupsummary(thresholdTable, {'Coherence', 'Size (r in px)', 'Size (°)'}, {'mean'}, {'ResponseTime', 'LogRT', 'Accuracy'});

% Rename variables for clarity
summaryTable = renamevars(summaryTable, ["mean_ResponseTime", "mean_LogRT", "mean_Accuracy"], ...
    ["MeanResponseTime", "MeanLogRT", "AccuracyRatio"]);

% Group the data by Coherence and calculate the mean ResponseTime for each Coherence level
% 'grpstats' automatically computes the mean for each group
groupedDataCoherence = grpstats(thresholdTable, 'Coherence', {'mean'}, 'DataVars', {'ResponseTime', 'LogRT', 'Accuracy'});

groupedDataSize = grpstats(thresholdTable, {'Size (r in px)', 'Size (°)'}, {'mean'}, 'DataVars', {'ResponseTime', 'LogRT', 'Accuracy'});

% Clean up (NOT SURE IF NEEDED)
Screen('CloseAll');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Plotting

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set figure width and height
fig_width = width * .5;
fig_height = height * .5;

% Combined plot for both coherence and size
CoherenceSize_PsychFunc = figure;
CoherenceSize_PsychFunc.Position = [100 100 fig_width fig_height];
thresholdLine = .75; % Draws line at defined reliable accuracy (62.5% for 4afc, using 75% as only 10 repetitions)

line_ColoursS = lines(levelsS); % Gives different colours for amount of levels
line_ColoursC = lines(levelsC); % Gives different colours for amount of levels
markers = {'o', 's', '^', 'd', 'v', 'p', 'h'}; % A bunch of markers for lines to choose from

% Subplot 1 for coherence
subplot(2,1,1); % Create a 2-row, 1-column grid and use the first plot
hold on;
for i = 1:levelsS
    % Filter rows for the current size
    currentSize = Target_Degree_Sizes(i);
    sizeData = summaryTable(summaryTable.("Size (°)") == currentSize, :); % Current total target size in degrees

    % Choose marker for the current size (cycling through the marker list)
    marker = markers{mod(i-1, length(markers)) + 1}; 
    
    % Plot accuracy ratio for the current size at each coherence level
    plot(sizeData.Coherence, sizeData.AccuracyRatio, '-o', 'LineWidth', 2, 'MarkerSize', 6, ...
        'Marker', marker, 'DisplayName', sprintf('Size %.1f °', currentSize), 'Color', line_ColoursS(i, :));
end
yline(thresholdLine, 'r--', 'LineWidth', 1);
xlabel('Coherence');
ylabel('Accuracy Ratio');
xlim([min(coherencePercentageArray), max(coherencePercentageArray)]);
if length(coherencePercentageArray) == 1
    xlim([0 , 1]);
end
ylim([RT_Cutoff, 1]);
title('Accuracy Ratio vs Coherence');
legend('Location', 'eastoutside');
grid on;
hold off;

% Subplot 2 for RDK Target size
subplot(2,1,2); % Create the second plot in the same figure
hold on;
for i = 1:levelsC
    % Filter rows for the current size
    currentCoherence = coherencePercentageArray(i);
    coherenceData = summaryTable(summaryTable.Coherence == currentCoherence, :);

    % Choose marker for the current size (cycling through the marker list)
    marker = markers{mod(i-1, length(markers)) + 1}; 
    
    % Plot accuracy ratio for the current size at each coherence level
    plot(coherenceData.("Size (°)"), coherenceData.AccuracyRatio, '-o', 'LineWidth', 2, 'MarkerSize', 6, ...
        'Marker', marker, 'DisplayName', sprintf('Coherence %d%%', round(currentCoherence * 100)), 'Color', line_ColoursC(i, :));
end
yline(thresholdLine, 'r--', 'LineWidth', 1);
xlabel('RDK Diameter Size (°)');
ylabel('Accuracy Ratio');
xlim([min(targetinDeg), max(targetinDeg)]);
if length(targetinDeg) == 1
    xlim(Target_Degree_Sizes);
end
ylim([RT_Cutoff, 1]);
title('Accuracy Ratio vs RDK Diameter Size');
legend('Location', 'eastoutside');
grid on;
hold off;

%% Plot mean response time over group size and coherence

RTCombinedFig = figure;
RTCombinedFig.Position = [100 100 fig_width fig_height];
hold on;

% Plot 1: Average Response Time vs Coherence Level
subplot(1, 2, 1); % 1 row, 2 columns, first plot
plot(groupedDataCoherence.Coherence, groupedDataCoherence.mean_ResponseTime, '-o', 'LineWidth', 2, 'Color', 'b');
xlabel('Coherence Levels');
ylabel('Response Time (s)');
xlim([min(coherencePercentageArray), max(coherencePercentageArray)]);
ylim([RT_Cutoff, maxTime]);
title('Response Time vs Coherence Level');

% Plot 2: Average Response Time vs Size of Target
subplot(1, 2, 2); % 1 row, 2 columns, second plot
plot(groupedDataSize.("Size (°)"), groupedDataSize.mean_ResponseTime, '-o', 'LineWidth', 2, 'Color', 'r');
xlabel('Target Size (°)');
ylabel('Response Time (s)');
xlim([min(targetinDeg), max(targetinDeg)]);
ylim([RT_Cutoff, maxTime]);
title('Response Time vs Size of Target');
hold off;

%% Plot mean response time over group size and coherence separate lines

RTCombinedFig = figure;
RTCombinedFig.Position = [100 100 fig_width fig_height];
hold on;

% Plot 1: Average Response Time vs Coherence Level
subplot(1, 2, 1); % 1 row, 2 columns, first plot
hold on;
for i = 1:levelsS
    % Filter rows for the current size
    currentSize = Target_Degree_Sizes(i);
    sizeData = summaryTable(summaryTable.("Size (°)") == currentSize, :);

    % Choose marker for the current size (cycling through the marker list)
    marker = markers{mod(i-1, length(markers)) + 1}; 
    
    % Plot mean response time for the current size at each coherence level
    plot(sizeData.Coherence, sizeData.MeanResponseTime, '-o', 'LineWidth', 2, 'MarkerSize', 6, ...
        'Marker', marker, 'DisplayName', sprintf('Size %.1f °', currentSize), 'Color', line_ColoursS(i, :));
end
xlabel('Coherence Levels');
ylabel('Response Time (s)');
xlim([min(coherencePercentageArray), max(coherencePercentageArray)]);
ylim([RT_Cutoff, maxTime]);
legend('Location', 'northeast', 'FontSize', 6);
title('Response Time vs Coherence Level');
hold off;

% Plot 2: Average Response Time vs Size of Target
subplot(1, 2, 2); % 1 row, 2 columns, second plot
hold on;
for i = 1:levelsC
    % Filter rows for the current size
    currentCoherence = coherencePercentageArray(i);
    coherenceData = summaryTable(summaryTable.Coherence == currentCoherence, :);

    % Choose marker for the current size (cycling through the marker list)
    marker = markers{mod(i-1, length(markers)) + 1}; 
    
    % Plot mean response time for the current coherence at each size level
    plot(coherenceData.("Size (°)"), coherenceData.MeanResponseTime, '-o', 'LineWidth', 2, 'MarkerSize', 6, ...
        'Marker', marker, 'DisplayName', sprintf('Coherence %d%% ', round(currentCoherence * 100)), 'Color', line_ColoursC(i, :));
end
xlabel('Target Size (°)');
ylabel('Response Time (s)');
xlim([min(targetinDeg), max(targetinDeg)]);
ylim([RT_Cutoff, maxTime]);
legend('Location', 'northeast', 'FontSize', 6);
title('Response Time vs Size of Target');
hold off;

%% Plot mean log response time over group size and coherence

LogRTCombinedFig = figure;
LogRTCombinedFig.Position = [100 100 fig_width fig_height];
hold on;

% Plot 1: Average Response Time vs Coherence Level
subplot(1, 2, 1); % 1 row, 2 columns, first plot
plot(groupedDataCoherence.Coherence, groupedDataCoherence.mean_LogRT, '-o', 'LineWidth', 2, 'Color', 'b');
xlabel('Coherence Levels');
ylabel('Log Response Time (s)');
xlim([min(coherencePercentageArray), max(coherencePercentageArray)]);
ylim([min(logresponseTimeStore), log(maxTime)]);
title('Log Response Time vs Coherence Level');

% Plot 2: Average Response Time vs Size of Target
subplot(1, 2, 2); % 1 row, 2 columns, second plot
plot(groupedDataSize.("Size (°)"), groupedDataSize.mean_LogRT, '-o', 'LineWidth', 2, 'Color', 'r');
xlabel('Target Size (°)');
ylabel('Log Response Time (s)');
xlim([min(targetinDeg), max(targetinDeg)]);
ylim([min(logresponseTimeStore), log(maxTime)]);
title('Log Response Time vs Size of Target');
hold off;

%% Plot a heatmap comparing each block of coherence and size (shows trend of impact between coherence and size increase)

% Heatmap of trend with accuracy ratio

% Ensure data is in matrix form for surface plot
[xqRT, yqRT] = meshgrid(unique(summaryTable.("Size (°)")), unique(summaryTable.Coherence)); % Creates a matched grid for size and coherence

% Fit mean response times for each combination into the grid (transposed to
% fit the coherence and size response times correctly)
zqRT = reshape(summaryTable.MeanResponseTime, length(unique(summaryTable.("Size (°)"))), [])'; % Length of size so x and y are correct

hold on;
heatmapSvC = figure;
heatmapSvC.Position = [100 100 fig_width fig_height];
imagesc(xqRT(1, :), flipud(yqRT(:, 1)), flipud(zqRT)); % Plots a heatmap which also flips y and z axis to put low coherence at bottom
set(gca, 'YDir', 'normal'); % Ensure flipped y-axis appears in the correct order
xlabel('Target Size (°)');
ylabel('Coherence (%)');
title('Target Size vs Coherence - Mean Response Time');
clim([0, maxTime]); % Sets the colour limit to maxTime
colorbar;
hold off;

% Heatmap of trend with accuracy ratio

% Ensure data is in matrix form for surface plot
[xqAR, yqAR] = meshgrid(unique(summaryTable.("Size (°)")), unique(summaryTable.Coherence)); % Creates a matched grid for size and coherence

% Fit mean response times for each combination into the grid (transposed to
% fit the coherence and size response times correctly)
zqAR = reshape(summaryTable.AccuracyRatio, length(unique(summaryTable.("Size (°)"))), [])'; % Length of size so x and y are correct

hold on;
heatmapSvC = figure;
heatmapSvC.Position = [100 100 fig_width fig_height];
imagesc(xqAR(1, :), flipud(yqAR(:, 1)), flipud(zqAR)); % Plots a heatmap which also flips y and z axis to put low coherence at bottom
set(gca, 'YDir', 'normal'); % Ensure flipped y-axis appears in the correct order
xlabel('Target Size (°)');
ylabel('Coherence (%)');
title('Target Size vs Coherence - Accuracy Ratio');
clim([0, 1]); % Sets the colour limit to maxTime
colorbar;
hold off;

%% Plot the target positions
DRP = figure;
DRP.Position = [100 100 fig_width fig_height];
axis equal; % Ensure aspect ratio is preserved
title('Target Plot'); % Title

% Labels
xlabel('X Axis');
ylabel('Y Axis');

% Draws fixation point
rectangle('Position',[(xCenter-5) (yCenter-5) (5*2) (5*2)],'Curvature',[1,1], 'FaceColor', 'black', 'EdgeColor', 'black');

% Initialize axis limits
xlim([width-width, width]);
ylim([height-height, height]);

hold on;

for i = 1:size(RDK_Radius_Array)
    minRT = min(responseTimeStore);
    maxRT = max(responseTimeStore);
    radius_cMap = (responseTimeStore(i) - minRT) / (maxRT - minRT);
    radius_cMap = max(0, min(1, radius_cMap)); % Clamp between 0 and 1
    radius_Colour = [radius_cMap, 1 - radius_cMap, 0];
    circle2(Location_Array(i, 1), Location_Array(i, 2), RDK_Radius_Array(i), radius_Colour);
end

set(gca, 'YDir','reverse'); % Set y axis reverse (needed to match screen spawning to plot)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Save plots
saveas(heatmapSvC, fullfile(saveDir, sprintf('HeatMapCvsS_ID_%s.jpg', participant_ID)));
saveas(DRP, fullfile(saveDir, sprintf('TargetLocationsPlot_ID_%s.jpg', participant_ID)));
saveas(RTCombinedFig, fullfile(saveDir, sprintf('RTPlotSeparated_ID_%s.jpg', participant_ID)));
saveas(LogRTCombinedFig, fullfile(saveDir, sprintf('LogRTPlotSeparated_ID_%s.jpg', participant_ID)));
saveas(CoherenceSize_PsychFunc, fullfile(saveDir, sprintf('CoherencevsSizePsychFunc_ID_%s.jpg', participant_ID)));
%%