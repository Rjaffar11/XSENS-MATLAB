clc; clear all; close all;

sID='W014';
tID= '001';

% Load Excel with preserved column names
filename = ['March 6 2025-016_P06.xlsx'];
g = 9.81; % [m/s2]

% Load sheets
tbl_acc = readtable(filename, 'Sheet', 'Segment Acceleration');
tbl_vel = readtable(filename, 'Sheet', 'Segment Velocity');
tbl_rot = readtable(filename, 'Sheet', 'Segment Angular Velocity'); %#ok<NASGU> % not used now
tbl_ang = readtable(filename, 'Sheet', 'Segment Angular Acceleration');
tbl_pos = readtable(filename, 'Sheet', 'Segment Position');

% Time vector (assuming 60 Hz)
fs = 60;
nFrames = height(tbl_pos);
t = (0:nFrames-1)' / fs;

% Segments to display
segments = {"Head"};

% ----------------------------
% Magnitudes and helpers
% ----------------------------
acc_handles = gobjects(1, length(segments));
pos_handles = gobjects(1, length(segments));
pos_refs    = gobjects(1, length(segments));
vel_handles = gobjects(1, length(segments));
vel_refs    = gobjects(1, length(segments));
angvel_handles = gobjects(1, length(segments));   % <-- added
angvel_refs    = gobjects(1, length(segments));   % <-- added
jerk = struct();

% Accel magnitude from table + jerk
for i = 1:length(segments)
    s = segments{i};
    ax_a = tbl_acc.(strcat(s,'X'));
    ay_a = tbl_acc.(strcat(s,'Y'));
    az_a = tbl_acc.(strcat(s,'Z'));
    a_mag = sqrt(ax_a.^2 + ay_a.^2 + az_a.^2) / g; % in g
    assignin('base', strcat('a_', s, '_mag'), a_mag);
    jerk.(s) = [0; diff(a_mag) * fs];
end

% Linear velocity (from Segment Velocity) and angular accel (from Segment Angular Acceleration)
linvel_mag = struct();
angacc_mag = struct();
angvel_mag = struct();  % <-- added
for i = 1:length(segments)
    s = segments{i};
    % linear velocity
    vx = tbl_vel.(sprintf('%sX', s));
    vy = tbl_vel.(sprintf('%sY', s));
    vz = tbl_vel.(sprintf('%sZ', s));
    linvel_mag.(s) = sqrt(vx.^2 + vy.^2 + vz.^2);
    % angular acceleration
    ax_w = tbl_ang.(sprintf('%sX', s));
    ay_w = tbl_ang.(sprintf('%sY', s));
    az_w = tbl_ang.(sprintf('%sZ', s));
    angacc_mag.(s) = sqrt(ax_w.^2 + ay_w.^2 + az_w.^2);
    % angular velocity (from Segment Angular Velocity)
    wx = tbl_rot.(sprintf('%sX', s));
    wy = tbl_rot.(sprintf('%sY', s));
    wz = tbl_rot.(sprintf('%sZ', s));
    angvel_mag.(s) = sqrt(wx.^2 + wy.^2 + wz.^2);
end

% Extract segment positions for animation skeleton and Z plots
tbl_vars = tbl_pos.Properties.VariableNames;
segment_names = {};
positions = {};
for i = 2:3:length(tbl_vars)-2
    base = tbl_vars{i}(1:end-1);
    if all(ismember({[base 'X'], [base 'Y'], [base 'Z']}, tbl_vars))
        segment_names{end+1} = base; %#ok<SAGROW>
        positions{end+1} = [tbl_pos{:, [base 'X']}, tbl_pos{:, [base 'Y']}, tbl_pos{:, [base 'Z']}]; %#ok<SAGROW>
    end
end

% ----------------------------
% Figure and layout
% ----------------------------
figure('Color','w');
ax3d = subplot(2,6,[1 2 7 8]);
hold(ax3d, 'on'); grid(ax3d, 'on'); axis(ax3d, 'equal');
xlabel(ax3d,'X'); ylabel(ax3d,'Y'); zlabel(ax3d,'Z');
title(ax3d, ['Animation - ' filename(1:end-5)]);
view(ax3d, [-111 22]);

