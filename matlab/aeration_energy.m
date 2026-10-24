%% Air supply, blower power and energy use
clear; 
clc;

%% 1. Inputs
Q  = 10000;    % Dry weather flow (m3/d)
PE = 50000;    % Population equivalent
Ro = 3924;     % Oxygen demand (kg O2/d)
T  = 10;       % Design temperature (degC)
DO = 2.0;      % Dissolved oxygen (mg/L)

%% 2. Design parameters
depth   = 5.0;     % Tank water depth (m)
h_diff  = 0.3;     % Diffuser height above floor (m)
SOTE_m  = 0.06;    % Oxygen transfer per metre of submergence
F_foul  = 0.90;    % Fouling factor
alpha   = 0.80;    % Alpha factor
beta    = 0.92;    % Beta factor
Cs_T    = 11.33;   % Oxygen saturation at design temperature (mg/L)
Cs_20   = 9.2;     % Oxygen saturation at 20 degC (mg/L)
O2_air  = 0.279;   % Oxygen in air (kg O2/m3)
gamma   = 1.4;     % Specific heat ratio for air
eta     = 0.60;    % Blower efficiency
p1      = 101.325; % Inlet pressure (kPa)
dp_loss = 10;      % Pipework and diffuser pressure losses (kPa)
hours   = 8760;    % Operating hours per year

%% 3. Oxygen transfer and air flow
AOTR   = Ro / 24;                                              % Oxygen needed per hour (kg O2/h)
f_corr = alpha * (beta * Cs_T - DO) / Cs_20 * 1.024^(T - 20);  % Correction factor
SOTR   = AOTR / f_corr;                                        % Standard oxygen requirement (kg O2/h)

submerge = depth - h_diff;                                     % Diffuser submergence (m)
SOTE     = SOTE_m * submerge * F_foul;                         % Effective transfer efficiency
Q_air_h  = SOTR / (SOTE * O2_air);                             % Air flow (m3/h)
Q_air_s  = Q_air_h / 3600;                                     % Air flow (m3/s)

%% 4. Blower power and energy use
p2 = p1 + 9.80665 * submerge + dp_loss;                        % Discharge pressure (kPa)

P = Q_air_s * p1 / eta * (gamma / (gamma - 1)) * ((p2 / p1)^((gamma - 1) / gamma) - 1);                    % Blower power (kW)

E_year  = P * hours;                                           % Annual energy use (kWh/year)
E_perPE = E_year / PE;                                         % Energy per PE (kWh/PE/year)
E_perm3 = E_year / (Q * 365);                                  % Energy per m3 treated (kWh/m3)
eff_f   = Ro / (P * 24);                                       % Field efficiency (kg O2/kWh)
eff_s   = SOTR / P;                                            % Standard efficiency (kg O2/kWh)

%% 5. Compare with benchmarks
share_low  = 0.25;     % Lower estimate of aeration's energy share
share_high = 0.60;     % Upper estimate of aeration's energy share
total_low  = E_perPE / share_high;
total_high = E_perPE / share_low;

%% 6. Sensitivity to alpha
power_for = @(a) (Ro/24) / (a * (beta*Cs_T - DO)/Cs_20 * 1.024^(T-20)) / (SOTE * O2_air) / 3600 * p1 / eta * (gamma/(gamma-1)) * ((p2/p1)^((gamma-1)/gamma) - 1);

alpha_vec = 0.4:0.1:0.9;
P_vec     = arrayfun(power_for, alpha_vec);
perPE_vec = P_vec * hours / PE;
eff_vec   = Ro ./ (P_vec * 24);

%% 7. Display results
fprintf('\nOXYGEN TRANSFER\n');
fprintf('Field oxygen needed: %.1f kg O2/h\n', AOTR);
fprintf('Field-to-standard factor: %.3f\n', f_corr);
fprintf('Standard oxygen needed: %.1f kg O2/h\n', SOTR);
fprintf('Diffuser submergence: %.1f m\n', submerge);
fprintf('Effective transfer eff.: %.1f %%\n', SOTE * 100);

fprintf('\nAIR AND BLOWERS\n');
fprintf('Air flow: %.0f m3/h (%.2f m3/s)\n', Q_air_h, Q_air_s);
fprintf('Discharge pressure: %.1f kPa\n', p2);
fprintf('Blower power: %.1f kW\n', P);

fprintf('\nENERGY\n');
fprintf('Annual energy: %.0f MWh/year\n', E_year / 1000);
fprintf('Per population equiv.: %.1f kWh/PE/year\n', E_perPE);
fprintf('Per m3 treated: %.3f kWh/m3\n', E_perm3);
fprintf('Field efficiency: %.2f kg O2/kWh\n', eff_f);
fprintf('Standard efficiency: %.2f kg O2/kWh\n', eff_s);

fprintf('\nBENCHMARK COMPARISON\n');
fprintf('Implied total plant: %.1f to %.1f kWh/PE/year\n', total_low, total_high);

fprintf('\nALPHA SENSITIVITY\n');
fprintf('Alpha Power (kW) kWh/PE/year  kg O2/kWh\n');

for i = 1:numel(alpha_vec)
    fprintf('%5.1f   %9.1f   %10.1f   %9.2f\n', alpha_vec(i), P_vec(i), perPE_vec(i), eff_vec(i));
end

%% 8. Plot the sensitivity results
figure;

subplot(1, 2, 1);
plot(alpha_vec, P_vec, '-o');
hold on;
plot(alpha, P, 'rs', 'MarkerFaceColor', 'r');
xlabel('Alpha factor');
ylabel('Blower power (kW)');
title('Power against alpha');
grid on;

subplot(1, 2, 2);
plot(alpha_vec, eff_vec, '-o');
hold on;
plot(alpha, eff_f, 'rs', 'MarkerFaceColor', 'r');
plot([alpha_vec(1) alpha_vec(end)], [0.91 0.91], 'k--');
plot([alpha_vec(1) alpha_vec(end)], [1.40 1.40], 'k--');
xlabel('Alpha factor');
ylabel('Field efficiency (kg O2/kWh)');
title('Efficiency (dashed: ORNL range)');
grid on;

saveas(gcf, 'aeration_energy_sensitivity.png');

%% 9. Save results for the next stage
save('aeration_energy_results.mat');
