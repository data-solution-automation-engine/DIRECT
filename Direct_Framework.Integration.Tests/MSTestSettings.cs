// Each class runs its own container, which allows for parallel execution of tests
// tweak number of workers based on test system's capabilities if required
[assembly: Parallelize(Workers = 4, Scope = ExecutionScope.ClassLevel)]
