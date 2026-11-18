== Pipeline Mode

pygrametl loads data row by row. Each `insert` call sends one `INSERT` statement to the database and waits for the reply. Because the reply carries nothing that subsequent inserts depend on, this wait is wasted. It dominates statement cost over remote connections and leaves the process largely idle. Existing parallel workflows in pygrametl only distribute this wait across workers rather than eliminating it.

#ref(<fig-timeline>) illustrates PostgreSQL's pipeline mode which enables
a client to send batches of statements without
waiting for individual responses~#cite(<postgres>). The server executes them in order and the client reads results at explicit synchronization points. We implemented a `PipelinedConnectionWrapper` around a standard psycopg 3 connection to keep ETL code transferable from original pygrametl~#cite(<psycopg3>). Fire-and-forget statements such as `INSERT` are queued unanswered, while the wrapper synchronizes whenever a result is required (`SELECT` or `COMMIT`). Because PostgreSQL prohibits `COPY` inside a pipeline, the wrapper temporarily exits pipeline mode before a `COPY` and re-enters it afterward.

#figure(
  layout(avail => {
    let label-w = 1.8cm
    let bar-w = avail.width - label-w
    let unit = bar-w / 18 // 6 sends (1u each) + 6 waits (2u each) = 18 units
    let seg(u, fill, body) = box(
      width: u * unit,
      height: 0.65cm,
      fill: fill,
      stroke: 0.5pt + white,
      align(center + horizon, text(
        size: 6.5pt,
        fill: white,
        weight: "bold",
        body,
      )),
    )
    let send = seg.with(1, rgb("#3498db"))
    let wait = seg.with(2, rgb("#e74c3c"))
    let sync = seg.with(2, rgb("#e67e22"))

    grid(
      columns: (label-w, 1fr),
      row-gutter: 0.6em,
      align: (left + horizon, left + horizon),
      text(size: 8.5pt)[Sequential], stack(dir: ltr, ..range(6).map(_ => (send[S], wait[wait])).flatten()),
      text(size: 8.5pt)[Pipelined], stack(dir: ltr, ..range(6).map(_ => send[S]), sync[sync]),
    )
    v(0.5em)
    text(size: 7.5pt)[
      #box(width: 0.5em, height: 0.5em, fill: rgb("#3498db")) send a statement
      #h(0.8em)
      #box(width: 0.5em, height: 0.5em, fill: rgb("#e74c3c")) wait for a reply
      #h(0.8em)
      #box(width: 0.5em, height: 0.5em, fill: rgb("#e67e22")) wait at a sync point
    ]
  }),
  caption: [Client activity over time for six statements. Time runs from left to right. Segment widths are illustrative and not to scale.],
) <fig-timeline>

We evaluate three pipelined variants built on existing workflows: `Pipeline sequential`, `Pipeline multiprocessing` and `Pipeline free-threading`. All three use the pipelined connection wrapper. The first runs the `cpygrametl1_db` workflow with a single pipelined connection. The other two run the `cpygrametl2_db` workflow; the second with one pipelined connection per worker process and the third with one per worker thread on free-threaded CPython `3.15t`.
