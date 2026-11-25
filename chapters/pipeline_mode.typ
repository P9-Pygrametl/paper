== Pipeline Mode <pipeline_mode>

When executing SQL statements synchronously, the client waits for a response from the database before issuing the next statement. In pygrametl, where data is often loaded row by row, this introduces repeated database round-trip waits. When subsequent statements do not depend on the results of previous statements, these waits can potentially be avoided.

As illustrated in @fig-timeline, PostgreSQL pipeline mode allows multiple SQL statements to be sent to the database without waiting for individual responses @PostgreSQLPipelineDocs. The statements are still executed sequentially by the database, but the client can issue subsequent statements while previous statements are being processed. Synchronisation points are used when the client needs to wait for outstanding operations to complete.

#include "../figures/pipeline-timeline.typ"

To support pipeline mode in pygrametl, we implemented a `PipelinedConnectionWrapper` using psycopg 3 @psycopg3. The wrapper extends the existing `ConnectionWrapper`, allowing pipeline mode to be used without restructuring the @ETL workflow. To identify statements expected to return rows, the wrapper checks whether the SQL statement begins with `SELECT` or `WITH`, or contains `RETURNING`. Synchronisation is performed when results are required, when committing a transaction or when the configurable `sync_threshold` is reached.

The effectiveness of pipeline mode depends on how frequently synchronisation is required. In pygrametl, dimension cache misses require database lookups, which can force synchronisation. Prefilling dimension caches and providing sufficient cache capacity can therefore reduce the frequency of synchronisation.

For bulk loading, pygrametl allows data to be loaded using database-specific functionality, such as PostgreSQL's `COPY` command. Since `COPY` is not supported within PostgreSQL pipeline mode @PostgreSQLPipelineDocs, requesting a raw cursor causes the wrapper to synchronise and temporarily exit pipeline mode. Pipeline mode is re-entered on the next call to `execute` or `executemany`.
