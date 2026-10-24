clear;
clc;

%% 1. Input data from primary treatment

Q      = 10000;   % Dry weather flow (m3/d)
BOD_AS = 2100;    % BOD5 entering the aeration tank (kg/d)
SS_AS  = 1500;    % Suspended solids entering the aeration tank (kg/d)
TKN_AS = 585;     % Total Kjeldahl nitrogen entering the tank (kg N/d)

%% 2. Design assumptions and parameters

T_design = 10;    % Winter design temperature (degC)
T_vec    = 8:2:20; % Temperatures considered (degC)

% Nitrification parameters
mu_n15 = 0.50;    % Nitrifier growth rate at 15 degC (1/d)
DO     = 2.0;     % Dissolved oxygen concentration (mg/L)
K_o    = 1.3;     % Oxygen half-saturation constant (mg/L)
N_e    = 1.0;     % Target effluent ammonia-N concentration (mg/L)
SF     = 2.0;     % Safety factor applied to the minimum SRT

% Heterotrophic biomass parameters
bCOD_BOD = 1.47;  % Biodegradable COD/BOD5 ratio
S_e      = 5;     % Soluble bCOD remaining in the effluent (mg/L)
Y        = 0.45;  % Biomass yield (g VSS/g bCOD)
b20      = 0.10;  % Decay coefficient at 20 degC (1/d)
theta_b  = 1.04;  % Temperature correction factor for decay
f_d      = 0.15;  % Fraction of decayed biomass remaining as cell debris
VSS_TSS  = 0.85;  % Ratio of VSS to TSS in biological sludge

% Sludge concentration and inert solids
MLSS     = 4000;  % Mixed liquor suspended solids (mg/L)
MLVSS_fr = 0.75;  % Fraction of MLSS that is volatile solids
inert_fr = 0.40;  % Fraction of incoming suspended solids that is inert

% Stoichiometric coefficients
N_bio   = 0.124;  % Nitrogen content of biomass (g N/g VSS)
O2_cell = 1.42;   % Oxygen demand for biomass production (g O2/g VSS)
O2_nit  = 4.33;   % Oxygen demand for nitrification (g O2/g NH4-N)

%% 3. Calculate design values at each temperature

nT = numel(T_vec);

% Set up arrays to store the results for each temperature
SRT_min = zeros(1, nT);
SRT_des = zeros(1, nT);
Px_VSS  = zeros(1, nT);
Px_TSS  = zeros(1, nT);
V       = zeros(1, nT);
NOx     = zeros(1, nT);
Ro_C    = zeros(1, nT);
Ro_N    = zeros(1, nT);
Ro      = zeros(1, nT);

for i = 1:nT

    T = T_vec(i);

    % Calculate the nitrifier growth rate at the current temperature
    % Account for the effects of temperature, ammonia and dissolved oxygen
    f_T = exp(0.098 * (T - 15));
    K_n = 10^(0.051 * T - 1.158);

    mu_n = (mu_n15 * f_T) * (N_e / (K_n + N_e)) * (DO / (K_o + DO));

    % Calculate the minimum sludge retention time and apply the safety factor
    SRT_min(i) = 1 / mu_n;
    SRT_des(i) = SF * SRT_min(i);

    % Calculate the biodegradable COD removed from the wastewater (mg/L)
    dS = bCOD_BOD * BOD_AS * 1000 / Q - S_e;

    % Adjust the heterotrophic decay coefficient for temperature
    b = b20 * theta_b^(T - 20);

    % Estimate the net biological sludge production (kg VSS/d)
    Px_VSS(i) = Q * Y * dS / 1000 * (1 + f_d * b * SRT_des(i)) / (1 + b * SRT_des(i));

    % Add the inert solids to obtain the total sludge production (kg TSS/d)
    Px_TSS(i) = Px_VSS(i) / VSS_TSS + inert_fr * SS_AS;

    % Calculate the aeration tank volume needed for the design sludge age
    V(i) = SRT_des(i) * Px_TSS(i) / (MLSS / 1000);

    % Estimate the nitrogen oxidised during treatment (kg N/d)
    % Subtract nitrogen leaving in the biomass and effluent ammonia
    NOx(i) = TKN_AS - N_bio * Px_VSS(i) - Q * N_e / 1000;

    % Calculate the carbonaceous and nitrification oxygen demands (kg O2/d)
    Ro_C(i) = Q * dS / 1000 - O2_cell * Px_VSS(i);
    Ro_N(i) = O2_nit * NOx(i);

    % Total oxygen demand
    Ro(i) = Ro_C(i) + Ro_N(i);

