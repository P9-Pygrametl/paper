
//----- Pipeline Mode results -----
#figure(
  {
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto, auto, auto),
      inset: (x: 2.5pt, y: 4pt),
      stroke: none,
      align: (left, right, right, right, right),
      table.hline(),
      table.header[*Impl.*][*Wall (s)*][*Speedup*][*CPU (s)*][*CPU (%)*],
      table.hline(stroke: 0.5pt),
      [Baseline], [#box[111.9 #sym.plus.minus 12.1]], [1.0x], [44.4], [40.0],
      [Sequential], [#box[36.8 #sym.plus.minus 0.3]], [3.0x], [31.9], [86.6],
      [Multiprocessing], [#box[22.8 #sym.plus.minus 0.2]], [4.9x], [72.3], [317.3],
      [Free-threading], [#box[17.5 #sym.plus.minus 0.2]], [6.4x], [66.4], [379.5],
      table.hline(),
    )
  },
  caption: [Mean wall time, standard deviation, CPU time, and utilization at 100 pages.],
)

Pipelining alone makes the sequential workflow 3.0x faster than `cpygrametl1_db` while cutting CPU time by 28 percent and raising CPU utilization from 40.0 to 86.6 percent as round-trip idle time disappears. Combining pipelining with parallelism reaches 4.9x speedup for multiprocessing and 6.4x for free-threading, trading 1.5x to 1.6x higher total CPU time for lower wall time.

Run time scales linearly with page count across all pipelined variants, with speedups peaking at 25 pages (7.0x for free-threading) and tapering slightly by 100 pages (6.4x). Pipelining also eliminates timing jitter, dropping standard deviation at 100 pages from 12.1 seconds to under 0.3 seconds. Three of the 120 `Pipeline free-threading` runs crashed with a segmentation fault (one each at 50, 75, and 100 pages) and are excluded from the means above. The root cause remains under investigation.
