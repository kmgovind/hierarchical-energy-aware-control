# Aggregated paper simulations

This directory contains the compact data and figures from the final simulation
studies reported in the paper. Large per-step trajectories, animations, and
scheduler logs are intentionally omitted.

## Monte Carlo study

- Design: 3 spatial length scales x 3 temporal length scales x 4 rated wind speeds x 7 strategies x 30 seeds
- Total: 7,560 three-hour trials
- Strategies: transect; uniform-target, adaptive, and ground-truth-target variants of BB-IPP and ergodic control
- Pairing: each environment seed and measurement-noise seed is shared across strategies within a condition
- Timing metadata checked in the saved trials: timestamped sequential filtering, 2.5 s sampling, and 5 s filter fusion

The `mc` directory contains:

- `mc_summary_all.csv`: all 252 condition-by-strategy summary rows
- `mc_adaptation_effects.csv`: adaptive-minus-uniform comparisons for both planners in all 36 environmental settings
- `mc_oracle_target_effects.csv`: ground-truth-target-minus-adaptive comparisons
- `mc_strategy_overall.csv`: equally weighted summaries across all 36 environmental settings
- `analysis.md`: concise numerical findings used in the manuscript
- `analysis.md`: a concise numerical summary of the comparisons

## Target-clarity-weight sweep

- Design: 11 values of `lambda_cd` from 0 to 0.05 in the half-domain and moving-pocket environments
- Total: 22 adaptive-ergodic diagnostic runs

The `lambda` directory contains the combined CSV plus figures for each environment. These runs are deterministic sensitivity diagnostics, so each marker is one run rather than a Monte Carlo confidence estimate.

The `figures` directory contains the four paper-ready figures regenerated from
the included aggregate data.

## Interpretation guardrails

- A higher in-target fraction means the strategy collects more measurements near the rated wind speed. It does not imply lower spatial clarity deficit, because repeated samples can remain concentrated in one portion of the interesting region.
- Ground-truth clarity deficit evaluates spatial coverage of all interesting regions. It is the appropriate common-target comparison between adaptive and non-adaptive strategies.
- Global RMSE evaluates reconstruction over the full domain, including regions that the adaptive objective may intentionally deprioritize.
- The min-max bands in the Monte Carlo sensitivity figure represent variation among the nine length-scale settings. They are not confidence intervals.
- The Monte Carlo generator and estimator use matched spatial and temporal length scales. The study tests environmental sensitivity, not estimator-kernel misspecification.
