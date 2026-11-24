== Subinterpreters <subinterpreters>
Python's subinterpreters provide another way to run isolated interpreters within one process @pep734. We use microbenchmarks to test whether they offer practical advantages over multiprocessing for workloads relevant to @ETL.

We developed seven standalone microbenchmarks covering communication overhead, task distribution, shared identifier generation, CPU-bound scalability, memory consumption, and worker initialization. Each benchmark was repeated, and median execution times are reported. Where applicable, workers were reused to separate steady-state performance from initialization cost.

With eight workers, both approaches achieved similar CPU-bound speedups. The advantage was not consistent across operations. For ten-column dictionaries, which resemble the row representation used by `pygrametl`, multiprocessing queues transferred about 267,000 rows per second, compared with 132,000 for subinterpreter queues, as shown in @fig:dict-transfer. The difference persisted across tested dictionary sizes. Initializing eight workers also took about 1.61 ms with process forking, compared with 31.46 ms for subinterpreters.

Taken together, the microbenchmarks shows a trade-off. Where subinterpreters improve task distribution and memory use, but are slower for dictionary transfer and worker initialization. Since using them would require substantial changes to the existing multiprocessing implementation, these results do not justify pursuing that rewrite.
