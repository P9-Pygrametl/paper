#import "@preview/lilaq:0.6.0" as lq

#let scaling-path = "../results/scaling.csv"
#let page-size = 100
#let core-counts = (1, 2, 4, 8)

#let raw-data = csv(scaling-path, row-type: dictionary)

#let rows = raw-data.filter(row => (
  row.valid == "1" and row.returncode == "0" and int(row.pages) == page-size
))

#let impl-names = (
  cpygrametl1_db: "sequential",
  cpygrametl1_async_db: "sequential async",
  cpygrametl2_db: "multiprocessing",
  cpygrametl2_async_db: "multiprocessing async",
  jython1: "jython sequential",
  jython2: "jython multiprocessing",
  "pipeline sequential": "pipeline sequential",
  "pipeline multiprocessing": "pipeline multiprocessing",
  "pipeline free-threading": "pipeline free-threading",
)

#let impl-name(name) = impl-names.at(name, default: name)
#let runtime-name(runtime) = runtime.replace("cpython-", "").replace("jython-", "")
#let label-of(group) = [#impl-name(group.at(0)) / #runtime-name(group.at(1))]

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

#let color-of(group) = {
  let base = impl-colors.at(group.at(0), default: luma(120))
  if group.at(0).starts-with("cpygrametl") and group.at(1).ends-with("t") {
    base.lighten(35%)
  } else {
    base
  }
}

#let marker-of(group) = impl-markers.at(group.at(0), default: "o")

#let all-groups = {
  let result = ()
  for row in rows {
    let group = (row.implementation, row.runtime)
    if not result.contains(group) { result.push(group) }
  }
  result.sorted(key: group => (impl-name(group.at(0)), runtime-name(group.at(1))))
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
    [–]
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
    [–]
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
    ylabel: [Speedup (×)],
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

  show lq.selector(lq.legend): set grid(columns: (auto,) * 4, column-gutter: 1.2em)
  show lq.selector(lq.legend): set text(size: 8pt)
  show: lq.set-grid(stroke: none)

  lq.diagram(
    width: 100%,
    height: 3cm,
    xaxis: none,
    yaxis: none,
    legend: (position: top + center),
    ..plots,
  )
}
== CPU-Core Scaling
To measure how the implementations use additional CPU cores, we pin the entire ETL process tree to physical P-cores with `taskset`. @fig:scaling shows speedup at page size 100 as the ETL process tree is restricted to 1, 2, 4, or 8 P-cores, relative to each implementation's own one-core measurement. The ETL tree is pinned to the P-cores (CPU 0–7) and PostgreSQL to the twelve E-cores (CPU 8–19), so the database has a separate CPU pool and does not compete with the ETL workers for P-cores. A one-core run is the same implementation restricted to one P-core. Each configuration uses its tuned parameters and 10 repetitions per core count; @tab:scaling gives absolute means and standard deviations. The relevant comparison is how much each configuration gains from additional client cores, not which configuration is fastest at a fixed core count.

The parallel pipeline variants gain most of their speed by four cores. Pipeline multiprocessing goes from 63.9~s at one core to 20.7~s at four and 20.2~s at eight, speedups of 3.08x and 3.17x. Free-threading goes from 55.6~s to 20.0~s and 17.1~s, speedups of 2.77x and 3.24x. The last four cores improve wall time by only 2.5% and 14.5%, and eight-core efficiency is about 40%. CPU utilisation reaches only 306% and 388%, so neither configuration fills all eight P-cores.

The cpygrametl multiprocessing configurations on CPython 3.15 peak at four cores. Multiprocessing improves from 133.8~s at one core to 68.4~s at four, a 1.96x speedup, but regresses to 102.3~s at eight, or 1.31x. The async variant goes from 136.3~s to 65.5~s at four and 74.4~s at eight, or 2.08x and 1.83x. CPU utilisation at eight cores falls to 93% and 120%, so the workers are waiting rather than saturating the P-cores. The 3.15t configurations keep improving to 51.5~s and 49.1~s, or 1.55x and 1.66x. Their one-core baselines are much faster, so the speedups understate their absolute advantage. Because the runtimes use different tuned parameters, this is not a clean comparison.

Jython sequential, nominally single-threaded, also speeds up substantially: it drops from 127.3~s at one core to 66.8~s at two and 63.5~s at eight, a 2.00x speedup. Its CPU utilisation rises from 68% to 129% and its PSS from 1.1~GB to 3.6~GB, so the process is not limited to one core. This is likely because the JVM, garbage collector, and JDBC connection wrapper use background threads, and the benchmark pins the process tree rather than a single thread; we did not isolate their contribution. Jython multiprocessing scales further, to 51.0~s at eight, a 3.53x speedup and the largest relative gain, but uses 3.7~GB PSS against 0.19~GB for cpygrametl 3.15t.

The flattening and regression at four to eight P-cores therefore point to database throughput or coordination rather than P-core contention. All 520 runs passed validation, with 10 repetitions per configuration and core count. Absolute times are not directly comparable to the page-size results because the affinity setup and run counts differ.

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
