#import "lib.typ": project

#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)

#set par(justify: true, leading: 0.62em)


#counter(page).update(1)

#align(center)[
  \
  #text(20pt)[*How can a distributed smart scheduling system optimize the current EV charging environment*]
  \
  \
  Daniel Rantzau Bech, Tobias Lundholm Bjerregaard, Niklas Bo Hedehus,\
  Anders Mariegaard, Andreas Mertz, Simon Melgaard Skelkjær
  \
  Department of Computer Science, Aalborg University \
  Aalborg, Denmark \
  Group number: cs-26-sw-8-03 \
  Email: {dbech22, tbjerr22, nhedeh22, amarie20, amertz22, sskelk21}\@student.aau.dk
  \
  GitHub: #link("https://github.com/SmartEVP8")[https://github.com/SmartEVP8]
  \
  \
]

#set heading(numbering: "1.")

#columns(2)[
  #include "chapters/abstract.typ"
  #include "chapters/intro.typ"
  #include "chapters/stateoftheart.typ"
  #include "chapters/systemdesign.typ"
  #include "chapters/experiment.typ"
  #include "chapters/results.typ"
  #include "chapters/discussion.typ"
  #include "chapters/conclusion.typ"
  #include "chapters/futurework.typ"

  #bibliography("works.bib")
]

#pagebreak()

#include "appendix.typ"

