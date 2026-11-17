#import "lib.typ": project

#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)

#set par(justify: true, leading: 0.62em)


#counter(page).update(1)

#set par(justify: false)
#align(center)[
  #text(15pt, weight: "bold")[
    Can Modern Python Make pygrametl Faster? \
    Exploring Async/Await, Subinterpreters, and Free-Threading
  ]
  #v(1.4em)

  #let person((name, user)) = align(center)[
    #text(11pt)[#name] \
    #text(8.5pt, fill: luma(90))[#user\@student.aau.dk]
  ]

  #let people = (
    ("Daniel Rantzau Bech", "dbech22"),
    ("Tobias Lundholm Bjerregaard", "tbjerr22"),
    ("Anders Mariegaard", "amarie20"),
    ("Andreas Mertz", "amertz22"),
    ("Simon Melgaard Skelkjær", "sskelk21"),
  )

  #align(center)[
    #block(width: 95%)[
      #grid(
        columns: (1fr,) * 6,
        column-gutter: 1em,
        row-gutter: 0.8em,
        ..people.slice(0, 3).map(p => grid.cell(colspan: 2, person(p))),
        grid.cell(colspan: 1, []),
        ..people.slice(3).map(p => grid.cell(colspan: 2, person(p))),
      )
    ]
  ]

  #text(10pt)[
    *Department of Computer Science, Aalborg University* \
    Aalborg, Denmark · Group cs-26-dt-9-04
  ]

  #text(9pt)[#link("https://github.com/P9-Pygrametl")[github.com/P9-Pygrametl]]
  #v(1.2em)
]
#set par(justify: true)

#set heading(numbering: "1.")

#columns(2)[
  #include "chapters/abstract.typ"
  #include "chapters/intro.typ"
  = Related Works
  = Methods
  == Subinterpreters
  == Free threading
  == Async
  == Pipeline mode
  = Experimental Setup
  == Star schema diagram
  #include "figures/StarSchema.typ"
  To evaluate the parallelization methods described in XXX, we adopt the star schema presented in @Liu2011ETLMR and @Pygrametl2011. As shown in @fig-star-schema, the schema consists of a central fact table, `testresults`, and three dimension tables: `datedim`, `testdim`, and `pagedim`. Notably, `pagedim` is modeled as a Type 2 slowly changing dimension (SCD), meaning that each update inserts a new row, and as a byproduct, `pagedim` contains the largest number of rows in the schema. The benchmark dataset was produced using the data generator @Thomsen2011Exaprogs provided in @Pygrametl2011. We specifically selected this schema because @Pygrametl2011 employed it to evaluate their parallel Jython @JythonProject implementation of `pygrametl`, which serves as a comparison for this work.
  == Hardware
  == General Setup
  == Benchmark
  = Results
  == Compare to previous pygrametl results
  == Other
  #include "chapters/conclusion.typ"
  #include "chapters/futurework.typ"

  #bibliography("works.bib")
]

#pagebreak()

#include "appendix.typ"

