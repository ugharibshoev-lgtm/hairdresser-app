/*
   Лабораторная работа 3. Вариант 15 «Парикмахерская».
   Соединения таблиц, операции множеств и модификация данных.
*/

USE HairdresserDB;
GO

-- 1. Список сотрудников, работающих сегодня.
SELECT DISTINCT e.EmployeeId, e.LastName, e.FirstName, e.MiddleName
FROM dbo.Employees AS e
INNER JOIN dbo.Schedule AS s ON s.EmployeeId = e.EmployeeId
WHERE s.ServiceDate = CAST(GETDATE() AS DATE);

-- 2. Список клиентов с указанием услуг, записанных на сегодня.
SELECT c.ClientId, c.LastName, c.FirstName,
       srv.ServiceName, s.ServiceTime
FROM dbo.Schedule AS s
INNER JOIN dbo.Clients AS c ON c.ClientId = s.ClientId
INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
WHERE s.ServiceDate = CAST(GETDATE() AS DATE)
ORDER BY s.ServiceTime;

-- 3. Услуги и их цены, запланированные на сегодня.
SELECT DISTINCT srv.ServiceId, srv.ServiceName, srv.Price
FROM dbo.Schedule AS s
INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
WHERE s.ServiceDate = CAST(GETDATE() AS DATE);

-- 4. Расписание работы сотрудников с клиентами и услугами.
SELECT s.ScheduleId, s.ServiceDate, s.ServiceTime,
       e.EmployeeId, e.LastName AS EmployeeLastName, e.FirstName AS EmployeeFirstName,
       c.ClientId, c.LastName AS ClientLastName, c.FirstName AS ClientFirstName,
       srv.ServiceName, srv.Price
FROM dbo.Schedule AS s
INNER JOIN dbo.Employees AS e ON e.EmployeeId = s.EmployeeId
INNER JOIN dbo.Clients AS c ON c.ClientId = s.ClientId
INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
ORDER BY s.ServiceDate, s.ServiceTime;

-- 5. Список услуг, у которых цена одинакова.
SELECT s1.ServiceId, s1.ServiceName, s1.Price
FROM dbo.Services AS s1
WHERE s1.ServiceId IN
(
    SELECT s2.ServiceId
    FROM dbo.Services AS s2
    INNER JOIN dbo.Services AS s3
        ON s2.Price = s3.Price AND s2.ServiceId <> s3.ServiceId
);

-- 6. Сотрудники, которым запланировано одновременное оказание услуг.
SELECT DISTINCT e.EmployeeId, e.LastName, e.FirstName, s1.ServiceDate, s1.ServiceTime
FROM dbo.Schedule AS s1
INNER JOIN dbo.Schedule AS s2
    ON s1.ServiceDate = s2.ServiceDate
   AND s1.ServiceTime = s2.ServiceTime
   AND s1.EmployeeId <> s2.EmployeeId
INNER JOIN dbo.Employees AS e ON e.EmployeeId = s1.EmployeeId;

-- 7. Клиенты-однофамильцы.
SELECT c1.ClientId, c1.LastName, c1.FirstName, c1.MiddleName
FROM dbo.Clients AS c1
WHERE c1.LastName IN
(
    SELECT c2.LastName
    FROM dbo.Clients AS c2
    GROUP BY c2.LastName
    HAVING COUNT(*) > 1
);

-- Операции UNION, EXCEPT, INTERSECT.
-- Сотрудники, работавшие сегодня или вчера.
SELECT DISTINCT EmployeeId FROM dbo.Schedule WHERE ServiceDate = CAST(GETDATE() AS DATE)
UNION
SELECT DISTINCT EmployeeId FROM dbo.Schedule WHERE ServiceDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));

-- Сотрудники, работавшие сегодня, но не вчера.
SELECT DISTINCT EmployeeId FROM dbo.Schedule WHERE ServiceDate = CAST(GETDATE() AS DATE)
EXCEPT
SELECT DISTINCT EmployeeId FROM dbo.Schedule WHERE ServiceDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));

-- Сотрудники, работавшие и сегодня, и вчера.
SELECT DISTINCT EmployeeId FROM dbo.Schedule WHERE ServiceDate = CAST(GETDATE() AS DATE)
INTERSECT
SELECT DISTINCT EmployeeId FROM dbo.Schedule WHERE ServiceDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));

-- Создание таблицы «Архив».
IF OBJECT_ID(N'dbo.Archive', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Archive
    (
        ArchiveId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Archive PRIMARY KEY,
        ScheduleId INT NOT NULL,
        ServiceDate DATE NOT NULL,
        ServiceTime TIME(0) NOT NULL,
        ClientId INT NOT NULL,
        ServiceId INT NOT NULL,
        EmployeeId INT NOT NULL
    );
END;
GO

-- Запись в архив услуг за месяцы, предшествующие текущему.
INSERT INTO dbo.Archive (ScheduleId, ServiceDate, ServiceTime, ClientId, ServiceId, EmployeeId)
SELECT s.ScheduleId, s.ServiceDate, s.ServiceTime, s.ClientId, s.ServiceId, s.EmployeeId
FROM dbo.Schedule AS s
WHERE s.ServiceDate < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Archive AS a
      WHERE a.ScheduleId = s.ScheduleId
  );

SELECT *
FROM dbo.Archive;

-- Добавление и заполнение поля «Продолжительность» в таблице услуг.
IF COL_LENGTH(N'dbo.Services', N'DurationMinutes') IS NULL
    ALTER TABLE dbo.Services ADD DurationMinutes INT NULL;
GO

UPDATE dbo.Services
SET DurationMinutes = CASE WHEN ServiceId % 2 = 0 THEN 30 ELSE 20 END;

SELECT ServiceId, ServiceName, Price, DurationMinutes
FROM dbo.Services;

-- Удаление из расписания услуг, оказанных до начала текущего месяца.
DELETE FROM dbo.Schedule
WHERE ServiceDate < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
GO