end

%% 4. Results at the design temperature

% Find the results corresponding to the winter design temperature
idx = find(T_vec == T_design);

% Calculate the hydraulic retention time and food-to-microorganism ratio
HRT = V(idx) / Q * 24;
FM  = BOD_AS / (V(idx) * MLSS / 1000 * MLVSS_fr);

% Estimate the alkalinity consumed during nitrification
Alk = 7.14 * NOx(idx);

%% 5. Display the design results

fprintf('\nSLUDGE AGE FOR NITRIFICATION AT %d degC\n', T_design);
fprintf('Minimum SRT              : %.2f d\n', SRT_min(idx));
fprintf('Design SRT (SF = %.1f)    : %.1f d\n', SF, SRT_des(idx));

fprintf('\nAERATION TANK\n');
fprintf('Volume                   : %.0f m3\n', V(idx));
fprintf('Retention time at DWF    : %.1f h\n', HRT);
fprintf('F/M                      : %.3f kg BOD/kg MLVSS/d\n', FM);

fprintf('\nSLUDGE PRODUCTION\n');
fprintf('Biomass (VSS)            : %.0f kg/d\n', Px_VSS(idx));
fprintf('Total sludge (TSS)       : %.0f kg/d\n', Px_TSS(idx));

fprintf('\nOXYGEN DEMAND\n');
fprintf('Nitrogen oxidised        : %.0f kg N/d\n', NOx(idx));
fprintf('Carbonaceous             : %.0f kg O2/d\n', Ro_C(idx));
fprintf('Nitrification            : %.0f kg O2/d\n', Ro_N(idx));
fprintf('Total                    : %.0f kg O2/d\n', Ro(idx));
fprintf('Alkalinity consumed      : %.0f kg CaCO3/d (%.0f mg/L)\n', Alk, Alk * 1000 / Q);

%% 6. Compare results across the temperature range

fprintf('\nTEMPERATURE SENSITIVITY\n');
fprintf('T (C)   SRT design (d)   Volume (m3)   HRT (h)   O2 demand (kg/d)\n');

for i = 1:nT
    fprintf('%4d    %10.1f       %9.0f     %6.1f     %10.0f\n', T_vec(i), SRT_des(i), V(i), V(i) / Q * 24, Ro(i));
end

%% 7. Plot the effect of temperature on the design

figure;

% Plot the design sludge age
subplot(1, 2, 1);
plot(T_vec, SRT_des, '-o');
hold on;
plot(T_design, SRT_des(idx), 'rs', 'MarkerFaceColor', 'r');
xlabel('Temperature (degC)');
ylabel('Design sludge age (d)');
title('Sludge age for nitrification');
grid on;

% Plot the required aeration tank volume
subplot(1, 2, 2);
plot(T_vec, V, '-o');
hold on;
plot(T_design, V(idx), 'rs', 'MarkerFaceColor', 'r');
xlabel('Temperature (degC)');
ylabel('Aeration tank volume (m3)');
title('Aeration tank volume');
grid on;

% Save the figure for the design report
saveas(gcf, 'aeration_sensitivity.png');

%% 8. Save results for the next treatment stage

save('aeration_results.mat');
