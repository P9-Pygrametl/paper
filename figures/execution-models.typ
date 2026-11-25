// ── Colors ────────────────────────────────────────────
#let c-dark = rgb("#17253a")
#let c-line = rgb("#3c4654")
#let c-green = rgb("#5b7a75")

// ── Components ────────────────────────────────────────
#let interpreter(title, subtitle, height: 28pt) = block(
  width: 100%,
  height: height,
  inset: 2pt,
  radius: 1pt,
  fill: c-dark,
  align(center + horizon)[
    #text(fill: white, size: 6.5pt, weight: "bold", title)
    #linebreak()
    #text(fill: white, size: 6pt, subtitle)
  ],
)

#let thread-card(title) = block(
  width: 100%,
  height: 24pt,
  radius: 1pt,
  fill: c-green,
  align(center + horizon)[
    #text(fill: white, size: 6.5pt, title)
  ],
)

#let process-box(title, body, height: 48pt) = block(
  width: 100%,
  height: height,
  inset: 3pt,
  radius: 2pt,
  stroke: 0.6pt + c-line,
  stack(
    dir: ttb,
    spacing: 3pt,
    align(center, text(size: 7pt, weight: "bold", title)),
    body,
  ),
)

// ── Multiprocessing ───────────────────────────────────
#let multiprocessing = stack(
  dir: ttb,
  spacing: 4pt,

  process-box(
    "Process 1",
    interpreter("Interpreter", "GIL"),
  ),

  process-box(
    "Process 2",
    interpreter("Interpreter", "GIL"),
  ),

  process-box(
    "Process 3",
    interpreter("Interpreter", "GIL"),
  ),
)

// ── Subinterpreters ───────────────────────────────────
#let subinterpreters = process-box(
  "Process",
  stack(
    dir: ttb,
    spacing: 4pt,

    interpreter(
      "Interpreter 1",
      [Own GIL \ Worker thread],
      height: 40pt,
    ),

    interpreter(
      "Interpreter 2",
      [Own GIL \ Worker thread],
      height: 40pt,
    ),

    interpreter(
      "Interpreter 3",
      [Own GIL \ Worker thread],
      height: 40pt,
    ),
  ),
  height: 152pt,
)

// ── Free-threading ─────────────────────────────────────
#let freethreading = process-box(
  "Process",
  block(
    width: 100%,
    height: 132pt,
    inset: 4pt,
    radius: 1pt,
    fill: c-dark,
    stack(
      dir: ttb,
      spacing: 5pt,

      align(center)[
        #text(fill: white, size: 6.5pt, weight: "bold")[
          Interpreter
        ]
        #linebreak()
        #text(fill: white, size: 6pt)[GIL disabled]
      ],

      thread-card("Thread 1"),
      thread-card("Thread 2"),
      thread-card("Thread 3"),
    ),
  ),
  height: 152pt,
)

// ── Figure ────────────────────────────────────────────
#figure(
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 5pt,
    row-gutter: 5pt,
    align: center + top,

    // Headings
    text(size: 7pt, weight: "bold")[Multiprocessing],
    text(size: 7pt, weight: "bold")[Subinterpreters],
    text(size: 7pt, weight: "bold")[Free-threading],

    // Execution models
    multiprocessing, subinterpreters, freethreading,

    // Labels
    text(size: 6.5pt)[Separate processes],
    text(size: 6.5pt)[Isolated interpreters],
    text(size: 6.5pt)[Shared interpreter],
  ),
  kind: image,
  caption: [Comparison of parallel execution models.],
) <fig-execution-models>
