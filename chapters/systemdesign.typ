= Data Acquisition <data_acquisition>
To reflect the Danish EV charging environment, the simulation draws on five datasets covering national EV ownership, charging station locations, city populations, road congestion, and energy prices. 

Per-city population counts (January 2025 baseline) and national EV ownership figures (March 2026) were drawn from StatBank Denmark @dst_by1 @dst_bil52. Charging station locations came from OpenChargeMap @openchargemap, from which geographic coordinates were extracted. Since hardware metadata is inconsistently reported, station configurations are synthetically derived, whereby each station is assigned either a single or dual charger, and power outputs are assigned based on station location, with highway stations assigned high kW outputs while other stations are equally split between high and low kW outputs. Agent generation draws on a dataset of 100 distinct EV models sourced from EV-Database @ev-database, with agents inheriting battery parameters and drivetrain efficiency. Spawn probabilities are constrained by real-world market share data from Mobility Denmark @mobility, reflecting the Danish EV fleet composition as of March 2026. Spawn rates are governed by time-of-day congestion data from the Danish Road Directorate @vd_trafik, mapping hourly peaks across the week to derive proportional spawn fractions. Energy prices are sourced from day-ahead spot prices from Energi Data Service @energidataservice, covering per-hour DKK/kWh rates across February 2026, providing a realistic distribution of energy prices throughout the week.

= Simulation model <simulation_model>

#place(
  bottom + center,
  scope: "parent",
  float: true,
  block(width: 90%, include "../figures/system-diagram.typ"),
)

The simulation is designed to investigate how preference-driven, decentralized charging decisions influence station congestion and utilization across a nationwide charging network. Each EV is modeled as an independent agent that makes locally rational charging decisions without central coordination. The emergent behavior produced by these agents competing for shared charging infrastructure constitutes the primary object of study.

The overall structure of the system is illustrated in @system-architecture. National datasets described in @data_acquisition are integrated into a multi-agent simulation pipeline that generates journeys, evaluates charging opportunities, and records system-wide performance metrics. During execution, EV agents traverse the Danish road network and dynamically evaluate whether charging is required before reaching their destination. When charging becomes necessary, reachable stations are evaluated through a multi-objective cost function incorporating a weighted set of cost parameters.

Because charging stations operate as limited physical resources, independently acting EVs compete for the same infrastructure, producing dynamic queue formation and uneven load distributions across the network. To evaluate these interactions, the simulation records both infrastructure-level and vehicle-level performance metrics. Together, these outputs provide a basis for analyzing how decentralized charging behavior affects both network efficiency and driver experience at national scale.

== Discrete Event Simulation
The simulation generates a large volume of events. To handle this, a Discrete Event Simulation (DES) framework is utilized @banks2010discrete. Unlike continuous or time-stepped simulations that poll the system state at uniform intervals, DES models a system as a chronological sequence of discrete events, where state changes occur instantaneously at discrete points in time. The global clock advances directly to the timestamp of the next scheduled event.

By skipping the empty intervals between events, the framework avoids the computational overhead of repeatedly processing unchanged system states. This efficiency is particularly beneficial at a national scale, where hundreds of thousands of EVs progress through independent lifecycle stages at staggered unpredictable times.

== Journey Generation and Routing
To constrain the simulation to Denmark's geography, Denmark's land area was discretized into a 2D spawn grid. Cells are classified as valid origin points only if they intersect the defined Danish landmass polygons and avoid predefined water bodies.

The system employs a gravity model @gravitymodel to stochastically generate journey origins and destinations. The model does not rely on detailed population density data, but instead uses each city's population count and city-center coordinate. Each city therefore acts as a weighted attraction point, where larger cities have a stronger influence on journey generation than smaller cities.

#include "../figures/journey-sampling-prob.typ"

As illustrated in @journey-sampling-prob, journey generation is performed in two stages. First, each grid cell is assigned an origin weight based on its combined gravitational attraction to all cities. An origin cell is then sampled from these weights.

Given the selected origin cell, the destination is sampled from a conditional distribution specific to that origin. In this distribution, each city is weighted according to its population and its distance from the origin. As a result, larger cities are more likely to be selected as destinations, while increasing distance reduces the likelihood of a city being chosen. The influence of population and distance is adjusted over the course of the day. During morning hours, high-population centers exert a stronger attraction, representing morning commutes towards workplaces. Later in the day, distance is weighted more strongly, making shorter and more local journeys more likely. A heatmap of spawn origins can be seen in @Heatmap.

