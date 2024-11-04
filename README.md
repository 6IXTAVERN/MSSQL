<h1 align="center"><a href=""><img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/></a> MSSQL</h1>

<p align="center">
  <a href="#-lab1"><img alt="lab1" src="https://img.shields.io/badge/Lab1-blue"></a> 
  <a href="#-lab2"><img alt="lab2" src="https://img.shields.io/badge/Lab2-red"></a>
</p>

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab1
<h3 align="center">
  <a href="#client"></a>
  1.1 Разработать представления или хранимые процедуры для выполнения заданий.
</h3>

#### №6. Вывести все таблицы SQL Server без столбца identity.
```tsql
--- №6
-- Пояснение: запрос находит таблицы, у которых все столбцы не имеют IDENTITY - в параметрах "Удостоверение"
-- т.е. авто-приращение идентификатора при создании новых записей
CREATE PROCEDURE GetTablesWithoutIdentityColumns
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.name AS TableName, t.object_id
    FROM sys.tables t
    WHERE t.object_id NOT IN (
        SELECT c.object_id
        FROM sys.columns c
        WHERE c.is_identity = 1
    )
    ORDER BY t.name;
END
```

```tsql
-- Использование
EXEC GetTablesWithoutIdentityColumns;
```

| TableName | object\_id |
| :--- | :--- |
| Customers | 901578250 |
| Order Details | 965578478 |


#### №29 Вывести все таблицы SQL Server, на которые напрямую ссылается хотя бы одно представление.
```tsql
-- №29
CREATE PROCEDURE GetTablesReferencedByViews
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT t.name AS TableName, t.object_id AS TableId
    FROM sys.tables t
    JOIN sys.sql_expression_dependencies d ON t.object_id = d.referenced_id
    JOIN sys.views v ON d.referencing_id = v.object_id
    WHERE d.referenced_class_desc = 'OBJECT_OR_COLUMN'
    ORDER BY t.name;
END;
```

```tsql
-- Создание представления для теста
CREATE VIEW vw_EmployeeNames AS
SELECT FirstName, LastName, Country
FROM Employees;
```

```tsql
-- Использование
EXEC GetTablesReferencedByViews;
```

| TableName | TableId |
| :--- | :--- |
| Employees | 933578364 |


#### №38 Вывести все столбцы первичного ключа для указанной таблицы.
```tsql
-- №38
-- Пояснение: процедура находит названия столбцов в указанной таблице, которые являются первичными ключами
CREATE PROCEDURE GetPrimaryKeyColumns
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT kcu.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    WHERE tc.TABLE_NAME = @TableName AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY';
END
```

```tsql
-- Использование
EXEC GetPrimaryKeyColumns @TableName = 'Order Details';
```

| COLUMN\_NAME |
| :--- |
| OrderID |
| ProductID |

<h3 align="center">
  <a href="#client"></a>
  1.2 Написать хранимую процедуру, которая для указанного объекта, заданного именем и схемой, вернет его свойства
</h3>

