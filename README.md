# Adaptive Ocean Exploration Simulations

Simulation code and compact result summaries accompanying **“Clarity-Driven
Adaptive Mission Planning for a Solar-Powered Autonomous Surface Vessel.”**

The repository implements the spatiotemporal Gaussian-process Kalman filter,
clarity-based target adaptation, ergodic and branch-and-bound informative path
planners, transect baselines, state-of-charge speed control, and the diagnostic
and Monte Carlo studies reported in the paper.

## Repository contents

- `src/`: simulation, estimation, planning, boundary handling, and energy models.
- `revision_sims/`: paper-study runners, aggregation utilities, plotting scripts,
  and portable Slurm templates.
- `results/paper/`: compact CSV summaries and paper-ready plots from the final
  revision studies. Full per-step trajectories and videos are intentionally not
  stored in Git.
- `test/`: timing, target-update, boundary, and metric regression tests.
- `vendor/fieldline/`: the MIT-licensed plotting palette used by the paper figures.

## Requirements

- Julia 1.11 or a later Julia 1.x release.
- Python 3 for the compact Monte Carlo aggregation utility.
- FFmpeg, available on `PATH`, when generating MP4 animations.
- A Slurm cluster only for the optional batch scripts.

## Setup

```bash
git clone https://github.com/dasc-lab/adaptive-ocean-exploration-sim.git
cd adaptive-ocean-exploration-sim
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

The committed `Manifest.toml` records the environment used for the public
release. To validate the installation:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Reproduce the paper summaries and figures

The final aggregate data are already included, so regenerating the summary
plots does not require rerunning thousands of trials:

```bash
julia --project=. revision_sims/plot_tcst_simulation_figures.jl generated_figures .
```

The generated files are written to `generated_figures/`. See
[`REPRODUCIBILITY.md`](REPRODUCIBILITY.md) for the study configurations,
output structure, local commands, and Slurm workflow.

## Run the simulations

Run the static half-domain diagnostic locally:

```bash
julia --project=. revision_sims/run_half_domain_sim.jl \
  --nworkers 7 \
  --outdir revision_sims/results/half_domain
```

Run the moving-pocket diagnostic:

```bash
julia --project=. revision_sims/run_single_env_comparison.jl \
  --nworkers 6 \
  --outdir revision_sims/results/moving_pockets
```

Run the Monte Carlo grid using the available local CPUs:

```bash
bash revision_sims/run_mc_comparison.sh
```

These studies are computationally intensive. The local commands preserve the
paper defaults; use the command-line options documented at the top of each
runner for shorter exploratory runs.

## Data policy

Only the aggregate statistics required to reconstruct the reported plots and
tables are versioned. Raw JLD2 trajectories, videos, logs, and scheduler output
are generated artifacts and are excluded by `.gitignore`.

## Citation

Use the metadata in [`CITATION.cff`](CITATION.cff) when citing this software.
Publication identifiers can be added there when the final IEEE record is
available.

## Contact

For questions about the code or study configuration, open a GitHub issue.

