clc; clear; close all;

% File
filename = 'MG98799-0726-2025-03-06T104256+125.csv';

% Read table
tbl = readtable(filename);

% Time (convert ms to seconds)
t = tbl.T_ms / 1000;

% Angular Acceleration (rad/s²)
aa_x = tbl.PAA_X_radsec_2;
aa_y = tbl.PAA_Y_radsec_2;
aa_z = tbl.PAA_Z_radsec_2;
if ismember('PAA_R_radsec_2', tbl.Properties.VariableNames)
    aa_r = tbl.PAA_R_radsec_2;
else
    aa_r = sqrt(aa_x.^2 + aa_y.^2 + aa_z.^2);
end

% Angular Velocity (rad/s)
av_x = tbl.PAV_X_radsec;
av_y = tbl.PAV_Y_radsec;
av_z = tbl.PAV_Z_radsec;
if ismember('PAV_R_radsec_', tbl.Properties.VariableNames)
    av_r = tbl.PAV_R_radsec;
else
    av_r = sqrt(av_x.^2 + av_y.^2 + av_z.^2);
end

% Linear Acceleration (m/s²)
la_x = tbl.PLA_X_msec_2;
la_y = tbl.PLA_Y_msec_2;
la_z = tbl.PLA_Z_msec_2;
if ismember('PLA_R_msec_2', tbl.Properties.VariableNames)
    la_r = tbl.PLA_R_msec_2;
else
    la_r = sqrt(la_x.^2 + la_y.^2 + la_z.^2);
end

% Linear Velocity (m/s)
lv_x = tbl.PLV_X_msec;
lv_y = tbl.PLV_Y_msec;
lv_z = tbl.PLV_Z_msec;
if ismember('PLV_R_msec', tbl.Properties.VariableNames)
    lv_r = tbl.PLV_R_msec;
else
    lv_r = sqrt(lv_x.^2 + lv_y.^2 + lv_z.^2);
end

% Plotting
figure('Name','Head Kinematics','Color','w','Units','normalized','Position',[0.05 0.05 0.9 0.9]);

subplot(4,1,1);
plot(t, aa_x, 'r', t, aa_y, 'g', t, aa_z, 'b', t, aa_r, 'k--', 'LineWidth',1.2);
title('Angular Acceleration'); ylabel('rad/s²'); legend('X','Y','Z','Resultant'); grid on;

subplot(4,1,2);
plot(t, av_x, 'r', t, av_y, 'g', t, av_z, 'b', t, av_r, 'k--', 'LineWidth',1.2);
title('Angular Velocity'); ylabel('rad/s'); legend('X','Y','Z','Resultant'); grid on;

subplot(4,1,3);
plot(t, la_x, 'r', t, la_y, 'g', t, la_z, 'b', t, la_r, 'k--', 'LineWidth',1.2);
title('Linear Acceleration'); ylabel('m/s²'); legend('X','Y','Z','Resultant'); grid on;

subplot(4,1,4);
plot(t, lv_x, 'r', t, lv_y, 'g', t, lv_z, 'b', t, lv_r, 'k--', 'LineWidth',1.2);
title('Linear Velocity'); ylabel('m/s'); xlabel('Time (s)');
legend('X','Y','Z','Resultant'); grid on;
