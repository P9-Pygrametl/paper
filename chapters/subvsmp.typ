== Subinterpreters <subinterpreters>

CPython supports multiple isolated interpreters within a single process. Both the main interpreter and subinterpreters are represented internally by the same `PyInterpreterState` structure, which maintains interpreter-specific state such as imported modules, built-in objects and garbage collection state @CPythonInterpreterState. PEP 684 introduced support for individual interpreters to have their own @GIL, enabling parallel execution across interpreters running in separate threads @PEP684. Python 3.14 introduced the `concurrent.interpreters` module through PEP 734, providing a Python-level interface for creating and communicating between interpreters @pep734.

As illustrated in @fig-execution-models, subinterpreters share a process address space, potentially reducing the overhead associated with process creation and memory consumption compared to multiprocessing. However, unlike free-threading, workers operate within isolated interpreters and cannot directly share most Python objects. This is particularly relevant to pygrametl, where rows represented as dictionaries are frequently transferred between workers.

#include "../figures/execution-models.typ"

Rather than adapting pygrametl's existing parallel architecture directly, we developed seven standalone microbenchmarks to investigate the suitability of subinterpreters for parallel @ETL workflows:

- *Data transport:* Transfer of different data types and payload sizes through queues and pipes.
- *Task distribution:* Distribution of computational tasks among workers and collection of results.
- *Dictionary transport:* Transfer of dictionaries with varying numbers of attributes, representing pygrametl rows, with results shown in @fig:dict-transfer.
- *Coordination:* Requests for unique identifiers from a central coordinator, resembling pygrametl's shared identifier generation.
- *CPU scalability:* Parallel execution of CPU-bound row transformations.
- *Shared buffers:* Concurrent access to shared data without copying the underlying buffer.
- *Initialisation:* Creation and termination costs of processes and subinterpreters.

The experiments use up to eight workers. The transport experiments are repeated seven times, the initialisation experiment thirty times, and the remaining experiments five times. Where applicable, workers are initialised before timing and reused to separate workload execution from initialisation costs.

While the microbenchmarks indicate potential benefits in task distribution and memory consumption, subinterpreters introduce greater overhead when transferring dictionaries and initialising interpreters. Given the importance of dictionary transfer in pygrametl and the substantial changes required to its existing parallel architecture, we decided not to pursue a subinterpreter-based implementation.
