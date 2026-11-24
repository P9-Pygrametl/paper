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
)
#let impl-name(name) = impl-names.at(name, default: name)
#let runtime-name(runtime) = runtime.replace("cpython-", "")

// ---------- Data ----------
#let raw-data = csv(csv-path, row-type: dictionary)
#let rows = raw-data.filter(row => (
  not only-valid or (row.valid == "1" and row.returncode == "0")
))

// ---------- Helpers ----------
#let fmt(v, d: 1) = str(calc.round(v, digits: d))

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

#let label-of(group) = [#impl-name(group.at(0)) / #runtime-name(group.at(1))]

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
