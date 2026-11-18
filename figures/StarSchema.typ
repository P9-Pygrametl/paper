#let key-badge(label, is-fk: false) = {
  if label == "" {
    none
  } else {
    box(
      fill: if is-fk { rgb("#5b7a75") } else { rgb("#4b5563") },
      radius: 2pt,
      inset: (x: 2.5pt, y: 1.5pt),
      text(fill: white, size: 6.5pt, weight: "bold", label)
    )
  }
}

#let schema-card(title, rows, is-fact: false) = {
  let header-bg = if is-fact { rgb("#17253a") } else { rgb("#3c4654") }
  let border-col = if is-fact { rgb("#17253a") } else { rgb("#9ca3af") }

  box(
    radius: 4pt,
    clip: true,
    stroke: 1pt + border-col,
    fill: white,
    table(
      columns: (auto, auto),
      inset: (x: 3.5pt, y: 2pt),
      align: (center + horizon, left + horizon),
      stroke: (x, y) => (
        right: if x == 0 and y > 0 { 0.6pt + rgb("#cbd5e1") } else { none },
        bottom: if y == 0 { 1pt + border-col } else { none },
      ),
      table.cell(
        colspan: 2,
        fill: header-bg,
        align: center,
        inset: (x: 5pt, y: 3.5pt),
        text(fill: white, weight: "bold", size: 6.5pt, hyphenate: false, title)
      ),
      ..rows.map(((badge, col)) => (
        key-badge(badge, is-fk: badge.contains("fk")),
        text(size: 7.2pt, fill: rgb("#111827"), hyphenate: false, col)
      )).flatten()
    )
  )
}

#let h-arrow(width, dir: "right", col: rgb("#3c4654")) = {
  box(width: width, height: 8pt, {
    place(left + horizon, line(length: width - 3pt, stroke: 1.2pt + col))
    if dir == "right" {
      place(right + horizon, polygon(fill: col, (0pt, 1pt), (4.5pt, 4pt), (0pt, 7pt)))
    } else {
      place(left + horizon, polygon(fill: col, (4.5pt, 1pt), (0pt, 4pt), (4.5pt, 7pt)))
    }
  })
}

#let v-arrow(height, col: rgb("#3c4654")) = {
  box(width: 8pt, height: height, {
    place(center + bottom, line(angle: 90deg, length: height - 3pt, stroke: 1.2pt + col))
    place(center + top, polygon(fill: col, (4pt, 0pt), (7pt, 4.5pt), (1pt, 4.5pt)))
  })
}

#figure(
  align(center, {
    set text(hyphenate: false, size: 10pt)
    grid(
      columns: (auto, 25pt, auto, 25pt, auto),
      rows: (auto, 25pt, auto),
      align: (x, y) => if y == 2 { center + top } else { center + horizon },

      // Row 1: testdim
      [], [],
      schema-card("testdim", (
        ("pk", "testid"),
        ("", "testname"),
        ("", "testauthor"),
      )),
      [], [],

      // Row 2: Shorter upward arrow
      [], [],
      v-arrow(25pt),
      [], [],

      // Row 3: Top-aligned so testresults sits right under the arrow
      schema-card("datedim", (
        ("pk", "dateid"),
        ("", "date"),
        ("", "day"),
        ("", "month"),
        ("", "year"),
        ("", "week"),
        ("", "weekyear"),
      )),
      // Padding top aligns horizontal arrows with the middle of testresults
      pad(top: 24pt, h-arrow(25pt, dir: "left")),
      schema-card("testresults", is-fact: true, (
        ("pk,fk", "testid"),
        ("pk,fk", "dateid"),
        ("pk,fk", "pageid"),
        ("", "errors"),
      )),
      pad(top: 24pt, h-arrow(25pt, dir: "right")),
      schema-card("pagedim", (
        ("pk", "pageid"),
        ("", "url"),
        ("", "validfrom"),
        ("", "validto"),
        ("", "version"),
        ("", "domain"),
        ("", "topdomain"),
        ("", "serverversion"),
      )),
    )
  }),
  kind: image,
  caption: [Star schema for `testresults` and its dimension tables (`datedim`, `testdim`, and `pagedim`).]
) <fig-star-schema>