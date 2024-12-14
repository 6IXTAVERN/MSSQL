USE [msdb]
GO

/****** Object:  Job [DB_Diff_Backup(task2)]    Script Date: 15.12.2024 0:41:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 15.12.2024 0:41:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB_Diff_Backup(task2)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Описание недоступно.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'root', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Создание дифф. копии]    Script Date: 15.12.2024 0:41:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Создание дифф. копии', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [TestDB] 
TO DISK = ''C:\Backup(Task2)\SourceBak\TestDBdiff.bak'' 
WITH DIFFERENTIAL;
', 
		@database_name=N'TestDB', 
		@output_file_name=N'C:\Backup(Task2)\SourceBak\log.txt', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Копирование .bak]    Script Date: 15.12.2024 0:41:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Копирование .bak', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -ExecutionPolicy Bypass -File "C:\Backup(Task2)\CopyBackup.ps1"', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Восстановление новой БД]    Script Date: 15.12.2024 0:41:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Восстановление новой БД', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'------------------ Part1: Восстановить последний полный бэкап
IF DB_ID(N''DiffBackupTestDB'') IS NOT NULL
BEGIN
    ALTER DATABASE [DiffBackupTestDB]
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DiffBackupTestDB]
END;
GO

DECLARE @lastPosition INT
SELECT TOP 1 @lastPosition = [position]
FROM [msdb].[dbo].[backupset]
WHERE [database_name] = N''TestDB'' AND [type] = ''D''
ORDER BY [backup_finish_date] DESC;

-- Восстанавливаем базу данных из актуального полного бэкапа
RESTORE DATABASE [DiffBackupTestDB]
FROM DISK = ''C:\Backup(Task1)\TargetBak\TestDB.bak''
WITH FILE = @lastPosition,
MOVE ''TestDB'' TO ''C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB.mdf'',
MOVE ''TestDB_log'' TO ''C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB_log.ldf'',
NORECOVERY
GO

------------------ Part2: Восстановить последний дифференциальный бэкап
DECLARE @lastPosition INT
SELECT TOP 1 @lastPosition = [position]
FROM [msdb].[dbo].[backupset]
WHERE [database_name] = N''TestDB'' AND [type] = ''I''
ORDER BY [backup_finish_date] DESC;

RESTORE DATABASE [DiffBackupTestDB]
FROM DISK = ''C:\Backup(Task2)\TargetBak\TestDBdiff.bak''
WITH FILE = @lastPosition,
MOVE ''TestDB'' TO ''C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB.mdf'',
MOVE ''TestDB_log'' TO ''C:\MS SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DiffBackupTestDB_log.ldf'',
RECOVERY
GO', 
		@database_name=N'master', 
		@output_file_name=N'C:\Backup(Task2)\SourceBak\log.txt', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'MySchedule2', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20241207, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'885704ca-ab83-4f91-96a5-22e98f8b04e8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

