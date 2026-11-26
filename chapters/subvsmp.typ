== Subinterpreters <subinterpreters>

CPython supports multiple isolated interpreters within a single process. Both the main interpreter and subinterpreters are represented internally by the same `PyInterpreterState` structure, which maintains interpreter-specific state such as imported modules, built-in objects and garbage collection state @CPythonInterpreterState. Python 3.14 introduced the `concurrent.interpreters` module through PEP 734, providing a Python-level interface for creating and communicating between interpreters @pep734.

As illustrated in @fig-execution-models, subinterpreters operate within a shared process address space, unlike multiprocessing, where each worker runs in a separate process. This motivates investigating how subinterpreters compare to multiprocessing in terms of worker initialisation, communication overhead and memory consumption. However, unlike free-threading, workers operate within isolated interpreters and cannot directly share most Python objects. This is particularly relevant to pygrametl, where rows represented as dictionaries are frequently transferred between workers.

#include "../figures/execution-models.typ"

Rather than adapting pygrametl's existing parallel architecture directly, we developed five standalone microbenchmarks to investigate the suitability of subinterpreters for parallel @ETL workflows:

- *Data transport:* Transfer of different data types and payload sizes through queues and pipes.
- *Task distribution:* Distribution of computational tasks among workers and collection of results.
- *Dictionary transport:* Transfer of dictionaries with varying numbers of attributes, representing pygrametl rows, with results shown in @fig:dict-transfer.
- *CPU scalability:* Parallel execution of CPU-bound row transformations.
- *Initialisation:* Creation and termination costs of processes and subinterpreters.

The experiments are conducted with up to eight workers, with each configuration repeated ten times to provide a statistical basis for comparing performance and assessing variability between runs. Where applicable, workers are initialised before timing and reused to separate workload execution from initialisation costs.

While the microbenchmarks indicate benefits in task distribution and memory consumption, subinterpreters introduce greater overhead when transferring dictionaries and initialising interpreters. Integrating subinterpreters into pygrametl would require changes to worker management, communication between workers and the initialisation of objects within isolated interpreters. Given these required changes and the importance of dictionary transfer in pygrametl, we decided not to pursue a subinterpreter-based implementation.
