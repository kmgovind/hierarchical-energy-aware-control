# Reproducibility guide

## Final studies

The paper uses three simulation studies:

1. **Static half-domain diagnostic.** The bounded Jordan Lake domain is split
   into equal navigable areas. One half contains the rated wind speed and the
   other contains a strongly off-target wind speed.
2. **Moving-pocket diagnostic.** Localized regions of near-rated wind evolve
   over time, exposing the planners' exploration and exploitation behavior.
3. **Monte Carlo sensitivity study.** Thirty paired seeds are evaluated at each
   combination of four rated normalized wind speeds, three spatial correlation
   scales, three temporal correlation scales, and seven strategies.

Every strategy within a Monte Carlo condition receives the same environmental
and measurement-noise seed. The generator and estimator use matched spatial
and temporal scales in this study.

## Included results

`results/paper/mc/` contains the 252 condition-by-strategy summary rows and the
derived adaptive-minus-uniform and ground-truth-target comparisons.

`results/paper/lambda/` contains the coarse comparison sweep, the fine
target-selectivity sweep, and the corresponding summary figures. The `source`
column is intentionally blank because the large raw trial directories are not
part of the public repository.

The min-max bands in the Monte Carlo figure show variation across the nine
spatial/temporal scale settings. They are not confidence intervals.

## Figure regeneration

Regenerate the figures that depend only on the compact aggregates:

```bash
julia --project=. revision_sims/plot_tcst_simulation_figures.jl generated_figures .
```

The environment snapshots and trajectory-concentration diagnostic require raw
trial files. The plotting script detects their absence and skips those outputs
when operating on the public aggregate data.

## Local runs

Each Julia runner accepts `--outdir` and `--srcdir`; diagnostic runners also
accept mission duration, random seed, estimator scales, target selectivity, and
a comma-separated strategy list. Run a script with an unknown option to see its
accepted option names and defaults near the top of the resulting stack trace,
or inspect its `parse_args` function.

For a short installation check that exercises the full half-domain path:

```bash
julia --project=. revision_sims/run_half_domain_sim.jl \
  --nworkers 0 \
  --duration_minutes 5 \
  --strategies transect \
  --animation_seconds 2 \
  --animation_fps 2 \
  --outdir revision_sims/results/smoke
```

## Slurm runs

The `.sbatch` files are portable templates. Scheduler account and partition
directives are deliberately omitted because they are site-specific. Set these
environment variables as needed:

- `REPO_ROOT`: absolute path to the checkout. Defaults to the submission
  directory, with automatic handling when submitted from `revision_sims/`.
- `RESULTS_ROOT`: absolute output root. Defaults to
  `revision_sims/results/` in the checkout.
- `JULIA_MODULE`: module name to load on clusters that provide environment
  modules. Defaults to `julia/1.11.4`.

Example:

```bash
RESULTS_ROOT=/path/to/scratch/results \
  sbatch revision_sims/run_mc_comparison.sbatch
```

The Monte Carlo job is a 36-element array, one element for each combination of
spatial scale, temporal scale, and rated wind speed. Each array element runs all
seeds for its assigned condition and writes compact summaries in addition to
the raw trials.

## Numerical interpretation

- Higher in-target fraction means that more measurements were collected near
  the rated wind speed.
- Lower ground-truth-target clarity deficit means the achieved spatial clarity
  better matches the common ground-truth target.
- Lower global RMSE means better reconstruction over the complete domain.

These metrics measure different objectives; improvement in one does not imply
improvement in the others.

