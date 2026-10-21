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

  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 1em,
    row-gutter: 0.8em,
    ..(
      ("Daniel Rantzau Bech", "dbech22"),
      ("Tobias Lundholm Bjerregaard", "tbjerr22"),
      ("Niklas Bo Hedehus", "nhedeh22"),
      ("Anders Mariegaard", "amarie20"),
      ("Andreas Mertz", "amertz22"),
      ("Simon Melgaard Skelkjær", "sskelk21"),
    ).map(((name, user)) => align(center)[
      #text(11pt)[#name] \
      #text(8.5pt, fill: luma(90))[#user\@student.aau.dk]
    ])
  )

  #v(1.2em)
  #text(10pt)[
    *Department of Computer Science, Aalborg University* \
    Aalborg, Denmark · Group cs-26-dt-9-04
  ]
  #v(0.5em)
  #text(9pt)[#link("https://github.com/P9-Pygrametl")[github.com/P9-Pygrametl]]
  #v(1.2em)
]
#set par(justify: true)

#set heading(numbering: "1.")

#columns(2)[
  #include "chapters/abstract.typ"
  #include "chapters/intro.typ"
  #include "chapters/conclusion.typ"
  #include "chapters/futurework.typ"

  #bibliography("works.bib")
]

#pagebreak()

#include "appendix.typ"

