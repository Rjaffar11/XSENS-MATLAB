clc; clear all; close all;

filelist = {'March 6 2025-012_P005.xlsx','March 6 2025-013_P005.xlsx','March 6 2025-014_P005.xlsx','March 6 2025-015_P005.xlsx','March 6 2025-016_P005.xlsx'}; 


fs = 60; g = 9.81;

nFiles = length(filelist);
figure('Name', 'Head Kinematics by File', 'Color', 'w', ...
       'Units','normalized', 'Position', [0.05 0.05 0.9 0.9]);

for fileIdx = 1:nFiles
    filename = filelist{fileIdx};
    disp(['Processing: ' filename]);

    % Load Data 
    tbl_acc = readtable(filename, 'Sheet', 'Segment Acceleration');
    tbl_pos = readtable(filename, 'Sheet', 'Segment Position');

    %  Extract Data 
    ax = tbl_acc.HeadX;
    ay = tbl_acc.HeadY;
    az = tbl_acc.HeadZ;
    a_mag = sqrt(ax.^2 + ay.^2 + az.^2) / g;

    z = tbl_pos.HeadZ;
    t = (0:length(z)-1)' / fs;
    score = a_mag ./ (z - min(z) + 0.01);  % Continuous score

    % Top Subplot: Z-position + a_mag 
    subplot(nFiles, 2, (fileIdx-1)*2 + 1);
    yyaxis left;
    plot(t, z, 'b-', 'LineWidth', 1.2);
    ylabel('Z Pos (m)');
    ylim([0, 2]);

    yyaxis right;
    plot(t, a_mag, 'k-', 'LineWidth', 1.2);
    ylabel('a_{mag} (g)');
    ylim([0, 10]);

%ALGORITHM 1
    z_floor = 0.6;         % Head below x cm
    acc_thresh = 5;         % Acceleration above x g
    
    %  Detect candidate impact frames
    impact_frames = find(z < z_floor & a_mag > acc_thresh);
    
    %Plot on acceleration axis (right y-axis)
    hold on;
    scatter(t(impact_frames), a_mag(impact_frames), 50, 'r', 'filled');
    title(['[' num2str(fileIdx) '] ' filename], 'Interpreter','none');
    grid on;

% Algorithm 2
    % Bottom Subplot: Score 
    subplot(nFiles, 2, (fileIdx-1)*2 + 2);
    plot(t, score, 'm-', 'LineWidth', 1.2);
    ylabel('Score');   
    xlabel('Time (s)');
    title('a_{mag} / (z - min(z) + 0.01)');
    grid on;

    [max_score, max_idx] = max(score);
    hold on;
    scatter(t(max_idx), max_score, 60, 'k', 'filled');  % black dot
    text(t(max_idx), max_score, sprintf('  %.2f', max_score), ...
     'VerticalAlignment','bottom', 'Color','k', 'FontSize', 8);
end
