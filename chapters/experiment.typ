= Experimental Setup
== Star schema diagram
== Hardware
#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[*Component*][*Specification*],
    [CPU], [Intel Core Ultra 7 265KF, 20 cores (8P + 12E, no SMT), up to 5.6 GHz, 36 MiB L2, 30 MiB L3],
    [Memory], [64 GB (2 × 32 GB) DDR5-6000],
    [Storage], [WD_BLACK SN770 2 TB NVMe],
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

== Benchmark
