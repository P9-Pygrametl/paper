#import "../helpers/results-common.typ": *

#let table-spread = true // "mean ± std" in the table

// ---------- Summary table ----------
#let metric-cell(group, metric, d: 1) = {
  let v = values-for(group, table-page, metric)
  if v.len() == 0 {
    [-]
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
    [-]
  } else {
    [#fmt(mean(base) / mean(v), d: 2)]
  }
}

#let summary-table() = {
  let body = groups
    .map(group => (
      [#group-name(group)],
      metric-cell(group, "wall_seconds"),
      speedup-cell(group),
      metric-cell(group, "peak_pss_mb", d: 0),
      metric-cell(group, "cpu_percent", d: 0),
    ))
    .flatten()

  set text(size: 10pt)
  set par(justify: false)
  table(
    columns: (1fr, auto, auto, auto, auto),
    align: (left, right, right, right, right),
    inset: (x: 3pt, y: 3pt),
    table.header[*Implementation*][*Time (s)*][*Speedup ($times$)*][*Peak PSS (MB)*][*CPU util. (%)*],
    ..body,
  )
}

#figure(
  summary-table(),
  placement: top,
  scope: "parent", // spans both columns
  caption: [
    Results at page size #table-page (mean ± sample standard deviation over
    30 runs). Speedup is the ratio of mean execution times relative to
    `sequential`. CPU utilisation is relative to one core (100% = one fully used core).
  ],
) <tab:summary>
