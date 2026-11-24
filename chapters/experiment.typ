= Experimental Setup
== Star Schema Diagram
#include "../figures/StarSchema.typ"
We use the star schema shown in @fig-star-schema and the data generator, both from @Thomsen2011Exaprogs. The benchmark setup is based on @Pygrametl2011 and @Liu2011ETLMR. This follows the earlier evaluation of `pygrametl`'s parallel Jython implementation and provides a common workload for comparing the methods in this paper.

== Hardware
#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[*Component*][*Specification*],
    [CPU], [Intel Core Ultra 7 265KF, 20 cores (8P + 12E, no SMT), up to 5.6 GHz, 36 MiB L2, 30 MiB L3],
    [Memory], [64 GB (2 x 32 GB) DDR5-6000],
    [Storage], [WD_BLACK SN770 2 TB NVMe, 5865 MB/s read / 4502 MB/s write],
    [Motherboard], [ASUS TUF Gaming Z890-Plus WiFi],
    [OS], [Ubuntu 26.04.1 LTS, Linux 7.0.0-38-generic],
  ),
  caption: [Hardware and operating system used for all benchmarks.],
)

== General Setup
The CPython implementations ran on CPython 3.15.1 with the @GIL and on a free-threaded CPython 3.15.1 build (`3.15t`), both compiled with Clang 23.1.3. The Jython implementations ran on Jython 2.7.3 with OpenJDK 1.8.0_512 and PostgreSQL @JDBC driver 42.7.10. The CPython environments used psycopg 3.3.5 and psycopg-c 3.3.5.

The source and warehouse databases ran in separate PostgreSQL 18.6 Docker containers with default configuration on the benchmark machine. We tested page sizes of 25, 50, 75, and 100, corresponding to 1.125, 2.25, 3.375, and 4.5 million fact rows. Each configuration was run 30 times in a freshly shuffled order, with no warm-up.
