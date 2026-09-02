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

= Results <results>
#figure(
  image("../figures/configuration_scores_with_worst.svg"),
  caption: [Configuration Scores] 
) <configurationScores>
@configurationScores showcases a 4-dimensional representation of the configurations gathered from the grid search. Each axis, *$w_"price"$*, *$w_"dev"$* and *$w_"wait"$*, is its own dimension, and the color of the points represents the score the run achieved. Additionally, it should be noted that all points below the score of 0.78 have been excluded in @configurationScores for visualization purposes and the full figure can be seen in @configurationScoresFull.
The data shows that higher *$w_"price"$* is generally associated with lower scores, indicating a clear negative relationship between price sensitivity and score. *$w_"dev"$* shows an optimal intermediate range, where both very low and very high values correspond to lower scores, suggesting that moderate *$w_"dev"$* yields the best results. *$w_"wait"$* behaves similarly, where higher values tend to produce better scores, while lower values are generally associated with worse outcomes. 


#figure(
  block(width: 100%)[
    #set text(size: 10pt)
    #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (left, center, center, center, center, right),
      stroke: none,
      inset: (x: 3.5pt, y: 5pt),
      
      table.hline(),
      [*Config.*], [*$w_"wait"$*], [*$w_"dev"$*], [*$w_"price"$*], [*Score*], [*$plus.minus$ %*],
      table.hline(stroke: 0.5pt),
      
      [*Baseline*], [1.0], [100.0], [1.0], [0.489], [0.00],
      [*Best*], [65.0], [40.6], [1.0], [0.803], [64.28],
      [*Worst*], [1.0], [100.0], [8.2], [0.481], [-1.61],
      [*EV*], [82.0], [20.8], [1.0], [0.795], [62.56],
      [*Station*], [65.0], [40.6], [1.0], [0.803], [64.28],
      
      table.hline()
    )
  ],
  caption: [Scores and relative improvement over baseline across configurations.]
) <combinedScores>

The configurations selected from @configurationScores capture the highest-scoring configurations for the best overall, station, and EV scores, alongside the lowest-scoring overall configuration. Their corresponding combined scores and comparison against the baseline are showcased in @combinedScores. As the configurations for *Best* and *Station* are identical, only *Best* will be considered in further analysis.

*Best* was identified as the highest-scoring configuration from the grid search, balancing all three cost components. *EV* represents the variant that had the highest EV score. *Worst* represents the variant that had the lowest-scoring configuration. The *Baseline* configuration uses only path deviation as its decision criterion, reflecting the minimalistic strategy described in @Baseline.

The baseline achieves a score of 0.489, establishing the performance floor against which all other configurations are evaluated. *Best* yields a score of 0.803, a 64.28% improvement over the baseline.

*Best* suggests that prioritizing *$w_"wait"$* over *$w_"dev"$* is the primary driver of system-wide improvement, as agents accepting moderate route detours in exchange for reduced queuing yields the greatest benefit. This is consistent with the prospective load-balancing mechanism described in @EWTCost: by penalizing *$C_"wait"$* at the estimated arrival time rather than current occupancy, the cost function naturally disperses demand across the network before station congestion materializes. 

The worst-performing grid search configuration, *Worst*, demonstrates that carelessly enabling all three cost components does not guarantee improvement over the baseline. *Worst* scores comparably to *Baseline*, reinforcing that weight configuration is important. For instance, this could be due to a misconfigured *$w_"wait"$* weight, which could cause agents to over-prioritize distant low-congestion stations, inflating path deviation costs despite decreasing the wait time.

The 3 configurations, *Best*, *EV* and *Worst* can be seen highlighted in red in @configurationScores, where the yellow point is *Best*, the green point is *EV* and the black point is *Worst*.

== Reliability Analysis
To assess whether the selected configurations were reliable across randomized seeds, each configuration was evaluated over multiple simulation runs with different random seeds. This makes it possible to distinguish broader performance tendencies from individual simulation outcomes.

#include "../charts/best.typ"
#include "../charts/bestev.typ"
#include "../charts/worst.typ"

The resulting score distributions are shown in @best-distribution, @bestev-distribution, and @worst-distribution. In total, the evaluation consists of 305 runs of *Best*, 383 runs of *EV*, and 131 runs of *Worst*. The distributions show that both *Best* and *EV* consistently achieve high scores, with most observations concentrated near the upper end of their respective score ranges. *Best* ranges from 0.772 to 0.806, while *EV* ranges from 0.743 to 0.807. Although both configurations have similar average scores, the wider range of *EV* indicates that it is more sensitive to the random seed than *Best*.

In comparison, *Worst* produces substantially lower scores than both *Best* and *EV*, with its runs ranging from 0.470 to 0.494. However, the distribution is not concentrated around a single clear value. Instead, the scores are spread across most of the observed interval, which indicates that the outcome varies slightly between seeds.

To investigate the smaller score concentrations around 0.78 in @best-distribution and @bestev-distribution, the runs were divided into two buckets: runs with scores between 0.76 and 0.79, and runs with scores from 0.79 and above. The purpose of this comparison was to examine whether the lower-scoring group differed noticeably in any of the underlying score components.

