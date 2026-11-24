#import "@preview/lilaq:0.6.0" as lq
#import "../helpers/results-common.typ": *

#let page-sizes = (25, 50, 75, 100)
#let show-spread = false // error bars on charts

// Chart layout
#let axis-margin = 1.8cm // space for y-axis label and tick numbers, per chart
#let chart-gutter = 0.5cm // gap between the two charts
#let chart-height = 7.5cm
#let legend-columns = 6
#let legend-height = 2.6cm // room reserved for the legend below the charts

// ---------- Colors ----------
#let impl-colors = (
  cpygrametl1_db: rgb("#0072B2"), // blue
  cpygrametl1_async_db: rgb("#009E73"), // green
  cpygrametl2_db: rgb("#E31A1C"), // red
  cpygrametl2_async_db: rgb("#CC79A7"), // pink
  jython1: rgb("#000000"), // black
  jython2: rgb("#7F7F7F"), // grey
  "pipeline free-threading": rgb("#6A3D9A"), // purple
  "pipeline multiprocessing": rgb("#E69F00"), // orange
  "pipeline sequential": rgb("#8C510A"), // brown
)

// ---------- Chart markers ----------
#let impl-markers = (
  cpygrametl1_db: "o", // circle
  cpygrametl1_async_db: "s", // square
  cpygrametl2_db: "^", // triangle up
  cpygrametl2_async_db: "d", // diamond
  jython1: "+", // plus
  jython2: "x", // cross
  "pipeline free-threading": "p5", // pentagon
  "pipeline multiprocessing": "v", // triangle down
  "pipeline sequential": "s5", // five-point star
)

#let group-markers = (
  "cpygrametl2_db/cpython-3.15t": "x",
  "cpygrametl1_db/cpython-3.15t": "s5",
  "cpygrametl1_async_db/cpython-3.15t": "v",
)
#let group-colors = (:
  // "cpygrametl2_db/cpython-3.15t": rgb("#B2182B"),
)

#let key-of(group) = group.at(0) + "/" + group.at(1)

#let marker-of(group) = group-markers.at(
  key-of(group),
  default: impl-markers.at(group.at(0), default: "o"),
)

#let color-of(group) = {
  let override = group-colors.at(key-of(group), default: none)
  if override != none { return override }

  let base = impl-colors.at(group.at(0), default: luma(120))
  if group.at(0).starts-with("cpygrametl") and group.at(1).ends-with("t") {
    base.lighten(45%)
  } else {
    base
  }
}

// ---------- Chart ----------
#let metric-chart(metric, y-label, width, height) = {
  let plots = groups.map(group => {
    let pages = page-sizes.filter(p => values-for(group, p, metric).len() > 0)
    let vals = pages.map(p => values-for(group, p, metric))
    let averages = vals.map(mean)
    if show-spread {
      lq.plot(
        pages,
        averages,
        yerr: vals.map(std),
        mark: marker-of(group),
        color: color-of(group),
      )
    } else {
      lq.plot(
        pages,
        averages,
        mark: marker-of(group),
        color: color-of(group),
      )
    }
  })

  lq.diagram(
    xlabel: [Page size],
    ylabel: y-label,
    legend: none,
    width: width,
    height: height,
    xaxis: (ticks: (25, 50, 75, 100), subticks: none),
    ..plots,
  )
}

#let legend-diagram(width) = {
  let plots = groups.map(group => lq.plot(
    (),
    (),
    mark: marker-of(group),
    color: color-of(group),
    label: label-of(group),
  ))

  show lq.selector(lq.legend): set grid(columns: (auto,) * legend-columns, column-gutter: 1.2em)
  show lq.selector(lq.legend): set text(size: 8pt)
  show: lq.set-grid(stroke: none)

  lq.diagram(
    width: width,
    height: legend-height,
    xaxis: none,
    yaxis: none,
    legend: (position: top + center),
    ..plots,
  )
}

#figure(
  layout(size => {
    let w = (size.width - chart-gutter) / 2 - axis-margin

    stack(
      dir: ttb,
      spacing: 0.8em,
      {
        show: lq.layout
        grid(
          columns: 2,
          column-gutter: chart-gutter,
          metric-chart("wall_seconds", [Execution time (s)], w, chart-height),
          metric-chart("cpu_seconds", [CPU time (s)], w, chart-height),
        )
      },
      legend-diagram(size.width),
    )
  }),
  placement: top,
  scope: "parent",
  caption: [Mean execution time (left) and mean total CPU time (right) by page size.],
) <fig:time>
