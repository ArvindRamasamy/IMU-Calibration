%% AccMag_Calibration      %
% Author: Mattia Giurato   %
% Last review: 2015/09/29  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all 
clc

%% Import logged data
endACCMAG = 8250;
    
RAW = dlmread('log1702161944.txt');
acc = RAW(1:endACCMAG,1:3);
mag = RAW(1:endACCMAG,7:9);
gyr = RAW(endACCMAG+1:length(RAW),4:6);

%% Plot RAW data
% figure('name','Accelerometer')
% plot(1:length(acc), acc(:,1))
% hold on
% plot(1:length(acc), acc(:,2))
% plot(1:length(acc), acc(:,3))
% hold off
% legend('X_{body}', 'Y_{body}', 'Z_{body}')
% title('Accelerometer RAW data')
% grid
% 
% figure('name','Magnetometer')
% plot(1:length(mag), mag(:,1))
% hold on
% plot(1:length(mag), mag(:,2))
% plot(1:length(mag), mag(:,3))
% hold off
% legend('X_{body}', 'Y_{body}', 'Z_{body}')
% title('Magnetometer RAW data')
% grid

%% Filtering RAW data
LPF = designfilt('lowpassfir','PassbandFrequency',0.15, ...
      'StopbandFrequency',0.25,'PassbandRipple',0.1, ...
      'StopbandAttenuation',65,'DesignMethod','kaiserwin');
% fvtool(LPF)

acc_f = filtfilt(LPF,acc);
gyr_f = filtfilt(LPF,gyr);

% figure('name','Accelerometer')
% plot(1:length(acc_f), acc_f(:,1))
% hold on
% plot(1:length(acc_f), acc_f(:,2))
% plot(1:length(acc_f), acc_f(:,3))
% hold off
% title('Accelerometer filtered data')
% legend('X_{body}', 'Y_{body}', 'Z_{body}')
% grid

%% Calibrating Accelerometer

% Find gains and biases
bias_a_guess = .5;
gain_a_guess = 9.81/1000;

optionsOpt = optimset('LargeScale', 'off', 'Display', 'off', 'TolX', 1E-21, 'TolFun', 1E-21, 'HessUpdate', 'bfgs', 'MaxIter', 128);  
optVal = [ones(1,3)*bias_a_guess ones(1,3)*gain_a_guess];  	% vector of initial guess for optimal value
optValScaler = 1 ./ optVal;                                 % individual scalers unit optimal values
optVal = optVal .* optValScaler;                            % initial guess for optimal values = unity
optVal = fminunc('objFunAccelMag', optVal, optionsOpt, optValScaler, acc_f, 9.81);
optVal = optVal ./ optValScaler;                            % rescale optimal values to original units
bias_a = optVal(1:3);
gain_a = optVal(4:6);

% Plot calibrated data
figure('name','Accelerometer Calibration');
subplot(3,1,1:2)
    hold on;    
    acc_c(:,1) = gain_a(1) * acc_f(:,1) - bias_a(1);
    acc_c(:,2) = gain_a(2) * acc_f(:,2) - bias_a(2);
    acc_c(:,3) = gain_a(3) * acc_f(:,3) - bias_a(3);
    plot(1:length(acc_c), acc_c(:,1), 'b');
    plot(1:length(acc_c), acc_c(:,2), 'r');
    plot(1:length(acc_c), acc_c(:,3), 'g');
    legend('X', 'Y', 'Z');
    title('Accelerometer calibration');
    ylabel('Acceleration [m/s^2]');
subplot(3,1,3)    
    hold on;
    plot(1:length(acc_c), sqrt((acc_c(:,1).^2) + (acc_c(:,2).^2) + (acc_c(:,3).^2)), 'Color', [0.6, 0.6, 0.6]);
    plot([0 length(acc_c)], [9.81 9.81], 'k:');
    legend('Measured field', 'field');
    ylabel('[m/s^2]');
    xlabel('Sample');
drawnow;

%Print gains and biases
disp('The estimated Accelerometer biases are:')
disp(['X:', num2str(bias_a(1))])
disp(['Y:', num2str(bias_a(2))])
disp(['Z:', num2str(bias_a(3))])
disp('The estimated Accelerometer scale factors are:')
disp(['X:', num2str(gain_a(1))])
disp(['Y:', num2str(gain_a(2))])
disp(['Z:', num2str(gain_a(3))])

%% Calibrating Magnetometer

