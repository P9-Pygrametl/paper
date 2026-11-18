== Multiprocessing

Standard CPython enforces a Global Interpreter Lock (GIL) @Python315GILDocs that serializes Python bytecode execution across threads. To bypass this, pygrametl relies on `multiprocessing` in CPython or with Jython @JythonProject, which runs on the Java Virtual Machine (JVM) without the GIL. However, Jython remains pinned to Python 2.7, whereas pygrametl targets Python 3 except for some Jython support.