% Limits and ground patch
all_xyz = vertcat(positions{:});
min_xyz = min(all_xyz); max_xyz = max(all_xyz); margin = 0.1;
xlim(ax3d,[min_xyz(1)-margin, max_xyz(1)+margin]);
ylim(ax3d,[min_xyz(2)-margin, max_xyz(2)+margin]);
zlim(ax3d,[min_xyz(3)-margin, max_xyz(3)+margin]);
patch('Parent', ax3d, ...
    'XData', [min_xyz(1) max_xyz(1) max_xyz(1) min_xyz(1)], ...
    'YData', [min_xyz(2) min_xyz(2) max_xyz(2) max_xyz(2)], ...
    'ZData', [min_xyz(3) min_xyz(3) min_xyz(3) min_xyz(3)], ...
    'FaceColor','b','FaceAlpha',0.05,'EdgeColor','none');

% Animated markers and lines
h = gobjects(numel(segment_names), 1);
for j = 1:numel(segment_names)
    h(j) = plot3(ax3d, NaN, NaN, NaN, 'o');
end

connections = {
    'Head','Neck'; 'Neck','T8'; 'T8','T12'; 'T12','L3'; 'L3','L5'; 'L5','Pelvis';
    'Pelvis','LeftUpperLeg'; 'LeftUpperLeg','LeftLowerLeg'; 'LeftLowerLeg','LeftFoot'; 'LeftFoot','LeftToe';
    'Pelvis','RightUpperLeg'; 'RightUpperLeg','RightLowerLeg'; 'RightLowerLeg','RightFoot'; 'RightFoot','RightToe';
    'T8','LeftUpperArm'; 'LeftUpperArm','LeftForearm'; 'LeftForearm','LeftHand';
    'T8','RightUpperArm'; 'RightUpperArm','RightForearm'; 'RightForearm','RightHand'};
lines = gobjects(size(connections,1), 1);
for i = 1:size(connections,1)
    lines(i) = plot3(ax3d, NaN(1,2), NaN(1,2), NaN(1,2), 'k-', 'LineWidth', 2);
end

