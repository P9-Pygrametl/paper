== Pipeline Mode

Pygrametl loads data row by row. Each `insert` sends one statement to the database and waits for the reply. Because the reply carries nothing that subsequent inserts depend on, this wait is wasted. It dominates statement cost over remote connections and leaves the process largely idle even locally. Existing parallel workflows in pygrametl only distribute this wait across workers rather than eliminating it.

PostgreSQL's pipeline mode allows a client to send batches of statements without waiting for individual responses. The server executes them in order and the client reads results at explicit synchronization points. We implemented a `PipelinedConnectionWrapper` around a standard psycopg 3 connection to keep ETL code transferable from original pygrametl. Fire-and-forget statements such as `INSERT` are queued unanswered, while the wrapper synchronizes whenever a result is required (`SELECT` or `commit`). Because PostgreSQL prohibits `COPY` inside a pipeline, the wrapper temporarily exits pipeline mode before a `COPY` and re-enters it afterward.

We evaluate three pipelined variants built on existing workflows: `Pipeline sequential` (`cpygrametl1_db` with the pipelined wrapper), `Pipeline multiprocessing` (`cpygrametl2_db` using a pipelined connection per worker process), and `Pipeline free-threading` (`cpygrametl2_db` running threads on free-threaded CPython `3.15t`).

#figure(
  table(
    columns: 6,
    align: (left, right, right, right, right, right),
    table.header[Implementation][Wall (s)][Std. dev. (s)][Speedup][CPU (s)][CPU (%)],
    [`cpygrametl1_db`], [111.9], [12.1], [1.0x], [44.4], [40.0],
    [Pipeline sequential], [36.8], [0.3], [3.0x], [31.9], [86.6],
    [Pipeline multiprocessing], [22.8], [0.2], [4.9x], [72.3], [317.3],
    [Pipeline free-threading], [17.5], [0.2], [6.4x], [66.4], [379.5],
  ),
  caption: [Mean wall time, CPU time, and utilization at 100 pages.],
)

Pipelining alone makes the sequential workflow 3.0x faster than `cpygrametl1_db` while cutting CPU time by 28 percent and raising CPU utilization from 40.0 to 86.6 percent as round-trip idle time disappears. Combining pipelining with parallelism reaches 4.9x speedup for multiprocessing and 6.4x for free-threading, trading 1.5x to 1.6x higher total CPU time for lower wall time.

Run time scales linearly with page count across all pipelined variants, with speedups peaking at 25 pages (7.0x for free-threading) and tapering slightly by 100 pages (6.4x). Pipelining also eliminates timing jitter, dropping standard deviation at 100 pages from 12.1 seconds to under 0.3 seconds. Three of the 120 `Pipeline free-threading` runs crashed with a segmentation fault (one each at 50, 75, and 100 pages) and are excluded from the means above. The root cause remains under investigation.
