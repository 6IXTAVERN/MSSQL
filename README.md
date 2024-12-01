<h1 align="center"><a href=""><img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/></a> MSSQL</h1>

<p align="center">
  <a href="#-lab1"><img alt="lab1" src="https://img.shields.io/badge/Lab1-blue"></a> 
  <a href="#-lab2"><img alt="lab2" src="https://img.shields.io/badge/Lab2-red"></a>
  <a href="#-lab3"><img alt="lab3" src="https://img.shields.io/badge/Lab3-green"></a>
  <a href="#-lab4"><img alt="lab4" src="https://img.shields.io/badge/Lab4-yellow"></a>
  <a href="#-lab5"><img alt="lab5" src="https://img.shields.io/badge/Lab5-gray"></a>
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