```tsql
CREATE PROCEDURE GetObjectProperties
    @SchemaName NVARCHAR(128),
    @ObjectName NVARCHAR(128)
AS
BEGIN
    -- Определение типа объекта
    DECLARE @ObjectType NVARCHAR(2);
    SELECT @ObjectType = TYPE
    FROM sys.objects
    WHERE name = @ObjectName AND SCHEMA_NAME(schema_id) = @SchemaName;

    IF @ObjectType IS NULL
    BEGIN
        PRINT 'Объект не найден.';
        RETURN;
    END

    -- Общая информация: дата создания, модификация, права
    SELECT 
        sys_obj.name AS ObjectName,
        SCHEMA_NAME(sys_obj.schema_id) AS SchemaName,
        sys_obj.type_desc AS ObjectType,
        sys_obj.create_date AS CreationDate,
        sys_obj.modify_date AS LastModifiedDate,
        db_permissions.permission_name AS PermissionName,
        db_permissions.state_desc AS PermissionState
    FROM sys.objects sys_obj
    LEFT JOIN sys.database_permissions db_permissions ON db_permissions.major_id = sys_obj.object_id
    WHERE sys_obj.name = @ObjectName AND SCHEMA_NAME(sys_obj.schema_id) = @SchemaName;

    -- Таблицы(U) и представления(V)
    IF @ObjectType IN ('U', 'V')
    BEGIN
        -- Столбцы
        SELECT 
            columns.name AS ColumnName,
            types.name AS DataType,
            columns.max_length AS MaxLength,
            columns.is_nullable AS IsNullable,
            columns.is_identity AS IsIdentity
        FROM sys.columns columns
        JOIN sys.types types ON columns.user_type_id = types.user_type_id
        WHERE columns.object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));

        -- Ограничения
        SELECT 
            key_constraints.name AS ConstraintName,
            key_constraints.type_desc AS ConstraintType
        FROM sys.key_constraints key_constraints
        WHERE key_constraints.parent_object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));

        -- Триггеры
        SELECT 
            t.name AS TriggerName,
            t.is_disabled AS IsDisabled
        FROM sys.triggers t
        WHERE t.parent_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));

        -- Количество строк
        DECLARE @RowCount INT;
        SELECT @RowCount = SUM(partitions.rows)
        FROM sys.partitions partitions
        WHERE partitions.object_id =
              OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName)) AND partitions.index_id IN (0, 1);

        PRINT 'Количество строк: ' + CAST(@RowCount AS NVARCHAR(100));

        -- Объекты, ссылающиеся на таблицу
        SELECT 
            referencing_object.name AS ReferencingObject,
            referencing_object.type_desc AS ReferencingType
        FROM sys.foreign_keys foreign_keys
        JOIN sys.objects referencing_object ON foreign_keys.parent_object_id = referencing_object.object_id
        WHERE foreign_keys.referenced_object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));
    END

    -- Процедуры(P) и функции(FN/IF/TF)
    ELSE IF @ObjectType IN ('P', 'FN', 'IF', 'TF')
    BEGIN
        -- Параметры
        SELECT 
            parameters.name AS ParameterName,
            types.name AS DataType,
            parameters.max_length AS MaxLength,
            parameters.is_output AS IsOutput
        FROM sys.parameters parameters
        JOIN sys.types types ON parameters.system_type_id = types.system_type_id
        WHERE parameters.object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));

        -- Текст процедуры или функции
        SELECT 
            OBJECT_DEFINITION(OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName))) AS ObjectText;

        -- Зависимости
        SELECT 
            referenced_entity.name AS ReferencedObjectName,
            referenced_entity.type_desc AS ReferencedObjectType
        FROM sys.sql_expression_dependencies expr_dependencies
        JOIN sys.objects referenced_entity ON expr_dependencies.referenced_id = referenced_entity.object_id
        WHERE expr_dependencies.referencing_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));
    END

    -- Триггеры(TR)
    ELSE IF @ObjectType = 'TR'
    BEGIN
        -- Детали триггера
        SELECT 
            triggers.name AS TriggerName,
            triggers.is_disabled AS IsDisabled,
            OBJECT_DEFINITION(triggers.object_id) AS TriggerText
        FROM sys.triggers triggers
        WHERE triggers.object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));
    END

    ELSE
    BEGIN
        PRINT 'Тип объекта не поддерживается';
    END
END;
```

```tsql
-- Использование (пример с таблицей)
EXEC GetObjectProperties 'dbo', 'Customers';
```

| ObjectName | SchemaName | ObjectType | CreationDate | LastModifiedDate | PermissionName | PermissionState |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Customers | dbo | USER\_TABLE | 2024-11-04 01:22:50.220 | 2024-11-04 01:22:50.220 | null | null |

| ColumnName | DataType | MaxLength | IsNullable | IsIdentity |
| :--- | :--- | :--- | :--- | :--- |
| CustomerID | nchar | 10 | false | false |
| CompanyName | nvarchar | 80 | false | false |
| ContactName | nvarchar | 60 | true | false |
| ContactTitle | nvarchar | 60 | true | false |
| Address | nvarchar | 120 | true | false |
| City | nvarchar | 30 | true | false |
| Region | nvarchar | 30 | true | false |
| PostalCode | nvarchar | 20 | true | false |
| Country | nvarchar | 30 | true | false |
| Phone | nvarchar | 48 | true | false |
| Fax | nvarchar | 48 | true | false |

| ConstraintName | ConstraintType |
| :--- | :--- |
| PK\_Customers | PRIMARY\_KEY\_CONSTRAINT |

| TriggerName | IsDisabled |
| :--- | :--- |

| ReferencingObject | ReferencingType |
| :--- | :--- |


```tsql
-- Использование (пример с представлением)
EXEC GetObjectProperties 'dbo', 'vw_EmployeeNames';
```

| ObjectName | SchemaName | ObjectType | CreationDate | LastModifiedDate | PermissionName | PermissionState |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| vw\_EmployeeNames | dbo | VIEW | 2024-11-04 02:00:16.240 | 2024-11-04 02:00:16.240 | null | null |

| ColumnName | DataType | MaxLength | IsNullable | IsIdentity |
| :--- | :--- | :--- | :--- | :--- |
| FirstName | nvarchar | 20 | false | false |
| LastName | nvarchar | 40 | false | false |
| Country | nvarchar | 30 | true | false |

| ConstraintName | ConstraintType |
| :--- | :--- |

| TriggerName | IsDisabled |
| :--- | :--- |

| ReferencingObject | ReferencingType |
| :--- | :--- |


```tsql
-- Использование (пример с процедурой)
EXEC GetObjectProperties 'dbo', 'GetPrimaryKeyColumns';
```

