// Las pruebas comparten una sola base con consultas pesadas y un contenedor con 4 GB de memoria: se ejecutan una a la
// vez para que las concesiones de memoria y los tiempos no se distorsionen.
[assembly: CollectionBehavior(DisableTestParallelization = true)]
