clc; clear; close all;

% Load one file
filename = 'March 6 2025-012_P006.xlsx';

% Constants
g = 9.81; % gravity
fs = 60;  % sampling frequency

% Read tables
tbl_acc = readtable(filename, 'Sheet', 'Segment Acceleration');
tbl_pos = readtable(filename, 'Sheet', 'Segment Position');

nFrames = height(tbl_pos);
t = (0:nFrames-1)' / fs;

% === Acceleration magnitude for Head ===
ax = tbl_acc.HeadX;
ay = tbl_acc.HeadY;
az = tbl_acc.HeadZ;
a_head_mag = sqrt(ax.^2 + ay.^2 + az.^2) / g;  % in g

% === Jerk (rate of change of acceleration) ===
jerk_head = [0; diff(a_head_mag) * fs];

% === Z Position of Head ===
z_head = tbl_pos.HeadZ;

% === Plotting ===
figure('Name', 'Head Segment Check', 'Color', 'w');

% 1. Head Acceleration Magnitude
subplot(4,1,1);
plot(t, a_head_mag, 'r', 'LineWidth', 2);
title('Head Acceleration Magnitude'); ylabel('g'); grid on; xlim([0 t(end)]);

% 2. Head Jerk
subplot(4,1,2);
plot(t, jerk_head, 'g', 'LineWidth', 2);
title('Head Jerk'); ylabel('g/s'); grid on; xlim([0 t(end)]);

% 3. Head Z-Position
subplot(4,1,3);
plot(t, z_head, 'b', 'LineWidth', 2);
title('Head Z-Position'); ylabel('Position (m)'); grid on; xlim([0 t(end)]);

% 4. Optional: X, Y, Z components of head accel
subplot(4,1,4);
plot(t, ax, 'r--', t, ay, 'g--', t, az, 'b--');
title('Head Acceleration Components'); ylabel('m/s²'); xlabel('Time (s)');
legend('X','Y','Z'); grid on; xlim([0 t(end)]);
