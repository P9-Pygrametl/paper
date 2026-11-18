#import "@preview/fletcher:0.5.8": diagram, edge, node

// ── Colors ────────────────────────────────────────────
#let c-fact = rgb("#17253a")
#let c-dim = rgb("#3c4654")
#let c-border = rgb("#17253a")
#let c-pk = rgb("#5b7a75")
#let c-fk = rgb("#5b7a75")

// ── Components ────────────────────────────────────────
// The badge is now a table cell, so it fills the full cell area.
#let badge-cell(label) = {
  if label == "" {
    table.cell([])
  } else {
    let col = if label.contains("fk") { c-fk } else { c-pk }
    table.cell(
      fill: col,
      stroke: (
        bottom: 0.5pt + col,
        left: c-border,
        right: c-border,
      ),
      align: center + horizon,
      text(fill: white, size: 6.5pt, weight: "bold", label),
    )
  }
}

#let table-card(title, rows, fact: false) = {
  let accent = c-fact
  let n = rows.len() // last row index is n (title is row 0)
  let outer = c-border

  table(
    columns: 2,
    inset: (x: 3.5pt, y: 3pt),
    align: (center + horizon, left + horizon),
    stroke: (x, y) => (
      left: if x == 0 { outer },
      right: c-border,
      top: if y == 0 { outer },
      bottom: if y == 0 or y == n { outer },
    ),
    table.cell(
      colspan: 2,
      fill: accent,
      align: center,
      inset: (x: 5pt, y: 3.5pt),
      text(fill: white, weight: "bold", size: 6.5pt, hyphenate: false, title),
    ),
    ..rows
      .map(((key, col)) => (
        badge-cell(key),
        text(size: 7.2pt, fill: rgb("#111827"), hyphenate: false, col),
      ))
      .flatten(),
  )
}

// ── Figure ────────────────────────────────────────────
#figure(
  diagram(
    spacing: (15pt, 0pt),
    node-inset: 0pt,
    node-stroke: none,
    node-shape: rect,
    node-defocus: 0,
    node-outset: 0.5pt,
    edge-stroke: 0.8pt + c-dim,

    node((1, 0), name: <testdim>, table-card("testdim", (
      ("pk", "testid"),
      ("", "testname"),
      ("", "testauthor"),
    ))),

    node((0, 1), name: <datedim>, table-card("datedim", (
      ("pk", "dateid"),
      ("", "date"),
      ("", "day"),
      ("", "month"),
      ("", "year"),
      ("", "week"),
      ("", "weekyear"),
    ))),

    node((1, 1), name: <facts>, table-card("testresults", fact: true, (
      ("pk,fk", "testid"),
      ("pk,fk", "dateid"),
      ("pk,fk", "pageid"),
      ("", "errors"),
    ))),

    node((2, 1), name: <pagedim>, table-card("pagedim", (
      ("pk", "pageid"),
      ("", "url"),
      ("", "validfrom"),
      ("", "validto"),
      ("", "version"),
      ("", "domain"),
      ("", "topdomain"),
      ("", "serverversion"),
    ))),

    // All arrows point from the fact table to the dimensions
    edge(<facts>, <testdim>, "->"),
    edge(<facts>, <datedim>, "->"),
    edge(<facts>, <pagedim>, "->"),
  ),
  kind: image,
  caption: [Star schema for `testresults` and its dimension tables (`datedim`, `testdim`, and `pagedim`).],
) <fig-star-schema>
