%% Inlet works and primary treatment sizing

clear;
clc;

%% 1. Design flow rates and incoming loads

DWF = 10000;       % Dry weather flow (m3/d)
FFT = 25000;       % Flow to full treatment (m3/d)

BOD_load = 3000;    % kg/d
COD_load = 6000;    % kg/d
SS_load  = 3750;    % kg/d
TKN_load = 650;     % kg N/d
NH4_load = 400;     % kg N/d

%% 2. Design choices

% Screens
V_through = 0.9;    % Velocity through screen openings (m/s)
b_clear = 0.020;    % Clear spacing between bars (m)
w_bar = 0.010;      % Width of each bar (m)

% Grit chamber
t_grit = 180;    % Detention time at FFT (s)

% Primary settlement tanks
SOR_avg  = 40;     % Surface overflow rate at DWF (m3/m2/d)
SOR_peak = 100;    % Surface overflow rate at FFT (m3/m2/d)
HRT_tgt  = 2.0;    % Target retention time at DWF (h)
n_tanks  = 2;      % Number of circular settlement tanks

% Assumed removal efficiencies
rem_BOD = 0.30;
rem_COD = 0.30;
rem_SS  = 0.60;
rem_TKN = 0.10;

%% 3. Screen sizing

% Convert the peak flow from m3/d to m3/s
Q_fft = FFT / 86400;

% Calculate the area required for water to pass through the openings
A_open = Q_fft / V_through;

% Estimate the proportion of the screen area that is open
open_fr = b_clear / (b_clear + w_bar);

% Calculate the total submerged screen area
A_gross = A_open / open_fr;

% Calculate the approach velocity and clean-screen headloss
v_app = Q_fft / A_gross;

h_clean = 0.0729 * (V_through^2 - v_app^2);

%% 4. Grit chamber sizing

% Calculate the chamber volume required at full treatment flow
V_grit = Q_fft * t_grit;

%% 5. Primary settlement tank sizing

% Calculate the surface area required at average and peak flows
A_avg  = DWF / SOR_avg;
A_peak = FFT / SOR_peak;

% Use the larger area to satisfy both design conditions
A_req = max(A_avg, A_peak);

% Calculate the minimum diameter of each circular tank
D_req = sqrt(4 * (A_req / n_tanks) / pi);

% Round the diameter up to the next 0.5 m
D = ceil(D_req * 2) / 2;

% Calculate the total surface area provided by the tanks
A_tot = n_tanks * pi * D^2 / 4;

% Calculate the tank volume needed for the target retention time at DWF
V_req = DWF / 24 * HRT_tgt;

% Calculate the side water depth, rounded up to the next 0.1 m
depth = ceil(V_req / A_tot * 10) / 10;

% Calculate the actual overflow rates with the tanks as sized
SOR_avg_act  = DWF / A_tot;
SOR_peak_act = FFT / A_tot;

% Calculate the actual retention times at DWF and FFT
HRT_avg_act  = A_tot * depth / (DWF / 24);
HRT_peak_act = A_tot * depth / (FFT / 24);

%% 6. Loads remaining after primary treatment

% Calculate the loads entering the aeration stage
BOD_AS = BOD_load * (1 - rem_BOD);
COD_AS = COD_load * (1 - rem_COD);
SS_AS  = SS_load  * (1 - rem_SS);
TKN_AS = TKN_load * (1 - rem_TKN);

% Assume ammonium nitrogen is unchanged during primary treatment
NH4_AS = NH4_load;

% Calculate the dry solids removed as primary sludge
SS_sludge = SS_load * rem_SS;

% Convert loads in kg/d to concentrations in mg/L
conc = @(load) load * 1000 / DWF;

%% 7. Display design results
fprintf('\nSCREENS\n');
fprintf('Clear open area          : %.3f m2\n', A_open);
fprintf('Gross submerged area     : %.3f m2\n', A_gross);
fprintf('Approach velocity        : %.2f m/s\n', v_app);
fprintf('Clean headloss           : %.3f m\n', h_clean);

fprintf('\nGRIT CHAMBER\n');
fprintf('Required volume at FFT   : %.1f m3\n', V_grit);

fprintf('\nPRIMARY SETTLEMENT TANKS\n');
fprintf('Area required (DWF / FFT): %.0f / %.0f m2\n', A_avg, A_peak);
fprintf('Number of tanks          : %d\n', n_tanks);
fprintf('Tank diameter            : %.1f m\n', D);
fprintf('Side water depth         : %.1f m\n', depth);
fprintf('Overflow rate (DWF / FFT): %.1f / %.1f m3/m2/d\n', ...
    SOR_avg_act, SOR_peak_act);
fprintf('Retention time (DWF/FFT) : %.2f / %.2f h\n', ...
    HRT_avg_act, HRT_peak_act);
fprintf('Primary sludge solids    : %.0f kg/d\n', SS_sludge);

fprintf('\nTO AERATION STAGE\n');
fprintf('Parameter    Load (kg/d)    Concentration (mg/L)\n');
fprintf('BOD          %8.0f          %8.0f\n', BOD_AS, conc(BOD_AS));
fprintf('COD          %8.0f          %8.0f\n', COD_AS, conc(COD_AS));
fprintf('SS           %8.0f          %8.0f\n', SS_AS, conc(SS_AS));
fprintf('TKN          %8.0f          %8.1f\n', TKN_AS, conc(TKN_AS));
fprintf('NH4-N        %8.0f          %8.0f\n', NH4_AS, conc(NH4_AS));

%% 8. Save results for the next stage
save('primary_results.mat');

