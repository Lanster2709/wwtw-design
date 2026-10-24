# Preliminary design of a 50,000 PE activated sludge wastewater treatment works

Built in October 2026 to learn wastewater process design. This is a preliminary, textbook-based design to teach myself the method, not a site design. Every input is labelled in the workbook as a definition, a standard limit, a sourced typical value, or an assumption.

## Status

Complete:
- Design basis (flows, loads, discharge consents)
- Inlet works and primary treatment sizing
- Aeration tank design with nitrification and a temperature sensitivity study
- Secondary clarifier design with a sludge settleability (SVI) sensitivity study

To follow: oxygen supply and energy use, costing and whole-life cost, and (if time allows) a dynamic check.

## Contents

- `WWTW_Design.xlsx`: design basis (Inputs sheet) and the sources, status and limitations of every parameter (Notes sheet)
- `matlab/inlet_and_primary_sizing.m`: screens, grit chamber and primary settlement tanks
- `matlab/aeration_tank_design.m`: sludge age, tank volume, sludge production and oxygen demand, with a temperature sweep
- `matlab/secondary_clarifier_design.m`: clarifier area from overflow rate and solids loading, sludge return and wasting, with an SVI sweep
- `docs/`: figures

## Design basis

50,000 population equivalent, dry weather flow 10,000 m3/d, flow to full treatment 25,000 m3/d, winter design temperature 10 degC. Discharge limits: BOD5 25 mg/L, COD 125 mg/L and suspended solids 35 mg/L (EU Urban Waste Water Treatment Directive); ammonia-N 5 mg/L (an assumption).

## Key results

- Primary treatment: 2 tanks of 13.0 m diameter and 3.2 m depth, removing 30% of BOD and 60% of suspended solids, which cuts the BOD load on the aeration tank from 3,000 to 2,100 kg/d.
- Aeration tank: design sludge age 13.2 days at 10 degC, volume 5,159 m3, retention time 12.4 h, oxygen demand about 3,900 kg O2/d, roughly half of it for nitrification.
- Cold weather sets the tank size: the required volume is about 5,900 m3 at 8 degC and about 2,900 m3 at 20 degC.
- Secondary clarifiers: 2 tanks of 19.5 m diameter. Solids loading at peak flow sets the size, not the overflow rate.
- The clarifiers as sized work only up to a sludge volume index of about 105 mL/g. A bulking sludge (SVI 150) would need about 24% more area.

## Figures

![Load before and after primary treatment](docs/primary_loads.png)

![Effect of temperature on sludge age and tank volume](docs/aeration_sensitivity.png)

![Clarifier area against sludge settleability](docs/clarifier_svi_sensitivity.png)

## Limitations

- Design criteria come mainly from lecture notes, course notes and one existing plant's design basis, not from UK design standards.
- Nitrifier biomass growth, nitrite, soluble organic nitrogen and denitrification are not modelled.
- Alkalinity supply is not checked.
- Cost, energy and dynamic behaviour are still to be added.
