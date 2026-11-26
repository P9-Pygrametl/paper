#import "@preview/lilaq:0.6.0" as lq
#import "../helpers/results-common.typ": *

#let scaling-path = "../results/scaling.csv"
#let page-size = 100
#let core-counts = (1, 2, 4, 8)

#let raw-data = csv(scaling-path, row-type: dictionary)

#let rows = raw-data.filter(row => (
  row.valid == "1" and row.returncode == "0" and int(row.pages) == page-size
))

#let impl-colors = (
  cpygrametl1_db: rgb("#0072B2"),
  cpygrametl1_async_db: rgb("#009E73"),
  cpygrametl2_db: rgb("#E31A1C"),
  cpygrametl2_async_db: rgb("#CC79A7"),
  jython1: rgb("#000000"),
  jython2: rgb("#7F7F7F"),
  "pipeline free-threading": rgb("#6A3D9A"),
  "pipeline multiprocessing": rgb("#E69F00"),
  "pipeline sequential": rgb("#8C510A"),
)

#let impl-markers = (
  cpygrametl1_db: "o",
  cpygrametl1_async_db: "s",
  cpygrametl2_db: "^",
  cpygrametl2_async_db: "d",
  jython1: "+",
  jython2: "x",
  "pipeline free-threading": "p5",
  "pipeline multiprocessing": "v",
  "pipeline sequential": "s5",
)

#let group-markers = (
  "cpygrametl2_db/cpython-3.15t": "x",
  "cpygrametl1_db/cpython-3.15t": "s5",
  "cpygrametl1_async_db/cpython-3.15t": "v",
)

#let key-of(group) = group.at(0) + "/" + group.at(1)

#let marker-of(group) = group-markers.at(
  key-of(group),
  default: impl-markers.at(group.at(0), default: "o"),
)

#let color-of(group) = {
  let base = impl-colors.at(group.at(0), default: luma(120))
  if group.at(0).starts-with("cpygrametl") and group.at(1).ends-with("t") {
    base.lighten(45%)
  } else {
    base
  }
}

#let all-groups = {
  let result = ()
  for row in rows {
    let group = (row.implementation, row.runtime)
    if not result.contains(group) { result.push(group) }
  }
  result.sorted(key: group => (group-name(group), runtime-name(group.at(1))))
}

// All implementation/runtime combinations from the scaling results.
#let chart-groups = all-groups

#let values-for(group, cores, metric) = {
  rows
    .filter(row => (
      row.implementation == group.at(0)
        and row.runtime == group.at(1)
        and int(row.cores) == cores
        and row.at(metric) != ""
    ))
    .map(row => float(row.at(metric)))
}

#let mean(values) = {
  if values.len() == 0 { return none }
  values.sum() / values.len()
}

#let std(values) = {
  if values.len() == 0 { return none }
  let m = mean(values)
  calc.sqrt(
    values.map(x => calc.pow(x - m, 2)).sum() / calc.max(values.len() - 1, 1),
  )
}

#let fmt(value, d: 1) = {
  if value == none { return [–] }
  str(calc.round(value, digits: d))
}

#let metric-cell(group, cores) = {
  let v = values-for(group, cores, "wall_seconds")
  if v.len() == 0 {
    [-]
  } else {
    [#fmt(mean(v)) ± #fmt(std(v))]
  }
}

#let speedup-of(group, cores) = {
  let base = mean(values-for(group, 1, "wall_seconds"))
  let value = mean(values-for(group, cores, "wall_seconds"))
  if base == none or value == none { none } else { base / value }
}

#let speedup-cell(group, cores) = {
  let speedup = speedup-of(group, cores)
  if speedup == none {
    [-]
  } else {
    [#fmt(speedup, d: 2) ×]
  }
}

