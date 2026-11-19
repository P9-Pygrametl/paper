#import "/figures/dict-transfer.typ": dict-transfer

// Tuning tables are derived from the trial log at compile time.
#let tuning-rows = csv("results/tuning.csv", row-type: dictionary)
#let tuning-search = tuning-rows.filter(row => (
  row.knob != "final"
    and int(row.pass_index) >= 1
    and row.valid == "1"
    and row.wall_seconds != ""
))

#let tuning-modes = {
  let modes = ()
  for row in tuning-search {
    if not modes.contains(row.mode) { modes.push(row.mode) }
  }
  modes.sorted()
}

#let tuning-impl-names = (
  cpygrametl1_db: "sequential",
  cpygrametl1_async_db: "sequential async",
  cpygrametl2_db: "multiprocessing",
  cpygrametl2_async_db: "multiprocessing async",
  jython1: "jython sequential",
  jython2: "jython multiprocessing",
  "pipeline sequential": "pipeline sequential",
  "pipeline multiprocessing": "pipeline multiprocessing",
  "pipeline free-threading": "pipeline free-threading",
)

#let tuning-impl-name(name) = tuning-impl-names.at(name, default: name)
#let tuning-runtime-name(name) = name.replace("cpython-", "").replace("jython-", "")
#let tuning-fmt(value, d: 1) = {
  let text = str(calc.round(value, digits: d))
  if d == 1 and not text.contains(".") { text = text + ".0" }
  text
}

#let tuning-median(values) = {
  let sorted = values.sorted()
  let n = sorted.len()
  if n == 0 { return 0 }
  if calc.rem(n, 2) == 1 {
    sorted.at(calc.quo(n, 2))
  } else {
    (sorted.at(calc.quo(n, 2) - 1) + sorted.at(calc.quo(n, 2))) / 2
  }
}

#let tuning-param(params, key) = {
  let parts = params.replace("{", "").replace("}", "").split(",")
  for part in parts {
    let kv = part.split(":")
    let k = kv.at(0).replace("\"", "").replace(" ", "")
    if k == key {
      return kv.at(1).replace("\"", "").replace(" ", "")
    }
  }
  "–"
}

#let tuning-stats = {
  let result = (:)
  for mode in tuning-modes {
    let groups = (:)
    for row in tuning-search {
      if row.mode == mode {
        let params = row.params
        let value = float(row.wall_seconds)
        let current = groups.at(params, default: none)
        if current == none {
          groups.insert(params, (value,))
        } else {
          groups.insert(params, current + (value,))
        }
      }
    }

    let configs = ()
    for pair in groups {
      configs.push((
        params: pair.at(0),
        median: tuning-median(pair.at(1)),
        n: pair.at(1).len(),
      ))
    }
    result.insert(mode, configs)
  }
  result
}

#let tuning-sensitivity-rows = tuning-modes.map(mode => {
  let medians = tuning-stats.at(mode).map(config => config.median).sorted()
  let best = medians.first()
  let worst = medians.last()
  let parts = mode.split("@")
  (
    tuning-impl-name(parts.at(0)),
    tuning-runtime-name(parts.at(1)),
    tuning-fmt(best),
    tuning-fmt(tuning-median(medians)),
    tuning-fmt(worst),
    tuning-fmt(100 * (worst - best) / best, d: 0) + "%",
  )
}).flatten()

#let tuning-selected-rows = tuning-modes.map(mode => {
  let parts = mode.split("@")
  let impl = tuning-impl-name(parts.at(0))
  let runtime = tuning-runtime-name(parts.at(1))
  let configs = tuning-stats.at(mode).filter(config => config.n >= 4)
  if configs.len() == 0 {
    return (impl, runtime, "–", "–", "–", "–", "–")
  }

  let best = configs.at(0)
  for config in configs {
    if config.median < best.median { best = config }
  }

  (
    impl,
    runtime,
    tuning-param(best.params, "batchsize"),
    tuning-param(best.params, "queuesize"),
    tuning-param(best.params, "bulksize"),
    tuning-param(best.params, "fetchsize"),
    tuning-param(best.params, "heap"),
  )
}).flatten()

= Appendix
== Appendix A: Dictionary Transfer
#figure(
  dict-transfer,
  caption: [Dictionary transfer throughput across different row sizes.],
) <fig:dict-transfer>

== Appendix B: Tuning Sensitivity
#figure(
  table(
    columns: (1fr, auto, auto, auto, auto, auto),
    align: (left, left, right, right, right, right),
    table.header[*Implementation*][*Runtime*][*Best (s)*][*Median (s)*][*Worst (s)*][*Spread*],
    ..tuning-sensitivity-rows,
  ),
  caption: [
    Exploratory tuning sensitivity at 100 pages. Best, median and worst are
    medians of unique tested configurations; spread is (worst - best) / best.
    Configurations were measured twice per sweep, not in a controlled paired
    experiment.
  ],
) <tab:tuning-sensitivity>

== Appendix C: Selected Configurations
#figure(
  table(
    columns: (1fr, auto, auto, auto, auto, auto, auto),
    align: (left, left, right, right, right, right, right),
    table.header[*Implementation*][*Runtime*][*Batch*][*Queue*][*Bulk*][*Fetch*][*Heap*],
    ..tuning-selected-rows,
  ),
  caption: [
    Configuration selected at 100 pages by the tuning procedure. Dashes
    indicate parameters not exposed by the implementation.
  ],
) <tab:tuning-selected>