For *Best*, the difference between the two buckets is small. The overall score differs by 1.83%, while most individual components remain nearly unchanged. The largest differences are found in EV wait time and expected wait, but these are still limited. This makes it difficult to identify a single component as the cause of the lower score concentration.

For *EV*, the difference is slightly more visible, with an overall score difference of 1.94%. Here, expected wait, EV wait time, and path deviation show the most noticeable changes. However, the differences are still not large enough to determine a clear cause.

The bucket comparison therefore suggests that the bumps are not explained by one obvious scoring component. Instead, the lower score concentrations appear to reflect general seed-dependent variation across several metrics. The exact reason for these differences could not be isolated from the available data.

== Metric Breakdown
The full distributional statistics across all four configurations reveal several differences that aggregate scores alone cannot capture. The performance metrics shown in @rawMetricsTable reveal that the primary benefit of the distributed scheduling system is not necessarily an improvement in average-case charging behavior. The system rather prevents extreme congestion events, where the optimized configurations reduce queue formation under peak-load conditions. The following subsections examine these distributional differences in detail.  

=== Queue Wait Time
The most striking contrast lies in the EV queue wait time distributions. Both *Best* and *EV* achieve mean queue waits under one minute, 0.90 and 0.67 minutes respectively, while *Worst* and *Baseline* produce means of 23.5 and 21.8 minutes. Crucially, the median queue wait is 0 across all configurations, indicating that the majority of EVs never wait at all. The divergence emerges in the upper tail: at the 90th percentile, *Best* and *EV* incur only 3 and 1 minutes of waiting, whereas *Worst* and *Baseline* reach 84 and 78 minutes. At the 99th percentile this gap remains severe in absolute terms, 15 minutes for *Best* versus 203 for *Worst*, and escalates further at the 99.9th percentile to 29 minutes against 284. Among EVs that do queue *Best* and *EV* see median waits of 5 and 4 minutes, compared to 32 and 31 minutes under *Worst* and *Baseline*. This confirms that the smart configurations reduce extreme queuing events across the network.

=== Expected Wait Time
The expected wait time metrics, reflecting station-projected congestion at estimated arrival, mirror the queue wait findings but with amplified tail values. While both *Best* and *EV* maintain a mean of around 1.17-1.19 minutes and an identical 90th percentile of zero, the 99.9th percentile under *Worst* reaches 444 minutes versus 57-58 minutes under the optimized configurations. Among the expected wait time cases that are non-zero, *Worst* reports a mean projected wait of 76.4 minutes, compared to the 15.5-15.8 minutes seen in *Best* and *EV*. Notably, *Baseline* performs comparably to *Worst* on this metric, confirming that the baseline's purely deviation-minimizing heuristic provides no protection against station-level congestion. The near-identical expected wait figures between *Best* and *EV*, differing by less than 0.3 minutes in the non-zero mean and by at most one minute across all shared percentile breakpoints, reinforces the earlier finding that these two configurations are functionally similar.

=== Path Deviation
The lower path deviation in *Worst* and *Baseline*, means of 9.8 and 9.5 minutes, relative to *Best* and *EV*, 13.6 and 14.8 minutes, is an expected consequence of their nearest-station routing strategy rather than a genuine efficiency advantage. By always directing agents to the closest available station, these configurations minimize detour distance, but at the cost of concentrating demand and producing severe congestion.

//TODO: Mention something about low MD frac, but high wait time.
=== Deadline Adherence and Delta Arrival
The missed deadline fraction offers perhaps the clearest summary statistic for EV impact. *Best* and *EV* both achieve a missed deadline fraction of 0.012, compared to 0.109 for *Worst* and 0.098 for *Baseline*. The delta arrival distributions for late EVs show that the mean lateness under *Worst*, 53.3 minutes, is actually lower than under *Best* and *EV*, 82.3 and 82.4 minutes. However, the 99th percentile delta arrival under *Worst* reaches 136.9 minutes, whereas that number is 7.4 and 9.7 under *Best* and *EV*, showing that the worst-case late arrivals are dramatically more severe under the poorly configured system.


