// lib.typ

#let project(
  title: "",
  subtitle: "",
  project_period: "",
  group: "",
  authors: (),
  supervisors: (),
  date: datetime.today(),
  abstract: [],
  body,
) = {
  // Set document metadata
  set document(author: authors.map(a => a.name), title: title)

  // Set global text properties
  set heading(numbering: "1.1")

  // --- Front Page ---
  page(margin: (top: 4cm, bottom: 2cm, x: 2cm))[
    #set align(center)
    #text(2em, weight: "bold")[#title] \
    #v(1em)
    #text(1.5em)[#subtitle] \
    #v(1em)
    #text(1.2em)[#group] \

    #v(1fr)
    // Placeholder for AAU Logo
    #image("figures/aau_logo.png", width: 50%)
    #text(weight: "bold")[Aalborg University] \
    Electronics and IT
  ]

  // --- Main Body ---
  set page(
    numbering: "1",
  )

  body
}
