#import "../helpers/results-common.typ": group-name

// Tuning tables are derived from the trial log at compile time.
#let tuning-rows = csv("../results/tuning.csv", row-type: dictionary)
#let tuning-search = tuning-rows.filter(row => (
  row.knob != "final" and int(row.pass_index) >= 1 and row.valid == "1" and row.wall_seconds != ""
))

// A mode in the log looks like "cpygrametl2_db@cpython-3.15t"
#let mode-group(mode) = {
  let parts = mode.split("@")
  (parts.at(0), parts.at(1))
}
#let mode-name(mode) = group-name(mode-group(mode))

#let tuning-modes = {
  let modes = ()
  for row in tuning-search {
    if not modes.contains(row.mode) { modes.push(row.mode) }
  }
  modes.sorted(key: mode => mode-name(mode))
}

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

#let tuning-sensitivity-rows = (
  tuning-modes
    .map(mode => {
      let medians = tuning-stats.at(mode).map(config => config.median).sorted()
      let best = medians.first()
      let worst = medians.last()
      (
        mode-name(mode),
        tuning-fmt(best),
        tuning-fmt(tuning-median(medians)),
        tuning-fmt(worst),
        tuning-fmt(100 * (worst - best) / best, d: 0) + "%",
      )
    })
    .flatten()
)

#let tuning-selected-rows = (
  tuning-modes
    .map(mode => {
      let name = mode-name(mode)
      let configs = tuning-stats.at(mode).filter(config => config.n >= 4)
      if configs.len() == 0 {
        return (name, "–", "–", "–", "–", "–")
      }

      let best = configs.at(0)
      for config in configs {
        if config.median < best.median { best = config }
      }

      (
        name,
        tuning-param(best.params, "batchsize"),
        tuning-param(best.params, "queuesize"),
        tuning-param(best.params, "bulksize"),
        tuning-param(best.params, "fetchsize"),
        tuning-param(best.params, "heap"),
      )
    })
    .flatten()
)

// ---------- Figures ----------
#let tuning-sensitivity-figure() = [
  #figure(
    table(
      columns: (1fr, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header[*Implementation*][*Best (s)*][*Median (s)*][*Worst (s)*][*Spread*],
      ..tuning-sensitivity-rows,
    ),
    caption: [
      Exploratory tuning sensitivity at 100 pages. Best, median and worst are
      medians of unique tested configurations; spread is (worst - best) / best.
      Configurations were measured twice per sweep, not in a controlled paired
      experiment.
    ],
  ) <tab:tuning-sensitivity>
]

#let tuning-selected-figure() = [
  #figure(
    table(
      columns: (1fr, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right),
      table.header[*Implementation*][*Batch*][*Queue*][*Bulk*][*Fetch*][*Heap*],
      ..tuning-selected-rows,
    ),
    caption: [
      Configuration selected at 100 pages by the tuning procedure. Dashes
      indicate parameters not exposed by the implementation.
    ],
  ) <tab:tuning-selected>
]
