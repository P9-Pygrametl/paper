== Free Threading <freethreading>

PEP 703 proposes making the @GIL optional in CPython @PEP703, allowing multiple threads to execute Python bytecode in parallel within the same process. Support for free-threading is determined at compile time through the `--disable-gil` configuration option. However, a free-threaded build allows the @GIL to be enabled or disabled at runtime using the `-X gil` command-line option or the `PYTHON_GIL` environment variable @Python315FreeThreadingDocs.

To investigate whether free-threading can reduce the overhead associated with multiprocessing, we use the free-threaded CPython 3.15t build. Rather than redesigning pygrametl's parallel architecture, we retain the existing implementation and extend it to support Python's `threading` module @Python315ThreadingDocs as an alternative to `multiprocessing`.

By using threads, workers operate within a shared address space, removing the need to serialise data when transferring it between workers and avoiding memory duplication associated with copy-on-write. Furthermore, replacing `fork`-based process creation with threads removes the dependency on functionality specific to UNIX-like systems, allowing the parallel implementation to also support Windows.