#let scaling-table() = {
  let body = all-groups
    .map(group => (
      [#impl-name(group.at(0))],
      [#runtime-name(group.at(1))],
      metric-cell(group, 1),
      metric-cell(group, 2),
      metric-cell(group, 4),
      metric-cell(group, 8),
      speedup-cell(group, 8),
    ))
    .flatten()

  set text(size: 10pt)
  table(
    columns: (1fr, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (left, left, right, right, right, right, right),
    table.hline(),
    table.header[*Implementation*][*Runtime*][*1 core*][*2 cores*][*4 cores*][*8 cores*][*8/1*],
    table.hline(),
    ..body,
    table.hline(),
  )
}

#let scaling-chart() = {
  let plots = chart-groups.map(group => {
    let points = core-counts.map(c => (c, speedup-of(group, c))).filter(point => point.at(1) != none)
    lq.plot(
      points.map(point => point.at(0)),
      points.map(point => point.at(1)),
      mark: marker-of(group),
      color: color-of(group),
    )
  })

  lq.diagram(
    xlabel: [Available P-cores],
    ylabel: [Speedup (x)],
    legend: none,
    width: 100%,
    height: 7cm,
    xaxis: (ticks: core-counts, subticks: none),
    yaxis: (ticks: (1, 1.5, 2, 2.5, 3, 3.5), subticks: none),
    ..plots,
  )
}

#let scaling-legend() = {
  let plots = chart-groups.map(group => lq.plot(
    (),
    (),
    mark: marker-of(group),
    color: color-of(group),
    label: label-of(group),
  ))

  show lq.selector(lq.legend): set grid(columns: (auto,) * 6, column-gutter: 1.2em)
  show lq.selector(lq.legend): set text(size: 8pt)
  show: lq.set-grid(stroke: none)

  lq.diagram(
    width: 100%,
    height: 2cm,
    xaxis: none,
    yaxis: none,
    legend: (position: top + center),
    ..plots,
  )
}
== CPU-Core Scaling
To measure how the implementations use additional CPU cores, we pin the entire ETL process tree to physical P-cores with `taskset` and PostgreSQL to the E-cores. The database therefore does not compete with the ETL workers for P-cores. @fig:scaling shows speedup at page size 100 for 1, 2, 4, and 8 P-cores, relative to each implementation's own one-core measurement. A one-core run is the same implementation restricted to one P-core. Each configuration uses its tuned parameters. @tab:scaling gives absolute means and standard deviations.

The parallel pipeline variants gain most of their speed by four cores. Pipeline multiprocessing reaches 3.08x at four cores and 3.17x at eight, while free-threading reaches 2.77x and 3.24x. The last four cores add little, and neither configuration fills all eight P-cores.

The multiprocessing implementations peak at four cores. Multiprocessing reaches 1.96x at four cores but falls to 1.31x at eight, while the async variant peaks at 2.08x and falls to 1.83x. At eight cores, the workers use less than two cores of CPU, so they are waiting rather than saturating the P-cores. The 3.15t configurations keep improving through eight cores. *FIGURE OUT WHY.*

Jython sequential sees almost all of its speedup at two cores 1.91x, with very little additional gain up to eight cores 2.00x. Its CPU utilisation rises above one core and its memory footprint grows to several gigabytes, so the process is not limited to one core. This is likely because the JVM, garbage collector, and JDBC connection wrapper use background threads, and the benchmark pins the process tree rather than a single thread. We did not isolate their contribution. Jython multiprocessing reaches 3.53x at eight cores, the largest relative gain, but uses roughly 20x the memory of every CPython implementation.

#figure(
  layout(size => stack(
    dir: ttb,
    spacing: 0.8em,
    scaling-chart(),
    scaling-legend(),
  )),
  placement: top,
  scope: "parent",
  caption: [
    Speedup at page size 100 by available P-cores, relative to the same
    implementation on one P-core. Values derive from means over 10 runs; the
    table gives absolute wall times.
  ],
) <fig:scaling>

#figure(
  scaling-table(),
  placement: top,
  scope: "parent",
  caption: [
    Wall time at page size 100 by available P-cores (mean ± sample standard
    deviation over 10 runs). Speedup is relative to the same implementation
    on one P-core.
  ],
) <tab:scaling>
