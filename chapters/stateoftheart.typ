= State of the Art <StateOfTheArt>
This section reviews the current landscape of EV charging optimization, specifically focusing on how scheduling is used to reduce station congestion and wait times. To showcase the varying methodologies researchers currently apply to this problem, this chapter evaluates three distinct approaches. These range from centralized public transit models and theoretical frameworks to large-scale traffic simulation.
== Simulation-based Optimization for Electric Buses
Chiu et al. demonstrate the necessity of simulation-based approaches when modeling complex charging scenarios @chiu2024. By utilizing real-world operational data from a transit network in Taiwan, they investigated the stochastic nature of actual traffic and service conditions.

A key success of their modeling was proving that dynamic charging rules (e.g., adjusting charge duration based on current queue length) significantly outperform static, "fill-it-up" policies. This finding validates that flexibility is important for efficient station utilization. However, their definition of a "realistic environment" applies specifically to the traffic data, while the behavioral environment remains simplified. They achieve flexibility through centralized control by enforcing specific charge levels on fleet vehicles. While feasible for public transit systems operating on deterministic, fixed schedules, this centralized optimization technique fails to account for the diverse preferences and personal deadlines of private EV users.

== War Strategy Optimization for EV Scheduling
In contrast to Chiu et al., Madaram et al. introduced an optimization technique called War Strategy Optimization (WSO) to solve the charge scheduling problem for EVs @madaram2024. Using a military metaphor, their algorithm balances four objectives: minimizing total travel time, waiting time, charging cost, and maximizing grid stability. Each EV is treated as a soldier, and in each iteration a control parameter $rho$ is sampled uniformly between 0 and 1 and compared against a threshold of 0.5 to probabilistically assign one of two behaviors:

- *Attack Mode:* The EV moves toward its destination while accounting for charging time, reducing total travel time.
- *Defense Mode:* The EV moves toward its destination while avoiding congested charging stations, reducing waiting time.

After each iteration, soldiers are ranked based on how well their assigned charging schedule minimizes travel time, waiting time, and cost while maintaining grid stability. Poorly performing soldiers are then relocated to new positions, allowing the algorithm to continuously refine its scheduling decisions across iterations. While the system reduced waiting times by 83.25% over a First-Come-First-Serve baseline, improvements over more comparable algorithms were smaller: 11.17% over Chaotic Harris Hawk Optimization and 39.09% over Harris Hawk Optimization.

The algorithm was validated on a simplified network modeled on the city of Chennai with only 22 nodes and 12 charging stations. The evaluation further assumes all EVs can reach any charging station with their available battery, and the maximum tested load of 200 concurrent EVs is negligible compared to the hundreds of thousands found in real-world application.

== Event-Based Modeling of EV Charging Services
To capture specific user-station interactions in EV infrastructure, Mangini et al. proposed a Timed Colored Petri Net framework for simulating and managing multi-user charging demand @mangini2025.

Their model demonstrates the utility of evaluating infrastructure through discrete event states rather than continuous physical traffic flow. By treating the charging process as a series of state transitions, their framework explicitly tracks individual, multi stage user decisions such as an EV driver searching for available charging points, comparing tariffs, and booking a preferred charge point in a specific geographic area.

Furthermore, the model manages queue times and calculates charging durations based on the vehicle's State of Charge (SoC) and the station's power rate @mangini2025. However, the framework imposes strict constraints on the infrastructure. The model assumes each charging point can service only one vehicle at a time and limits the physical queue capacity to a maximum of two vehicles per station. Consequently, while the study simulates thousands of vehicles over a 30-day period, the simulated environment remains relatively small, consisting of only nine charging points within a single city.

== Summary and Identified Gap
Existing research effectively demonstrates the importance of dynamic scheduling @chiu2024, multi-objective routing @madaram2024, and event-based logic @mangini2025. Although each study isolates certain dimensions, such as behavior, routing, or scale, none integrates all three simultaneously. Studies either rely on deterministic fleets, validate on artificial road networks, or restrict complex event logic to localized zones.

Consequently, a gap remains in evaluating the behavior of private EVs, where individual preferences, and event-driven decision logic, and nationwide scale are considered simultaneously. This paper attempts to bridge this gap by introducing a simulation environment that addresses all three dimensions within a single framework.
