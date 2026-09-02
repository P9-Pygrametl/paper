#show figure: set block(breakable: true)
#set heading(numbering: none)
= Appendix
#let table-header = rgb(gray)
#let table-stripe = rgb("#EAEAEA")
#set table(
  fill: (x, y) => 
    if y == 0 {
      table-header
    } else {
      if calc.even(y) {
        table-stripe
      } else {
          none
      }
    },
  stroke: 0.5pt,
  align: center,
  inset: 0.4em,
)
#set heading(numbering: "A.1", supplement: [Appendix])
#set figure(supplement: "Appendix", numbering: num => context {
  counter(heading).display("A")
})
#counter(heading).update(0)
#show heading.where(level: 1): it => {
  counter(figure).update(0)
  text(size: 12pt, it)
}

= Origin Heatmap <Heatmap>
#figure(
  image("figures/HeatmapZoomedOut.png"),
  caption: [Heatmap of spawn origins]
)

= Charging Curve <charging-curve>
#include "figures/charging-curve.typ"

= Full Configuration Scores <configurationScoresFull>
#figure(
  image("figures/configuration_scores.svg"),
  caption: [Configuration scores]
) 

#pagebreak()

= Raw Metrics <rawMetricsTable>
#figure(
  caption: [Table of raw metrics],
  block(width: 100%)[
    #set text(size: 11pt)
    #table(
      columns: (auto, 1fr, 1fr, 1fr, 1fr),
      align: (left, right, right, right, right),
      stroke: none,
      inset: (x: 3.5pt, y: 5pt),

      table.hline(),
      [*Metric*], [*Best*], [*BestEV*], [*Worst*], [*Base*],
      table.hline(stroke: 0.5pt),

      [ev_queue_wait_time_mean], [0.904], [0.673], [23.548], [21.778],
      [ev_queue_wait_time_std], [3.080], [2.661], [43.107], [40.859],
      [ev_queue_wait_time_p50], [0.0], [0.0], [0.0], [0.0],
      [ev_queue_wait_time_p75], [0.0], [0.0], [29.0], [26.0],
      [ev_queue_wait_time_p90], [3.0], [1.0], [84.0], [78.0],
      [ev_queue_wait_time_p95], [7.0], [5.0], [114.0], [107.0],
      [ev_queue_wait_time_p99], [15.0], [13.0], [203.0], [195.0],
      [ev_queue_wait_time_p99.9], [29.0], [28.0], [284.0], [272.0],
      [ev_queue_wait_time_mean_nz], [6.382], [5.914], [49.953], [47.756],
      [ev_queue_wait_time_nz_p25], [2.0], [2.0], [12.0], [11.0],
      [ev_queue_wait_time_nz_p50], [5.0], [4.0], [32.0], [31.0],
      [ev_queue_wait_time_nz_p75], [9.0], [8.0], [75.0], [71.0],
      [ev_queue_wait_time_nz_p90], [13.0], [12.0], [116.0], [110.0],
      [ev_queue_wait_time_nz_p95], [17.0], [16.0], [144.0], [139.0],
      [ev_queue_wait_time_nz_p99], [27.0], [27.0], [244.0], [236.0],
      [ev_queue_wait_time_nz_p999], [46.0], [48.0], [313.0], [300.0],
      [expected_wait_mean], [1.174], [1.193], [4.467], [4.268],
      [expected_wait_std], [5.428], [5.467], [30.441], [29.196],
      [expected_wait_p90], [0.0], [0.0], [0.0], [0.0],
      [expected_wait_p95], [9.0], [9.0], [7.0], [8.0],
      [expected_wait_p99], [28.0], [28.0], [146.0], [138.0],
      [expected_wait_p99.9], [57.0], [58.0], [444.0], [432.0],
      [expected_wait_mean_nz], [15.818], [15.530], [76.382], [71.962],
      [expected_wait_nz_p25], [7.0], [7.0], [13.0], [12.0],
      [expected_wait_nz_p50], [13.0], [12.0], [34.0], [31.0],
      [expected_wait_nz_p75], [21.0], [20.0], [100.0], [92.0],
      [expected_wait_nz_p90], [32.0], [31.0], [207.0], [195.0],
      [expected_wait_nz_p95], [40.0], [40.0], [287.0], [272.0],
      [expected_wait_nz_p99], [61.0], [62.0], [483.0], [469.0],
      [expected_wait_nz_p99.9], [98.0], [101.0], [611.732], [591.0],
      [path_deviation_mean], [13.560], [14.779], [9.823], [9.511],
      [path_deviation_std], [12.387], [13.523], [10.151], [10.083],
      [path_deviation_p25], [2.782], [3.265], [1.332], [1.107],
      [path_deviation_p50], [11.334], [12.268], [6.932], [6.429],
      [path_deviation_p75], [20.572], [22.120], [15.571], [15.171],
      [path_deviation_p90], [30.216], [32.819], [24.120], [23.768],
      [path_deviation_p95], [36.893], [40.485], [29.767], [29.436],
      [path_deviation_p99], [51.905], [57.878], [41.479], [41.138],
      [path_deviation_p99.9], [73.336], [80.060], [56.053], [55.826],
      [delta_arrival_mean], [0.953], [0.994], [5.795], [5.049],
      [delta_arrival_std], [12.622], [12.881], [24.166], [22.500],
      [delta_arrival_p75], [0.0], [0.0], [0.0], [0.0],
      [delta_arrival_p90], [0.0], [0.0], [4.641], [0.0],
      [delta_arrival_p95], [0.0], [0.0], [40.364], [32.873],
      [delta_arrival_p99], [7.411], [9.719], [136.868], [128.920],
      [delta_arrival_p99.9], [222.480], [225.170], [236.349], [226.754],
      [delta_arrival_mean_late], [82.270], [82.413], [53.297], [51.606],
      [delta_arrival_std_late], [84.018], [83.916], [53.290], [52.648],
      [path_deviation_late_mean], [19.006], [21.043], [16.004], [16.040],
      [path_deviation_late_p50], [16.084], [17.573], [14.259], [14.314],
      [path_deviation_late_p95], [51.430], [57.545], [38.197], [38.253],
      [path_deviation_ontime_mean], [13.496], [14.702], [9.069], [8.803],
      [path_deviation_ontime_p50], [11.288], [12.216], [6.034], [5.599],
      [path_deviation_ontime_p95], [36.698], [40.246], [28.136], [27.875],
      [missed_deadline_frac], [0.012], [0.012], [0.109], [0.098],

      table.hline()
    )
  ]
)