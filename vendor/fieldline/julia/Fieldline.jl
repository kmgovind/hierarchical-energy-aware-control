"""
    Fieldline

Loads the shared color/type system from ../palette.yaml (this repo's single
source of truth — never hardcode colors here) and exposes it to Makie and
Plots.jl.

Usage (Makie / CairoMakie, e.g. for publication figures):

    include("Fieldline.jl")
    using .Fieldline
    using CairoMakie
    set_theme!(; Fieldline.makie_theme()...)

    fig = Figure()
    ax = Axis(fig[1, 1])
    for (i, series) in enumerate(results)
        lines!(ax, series.t, series.value; color = Fieldline.categorical(i), label = series.name)
    end
    # value-function heatmap (perceptually-uniform, defaults to cividis):
    heatmap!(ax2, x, y, V; colormap = Fieldline.sequential(scientific = true))
    # residual/error field:
    heatmap!(ax3, x, y, V .- V_true; colormap = Fieldline.diverging(), colorrange = (-m, m))

Usage (Plots.jl):

    include("Fieldline.jl")
    using .Fieldline
    using Plots
    Fieldline.apply_plots_defaults!()   # or apply_plots_defaults!(mode = :dark)
    plot(x, y, color = Fieldline.categorical(1))
"""
module Fieldline

using YAML
using Colors
using PlotUtils: cgrad
using ColorSchemes

const _PALETTE_PATH = joinpath(@__DIR__, "..", "palette.yaml")
const PALETTE = YAML.load_file(_PALETTE_PATH)

# ---------------------------------------------------------------------
# Categorical accessors
# ---------------------------------------------------------------------
const CATEGORICAL_ORDER = Symbol.(PALETTE["categorical"]["order"])
const CATEGORICAL_HEX = Dict(
    Symbol(k) => v["hex"] for (k, v) in PALETTE["categorical"]["colors"]
)

"""
    categorical(i::Int) -> Colors.RGB
    categorical(name::Symbol) -> Colors.RGB

Get the i-th categorical color (1-indexed, wraps and cycles through the
8-color order), or fetch by name (e.g. `:cobalt`).
"""
categorical(i::Integer) = parse(Colorant, CATEGORICAL_HEX[CATEGORICAL_ORDER[mod1(i, length(CATEGORICAL_ORDER))]])
categorical(name::Symbol) = parse(Colorant, CATEGORICAL_HEX[name])
categorical_palette() = [categorical(i) for i in 1:length(CATEGORICAL_ORDER)]

# ---------------------------------------------------------------------
# Sequential / diverging colormaps -> Makie/Plots-compatible gradients
# ---------------------------------------------------------------------
function _stops_to_colormap(stops; normalize = false)
    ats = Float64[s["at"] for s in stops]
    if normalize
        lo, hi = extrema(ats)
        ats = (ats .- lo) ./ (hi - lo)
    end
    cols = [parse(Colorant, s["hex"]) for s in stops]
    return cgrad(cols, ats)
end

"""
    sequential(; name = "field_blue", scientific = false, scheme = :cividis)

Brand sequential colormap for simple one-variable heatmaps/density plots.

Pass `scientific = true` for value-function surfaces or anything read
quantitatively off the color, which returns an established
perceptually-uniform, colorblind-safe map from ColorSchemes.jl instead of
the brand ramp. Default is `:cividis` — its blue→gray→yellow path echoes
`cobalt`/`amber`/`citrine` and, importantly, never passes through green,
so it stays visually distinct from the `emerald` categorical color when
both appear in the same figure (e.g. a trajectory line over a value
surface). Pass `scheme = :batlow` instead for standalone panels with no
categorical overlay, where batlow's longer blue→green→olive→tan ramp can
aid reading fine gradients — but avoid it when `emerald` is also on the
plot, since batlow's green midtone sits close to it.
"""
function sequential(; name = "field_blue", scientific = false, scheme::Symbol = :cividis)
    if scientific
        return scheme === :cividis ? ColorSchemes.cividis :
               scheme === :batlow ? ColorSchemes.batlow :
               error("scientific sequential scheme must be :cividis or :batlow, got $scheme")
    end
    stops = PALETTE["sequential"][name]["stops"]
    return _stops_to_colormap(stops)
