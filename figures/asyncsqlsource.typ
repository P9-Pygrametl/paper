#import "@preview/fletcher:0.5.8": diagram, edge, node

// ── Colors ────────────────────────────────────────────
#let c-dark = rgb("#17253a")
#let c-line = rgb("#3c4654")
#let c-green = rgb("#5b7a75")
#let c-light = rgb("#f1f4f8")
#let c-white = white

// ── Components ────────────────────────────────────────
#let card(title, subtitle, fill: c-dark, width: 100pt) = block(
  width: width,
  inset: 4pt,
  radius: 2pt,
  fill: fill,
  stroke: 0.5pt + fill,
  align(center)[
    #text(fill: white, weight: "bold", size: 7.5pt, title)
    #linebreak()
    #text(fill: white, size: 6.5pt, subtitle)
  ],
)

#let batch-cell(label, empty: false) = block(
  width: 30pt,
  inset: (x: 2pt, y: 4pt),
  radius: 1pt,
  fill: if empty { white } else { c-light },
  stroke: (
    paint: c-line,
    thickness: 0.5pt,
    dash: if empty { (2pt, 2pt) } else { "solid" },
  ),
  align(center)[
    #text(size: 6.5pt, fill: c-dark, label)
  ],
)

#let queue-card() = block(
  width: 150pt,
  inset: 5pt,
  radius: 2pt,
  fill: white,
  stroke: 0.6pt + c-line,
  [
    #align(center)[
      #text(size: 7.5pt, weight: "bold")[
        Bounded `asyncio.Queue`
      ]
    ]

    #v(3pt)

    #grid(
      columns: 4,
      gutter: 3pt,
      align: center,
      batch-cell("Batch 1"), batch-cell("Batch 2"), batch-cell("Batch 3"), batch-cell("Empty", empty: true),
    )

    #v(3pt)

    #align(center)[
      #text(size: 6.5pt)[Example: `prefetch = 4`]
    ]
  ],
)

// ── Figure ────────────────────────────────────────────
#figure(
  align(center)[
    #diagram(
      spacing: (0pt, 12pt),
      node-inset: 0pt,
      node-stroke: none,
      node-shape: rect,
      node-defocus: 0,
      node-outset: 0pt,
      edge-stroke: 0.7pt + c-line,

      node((0, 0), name: <db>, card(
        "Source database",
        "Query results",
      )),

      node((0, 1), name: <eventloop>, block(
        width: 170pt,
        inset: 6pt,
        radius: 3pt,
        stroke: (
          paint: c-line,
          thickness: 0.6pt,
          dash: (3pt, 3pt),
        ),
        [
          #text(size: 7pt, weight: "bold")[
            `asyncio` event loop
          ]

          #v(4pt)

          #align(center)[
            #diagram(
              spacing: (0pt, 15pt),
              node-inset: 0pt,
              node-stroke: none,
              node-outset: 0pt,
              node-shape: rect,
              edge-stroke: 0.7pt + c-line,

              node((0, 0), name: <producer>, card(
                "Producer task",
                "Fetch next batch",
              )),

              node((0, 1), name: <queue>, queue-card()),

              node((0, 2), name: <consumer>, card(
                "Consumer task",
                "Consume rows",
                fill: c-green,
              )),

              edge(
                <producer>,
                <queue>,
                "->",
                label: text(size: 6.5pt)[`await put()`],
              ),

              edge(
                <queue>,
                <consumer>,
                "->",
                label: text(size: 6.5pt)[`await get()`],
              ),
            )
          ]
        ],
      )),

      edge(
        <db>,
        <eventloop>,
        "->",
        label: text(size: 6.5pt)[Async fetch],
      ),
    )
  ],
  kind: image,
  caption: [Asynchronous batch retrieval in `AsyncSQLSource`.],
) <fig-asyncsqlsource>