Integrating the Open Source Routing Machine (OSRM) @project_osrm as the underlying routing engine allows the simulation to accurately map EV journeys using OpenStreetMap data @osm. At scale, querying the routing engine introduces significant computational overhead. However, this approach provides the actual road geometries and speed limits needed to simulate realistic EV energy consumption along each route.

By interfacing with OSRM, the system extracts route distances and polylines. These polylines provide the exact sequence of waypoints that EVs traverse. Evaluating these routes ensures simulated travel times account for road classifications and speed limits. Moreover, OSRM enables the possibility for dynamic mid-journey rerouting.

Achieving computational efficiency over large-scale runs requires several simplifications to the routing data. The simulation determines travel speed purely by the average driving speed between the origin and destination. Furthermore, the OSRM backend provides a static snapshot of the road network, meaning dynamic factors such as traffic congestion, accidents, and weather are excluded.

== Charging Dynamics and Numerical Integration

To simulate EV charging, the system models SoC over time as an Ordinary Differential Equation @ODE, where the rate of change depends on the delivered power and the battery capacity.

To resolve this continuous process within the simulation environment, the system utilizes a discrete-time numerical integrator based on the Forward Euler method @ForwardEuler. At each fixed time step, the simulation evaluates the available output power $P_"out"$ from the current SoC and updates the battery state accordingly. This allows charging to be handled inside the discrete event simulation while still accounting for the EV's hardware charge limit and the charger's maximum output.

The integrator supports both single and dual charging connector configurations. For dual connectors, the station power $P_"max"$ is shared between two connected EVs, $A$ and $B$. The model uses surplus power spilling, where unused capacity from one EV can be reallocated to the other if its hardware limit is below its 50% share.

The power available to EV $A$, denoted $P_("avail", A)$, therefore depends on whether EV $B$ is still charging and how much power EV $B$ can accept. The final power allocated to EV $A$ is limited by both the available station power and EV $A$'s own hardware limit:

$ P_A(t) = min(P_("limit", A), P_("avail", A)) $

This allocation strategy models Dynamic Power Sharing @kempower_distributed, where dual-cable DC fast chargers can use otherwise unused capacity more effectively.

To model non-linear battery charging, the delivered power is scaled by the current SoC. At low SoC, charging increases linearly from 40% to 80% of the available power. Between 10% and 70% SoC, the EV charges at full power. Above 70% SoC, the charging rate decreases until it reaches a minimum of 10% near full charge, as shown in @charging-curve. This makes charging beyond 80% increasingly inefficient.

The model abstracts away several physical effects. It does not simulate battery temperature, coldgating, or thermal throttling. Energy use also ignores route-specific speed variation, and all EVs use a generalized SoC charging curve rather than vehicle-specific electrochemical profiles.

== Electric Vehicle Modeling

=== Journeys and Energy Consumption
Agents begin driving the moment they spawn, following a polyline towards their destination. When an event is processed for an agent, the agent advances along the polyline, and expends the corresponding energy from the battery. Over a traversed distance $d_"traveled"$, the expended energy is determined by the EV's drivetrain efficiency $C_"efficiency"$.

The EV's SoC is subsequently decremented based on its total battery capacity $C_"max"$:

$ "SoC"_t = "SoC"_(t-1) - frac(d_"traveled" dot C_"efficiency", C_"max") $

This discrete calculation maps the physical drain of the battery to the EV's geographic position on the polyline.

=== Station Selection and Routing

To simulate human driving behavior, the EV logic incorporates a Minimum Acceptable Charge parameter representing range anxiety @BADEN2025104661. An EV validates its route to the destination only if the predicted energy consumption leaves the battery above this threshold upon arrival. If this condition cannot be satisfied, the agent selects a charging station and routes through it before continuing toward its destination.

This station assignment is not static. While driving, the agent periodically reevaluates its assigned station at an interval equal to half the remaining journey duration. For an EV with 100 km remaining, the first reevaluation occurs after 50 km, the next after 25 km, and so on. This preserves flexibility early in the journey while naturally tightening the commitment window as the EV approaches its charging stop. To prevent indecision near arrival, reevaluation stops once the estimated travel time to the assigned station falls below 10 minutes.

When a charging stop is required, the agent does not target a full charge. Instead, a dynamic target SoC is computed as the exact energy required to traverse the remaining distance to the destination, plus the Minimum Acceptable Charge buffer. If this calculated target exceeds the battery's physical capacity, the target is capped at 80%. This reflects real-world charging behavior, as charging curves aggressively throttle above this threshold, making it more time efficient to depart at 80% and complete a secondary stop if necessary rather than waiting for a full charge at a single station @chargingCurve.

