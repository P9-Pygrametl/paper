#import "@preview/lilaq:0.6.0" as lq

#let results = json("../results/results.json")

#set text(size: 10pt)

#let recs(name) = results.at(name)

#let solo(title, ..args) = align(
  center,
  lq.diagram(
    width: 15cm,
    height: 6.6cm,
    title: title,
    ..args.named(),
    ..args.pos(),
  ),
)

#let dict-columns = (2, 5, 10, 20, 50)

#let dict-rows-per-second(transport) = {
  let rs = recs("exp3_dict_transport")
    .filter(r => r.transport == transport and r.columns > 1)
    .sorted(key: r => r.columns)
  rs.map(r => r.rows_per_s / 100000.0)
}

#let dict-transfer = {
  align(left)[
    #h(1.2cm)
    $times 10^5$
  ]
  v(-0.4cm)

  solo(
    [Dictionary transfer throughput],
    xlabel: [Number of columns],
    ylabel: [Rows per second],
    lq.plot(
      dict-columns,
      dict-rows-per-second("interp_queue"),
      mark: "o",
      label: [Subinterpreters],
    ),
    lq.plot(
      dict-columns,
      dict-rows-per-second("mp_queue"),
      mark: "s",
      label: [Multiprocessing queue],
    ),
    lq.plot(
      dict-columns,
      dict-rows-per-second("mp_pipe"),
      mark: "^",
      label: [Multiprocessing pipe],
    ),
  )
}
