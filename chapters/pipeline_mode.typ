#import "@preview/smartaref:0.1.2": Cref, cref
== Pipeline Mode <pipeline_mode>
#Cref[@multiprocessing @subinterpreters @freethreading @async] focus on how @ETL work is scheduled. Pipeline mode addresses a different bottleneck: `pygrametl` loads data row by row, and each `insert` call normally waits for the database response before sending the next statement. For independent inserts, that round-trip wait does not contribute to the transformation and can leave the client idle. Parallel workers can overlap some of this waiting, but do not remove it.

As shown in @fig-timeline, PostgreSQL pipeline mode lets a client send multiple statements without waiting for each response @postgres. The server executes statements in order, and the client reads results at explicit synchronization points. We implemented a `PipelinedConnectionWrapper` around a psycopg 3 connection to use this mode without changing the @ETL workflow @psycopg3. The wrapper queues statements such as `INSERT` and synchronizes when a result is needed, for example by a `SELECT` or `COMMIT`. Since PostgreSQL does not permit `COPY` inside a pipeline, the wrapper temporarily leaves pipeline mode for a `COPY` operation and re-enters it afterward.

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

//We evaluate three variants, all using the wrapper: `Pipeline sequential` runs the sequential workflow with one pipelined connection; `Pipeline multiprocessing` uses one pipelined connection per worker process; and `Pipeline free-threading` uses one per worker thread on free-threaded CPython `3.15t`. This comparison tests whether pipelining helps independently and whether it combines with either worker model.
