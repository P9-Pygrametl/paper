#import "lib.typ": project

#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)

#set par(justify: true, leading: 0.62em)


#counter(page).update(1)

#align(center)[
  \
  #text(
    20pt,
  )[Can Modern Python Make pygrametl Faster? Exploring Async/Await, Subinterpreters, and Free-Threading]
  \
  \
  Daniel Rantzau Bech, Tobias Lundholm Bjerregaard, Niklas Bo Hedehus,\
  Anders Mariegaard, Andreas Mertz, Simon Melgaard Skelkjær
  \
  Department of Computer Science, Aalborg University \
  Aalborg, Denmark \
  Group number: cs-26-dt-9-04 \
  Email: {dbech22, tbjerr22, nhedeh22, amarie20, amertz22, sskelk21}\@student.aau.dk
  \
  GitHub: #link("https://github.com/P9-Pygrametl")[https://github.com/P9-Pygrametl]
  \
  \
]

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