#import "@preview/lilaq:0.6.0" as lq
#let xs = range(25)
#let labels = ("10:00","10:20","10:40","11:00","11:20","11:40","12:00","12:20","12:40","13:00","13:20","13:40","14:00","14:20","14:40","15:00","15:20","15:40","16:00","16:20","16:40","17:00","17:20","17:40","18:00")
#let sw = (0.5305,0.5638,0.5484,0.5513,0.5421,0.5811,0.5971,0.6687,0.6961,0.7148,0.7340,0.7017,0.7122,0.7032,0.7152,0.6800,0.6803,0.6821,0.6398,0.6787,0.6619,0.6552,0.6542,0.6441,0.6472)
#let ev = (0.9051,0.9064,0.8955,0.8949,0.8744,0.8620,0.8974,0.9157,0.9415,0.9514,0.9557,0.9569,0.9588,0.9491,0.9506,0.9522,0.9391,0.9416,0.9429,0.9468,0.9401,0.9346,0.9367,0.9246,0.9778)
#let cb = (0.7178,0.7351,0.7220,0.7231,0.7082,0.7216,0.7472,0.7922,0.8188,0.8331,0.8449,0.8293,0.8355,0.8261,0.8329,0.8161,0.8097,0.8119,0.7913,0.8128,0.8010,0.7949,0.7955,0.7843,0.8125)
#let pd = (0.8529,0.8364,0.8265,0.8256,0.8300,0.8251,0.8361,0.8346,0.8558,0.8614,0.8705,0.8779,0.8889,0.8845,0.8832,0.8865,0.8772,0.8809,0.8750,0.8785,0.8671,0.8725,0.8659,0.8559,0.9111)
#let da = (0.9998,0.9996,0.9993,0.9993,0.9987,0.9988,0.9980,0.9965,0.9969,0.9935,0.9931,0.9876,0.9952,0.9843,0.9867,0.9832,0.9756,0.9870,0.9794,0.9826,0.9808,0.9850,0.9884,0.9895,1.0000)
#let ew = (0.8459,0.8607,0.8390,0.8379,0.7814,0.7522,0.8396,0.8918,0.9457,0.9721,0.9778,0.9822,0.9721,0.9611,0.9611,0.9668,0.9472,0.9386,0.9537,0.9581,0.9499,0.9273,0.9341,0.9079,1.0000)
#let md = (0.9980,0.9971,0.9957,0.9956,0.9938,0.9916,0.9924,0.9885,0.9897,0.9852,0.9845,0.9775,0.9861,0.9716,0.9812,0.9775,0.9657,0.9816,0.9733,0.9781,0.9751,0.9801,0.9826,0.9822,1.0000)
#let ut = (0.2243,0.2247,0.2238,0.2193,0.2027,0.1975,0.1852,0.1696,0.1570,0.1503,0.1511,0.1496,0.1399,0.1553,0.1547,0.1650,0.1666,0.1687,0.1662,0.1794,0.1791,0.1822,0.1870,0.1907,0.1892)
#let ex = (0.6325,0.6769,0.6567,0.6620,0.6552,0.7090,0.7343,0.8350,0.8759,0.9030,0.9283,0.8858,0.9030,0.8858,0.9020,0.8516,0.8516,0.8533,0.7976,0.8451,0.8228,0.8128,0.8100,0.7952,0.8000)


== Temporal Dynamics of Simulation Scores
#let xticks = range(25).filter(i => calc.rem(i, 4) == 0).map(i => (float(i), labels.at(i)))
#show lq.selector(lq.legend): set grid(columns: 4)
#figure(
  
  lq.diagram(
  legend: (position: bottom, dy: 35%),
  height: 8cm,
  width: 7.1cm,
  ylim:   (0.5, 1.03),
  xaxis:  (ticks: xticks),
  lq.plot(xs, cb, mark: none, stroke: 2pt, label: [Combined]),
  lq.plot(xs, sw, mark: none, stroke: 2pt, label: [Station]),
  lq.plot(xs, ev, mark: none, stroke: 2pt, label: [EV]),

  lq.plot(xs, pd, mark: none, label: [Path deviation]),
  lq.plot(xs, da, mark: none, label: [Delta arrival]),
  lq.plot(xs, ew, mark: none, label: [EV Wait]),
  lq.plot(xs, md, mark: none, label: [Deadline]),
  
  lq.plot(xs, ex, mark: none, label: [Expected wait]),

),
placement: auto,
caption: [Simulation scores over time for best observed run.]
) <TimeSeriesResults>

The temporal progression of the simulation scores, as illustrated in @TimeSeriesResults, provides insight into the dynamic interaction between the Station and EV domains between 10:00 and 18:00. Over this simulation window, the Combined Score exhibits distinct fluctuations that align closely with network load patterns. A notable decline in aggregate system performance occurs during the late morning, reaching its lowest point around 11:40 with a Combined Score of approximately 0.722. This is followed by a steady recovery to a midday peak of 0.845 at 13:20. This recovery phase reflects the network's capacity to clear queues once the immediate influx of newly spawned EV agents subsides. A secondary dip emerges approaching 16:00, corresponding to the elevated evening traffic.

Deconstructing this temporal trend confirms the differences between the two domain scores discussed previously. The Station Score demonstrates high volatility throughout the day, tracking closely with the expected wait time component. It drops to 0.542 during the 11:20 congestion peak, illustrating how localized station saturation rapidly degrades station domain performance, even when individual routing decisions are optimal.

In contrast, the EV Score remains resilient. It maintains values above 0.86 even during the peak stress period and exceeds 0.95 during off-peak hours. This stability is supported by the consistent satisfaction of individual constraints. Metrics such as delta arrival and deadline adherence remain near 1.0 throughout the entire simulation day, demonstrating that the configuration successfully prevents EVs from stranding or missing critical time constraints regardless of the surrounding network state. Furthermore, the path deviation metric remains highly stable between 0.82 and 0.91, proving that the algorithm achieves its load-balancing without forcing agents into long detours.