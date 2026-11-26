#let csv-path = "../results/merged.csv"
#let only-valid = true
#let table-page = 100
#let baseline = ("cpygrametl1_db", "cpython-3.15") // raw CSV names

// ---------- Display names ----------
#let impl-names = (
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
#let impl-name(name) = impl-names.at(name, default: name)
#let runtime-name(runtime) = runtime.replace("cpython-", "").replace("jython-", "")

#let group-name(group) = {
  let base = impl-name(group.at(0))
  let rt = runtime-name(group.at(1))

  if rt.ends-with("t") and not base.starts-with("pipeline") {
    base.replace("sequential", "sequential free-threading").replace("multiprocessing", "free-threading")
  } else {
    base
  }
}

#let label-of(group) = [#group-name(group) / #runtime-name(group.at(1))]

// ---------- Data ----------
#let raw-data = csv(csv-path, row-type: dictionary)
#let rows = raw-data.filter(row => (
  not only-valid or (row.valid == "1" and row.returncode == "0")
))

// ---------- Helpers ----------
#let fmt(v, d: 1) = {
  let s = str(calc.round(v, digits: d))
  if d == 0 { return s }
  let parts = s.split(".")
  let frac = if parts.len() > 1 { parts.at(1) } else { "" }
  parts.at(0) + "." + frac + "0" * (d - frac.len())
}

#let mean(v) = v.sum() / v.len()

#let std(v) = {
  let m = mean(v)
  calc.sqrt(v.map(x => calc.pow(x - m, 2)).sum() / calc.max(v.len() - 1, 1))
}

#let values-for(group, page, metric) = {
  rows
    .filter(r => (
      r.implementation == group.at(0) and r.runtime == group.at(1) and int(r.pages) == page and r.at(metric) != ""
    ))
    .map(r => float(r.at(metric)))
}

#let speedup-of(group) = {
  let base = values-for(baseline, table-page, "wall_seconds")
  let v = values-for(group, table-page, "wall_seconds")
  if base.len() == 0 or v.len() == 0 { none } else { mean(base) / mean(v) }
}

#let group-name(group) = {
  let base = impl-name(group.at(0))
  let rt = runtime-name(group.at(1))

  if rt.ends-with("t") {
    base.replace("sequential", "sequential free-threading").replace("multiprocessing", "free-threading")
  } else {
    base
  }
}

#let label-of(group) = [#group-name(group) / #runtime-name(group.at(1))]

// ---------- Grouping and sorting ----------
#let groups = {
  let g = ()
  for row in rows {
    let group = (row.implementation, row.runtime)
    if not g.contains(group) { g.push(group) }
  }
  g.sorted(key: group => {
    let s = speedup-of(group)
    if s == none { 1000 } else { -s } // speedup descending, none last
  })
}
