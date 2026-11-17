= Experimental Setup
== Star schema diagram
#include "../figures/StarSchema.typ"
To evaluate the parallelization methods described in @Methods, we use the same star schema (@fig-star-schema), data generator @Thomsen2011Exaprogs, and benchmark setup as #text(style: "italic")[ETLMR: A Highly Scalable Dimensional ETL
  Framework Based on MapReduce] @Liu2011ETLMR and #text(style: "italic")[Easy and Effective Parallel Programmable ETL] @Pygrametl2011, allowing direct comparison with the parallel Jython @JythonProject implementation of pygrametl evaluated there.
== Hardware
#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[*Component*][*Specification*],
    [CPU], [Intel Core Ultra 7 265KF, 20 cores (8P + 12E, no SMT), up to 5.6 GHz, 36 MiB L2, 30 MiB L3],
    [Memory], [64 GB (2 × 32 GB) DDR5-6000],
    [Storage], [WD_BLACK SN770 2 TB NVMe, 5865 MB/s read / 4502 MB/s write],
    [Motherboard], [ASUS TUF Gaming Z890-Plus WiFi],
    [OS], [Ubuntu 26.04.1 LTS, Linux 7.0.0-38-generic],
  ),
  caption: [Hardware and operating system used for all benchmarks.],
)

== General Setup
The CPython implementations were run on CPython 3.15.1 (with the GIL) and
the CPython 3.15.1 free-threading build (3.15t), both built with Clang 23.1.3.
The Jython implementations were run on Jython 2.7.3 with OpenJDK 1.8.0_512
and the PostgreSQL JDBC driver 42.7.10, whereas the CPython environments use
psycopg 3.3.5 (with psycopg-c 3.3.5).

The source and data warehouse databases ran as two PostgreSQL 18.6 Docker
containers with the default configuration on the same machine as the
benchmark. Each configuration (page sizes 25 (1.125 M rows), 50 (2.25 M rows), 75 (3.375 M rows) and 100 (4.5M rows)) was run 30 times and interleaved randomly with no warm-up.

== Benchmarking Approach
We considered pyperf @pyperf, pytest-benchmark @pytest-benchmark and perftester @perftester, but used our own harness. A run may be a single JVM process or a parent with several workers, so we need wall time, CPU time and peak PSS for the whole process tree. CPU time shows whether a speedup comes from using more cores or from doing less work, and PSS apportions shared pages so the tree total does not double-count them.

pytest-benchmark and perftester measure Python callables, and perftester documents that it does not support multiple threads or processes @perftester. pyperf is closer, since its command mode times an external program and can report its peak memory as maximum RSS @pyperf, but it gives neither tree-wide CPU time nor PSS. None of the tools restore the warehouse before a run or check that implementations produce the same output, so a wrapper would still leave the experiment-specific work as custom code.