% Find gains and biases
bias_m_guess = -0.1;
gain_m_guess = 1/(1000*0.35);

optionsOpt = optimset('LargeScale', 'off', 'Display', 'off', 'TolX', 1E-21, 'TolFun', 1E-21, 'HessUpdate', 'bfgs', 'MaxIter', 128);  
optVal = [ones(1,3)*bias_m_guess ones(1,3)*gain_m_guess];  	% vector of initial guess for optimal value
optValScaler = 1 ./ optVal;                                 % individual scalers unit optimal values
optVal = optVal .* optValScaler;                            % initial guess for optimal values = unity
optVal = fminunc('objFunAccelMag', optVal, optionsOpt, optValScaler, mag, 1);
optVal = optVal ./ optValScaler;                            % rescale optimal values to original units
bias_m = optVal(1:3);
gain_m = optVal(4:6);

% Plot calibrated data
figure('name','Magnetometer Calibration');
subplot(3,1,1:2)
    hold on;    
    mag_c(:,1) = gain_m(1) * mag(:,1) - bias_m(1);
    mag_c(:,2) = gain_m(2) * mag(:,2) - bias_m(2);
    mag_c(:,3) = gain_m(3) * mag(:,3) - bias_m(3);
    plot(1:length(mag_c), mag_c(:,1), 'b');
    plot(1:length(mag_c), mag_c(:,2), 'r');
    plot(1:length(mag_c), mag_c(:,3), 'g');
    legend('X', 'Y', 'Z');
    title('Magnetometer calibration');
    ylabel('Normalized flux []');
subplot(3,1,3)    
    hold on;
    plot(1:length(mag_c), sqrt((mag_c(:,1).^2) + (mag_c(:,2).^2) + (mag_c(:,3).^2)), 'Color', [0.6, 0.6, 0.6]);
    plot([0 length(mag_c)], [1 1], 'k:');
    legend('Measured field', 'field');
    ylabel('[]');
    xlabel('Sample');
drawnow;

%Print gains and biases
disp('The estimated Magnetometer biases are:')
disp(['X:', num2str(bias_m(1))])
disp(['Y:', num2str(bias_m(2))])
disp(['Z:', num2str(bias_m(3))])
disp('The estimated Magnetometer scale factors are:')
disp(['X:', num2str(gain_m(1))])
disp(['Y:', num2str(gain_m(2))])
disp(['Z:', num2str(gain_m(3))])

%% Calibrating Gyroscope

%Extracting each measurement
delta = 150;

%newnew
% gyr_x = -gyr(1120:1120+delta,1);
% gyr_y = gyr(320:320+delta,2);
% gyr_z = gyr(2030:2030+delta,3);
%newnew2
gyr_x = -gyr(1100:1100+delta,1);
gyr_y = gyr(300:300+delta,2);
gyr_z = gyr(2000:2000+delta,3);

gyro = [gyr_x gyr_y gyr_z];

% figure
% plot(gyr_x)
% hold on
% plot(gyr_y)
% plot(gyr_z)
% hold off

%Setting gyro parameters
target = pi;
samplePeriod = 1/100;
gain_g = [0.001 0.001 0.001];
bias_g = zeros(length(gyro),3);

