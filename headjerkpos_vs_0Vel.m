clc; clear all; close all;


folderPath = 'Session 5 -005';
fileStruct = dir(fullfile(folderPath, '*.xlsx'));
filelist = fullfile(folderPath, {fileStruct.name});

fs = 60; g = 9.81;
filesPerFigure = 5;  % 5 files × 3 subplots = 15 subplots per figure
nFiles = length(filelist);
nFigures = ceil(nFiles / filesPerFigure);

% LOOP 
for figIdx = 1:nFigures
    figure('Name', ['Head Kinematics: Figure ' num2str(figIdx)], ...
           'Color', 'w', ...
           'Units', 'normalized', ...
           'Position', [0.05 0.05 0.9 0.9]);

    for subplotIdx = 1:filesPerFigure
        fileIdx = (figIdx - 1) * filesPerFigure + subplotIdx;
        if fileIdx > nFiles
            break;
        end

        filename = filelist{fileIdx};
        disp(['Processing: ' filename]);

% Load
        tbl_acc = readtable(filename, 'Sheet', 'Segment Acceleration');
        tbl_pos = readtable(filename, 'Sheet', 'Segment Position');
        tbl_vel = readtable(filename, 'Sheet', 'Segment Velocity');
        tbl_rot = readtable(filename, 'Sheet', 'Segment Angular Acceleration');  % deg/s²

        t = (0:height(tbl_pos)-1)' / fs;
        z = tbl_pos.HeadZ;

% Linear acceleration magnitude (g) 
        ax = tbl_acc.HeadX;
        ay = tbl_acc.HeadY;
        az = tbl_acc.HeadZ;
        a_mag = sqrt(ax.^2 + ay.^2 + az.^2) / g;

 %  Vertical velocity 
        velz = tbl_vel.HeadZ;

 %  Angular acceleration magnitude (rad/s²) 
        wx = tbl_rot.HeadX * pi / 180;
        wy = tbl_rot.HeadY * pi / 180;
        wz = tbl_rot.HeadZ * pi / 180;
        w_mag = sqrt(wx.^2 + wy.^2 + wz.^2);

  % Algorithm 2 score 
        [~, peak_acc_idx] = max(a_mag);
        window_radius = round(0.25 * fs);
        start_idx = max(1, peak_acc_idx - window_radius);
        end_idx = min(length(z), peak_acc_idx + window_radius);
        velz_window = velz(start_idx:end_idx);
        [~, vz0_rel_idx] = min(abs(velz_window));
        vz0_idx = start_idx + vz0_rel_idx - 1;

   % Algorithm 2: Find z_min near peak acceleration
        z_window = z(start_idx:end_idx);
        [min_z_in_window, min_z_rel_idx] = min(z_window);
        z_min_global_idx = start_idx + min_z_rel_idx - 1;
        z_vel0_dynamic = z(vz0_idx);
        score = a_mag .* (max(z) - z);
        [max_score, max_idx] = max(score);

   % SUBPLOT 1: Z-pos + a_mag 
        subplot(filesPerFigure, 3, (subplotIdx-1)*3 + 1);
        yyaxis left;
        plot(t, z, 'b-', 'LineWidth', 1.2);
        ylabel('Z Pos (m)');
        ylim([0, 2]);

        yyaxis right;
        plot(t, a_mag, 'k-', 'LineWidth', 1.2);
        ylabel('a_{mag} (g)');
        ylim([0, 20]);

    % Threshold-based impact detection
        z_floor = 0.6; acc_thresh = 8;
        impact_frames = find(z < z_floor & a_mag > acc_thresh);
        hold on;
        scatter(t(impact_frames), a_mag(impact_frames), 50, 'r', 'filled');
        scatter(t(vz0_idx), z(vz0_idx), 50, 'c', 'filled');
        text(t(vz0_idx), z(vz0_idx), '  v_z=0', 'Color', 'c', 'FontSize', 8, 'VerticalAlignment', 'top');

        title(['[' num2str(fileIdx) '] ' fileStruct(fileIdx).name], 'Interpreter', 'none');
        grid on;

   % Plot z_min if it's close to peak acceleration
        if abs(z_min_global_idx - peak_acc_idx) <= round(0.25 * fs)
            yyaxis left;
            scatter(t(z_min_global_idx), z(z_min_global_idx), 50, 'b', 'filled');
            text(t(z_min_global_idx), z(z_min_global_idx), '  z_{min}', ...
                 'Color', 'b', 'FontSize', 8, 'VerticalAlignment', 'top');
        end
       

   %SUBPLOT 2: Algorithm 2 score
        subplot(filesPerFigure, 3, (subplotIdx-1)*3 + 2);
        plot(t, score, 'm-', 'LineWidth', 1.2);
        ylabel('Score');
        xlabel('Time (s)');
        title('a_{mag} x (max(z) - z)');
        ylim([0, 25]); 
        grid on;
        hold on;
        scatter(t(max_idx), max_score, 60, 'k', 'filled');
        text(t(max_idx), max_score, sprintf('  %.2f', max_score), ...
             'VerticalAlignment', 'bottom', 'Color', 'k', 'FontSize', 8);

  % SUBPLOT 3: Angular acceleration magnitude
        subplot(filesPerFigure, 3, (subplotIdx-1)*3 + 3);
        plot(t, w_mag, 'g-', 'LineWidth', 1.2);
        ylabel('\alpha_{mag} (rad/s^2)');
        xlabel('Time (s)');
        title('Head Angular Acceleration Magnitude');
        ylim([0, 25]); 
        grid on;
    end
    drawnow;  
end
