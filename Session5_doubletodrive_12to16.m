% Author = "Rashad Jaffar"
% Date = 06.23.2025
% Finished file

clc;clear all;close all;
filelist = {
    'March 6 2025-012_P006.xlsx',
    'March 6 2025-013_P006.xlsx',
    'March 6 2025-014_P006.xlsx',
    'March 6 2025-015_P006.xlsx',
    'March 6 2025-016_P006.xlsx'
};

for fileIdx = 1:length(filelist)
    sID = 'W014';
    tID = '001';
    filename = filelist{fileIdx};
    g=9.81; % [m/s2]
    % Load acceleration and angular velocity
    tbl_acc = readtable(filename, 'Sheet', 'Segment Acceleration');
    tbl_rot = readtable(filename, 'Sheet', 'Segment Angular Velocity');
    tbl_pos = readtable(filename, 'Sheet', 'Segment Position');
    % Time vector (assuming 60 Hz)
    fs = 60;
    nFrames = height(tbl_pos);
    t = (0:nFrames-1)' / fs;
    % List of body parts to add
    segments = {"Head","Neck","RightHand","LeftHand","RightForearm","LeftForearm",...
                "RightShoulder","LeftShoulder","Pelvis","L3","RightFoot","LeftFoot"};
    % Get magnitudes of acceleration and predefine handles
    acc_handles = gobjects(1, length(segments));
    pos_handles = gobjects(1, length(segments));
    pos_refs = gobjects(1, length(segments));
    vel_handles = gobjects(1, length(segments));
    vel_refs = gobjects(1, length(segments));
    h_jerk = gobjects(1,1);
    h_whip_neck = gobjects(1,1);
    h_whip_torso = gobjects(1,1);
    jerk = struct();
    for i = 1:length(segments)
        s = segments{i};
        ax = tbl_acc.(strcat(s,'X'));
        ay = tbl_acc.(strcat(s,'Y'));
        az = tbl_acc.(strcat(s,'Z'));
        a_mag = sqrt(ax.^2 + ay.^2 + az.^2)/g;
        assignin('base', strcat('a_', s, '_mag'), a_mag);
        jerk.(s) = [0; diff(a_mag) * fs];
    end
    % Get head rotational velocity
    wx = tbl_rot.('HeadX');
    wy = tbl_rot.('HeadY');
    wz = tbl_rot.('HeadZ');
    w_mag = sqrt(wx.^2 + wy.^2 + wz.^2);
    % Extract segment positions
    tbl_vars = tbl_pos.Properties.VariableNames;
    segment_names = {};
    positions = {};
    for i = 2:3:length(tbl_vars)-2
        base = tbl_vars{i}(1:end-1);
        if all(ismember({[base 'X'], [base 'Y'], [base 'Z']}, tbl_vars))
            segment_names{end+1} = base;
            positions{end+1} = [tbl_pos{:, [base 'X']}, tbl_pos{:, [base 'Y']}, tbl_pos{:, [base 'Z']}];
        end
    end
    % Setup figure
    figure('Color','w');
    ax=subplot(3,15,[1 2 16 17 31 32]);
    hold on; grid on; axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title(['Animation - ' filename(1:end-5)]);
    view([-111  22])
    % Limits and patch
    all_xyz = vertcat(positions{:});
    min_xyz = min(all_xyz); max_xyz = max(all_xyz); margin = 0.1;
    xlim([min_xyz(1)-margin, max_xyz(1)+margin]);
    ylim([min_xyz(2)-margin, max_xyz(2)+margin]);
    zlim([min_xyz(3)-margin, max_xyz(3)+margin]);
    hp= patch([min_xyz(1) max_xyz(1) max_xyz(1) min_xyz(1)], [min_xyz(2) min_xyz(2) max_xyz(2) max_xyz(2)], [0 0 0 0],'b');
    % Create animated markers and lines
    h = gobjects(numel(segment_names), 1);
    for j = 1:numel(segment_names)
        h(j) = plot3(NaN, NaN, NaN, 'o');
    end
    connections = {
        'Head','Neck'; 'Neck','T8'; 'T8','T12'; 'T12','L3'; 'L3','L5'; 'L5','Pelvis';
        'Pelvis','LeftUpperLeg'; 'LeftUpperLeg','LeftLowerLeg'; 'LeftLowerLeg','LeftFoot'; 'LeftFoot','LeftToe';
        'Pelvis','RightUpperLeg'; 'RightUpperLeg','RightLowerLeg'; 'RightLowerLeg','RightFoot'; 'RightFoot','RightToe';
        'T8','LeftUpperArm'; 'LeftUpperArm','LeftForearm'; 'LeftForearm','LeftHand';
        'T8','RightUpperArm'; 'RightUpperArm','RightForearm'; 'RightForearm','RightHand'};
    lines = gobjects(size(connections,1), 1);
    for i = 1:size(connections,1)
        lines(i) = plot3(NaN(1,2), NaN(1,2), NaN(1,2), 'k-', 'LineWidth', 2);
    end
    % Plot data
    for i = 1:length(segments)
        s = segments{i};
        subplot(3,15,i+2);  % acceleration row
        hold on; grid on;
        a_data = evalin('base', strcat('a_', s, '_mag'));
        plot(t, a_data, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
        acc_handles(i) = plot(t(1), 0, 'r-', 'LineWidth', 2);
        title([s ' Acc']); xlim([0 t(end)]); ylim([0 20]);
        subplot(3,15,i+17);  % position row
        hold on; grid on;
        ind = find(strcmpi(segment_names,s));
        if ~isempty(ind)
            z = positions{ind}(:,3);
            pos_refs(i) = plot(t, z, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
            pos_handles(i) = plot(t(1), z(1), 'b-', 'LineWidth', 2);
            title([s ' Z']); xlim([0 t(end)]); ylim([0 2]);
            pos = positions{ind};
            vel = [zeros(1,3); diff(pos)*fs];
            vel_mag = sqrt(sum(vel.^2, 2));
            subplot(3,15,i+32); %velocity row
            hold on; grid on;
            vel_refs(i) = plot(t, vel_mag, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
            vel_handles(i) = plot(t(1), vel_mag(1), 'm-', 'LineWidth', 2);
            title([s ' Vel']); xlim([0 t(end)]); ylim([0 6]);
            
        else
            pos_handles(i) = plot(NaN, NaN);
            pos_refs(i) = plot(NaN, NaN);
            vel_handles(i) = plot(NaN, NaN);
            vel_refs(i) = plot(NaN, NaN);
        end
    end
    % Head jerk plot (row 1, col 16)
    subplot(3,15,length(segments)+3);
    hold on; grid on;
    plot(t, jerk.Head, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
    h_jerk = plot(t(1), jerk.Head(1), 'g-', 'LineWidth', 2);
    title('Head Jerk'); xlim([0 t(end)]);

    % Head–Neck whiplash (row 2, col 16)
    subplot(3,15,length(segments)+18);
    v_head = positions{strcmp(segment_names,'Head')};
    v_neck = positions{strcmp(segment_names,'Neck')};
    vel_head = [zeros(1,3); diff(v_head)*fs];
    vel_neck = [zeros(1,3); diff(v_neck)*fs];
    vh_mag = sqrt(sum(vel_head.^2,2));
    vn_mag = sqrt(sum(vel_neck.^2,2));
    grid on; hold on;
    plot(t, vh_mag - vn_mag, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
    h_whip_neck = plot(t(1), vh_mag(1) - vn_mag(1), 'g-', 'LineWidth', 2);
    title('Head–Neck Whiplash'); xlim([0 t(end)]); 

    % Head–Torso whiplash (row 3, col 16)
    subplot(3,15,length(segments)+33);
    v_torso = positions{strcmp(segment_names,'T8')};
    vel_torso = [zeros(1,3); diff(v_torso)*fs];
    vtorso_mag = sqrt(sum(vel_torso.^2,2));
    grid on; hold on;
    plot(t, vh_mag - vtorso_mag, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
    h_whip_torso = plot(t(1), vh_mag(1) - vtorso_mag(1), 'g-', 'LineWidth', 2);
    title('Head–Torso Whiplash'); xlim([0 t(end)]); 
    % Animate
    for k = 1:nFrames
        subplot(3,15,[1 2 16 17 31 32]);
        for j = 1:numel(segment_names)
            h(j).XData = positions{j}(k, 1);
            h(j).YData = positions{j}(k, 2);
            h(j).ZData = positions{j}(k, 3);
        end
        for i = 1:size(connections,1)
            idx1 = find(strcmp(segment_names, connections{i,1}));
            idx2 = find(strcmp(segment_names, connections{i,2}));
            if ~isempty(idx1) && ~isempty(idx2)
                p1 = positions{idx1}(k, :);
                p2 = positions{idx2}(k, :);
                set(lines(i), 'XData', [p1(1), p2(1)], 'YData', [p1(2), p2(2)], 'ZData', [p1(3), p2(3)]);
            end
        end
        for i = 1:length(segments)
            s = segments{i};
            a_data = evalin('base', strcat('a_', s, '_mag'));
            set(acc_handles(i), 'XData', t(1:k), 'YData', a_data(1:k));
            ind = find(strcmpi(segment_names,s));
            if ~isempty(ind) && isvalid(pos_handles(i))
                z = positions{ind}(:,3);
                set(pos_handles(i), 'XData', t(1:k), 'YData', z(1:k));
                pos = positions{ind};
                vel = [zeros(1,3); diff(pos)*fs];
                vel_mag = sqrt(sum(vel.^2, 2));
                set(vel_handles(i), 'XData', t(1:k), 'YData', vel_mag(1:k));
            end
        end
        subplot(3,15,length(segments)+3);
        set(h_jerk, 'XData', t(1:k), 'YData', jerk.Head(1:k));
        set(h_whip_neck, 'XData', t(1:k), 'YData', vh_mag(1:k) - vn_mag(1:k));
        set(h_whip_torso, 'XData', t(1:k), 'YData', vh_mag(1:k) - vtorso_mag(1:k));

        pause(0.01);
    end
end     