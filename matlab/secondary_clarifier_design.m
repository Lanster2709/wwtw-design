%% Secondary clarifier design

clear;
clc;

%% 1. Input data from the previous design stages

DWF    = 10000;   % Dry weather flow (m3/d)
FFT    = 25000;   % Flow to full treatment (m3/d)
MLSS   = 4000;    % Sludge concentration in the aeration tank (mg/L)
Px_TSS = 1564;    % Total sludge production (kg TSS/d)
V_aer  = 5159;    % Aeration tank volume (m3)
SRT    = 13.2;    % Design sludge age (d)

%% 2. Design assumptions

SVI      = 100;   % Sludge volume index (mL/g)
SOR_avg  = 24;    % Surface overflow rate at DWF (m3/m2/d)
SOR_peak = 44;    % Surface overflow rate at FFT (m3/m2/d)
SLR_avg  = 144;   % Solids loading rate at DWF (kg/m2/d)
SLR_peak = 216;   % Solids loading rate at FFT (kg/m2/d)
WL_max   = 375;   % Maximum allowable weir loading (m3/m/d)
n_tanks  = 2;     % Number of circular clarifiers
depth    = 4.0;   % Side water depth (m)

%% 3. Calculate the return sludge flow

% Estimate the return sludge concentration from the SVI
Xr = 1e6 / SVI;

% Calculate the return sludge ratio
R = MLSS / (Xr - MLSS);

% Calculate the return flow using the dry weather flow
Qr = R * DWF;

%% 4. Calculate the required clarifier area

% Area required to meet the surface overflow rate limits
A_sor_avg  = DWF / SOR_avg;
A_sor_peak = FFT / SOR_peak;

% Area required to meet the solids loading rate limits
A_slr_avg  = (DWF + Qr) * MLSS / 1000 / SLR_avg;
A_slr_peak = (FFT + Qr) * MLSS / 1000 / SLR_peak;

% Compare the four area requirements
A_all = [A_sor_avg, A_sor_peak, A_slr_avg, A_slr_peak];

names = {'SOR at DWF', 'SOR at FFT', 'SLR at DWF', 'SLR at FFT'};

% The largest area determines the clarifier design
[A_req, g] = max(A_all);

%% 5. Determine the clarifier dimensions

% Calculate the minimum diameter required for each tank
D_req = sqrt(4 * (A_req / n_tanks) / pi);

% Round the diameter up to the next 0.5 m
D = ceil(D_req * 2) / 2;

% Calculate the total area and volume provided
A_tot  = n_tanks * pi * D^2 / 4;
V_clar = A_tot * depth;

% Check the actual surface overflow rates
SOR_avg_act  = DWF / A_tot;
SOR_peak_act = FFT / A_tot;

% Check the actual solids loading rates
SLR_avg_act  = (DWF + Qr) * MLSS / 1000 / A_tot;
SLR_peak_act = (FFT + Qr) * MLSS / 1000 / A_tot;

% Calculate the total weir length around the tanks
L_weir = n_tanks * pi * D;

% Calculate the weir loading at average and peak flows
WL_avg  = DWF / L_weir;
WL_peak = FFT / L_weir;

%% 6. Calculate sludge wasting rates

% Calculate the sludge wasting flow from the return line
Qw_ras = Px_TSS / (Xr / 1000);

% Estimate the wasting flow from the aeration tank
Qw_tank = V_aer / SRT;

% Calculate the solids removed through tank wasting
M_tank = Qw_tank * MLSS / 1000;

%% 7. Check the effect of different SVI values

% Calculate the required area for a given SVI
% The return sludge ratio changes as the SVI changes
area_needed = @(svi) max([DWF / SOR_avg, FFT / SOR_peak, (DWF + MLSS / (1e6 / svi - MLSS) * DWF) * MLSS / 1000 / SLR_avg, (FFT + MLSS / (1e6 / svi - MLSS) * DWF) * MLSS / 1000 / SLR_peak]);

% Calculate the area requirement at selected SVI values
SVI_vec = 80:10:150;
nS = numel(SVI_vec);

A_need = zeros(1, nS);
R_vec  = zeros(1, nS);

for i = 1:nS

    A_need(i) = area_needed(SVI_vec(i));

    % Calculate the return sludge ratio at this SVI
    R_vec(i) = MLSS / (1e6 / SVI_vec(i) - MLSS);

end

% Use smaller SVI increments to estimate the maximum acceptable SVI
SVI_fine = 80:0.5:150;
A_fine = arrayfun(area_needed, SVI_fine);

% Find the highest tested SVI for which the provided area is sufficient
SVI_limit = SVI_fine(find(A_fine <= A_tot, 1, 'last'));

%% 8. Display the design results

fprintf('\nRETURN SLUDGE (SVI = %d mL/g)\n', SVI);
fprintf('Return concentration: %.0f mg/L\n', Xr);
fprintf('Return ratio: %.3f\n', R);
fprintf('Return flow: %.0f m3/d\n', Qr);

fprintf('\nAREA REQUIRED (m2)\n');

for k = 1:4
    fprintf('%-5s: %.1f\n', names{k}, A_all(k));
end

fprintf('Governing: %s\n', names{g});

fprintf('\nCLARIFIERS\n');
fprintf('Number of tanks: %d\n', n_tanks);
fprintf('Tank diameter: %.1f m\n', D);
fprintf('Side water depth: %.1f m\n', depth);
fprintf('Total area / volume: %.1f m2 / %.0f m3\n', A_tot, V_clar);

fprintf('Overflow rate (DWF/FFT): %.1f / %.1f m3/m2/d\n', SOR_avg_act, SOR_peak_act);

fprintf('Solids loading (DWF/FFT): %.1f / %.1f kg/m2/d\n', SLR_avg_act, SLR_peak_act);

fprintf('Weir loading (DWF/FFT): %.1f / %.1f m3/m/d (limit %d)\n', WL_avg, WL_peak, WL_max);

fprintf('\nSLUDGE WASTING\n');
fprintf('From return line: %.1f m3/d\n', Qw_ras);
fprintf('From aeration tank: %.1f m3/d (%.0f kg/d)\n', Qw_tank, M_tank);

fprintf('\nSVI SENSITIVITY\n');
fprintf('SVI (mL/g) Return ratio Area needed (m2)\n');

for i = 1:nS
    fprintf('%6d %8.2f %10.0f\n', SVI_vec(i), R_vec(i), A_need(i));
end

fprintf('Area provided works up to SVI of about %.1f mL/g\n', SVI_limit);

%% 9. Plot the effect of SVI on clarifier area

figure;

plot(SVI_vec, A_need, '-o');
hold on;

% Show the total area provided by the designed clarifiers
plot([SVI_vec(1) SVI_vec(end)], [A_tot A_tot], 'r--');

xlabel('SVI (mL/g)');
ylabel('Clarifier area needed (m2)');
legend('Area needed', 'Area provided', 'Location', 'northwest');
title('Clarifier area against sludge settleability');
grid on;

% Save the figure for the design report
saveas(gcf, 'clarifier_svi_sensitivity.png');

%% 10. Save results for the next treatment stage

save('clarifier_results.mat');