% ----------------------------
% Small panels per segment
% ----------------------------
for i = 1:length(segments)
    s = segments{i};

    % Accel magnitude
    ax_acc = subplot(2,6,3); hold(ax_acc,'on'); grid(ax_acc,'on');
    a_data = evalin('base', strcat('a_', s, '_mag'));
    plot(ax_acc, t, a_data, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
    acc_handles(i) = plot(ax_acc, t(1), 0, 'r-', 'LineWidth', 2);
    title(ax_acc, [s ' Acc (g)']); xlim(ax_acc,[0 t(end)]);

    % Z position
    ax_pos = subplot(2,6,4); hold(ax_pos,'on'); grid(ax_pos,'on');
    ind = find(strcmpi(segment_names,s));
    if ~isempty(ind)
        z = positions{ind}(:,3);
        pos_refs(i) = plot(ax_pos, t, z, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
        pos_handles(i) = plot(ax_pos, t(1), z(1), 'b-', 'LineWidth', 2);
        title(ax_pos, [s ' Z']); xlim(ax_pos,[0 t(end)]);

        % Linear velocity magnitude from table (tile 5)
        ax_vel = subplot(2,6,5); hold(ax_vel,'on'); grid(ax_vel,'on');
        vel_refs(i) = plot(ax_vel, t, linvel_mag.(s), 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
        vel_handles(i) = plot(ax_vel, t(1), linvel_mag.(s)(1), 'm-', 'LineWidth', 2);
        title(ax_vel, [s ' Lin Vel']); xlim(ax_vel,[0 t(end)]);

        % Angular velocity magnitude (tile 6)
        ax_angvel = subplot(2,6,6); hold(ax_angvel,'on'); grid(ax_angvel,'on');
        angvel_refs(i) = plot(ax_angvel, t, angvel_mag.(s), 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
        angvel_handles(i) = plot(ax_angvel, t(1), angvel_mag.(s)(1), 'm-', 'LineWidth', 2);
        title(ax_angvel, [s ' Ang Vel']); xlim(ax_angvel,[0 t(end)]);

    else
        pos_handles(i) = plot(NaN, NaN);
        pos_refs(i)    = plot(NaN, NaN);
        vel_handles(i) = plot(NaN, NaN);
        vel_refs(i)    = plot(NaN, NaN);
        angvel_handles(i) = plot(NaN, NaN);   % <-- added to keep arrays aligned
        angvel_refs(i)    = plot(NaN, NaN);
    end
end

% ----------------------------
% Extra panels: Jerk + Whiplash + Angular Acceleration
% ----------------------------
% Head jerk (tile 11)
ax_jerk = subplot(2,6,11);
hold(ax_jerk,'on'); grid(ax_jerk,'on');
plot(ax_jerk, t, jerk.Head, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
h_head_jerk = plot(ax_jerk, t(1), jerk.Head(1), 'g-', 'LineWidth', 2);
title(ax_jerk,'Head Jerk'); xlim(ax_jerk,[0 t(end)]);

% Whiplash panels use velocity from positions (for relative motion)
idxHead = find(strcmpi(segment_names,'Head'), 1);
idxNeck = find(strcmpi(segment_names,'Neck'), 1);
idxT8   = find(strcmpi(segment_names,'T8'),   1);

ax_hw = subplot(2,6,9); hold(ax_hw,'on'); grid(ax_hw,'on');
v_head = positions{idxHead};
v_neck = positions{idxNeck};
vel_head_xyz = [zeros(1,3); diff(v_head)*fs];
vel_neck_xyz = [zeros(1,3); diff(v_neck)*fs];
vh_mag = sqrt(sum(vel_head_xyz.^2,2));
vn_mag = sqrt(sum(vel_neck_xyz.^2,2));
plot(ax_hw, t, vh_mag - vn_mag, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
h_whiplash_hn = plot(ax_hw, t(1), vh_mag(1) - vn_mag(1), 'g-', 'LineWidth', 2);
title(ax_hw,'Head–Neck Whiplash'); xlim(ax_hw,[0 t(end)]);

ax_ht = subplot(2,6,10); hold(ax_ht,'on'); grid(ax_ht,'on');
v_torso = positions{idxT8};
vel_torso_xyz = [zeros(1,3); diff(v_torso)*fs];
vtorso_mag = sqrt(sum(vel_torso_xyz.^2,2));
plot(ax_ht, t, vh_mag - vtorso_mag, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
h_whiplash_ht = plot(ax_ht, t(1), vh_mag(1) - vtorso_mag(1), 'g-', 'LineWidth', 2);
title(ax_ht,'Head–Torso Whiplash'); xlim(ax_ht,[0 t(end)]);

% Angular Acceleration (tile 12)
ax_ang_head = subplot(2,6,12); hold(ax_ang_head,'on'); grid(ax_ang_head,'on');
plot(ax_ang_head, t, angacc_mag.Head, 'k', 'LineWidth', 1, 'Color', [0.2 0.2 0.2 0.3]);
h_angacc_head = plot(ax_ang_head, t(1), angacc_mag.Head(1), 'c-', 'LineWidth', 2);
title(ax_ang_head,'Head Angular Accel'); xlim(ax_ang_head,[0 t(end)]);

% ----------------------------
% Animate
% ----------------------------
for k = 1:nFrames
    % 3D markers
    for j = 1:numel(segment_names)
        h(j).XData = positions{j}(k, 1);
        h(j).YData = positions{j}(k, 2);
        h(j).ZData = positions{j}(k, 3);
    end

    % Skeleton connections
    for i = 1:size(connections,1)
        idx1 = find(strcmp(segment_names, connections{i,1}));
        idx2 = find(strcmp(segment_names, connections{i,2}));
        if ~isempty(idx1) && ~isempty(idx2)
            p1 = positions{idx1}(k, :);
            p2 = positions{idx2}(k, :);
            set(lines(i), 'XData', [p1(1), p2(1)], ...
                          'YData', [p1(2), p2(2)], ...
                          'ZData', [p1(3), p2(3)]);
        end
    end

    % Update per-segment small panels
    for i = 1:length(segments)
        s = segments{i};
        a_data = evalin('base', strcat('a_', s, '_mag'));
        set(acc_handles(i), 'XData', t(1:k), 'YData', a_data(1:k));

        ind = find(strcmpi(segment_names,s));
        if ~isempty(ind) && isvalid(pos_handles(i))
            z = positions{ind}(:,3);
            set(pos_handles(i), 'XData', t(1:k), 'YData', z(1:k));

            % Linear velocity from table (no diff)
            set(vel_handles(i), 'XData', t(1:k), 'YData', linvel_mag.(s)(1:k));
            % Angular velocity from table
            set(angvel_handles(i), 'XData', t(1:k), 'YData', angvel_mag.(s)(1:k));
        end
    end

    % Jerk and whiplash updates
    set(h_head_jerk, 'XData', t(1:k), 'YData', jerk.Head(1:k));
    set(h_whiplash_hn, 'XData', t(1:k), 'YData', (vh_mag(1:k) - vn_mag(1:k)));
    set(h_whiplash_ht, 'XData', t(1:k), 'YData', (vh_mag(1:k) - vtorso_mag(1:k)));

    % Angular acceleration updates
    set(h_angacc_head, 'XData', t(1:k), 'YData', angacc_mag.Head(1:k));

    drawnow;
    pause(0.01);
end
