// ── Colours ───────────────────────────────────────────
#let c-dark = rgb("#17253a")
#let c-line = rgb("#3c4654")
#let c-green = rgb("#5b7a75")
#let c-light = rgb("#f1f4f8")

// ── Components ────────────────────────────────────────
#let card(title, subtitle, fill: c-dark) = block(
  width: 110pt,
  height: 30pt,
  radius: 2pt,
  fill: fill,
  align(center + horizon)[
    #text(fill: white, weight: "bold", size: 7.5pt, title)
    #linebreak()
    #text(fill: white, size: 6.5pt, subtitle)
  ],
)

#let batch-cell(label, empty: false) = block(
  width: 30pt,
  height: 17pt,
  radius: 1pt,
  fill: if empty { white } else { c-light },
  stroke: (
    paint: c-line,
    thickness: 0.5pt,
    dash: if empty { (2pt, 2pt) } else { "solid" },
  ),
  align(center + horizon)[
    #text(size: 6.5pt, fill: c-dark, label)
  ],
)

#let queue-card() = block(
  width: 150pt,
  height: 38pt,
  radius: 2pt,
  fill: white,
  stroke: 0.6pt + c-line,
  [
    #place(top + center, dy: 5pt)[
      #text(size: 7.5pt, weight: "bold", fill: c-dark)[
        Bounded `asyncio.Queue`
      ]
    ]

    #place(top + center, dy: 16pt)[
      #grid(
        columns: 4,
        gutter: 3pt,
        align: center,
        batch-cell("Batch 1"), batch-cell("Batch 2"), batch-cell("Batch 3"), batch-cell("Empty", empty: true),
      )
    ]
  ],
)

// ── Arrow component ───────────────────────────────────
#let arrow(x, y, length, up: false, dashed: false) = {
  let s = (
    paint: c-line,
    thickness: 0.7pt,
    dash: if dashed { (2pt, 2pt) } else { "solid" },
  )

  // Arrow shaft
  place(
    top + left,
    dx: x,
    dy: y,
    line(
      start: (0pt, 0pt),
      end: (0pt, length),
      stroke: s,
    ),
  )

  // Arrowhead
  place(
    top + left,
    dx: x - 2.5pt,
    dy: if up { y } else { y + length - 3.5pt },
    polygon(
      ..if up {
        ((0pt, 3.5pt), (2.5pt, 0pt), (5pt, 3.5pt))
      } else {
        ((0pt, 0pt), (2.5pt, 3.5pt), (5pt, 0pt))
      },
      fill: c-line,
      stroke: none,
    ),
  )
}

// ── Figure ────────────────────────────────────────────
#figure(
  align(center)[
    #block(
      width: 220pt,
      height: 218pt,
      [
        // Event loop boundary
        #place(top + left, dx: 25pt, dy: 57pt)[
          #rect(
            width: 170pt,
            height: 159pt,
            radius: 3pt,
            stroke: (
              paint: c-line,
              thickness: 0.6pt,
              dash: (3pt, 3pt),
            ),
          )
        ]

        // Event loop label
        #place(top + center, dy: 63pt)[
          #text(size: 7pt, weight: "bold")[
            `asyncio` event loop
          ]
        ]

        // Source database
        #place(top + left, dx: 55pt, dy: 0pt)[
          #card("Source database", "Query results")
        ]

        // Producer task
        #place(top + left, dx: 55pt, dy: 78pt)[
          #card("Producer task", "Await next batch")
        ]

        // Bounded queue
        #place(top + left, dx: 35pt, dy: 124pt)[
          #queue-card()
        ]

        // Consumer task
        #place(top + left, dx: 55pt, dy: 178pt)[
          #card(
            "Consumer task",
            "Consume rows",
            fill: c-green,
          )
        ]

        // Producer → Database
        #arrow(65pt, 30pt, 48pt, up: true)

        #place(top + left, dx: 14pt, dy: 39pt)[
          #text(size: 6.5pt)[Fetch request]
        ]

        // Database → Producer
        #arrow(155pt, 30pt, 48pt)

        #place(top + left, dx: 160pt, dy: 39pt)[
          #text(size: 6.5pt)[Retrieved batch]
        ]

        // Producer → Queue
        #arrow(110pt, 108pt, 16pt)

        #place(top + left, dx: 116pt, dy: 111pt)[
          #text(size: 6.5pt)[`await put()`]
        ]

        // Queue → Consumer
        #arrow(110pt, 162pt, 16pt)

        #place(top + left, dx: 116pt, dy: 165pt)[
          #text(size: 6.5pt)[`await get()`]
        ]
      ],
    )
  ],
  kind: image,
  caption: [Asynchronous batch retrieval in `AsyncSQLSource`.],
) <fig-asyncsqlsource>
