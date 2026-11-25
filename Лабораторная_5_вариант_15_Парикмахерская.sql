/*
   Лабораторная работа 5. Вариант 15 «Парикмахерская».
   Представления и триггер аудита.
*/

USE HairdresserDB;
GO

-- 1. Полное расписание работы на завтра.
CREATE OR ALTER VIEW dbo.vw_TomorrowFullSchedule
AS
SELECT s.ScheduleId,
       s.ServiceDate,
       s.ServiceTime,
       e.EmployeeId,
       e.LastName AS EmployeeLastName,
       e.FirstName AS EmployeeFirstName,
       c.ClientId,
       c.LastName AS ClientLastName,
       c.FirstName AS ClientFirstName,
       srv.ServiceId,
       srv.ServiceName,
       srv.Price
FROM dbo.Schedule AS s
INNER JOIN dbo.Employees AS e ON e.EmployeeId = s.EmployeeId
INNER JOIN dbo.Clients AS c ON c.ClientId = s.ClientId
INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
WHERE s.ServiceDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
GO

-- Сотрудники с максимальным количеством клиентов завтра.
SELECT EmployeeId, EmployeeLastName, EmployeeFirstName, COUNT(*) AS ClientCount
FROM dbo.vw_TomorrowFullSchedule
GROUP BY EmployeeId, EmployeeLastName, EmployeeFirstName
HAVING COUNT(*) =
(
    SELECT MAX(ClientCount)
    FROM
    (
        SELECT COUNT(*) AS ClientCount
        FROM dbo.vw_TomorrowFullSchedule
        GROUP BY EmployeeId
    ) AS Counts
);
GO

-- 2. Ожидаемая суммарная выручка каждого сотрудника завтра.
CREATE OR ALTER VIEW dbo.vw_TomorrowEmployeeRevenue
AS
SELECT e.EmployeeId,
       e.LastName AS EmployeeLastName,
       e.FirstName AS EmployeeFirstName,
       CAST(ISNULL(SUM(srv.Price), 0) AS DECIMAL(12,2)) AS ExpectedRevenue
FROM dbo.Employees AS e
LEFT JOIN dbo.Schedule AS s
    ON s.EmployeeId = e.EmployeeId
   AND s.ServiceDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
LEFT JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
GROUP BY e.EmployeeId, e.LastName, e.FirstName;
GO

-- Сотрудники с максимальной ожидаемой выручкой завтра.
SELECT EmployeeId, EmployeeLastName, EmployeeFirstName, ExpectedRevenue
FROM dbo.vw_TomorrowEmployeeRevenue
WHERE ExpectedRevenue = (SELECT MAX(ExpectedRevenue) FROM dbo.vw_TomorrowEmployeeRevenue);
GO

-- 3. Услуги и количество их оказаний, запланированных на завтра.
CREATE OR ALTER VIEW dbo.vw_TomorrowServiceCounts
AS
SELECT srv.ServiceId,
       srv.ServiceName,
       COUNT(*) AS ServiceCount
FROM dbo.Schedule AS s
INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
WHERE s.ServiceDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
GROUP BY srv.ServiceId, srv.ServiceName;
GO

-- Услуги, которые оказываются чаще всех завтра.
SELECT ServiceId, ServiceName, ServiceCount
FROM dbo.vw_TomorrowServiceCounts
WHERE ServiceCount = (SELECT MAX(ServiceCount) FROM dbo.vw_TomorrowServiceCounts);
GO

-- 4. Клиенты и оказанные им услуги за прошлый месяц.
CREATE OR ALTER VIEW dbo.vw_LastMonthClientServices
AS
SELECT c.ClientId,
       c.LastName,
       c.FirstName,
       s.ServiceDate,
       srv.ServiceId,
       srv.ServiceName,
       srv.Price
FROM dbo.Schedule AS s
INNER JOIN dbo.Clients AS c ON c.ClientId = s.ClientId
INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
WHERE s.ServiceDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
  AND s.ServiceDate <  DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
GO

-- Клиенты, которым оказали наиболее дорогие услуги в прошлом месяце.
SELECT ClientId, LastName, FirstName, ServiceDate, ServiceName, Price
FROM dbo.vw_LastMonthClientServices
WHERE Price = (SELECT MAX(Price) FROM dbo.vw_LastMonthClientServices);

-- Таблица для журнала изменений расписания.
IF OBJECT_ID(N'dbo.ScheduleAudit', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ScheduleAudit
    (
        AuditId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ScheduleAudit PRIMARY KEY,
        ChangedAt DATETIME2(0) NOT NULL CONSTRAINT DF_ScheduleAudit_ChangedAt DEFAULT SYSDATETIME(),
        OperationName NVARCHAR(10) NOT NULL,
        ScheduleId INT NOT NULL,
        OldServiceDate DATE NULL,
        NewServiceDate DATE NULL,
        OldServiceTime TIME(0) NULL,
        NewServiceTime TIME(0) NULL,
        OldClientId INT NULL,
        NewClientId INT NULL,
        OldServiceId INT NULL,
        NewServiceId INT NULL,
        OldEmployeeId INT NULL,
        NewEmployeeId INT NULL
    );
END;
GO

-- Триггер сохраняет добавления, изменения и удаления из расписания.
CREATE OR ALTER TRIGGER dbo.trg_ScheduleAudit
ON dbo.Schedule
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ScheduleAudit
    (
        OperationName, ScheduleId,
        OldServiceDate, NewServiceDate, OldServiceTime, NewServiceTime,
        OldClientId, NewClientId, OldServiceId, NewServiceId, OldEmployeeId, NewEmployeeId
    )
    SELECT CASE
               WHEN d.ScheduleId IS NULL THEN N'INSERT'
               WHEN i.ScheduleId IS NULL THEN N'DELETE'
               ELSE N'UPDATE'
           END,
           COALESCE(i.ScheduleId, d.ScheduleId),
           d.ServiceDate, i.ServiceDate, d.ServiceTime, i.ServiceTime,
           d.ClientId, i.ClientId, d.ServiceId, i.ServiceId, d.EmployeeId, i.EmployeeId
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.ScheduleId = i.ScheduleId;
END;
GO

-- Содержимое созданных представлений и журнала триггера.
SELECT * FROM dbo.vw_TomorrowFullSchedule;
SELECT * FROM dbo.vw_TomorrowEmployeeRevenue;
SELECT * FROM dbo.vw_TomorrowServiceCounts;
SELECT * FROM dbo.vw_LastMonthClientServices;
SELECT * FROM dbo.ScheduleAudit ORDER BY AuditId;
GO
