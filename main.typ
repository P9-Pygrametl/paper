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
  #include "chapters/relatedworks.typ"
  = Methods <Methods>
  #include "chapters/subvsmp.typ"
  #include "chapters/freethreading.typ"
  == Async
  #include "chapters/pipeline_mode.typ"
  #include "chapters/experiment.typ"
  #include "chapters/benchmarking_harness.typ"
  = Results
  #include "chapters/result_pygrametl.typ"
  == Other
  #include "chapters/conclusion.typ"
  #include "chapters/futurework.typ"

  #bibliography("works.bib")
]

#pagebreak()

#include "appendix.typ"

