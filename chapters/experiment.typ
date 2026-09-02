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


= Experiments <Experiments>
== Grid Search Optimization
To systematically determine the optimal parameters for the cost function, a grid search methodology is employed. 

#[
  #set par(justify: false)
  #figure(
    table(
      columns: (1fr, 1.1fr, 1fr),
      stroke: none,
      inset: (x: 0.5em, y: 0.6em),
      align: center,
      table.hline(),
      table.header(
        [*$w_"wait"$*], [*$w_"dev"$*], [*$w_"price"$*],
      ),
      table.hline(stroke: 0.5pt),
      [1, 17, 33, 49, \ 65, 82, 100],
      [1, 20.8, 40.6, 60.4, 80.2, 100],
      [1, 2.8, 4.6,\ 6.5, 8.2, 10],
      table.hline(),
    ),
    caption: [Grid search parameter space across 252 total configurations.],
  ) <GridConfigurations>
]

The parameter space is defined by three primary weights outlined in @GridConfigurations: price sensitivity *$w_"price"$* (bounded between 1 and 10), path deviation *$w_"dev"$* (1 to 100), and expected wait time *$w_"wait"$* (1 to 100).

== Baseline Strategy <Baseline>
The baseline represents a minimalistic approach to charging station selection where EVs select stations solely by minimizing path deviation. This serves as a reference point against which optimized configurations are evaluated. By comparing the performance of the optimized strategies against this baseline, it is possible to quantify the improvements achieved through optimization and to better understand the impact of different decision-making factors on overall system performance. 

== Scoring System <ScoringSystem>
To evaluate simulation performance under different configurations, a scoring system was developed. This enables a comparative analysis of simulation runs, allowing for identification of better and worse configurations based on different run objectives. The metrics are categorized into two primary domains: EV-centric and station-centric.

=== Performance Metrics
The evaluation is based on the following metrics, which provide the necessary variance to optimize for either station-centric or EV-centric outcomes.

Station-centric metrics:
- *Utilization:* The ratio of a station's throughput that is being used.
- *Expected wait time:* A predictive measure of the queuing duration at a station at a given timestamp.

EV-centric metrics:
- *Waiting time:* The duration individual EVs remain idle before beginning a charging session.
- *Path deviation:* The additional distance traveled to reach a charging station, relative to the direct origin-to-destination path.
- *Missed deadline:* Whether an EV fails to reach its destination before its assigned deadline.
- *Delta arrival time:* The time difference between actual and expected arrival.

=== Metric Scoring
Metrics are captured at discrete intervals, henceforth referred to as snapshots. Each snapshot is assigned a normalized score, which is then aggregated into a global simulation score ranging from 0 to 1.

=== Scoring Weight Configurations
The final simulation score is the mean of the aggregated EV and Station scores. Within each domain, individual metrics are aggregated using penalty weights. Two primary penalty weighting mechanisms are employed:
- *Bucket Weighting:* As an example, for EV path deviation, the penalty weight is determined by the minutes of deviation, with larger deviations receiving higher penalties.
- *Linear Weighting:* Applied to metrics without natural intervals, such as missed deadlines. The EVs either miss the deadline or not.


=== Station Scoring
Station metrics utilize percentile-based buckets, 25th, 50th, 75th, 90th, 95th, and 99th percentile, to categorize the distribution of metrics across the stations each snapshot. While the utilization score for a station is derived from the station's normalized utilization percentage, the expected wait time is evaluated using a Gaussian decay function. This ensures the score asymptotically approaches 0 as wait times increase, maintaining a domain of [0, 1]:

$
  "Expected Wait Time Score" = e^(-(frac(t, 45))^2)
$
where $t$ represents the expected wait time in minutes.

Under this model, a 0-minute wait yields a score of 1.0, while 45 and 90 minutes yield approximately 0.368 and 0.018, respectively.

The final station score is then calculated by taking a weighted mean of the metrics, multiplied by their penalty weights, at each interval and then calculating the mean of these weighted snapshots across the entire simulation.


=== EV Scoring
The EV domain also utilizes the bucket system to penalize delays for path deviation, delta arrival, and waiting time. Missed deadlines utilizes the linear weight system, scored as the inverse of the failure rate. While waiting time uses the aforementioned Gaussian decay function, as well as the percentile buckets, the path deviation and delta arrival uses a more granular bucket system, focusing on groups of minutes. The bucket spans are 0-5, 5-10, 10-15, 15-30, 30-60, and 60+ minutes, with delta arrival also including a 0-minute bucket to ensure on-time arrivals receive no penalty.

The final EV score is determined consistently with station scoring. At each snapshot interval, individual EV metrics are aggregated into a weighted snapshot score based on their respective penalty weights.

=== Simulation Scoring
The final simulation score is an aggregate of the EV and station domain scores, with values approaching 1 representing optimal performance. By calculating the final score as the mean of the normalized metrics, the model ensures balance between the two groupings. This prevents a configuration from appearing successful by excelling in one area at the expense of the other.