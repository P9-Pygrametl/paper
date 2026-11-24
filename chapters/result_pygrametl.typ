#import "@preview/lilaq:0.6.0" as lq

#let csv-path = "../results/merged.csv"
#let page-sizes = (25, 50, 75, 100)
#let only-valid = true
#let show-spread = false // error bars on charts
#let table-spread = true // "mean ± std" in the table

// Table settings
#let table-page = 100
#let baseline = ("cpygrametl1_db", "cpython-3.15") // raw CSV names

// Chart layout
#let axis-margin = 1.8cm // space for y-axis label and tick numbers, per chart
#let chart-gutter = 0.5cm // gap between the two charts
#let chart-height = 7.5cm
#let legend-columns = 6
#let legend-height = 2.6cm // room reserved for the legend below the charts

// ---------- Display names ----------
// Raw CSV name -> name shown in charts and tables. Unlisted names are shown as-is.
#let impl-names = (
  cpygrametl1_db: "sequential",
  cpygrametl1_async_db: "sequential async",
  cpygrametl2_db: "multiprocessing",
  cpygrametl2_async_db: "multiprocessing async",
  jython1: "jython sequential",
  jython2: "jython multiprocessing",
)

#let impl-name(name) = impl-names.at(name, default: name)
#let runtime-name(runtime) = runtime.replace("cpython-", "")

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

#let marker-of(group) = impl-markers.at(group.at(0), default: "o")

#let color-of(group) = {
  let base = impl-colors.at(group.at(0), default: luma(120))
  if group.at(0).starts-with("cpygrametl") and group.at(1).ends-with("t") {
    base.lighten(45%)
  } else {
    base
  }
}

// ---------- Data ----------
#let raw-data = csv(csv-path, row-type: dictionary)

#let rows = raw-data.filter(row => (
  not only-valid or (row.valid == "1" and row.returncode == "0")
))

#let groups = {
  let g = ()
  for row in rows {
    let group = (row.implementation, row.runtime)
    if not g.contains(group) { g.push(group) }
  }
  g.sorted(key: group => (impl-name(group.at(0)), runtime-name(group.at(1))))
}

// ---------- Helpers ----------
#let mean(v) = v.sum() / v.len()

#let std(v) = {
  let m = mean(v)
  calc.sqrt(v.map(x => calc.pow(x - m, 2)).sum() / calc.max(v.len() - 1, 1))
}

#let values-for(group, page, metric) = {
  rows
    .filter(r => (
      r.implementation == group.at(0) and r.runtime == group.at(1) and int(r.pages) == page and r.at(metric) != ""
    ))
    .map(r => float(r.at(metric)))
}

#let label-of(group) = [#impl-name(group.at(0)) / #runtime-name(group.at(1))]

#let fmt(v, d: 1) = str(calc.round(v, digits: d))

// ---------- Charts ----------
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

// ---------- Summary table ----------
#let metric-cell(group, metric, d: 1) = {
  let v = values-for(group, table-page, metric)
  if v.len() == 0 {
    [–]
  } else if table-spread {
    [#fmt(mean(v), d: d) ± #fmt(std(v), d: d)]
  } else {
    [#fmt(mean(v), d: d)]
  }
}

#let speedup-cell(group) = {
  let base = values-for(baseline, table-page, "wall_seconds")
  let v = values-for(group, table-page, "wall_seconds")
  if base.len() == 0 or v.len() == 0 {
    [–]
  } else {
    [#fmt(mean(base) / mean(v), d: 2)]
  }
}

#let summary-table() = {
  let body = groups
    .map(group => (
      [#impl-name(group.at(0))],
      [#runtime-name(group.at(1))],
      metric-cell(group, "wall_seconds"),
      speedup-cell(group),
      metric-cell(group, "peak_pss_mb", d: 0),
      metric-cell(group, "cpu_percent", d: 0),
    ))
    .flatten()

  set text(size: 10pt)
  table(
    columns: (1fr, auto, auto, auto, auto, auto),
    align: (left, left, right, right, right, right),
    inset: (x: 4pt, y: 3pt),
    table.header[*Implementation*][*Runtime*][*Time (s)*][*Speedup (×)*][*Peak PSS (MB)*][*CPU util. (%)*],
    ..body,
  )
}

// ---------- Figures ----------
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
  caption: [Mean execution time (left) and mean total CPU time (right) by page size. Spread is given in @tab:summary.],
) <fig:time>

#figure(
  summary-table(),
  placement: top,
  scope: "parent", // spans both columns
  caption: [
    Results at page size #table-page (mean ± sample standard deviation over
    30 runs). Speedup is the ratio of mean execution times relative to
    #label-of(baseline). Peak PSS is the peak proportional set
    size. CPU utilisation is relative to one core (100% = one fully used core).
  ],
) <tab:summary>

//At 100 pages, the sequential CPython baseline takes 113.6 s. Multiprocessing reduces this to 55.5 s, and multiprocessing with asynchronous extraction takes 52.9 s. The corresponding free-threaded multiprocessing variants take 46.4 s and 44.5 s. These results show that asynchronous extraction alone does not shorten the sequential workflow materially; its improvement is modest when combined with multiprocessing. Free-threaded workers reduce execution time further, but the additional speed comes with greater CPU use and memory consumption than the sequential baseline.

//The largest gains come from reducing database round trips. Pipeline mode brings the sequential workflow to 36.8 s, and combining it with multiprocessing and free-threading reduces execution time to 22.8 s and 17.5 s, respectively. The next section examines these pipeline results in detail, including the reliability issue observed in the free-threaded variant.

//The results support the distinction between worker parallelism and database wait time. At 100 pages, pipelining reduces sequential execution time from 113.6 s to 36.8 s, about a 3.1x speedup, while total CPU time falls from 44.7 s to 31.9 s. This indicates that the sequential gain comes from doing less waiting, not from using more CPU. Adding multiprocessing reduces wall time to 22.8 s; using free-threaded workers reduces it to 17.5 s, about 6.5x faster than the sequential baseline. These parallel pipeline variants use about 1.6 and 1.5 times the baseline CPU time, respectively, in exchange for lower wall time.

//The pipelined variants scale approximately linearly with page count. Their speedups are largest at 25 pages and taper slightly by 100 pages. Results are also less variable than the baseline, whose standard deviation at 100 pages is 12.1 s, compared with less than 0.3 s for each pipelined variant. However, three of the 120 `Pipeline free-threading` runs failed with segmentation faults, one each at page sizes 50, 75, and 100; these runs are excluded from the reported means. The speedup is therefore promising, but the observed crashes mean that this variant is not yet reliable.