| ObjectName | SchemaName | ObjectType | CreationDate | LastModifiedDate | PermissionName | PermissionState |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| GetPrimaryKeyColumns | dbo | SQL\_STORED\_PROCEDURE | 2024-11-04 01:48:34.420 | 2024-11-04 01:48:34.420 | null | null |

| ParameterName | DataType | MaxLength | IsOutput |
| :--- | :--- | :--- | :--- |
| @TableName | nvarchar | 256 | false |
| @TableName | sysname | 256 | false |

| ObjectText |
| :--- |
| CREATE PROCEDURE GetPrimaryKeyColumns<br/>    @TableName NVARCHAR\(128\)<br/>AS<br/>BEGIN<br/>    SET NOCOUNT ON;<br/><br/>    SELECT <br/>        kcu.COLUMN\_NAME<br/>    FROM <br/>        INFORMATION\_SCHEMA.TABLE\_CONSTRAINTS AS tc<br/>    JOIN <br/>        INFORMATION\_SCHEMA.KEY\_COLUMN\_USAGE AS kcu <br/>        ON tc.CONSTRAINT\_NAME = kcu.CONSTRAINT\_NAME<br/>    WHERE <br/>        tc.TABLE\_NAME = @TableName <br/>        AND tc.CONSTRAINT\_TYPE = 'PRIMARY KEY';<br/>END |

| ReferencingObjectName | ReferencingObjectType |
| :--- | :--- |


# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab2
<h3 align="center">
  <a href="#client"></a>
  2 Создать процедуру, которая принимает в качестве параметров имя таблицы и имена двух полей этой таблице и добавляет содержимое первого поля к содержимому второго. 
  Если второе поле пустое, то просто копируется содержимое поля 1 в содержимое поля 2 и наоборот.
</h3>

```tsql
CREATE PROCEDURE UpdateFields
    @TableName NVARCHAR(MAX),
    @Field1 NVARCHAR(MAX),
    @Field2 NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)

    -- Формируем динамический SQL
    SET @sql = N'UPDATE ' + QUOTENAME(@TableName) + ' SET ' +
        QUOTENAME(@Field2) + ' = CASE ' +
            'WHEN ' + QUOTENAME(@Field2) + ' IS NULL AND ' + QUOTENAME(@Field1) + ' IS NOT NULL THEN ' + QUOTENAME(@Field1) + ' ' +
            'WHEN ' + QUOTENAME(@Field2) + ' IS NOT NULL AND ' + QUOTENAME(@Field1) + ' IS NOT NULL THEN ' + QUOTENAME(@Field2) + ' + ' + QUOTENAME(@Field1) + ' ' +
            'WHEN ' + QUOTENAME(@Field1) + ' IS NULL AND ' + QUOTENAME(@Field2) + ' IS NOT NULL THEN ' + QUOTENAME(@Field2) + ' ' +
            'END, ' +
        QUOTENAME(@Field1) + ' = CASE ' +
            'WHEN ' + QUOTENAME(@Field1) + ' IS NULL AND ' + QUOTENAME(@Field2) + ' IS NOT NULL THEN ' + QUOTENAME(@Field2) + ' ' +
            'ELSE ' + QUOTENAME(@Field1) + ' ' +
            'END' +
        ' WHERE ' + QUOTENAME(@Field1) + ' IS NOT NULL OR ' + QUOTENAME(@Field2) + ' IS NOT NULL;'

    -- Выполнение динамического SQL с помощью sp_executesql
    EXEC sp_executesql @sql
END
```

```tsql
-- Тестовые данные
CREATE TABLE SampleTable (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Field1 NVARCHAR(100),
    Field2 NVARCHAR(100)
);

INSERT INTO SampleTable (Field1, Field2) VALUES ('Hello', NULL);
INSERT INTO SampleTable (Field1, Field2) VALUES (NULL, 'World');
INSERT INTO SampleTable (Field1, Field2) VALUES ('Goodbye', 'Everyone');
INSERT INTO SampleTable (Field1, Field2) VALUES (NULL, NULL);
```

```tsql
-- До использования
SELECT * FROM SampleTable;
```

| ID | Field1 | Field2 |
| :--- | :--- | :--- |
| 1 | Hello | null |
| 2 | null | World |
| 3 | Goodbye | Everyone |
| 4 | null | null |


```tsql
-- Использование процедуры
EXEC UpdateFields @TableName = 'SampleTable', @Field1 = 'Field1', @Field2 = 'Field2';
```

```tsql
-- После использования
SELECT * FROM SampleTable;
```

| ID | Field1 | Field2 |
| :--- | :--- | :--- |
| 1 | Hello | Hello |
| 2 | World | World |
| 3 | Goodbye | EveryoneGoodbye |
| 4 | null | null |



