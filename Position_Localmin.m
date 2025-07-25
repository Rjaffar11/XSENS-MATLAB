clc; clear all; close all;

folderPath = 'Session 5 -005';
fileStruct = dir(fullfile(folderPath, '*.xlsx'));
filelist = fullfile(folderPath, {fileStruct.name});

fs = 60; g = 9.81;
filesPerFigure = 5;  % 5 files × 2 plots = 10 subplots per figure
nFiles = length(filelist);
nFigures = ceil(nFiles / filesPerFigure);

for figIdx = 1:nFigures
    figure('Name', ['Head Kinematics: Figure ' num2str(figIdx)], 'Color', 'w', ...
           'Units','normalized', 'Position', [0.05 0.05 0.9 0.9]);

    for subplotIdx = 1:filesPerFigure
        fileIdx = (figIdx - 1) * filesPerFigure + subplotIdx;
        if fileIdx > nFiles
            break;
        end
        
        filename = filelist{fileIdx};
        disp(['Processing: ' filename]);

        % Load Data
        tbl_acc = readtable(filename, 'Sheet', 'Segment Acceleration');
        tbl_pos = readtable(filename, 'Sheet', 'Segment Position');
        
        ax = tbl_acc.HeadX;
        ay = tbl_acc.HeadY;
        az = tbl_acc.HeadZ;
        a_mag = sqrt(ax.^2 + ay.^2 + az.^2) / g;

        z = tbl_pos.HeadZ;
        t = (0:length(z)-1)' / fs;

% ALGORITHM 1
        subplot(filesPerFigure, 2, (subplotIdx-1)*2 + 1);
        yyaxis left;
        plot(t, z, 'b-', 'LineWidth', 1.2);
        ylabel('Z Pos (m)');
        ylim([0, 2]);

        yyaxis right;
        plot(t, a_mag, 'k-', 'LineWidth', 1.2);
        ylabel('a_{mag} (g)');
        ylim([0, 10]);

        z_floor = 0.6;
        acc_thresh = 4;
        impact_frames = find(z < z_floor & a_mag > acc_thresh);
        hold on;
        scatter(t(impact_frames), a_mag(impact_frames), 50, 'r', 'filled');
        title(['[' num2str(fileIdx) '] ' fileStruct(fileIdx).name], 'Interpreter','none');
        grid on;

 % ALGORITHM 2
        [~, peak_acc_idx] = max(a_mag);
        window_radius = round(0.25 * fs);
        start_idx = max(1, peak_acc_idx - window_radius);
        end_idx = min(length(z), peak_acc_idx + window_radius);
        z_window = z(start_idx:end_idx);
        [min_z_in_window, min_z_rel_idx] = min(z_window);
        z_min_dynamic = min_z_in_window;
        score = a_mag ./ (z - z_min_dynamic + 0.005);
        [max_score, max_idx] = max(score);

        subplot(filesPerFigure, 2, (subplotIdx-1)*2 + 2);
        plot(t, score, 'm-', 'LineWidth', 1.2);
        ylabel('Score');
        xlabel('Time (s)');
        title('a_{mag} / (z - z_{min} + 0.005)');
        grid on;
        hold on;
        scatter(t(max_idx), max_score, 60, 'k', 'filled');
        text(t(max_idx), max_score, sprintf('  %.2f', max_score), ...
             'VerticalAlignment','bottom', 'Color','k', 'FontSize', 8);

        % Mark z_min on top subplot
        % Mark z_min only if there is actual vertical motion
        if range(z_window) > 0.01  % adjust threshold if needed
            z_min_global_idx = start_idx + min_z_rel_idx - 1;
            subplot(filesPerFigure, 2, (subplotIdx-1)*2 + 1);
            yyaxis left;
            hold on;
            scatter(t(z_min_global_idx), z(z_min_global_idx), 50, 'b', 'filled');
            text(t(z_min_global_idx), z(z_min_global_idx), '  z_{min}', ...
                 'Color', 'b', 'FontSize', 8, 'VerticalAlignment', 'top');
        end

    end
    drawnow;
end
