using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;

namespace Censo.Pruebas.BaseDatos.Ayudantes;

public sealed record TablaInfo(string Esquema, string Nombre);

public sealed record ColumnaInfo(string Esquema, string Tabla, string Columna, string Tipo, bool AceptaNulos);

public sealed record LlaveForaneaInfo(
    string Nombre, string EsquemaHijo, string TablaHijo, string ColumnaHijo,
    string EsquemaPadre, string TablaPadre, string ColumnaPadre);

public sealed record IndiceInfo(string Esquema, string Tabla, string Nombre, string Tipo);

/// <summary>Lectura de los catalogos del sistema de SQL Server para las tablas de los esquemas dim y hechos.</summary>
public static class Metadatos
{
    public static List<TablaInfo> Tablas() => Consultar<TablaInfo>(
        @"SELECT s.name AS Esquema, t.name AS Nombre
          FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
          WHERE s.name IN ('dim', 'hechos')
          ORDER BY s.name, t.name");

    public static List<ColumnaInfo> Columnas() => Consultar<ColumnaInfo>(
        @"SELECT s.name AS Esquema, t.name AS Tabla, c.name AS Columna, ty.name AS Tipo, c.is_nullable AS AceptaNulos
          FROM sys.columns c
          JOIN sys.tables t ON t.object_id = c.object_id
          JOIN sys.schemas s ON s.schema_id = t.schema_id
          JOIN sys.types ty ON ty.user_type_id = c.user_type_id
          WHERE s.name IN ('dim', 'hechos')
          ORDER BY s.name, t.name, c.column_id");

    public static List<LlaveForaneaInfo> LlavesForaneas() => Consultar<LlaveForaneaInfo>(
        @"SELECT fk.name AS Nombre, sh.name AS EsquemaHijo, th.name AS TablaHijo, ch.name AS ColumnaHijo,
                 sp.name AS EsquemaPadre, tp.name AS TablaPadre, cp.name AS ColumnaPadre
          FROM sys.foreign_keys fk
          JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
          JOIN sys.tables th ON th.object_id = fk.parent_object_id
          JOIN sys.schemas sh ON sh.schema_id = th.schema_id
          JOIN sys.columns ch ON ch.object_id = fkc.parent_object_id AND ch.column_id = fkc.parent_column_id
          JOIN sys.tables tp ON tp.object_id = fk.referenced_object_id
          JOIN sys.schemas sp ON sp.schema_id = tp.schema_id
          JOIN sys.columns cp ON cp.object_id = fkc.referenced_object_id AND cp.column_id = fkc.referenced_column_id
          ORDER BY sh.name, th.name, fk.name");

    public static List<IndiceInfo> ClavesPrimarias() => Consultar<IndiceInfo>(
        @"SELECT s.name AS Esquema, t.name AS Tabla, i.name AS Nombre, i.type_desc AS Tipo
          FROM sys.indexes i
          JOIN sys.tables t ON t.object_id = i.object_id
          JOIN sys.schemas s ON s.schema_id = t.schema_id
          WHERE i.is_primary_key = 1 AND s.name IN ('dim', 'hechos')");

    public static List<IndiceInfo> Columnstore() => Consultar<IndiceInfo>(
        @"SELECT s.name AS Esquema, t.name AS Tabla, i.name AS Nombre, i.type_desc AS Tipo
          FROM sys.indexes i
          JOIN sys.tables t ON t.object_id = i.object_id
          JOIN sys.schemas s ON s.schema_id = t.schema_id
          WHERE i.type_desc = 'CLUSTERED COLUMNSTORE' AND s.name IN ('dim', 'hechos')");

    public static List<string> RestriccionesUnicas() => Consultar<string>(
        @"SELECT kc.name FROM sys.key_constraints kc
          JOIN sys.tables t ON t.object_id = kc.parent_object_id
          JOIN sys.schemas s ON s.schema_id = t.schema_id
          WHERE kc.type = 'UQ' AND s.name IN ('dim', 'hechos')
          ORDER BY kc.name");
}