end

"""
    diverging(; name = "cobalt_vermilion")

Diverging colormap for signed fields (residuals, errors, advantage
functions), symmetric about zero. Pair with `colorrange = (-m, m)` so
zero lands exactly on the neutral midpoint.
"""
function diverging(; name = "cobalt_vermilion")
    stops = PALETTE["diverging"][name]["stops"]
    return _stops_to_colormap(stops; normalize = true)
end

# ---------------------------------------------------------------------
# Neutrals
# ---------------------------------------------------------------------
neutral(mode::Symbol, key::Symbol) = parse(Colorant, PALETTE["neutral"][string(mode)][string(key)])

# ---------------------------------------------------------------------
# Makie theme
# ---------------------------------------------------------------------
"""
    makie_theme(; mode = :light)

Returns a NamedTuple of Makie theme attributes wired to the Fieldline
palette. Fieldline deliberately does NOT depend on Makie itself (so this
file works whether you're using CairoMakie, GLMakie, or just Plots.jl) —
you splat the result into `set_theme!` yourself, after `using Makie` (or
CairoMakie/GLMakie) is already in scope:

    using CairoMakie
    set_theme!(; Fieldline.makie_theme()...)
"""
function makie_theme(; mode::Symbol = :light)
    bg = neutral(mode, :background)
    panel = neutral(mode, :panel)
    grid = neutral(mode, :grid)
    axiscol = neutral(mode, :axis)
    text = neutral(mode, :text)
    strokes = PALETTE["strokes"]
    sans = PALETTE["typography"]["sans"]["family"]

    return (
        backgroundcolor = bg,
        palette = (color = categorical_palette(),),
        fontsize = 14,
        font = sans,
        Axis = (
            backgroundcolor = panel,
            xgridcolor = grid,
            ygridcolor = grid,
            xgridwidth = strokes["grid_width_pt"],
            ygridwidth = strokes["grid_width_pt"],
            spinewidth = strokes["axis_width_pt"],
            xtickcolor = axiscol,
            ytickcolor = axiscol,
            xlabelcolor = text,
            ylabelcolor = text,
            xticklabelcolor = text,
            yticklabelcolor = text,
            titlecolor = text,
            leftspinecolor = axiscol,
            bottomspinecolor = axiscol,
            rightspinecolor = (:black, 0),
            topspinecolor = (:black, 0),
        ),
        Legend = (
            backgroundcolor = panel,
            framecolor = grid,
            labelcolor = text,
        ),
        Lines = (linewidth = strokes["line_width_pt"],),
        Scatter = (markersize = strokes["marker_size_pt"],),
    )
end

# ---------------------------------------------------------------------
# Plots.jl defaults
# ---------------------------------------------------------------------
"""
    apply_plots_defaults!(; mode = :light)

Applies the Fieldline palette to Plots.jl via `Plots.default(...)`, the
stable documented API for setting global plot defaults (deliberately NOT
using PlotThemes' internal `PlotTheme` struct, whose field names shift
between versions). Call once per session, before making plots:

    using Plots
    Fieldline.apply_plots_defaults!()
"""
function apply_plots_defaults!(; mode::Symbol = :light)
    Main.Plots.default(
        background_color = neutral(mode, :background),
        background_color_inside = neutral(mode, :panel),
        foreground_color_grid = neutral(mode, :grid),
        foreground_color_axis = neutral(mode, :axis),
        foreground_color_text = neutral(mode, :text),
        foreground_color_guide = neutral(mode, :text),
        foreground_color_legend = neutral(mode, :text),
        palette = categorical_palette(),
        linewidth = PALETTE["strokes"]["line_width_pt"],
        markersize = PALETTE["strokes"]["marker_size_pt"],
        fontfamily = PALETTE["typography"]["sans"]["family"],
    )
end

export categorical, categorical_palette, sequential, diverging, neutral,
       makie_theme, apply_plots_defaults!

end # module