% Find gains and biases
for i = 1:3;
    sensMeas = gyro(:,i);
    bias_g(:,i) = sensMeas(1) + ([1:numel(sensMeas)]'/numel(sensMeas)) * (sensMeas(end) - sensMeas(1));
    sensMeas = sensMeas - bias_g(:,i);

    optionsOpt = optimset('LargeScale', 'off', 'Display', 'off', 'TolX', 1E-21, 'TolFun', 1E-21, 'HessUpdate', 'bfgs', 'MaxIter', 128);  
    optVal = [gain_g(i)];                            % vector of initial guess for optimal value
    optValScaler = 1 ./ optVal;                 % individual scalers unit optimal values
    optVal = optVal .* optValScaler;            % initial guess for optimal values = unity
    optVal = fminunc('objFunGyro', optVal, optionsOpt, optValScaler, sensMeas, target, samplePeriod);
    optVal = optVal ./ optValScaler;            % rescale optimal values to original units
    gain_g(i) = optVal(1);
    
    %-------------------------------------------------------------------------- 
    % Plot calibrated data
    sensMeas = gain_g(i)*sensMeas;
    angle = zeros(length(sensMeas), 1);
    for t = 2:numel(sensMeas)
        angle(t) = angle(t-1) + sensMeas(t) * samplePeriod;
    end

    figure
    hold on;    
    plot(1:length(sensMeas), sensMeas + gain_g(i)*(bias_g(:,i)-bias_g(1,i)), 'b');
    plot(1:length(sensMeas), angle, 'r');
    plot(1:length(sensMeas), gain_g(i)*(bias_g(:,i)-bias_g(1,i)), 'k:');     
    plot([1 length(sensMeas)], [target target], 'k--');     
    legend('Angular velocity', 'Angular position', 'Bias', num2str(target), 'location', 'southeast');
    if i == 1
        title('Gyroscope calibration - X axis');
    elseif i == 2
        title('Gyroscope calibration - Y axis');
    elseif i == 3
        title('Gyroscope calibration - Z axis');
    end
    ylabel('[rad],[rad/s]');
        xlabel('Sample');  
        grid
    drawnow;
end

%Print gains and biases
disp('The estimated Gyroscope biases are:')
disp(['X:', num2str(gain_g(1)*mean(bias_g(:,1)))])
disp(['Y:', num2str(gain_g(2)*mean(bias_g(:,2)))])
disp(['Z:', num2str(gain_g(3)*mean(bias_g(:,3)))])
disp('The estimated Gyroscope scale factors are:')
disp(['X:', num2str(gain_g(1))])
disp(['Y:', num2str(gain_g(2))])
disp(['Z:', num2str(gain_g(3))])

%% Generate output file
fid = fopen('IMU_output.txt', 'w');
fprintf(fid, 'The estimated Accelerometer biases are:\n');
fprintf(fid, 'X: %f\n', bias_a(1));
fprintf(fid, 'Y: %f\n', bias_a(2));
fprintf(fid, 'Z: %f\n', bias_a(3));
fprintf(fid, 'The estimated Accelerometer scale factors are:\n');
fprintf(fid, 'X: %f\n', gain_a(1));
fprintf(fid, 'Y: %f\n', gain_a(2));
fprintf(fid, 'Z: %f\n', gain_a(3));
fprintf(fid, 'The estimated Magnetometer biases are:\n');
fprintf(fid, 'X: %f\n', bias_m(1));
fprintf(fid, 'Y: %f\n', bias_m(2));
fprintf(fid, 'Z: %f\n', bias_m(3));
fprintf(fid, 'The estimated Magnetometer scale factors are:\n');
fprintf(fid, 'X: %f\n', gain_m(1));
fprintf(fid, 'Y: %f\n', gain_m(2));
fprintf(fid, 'Z: %f\n', gain_m(3));
fprintf(fid, 'The estimated Gyroscope biases are:\n');
fprintf(fid, 'X: %f\n', gain_g(1)*mean(bias_g(:,1)));
fprintf(fid, 'Y: %f\n', gain_g(2)*mean(bias_g(:,2)));
fprintf(fid, 'Z: %f\n', gain_g(3)*mean(bias_g(:,2)));
fprintf(fid, 'The estimated Gyroscope scale factors are:\n');
fprintf(fid, 'X: %f\n', gain_g(1));
fprintf(fid, 'Y: %f\n', gain_g(2));
fprintf(fid, 'Z: %f\n', gain_g(3));
fclose(fid);

%% 3D PLOT
[x,y,z] = sphere;
figure('name','Accelerometer_sphere')
plot3(acc_c(:,1), acc_c(:,2), acc_c(:,3))
axis equal
hold on
m = mesh(9.81*x,9.81*y,9.81*z);
set(m,'facecolor','none')
grid
hold off

figure('name','Magnetometer_sphere')
plot3(mag_c(:,1), mag_c(:,2), mag_c(:,3))
axis equal
hold on 
m = mesh(x,y,z);
set(m,'facecolor','none')
grid
hold off

figure('name','Accelerometer_afterbefore')
plot3(acc_c(:,1), acc_c(:,2), acc_c(:,3))
hold on
plot3(9.81/1000*acc_f(:,1), 9.81/1000*acc_f(:,2), 9.81/1000*acc_f(:,3))
axis equal
grid
legend('Calibrated', 'Non-calibrated');
hold off

figure('name','Magnetometer_afterbefore')
plot3(mag_c(:,1), mag_c(:,2), mag_c(:,3))
axis equal
hold on
plot3(1/(1000*0.35)*mag(:,1), 1/(1000*0.35)*mag(:,2), 1/(1000*0.35)*mag(:,3))
grid
legend('Calibrated', 'Non-calibrated');
hold off

%% End of code