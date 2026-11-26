// ── Colors ────────────────────────────────────────────
#let c-send = rgb("#17253a")
#let c-wait = rgb("#dce1e6")
#let c-sync = rgb("#5b7a75")

// ── Figure ────────────────────────────────────────────
#figure(
  layout(avail => {
    let label-w = 1.8cm
    let bar-w = avail.width - label-w
    let unit = bar-w / 18

    let seg(u, fill, body, foreground: white) = box(
      width: u * unit,
      height: 0.5cm,
      fill: fill,
      stroke: 0.5pt + white,
      align(center + horizon, text(
        size: 6.5pt,
        fill: foreground,
        weight: "bold",
        body,
      )),
    )

    let send = seg.with(1, c-send)
    let wait = seg.with(2, c-wait, foreground: c-send)
    let sync = seg.with(4, c-sync)

    grid(
      columns: (label-w, 1fr),
      row-gutter: 0.6em,
      align: (left + horizon, left + horizon),

      text(size: 8pt)[Sequential],
      stack(
        dir: ltr,
        ..range(6).map(_ => (send[S], wait[Wait])).flatten(),
      ),

      text(size: 8pt)[Pipelined],
      stack(
        dir: ltr,
        ..range(6).map(_ => send[S]),
        sync[Sync / wait],
      ),
    )

    v(0.4em)

    // Legend
    text(size: 7pt)[
      #box(width: 0.7em, height: 0.7em, fill: c-send)
      Send statement
      #h(0.6em)
      #box(width: 0.7em, height: 0.7em, fill: c-wait)
      Wait for reply
      #h(0.6em)
      #box(width: 0.7em, height: 0.7em, fill: c-sync)
      Synchronisation
    ]
  }),
  kind: image,
  caption: [Sequential and pipelined execution over time (not to scale).],
) <fig-timeline>