=== Lifecycle of an EV Agent

The lifecycle of an EV agent is driven by a recursive sequence of discrete events that govern its generation, charging decisions, charging sessions, and eventual journey completion.

#include "../figures/event-diagram.typ"
As illustrated in @event-diagram, vehicle generation is handled by spawn events that periodically instantiate fleets based on time-of-day traffic data, assigning each agent a sampled hardware configuration, initial battery state, and behavioral preferences. At the departure timestamp, the system generates a journey and initiates a station search event. This search computes reachable stations along the route, utilizes a multi-objective cost function to find the optimal candidate, and creates a reservation at the projected arrival time.

To simulate dynamic decision-making during transit, the station search event reschedules itself. The agent continually reevaluates its optimal station, canceling previous reservations if a superior option is found. Once the estimated travel time to the reserved station drops below 10 minutes, the assignment is locked, and an arrival event is scheduled.

Upon arrival, the agent either enters a queue if the station is fully occupied or immediately begins charging, scheduling a completion event based on the requested energy. When the charging event concludes, the system verifies if the agent possesses sufficient energy to reach its final destination. If not, the search cycle reinitiates, otherwise, the agent completes its journey.

== Cost Function <cost_function>
When an EV has to charge before reaching its destination, it must select a charging station from a set of reachable candidates. The system employs a multi-objective cost function that evaluates each candidate station across multiple dimensions. The function is designed to be preference-aware, meaning that individual EV agents carry personal preference parameters that modulate the influence of specific cost components. This allows the system to reflect the heterogeneous decision-making of drivers, where some might prioritize minimizing cost while others are more sensitive to time.

Critically, the cost function operates greedily: it is evaluated independently for each EV at the moment a charging decision is required, selecting the station that minimizes that individual EV's cost at that moment in time.

The total cost assigned to a candidate station $s$ for a given EV is defined as:

$ C(s) = (1 - U) dot (C_"dev" + C_"price" + C_"wait") $

where $U$ is a charge urgency factor, the three additive inner terms capture path deviation, energy price sensitivity, and expected wait time at the station, respectively.

=== Path Deviation Cost

The path deviation cost quantifies the extra time spent incurred by detouring to station $s$ relative to the EV's current trajectory. $T_"detour"$ denotes the total travel duration from the EV's current position to station $s$ and onward to the original destination, and $T_"remaining"$ denotes the duration of the EV's remaining route if no detour were taken.

The path deviation cost is then:

$ C_"dev" = w_"dev" dot (T_"detour" - T_"remaining") $

where $w_"dev"$ is the global path deviation weight. This component directly penalizes stations that require significant deviation from the planned journey.

=== Price Cost

To incorporate economic preferences, the price cost component penalizes stations whose current energy price exceeds the minimum available price across the entire station network.

$p_s(t)$ denotes the per-kWh price at station $s$ at time $t$, and $p_"min"(t)$ denotes the global minimum price across all stations at that time. The price cost is defined as:

$ C_"price" = w_"price" dot lambda_"EV" dot (p_s(t) - p_"min"(t)) $

where $w_"price"$ is the global price sensitivity weight and $lambda_"EV" in [0, 1]$ is a per-EV preference parameter.

=== Expected Wait Time Cost <EWTCost>
The expected wait time cost penalizes stations where the EV is likely to queue upon arrival. Rather than using the current queue length directly, the system projects the EV's expected arrival time $t_"arr"$ at station $s$ based on its current travel duration to the station. The station service then estimates the time at which a charger will become available, $t_"avail"$, given the current occupancy and expected session completions before $t_"arr"$. The expected wait time cost component is:

$ C_"wait" = w_"wait" dot (t_"avail" - t_"arr") $

where $w_"wait"$ is the global wait time weight. By projecting availability forward to the EV's estimated arrival, rather than evaluating current occupancy, this component enables the system to perform prospective load balancing. An EV traveling a longer distance to a station implicitly benefits from the sessions that will have completed by the time it arrives, reducing artificial congestion at high-throughput stations.

=== Urgency Modulation
The urgency factor $U$ acts as a global scalar on the path deviation, price cost, and expected wait time components, suppressing their influence as an EV's projected energy reserves on-arrival approach a critical threshold. It enters the cost function as $(1 - U)$, so higher urgency dampens the cost function, while lower urgency restores full weighting. This incentivizes EVs to drive longer to deplete their battery before charging, to ensure they are maximizing the utility of their battery and minimizing unnecessary detours, wait times, or expenses when they are not yet critically low on energy. Urgency is evaluated against the projected SoC rather than the current SoC.
