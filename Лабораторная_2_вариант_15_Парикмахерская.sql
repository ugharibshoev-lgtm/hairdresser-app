/*
   Лабораторная работа 2. Вариант 15 «Парикмахерская».
   Агрегатные запросы для базы HairdresserDB.
*/

USE HairdresserDB;
GO

-- 1. Количество клиентов парикмахерской.
SELECT COUNT(*) AS ClientCount
FROM dbo.Clients;

-- 2. Количество клиентов, обслуженных каждым сотрудником.
SELECT e.EmployeeId,
       e.LastName,
       e.FirstName,
       COUNT(DISTINCT s.ClientId) AS ClientCount
FROM dbo.Employees AS e
LEFT JOIN dbo.Schedule AS s ON s.EmployeeId = e.EmployeeId
GROUP BY e.EmployeeId, e.LastName, e.FirstName
ORDER BY e.EmployeeId;

-- 3. Код сотрудника, обслужившего максимальное количество клиентов.
SELECT TOP (1) WITH TIES s.EmployeeId,
       COUNT(DISTINCT s.ClientId) AS ClientCount
FROM dbo.Schedule AS s
GROUP BY s.EmployeeId
ORDER BY COUNT(DISTINCT s.ClientId) DESC;

-- 4. Код самой популярной на прошлой неделе услуги.
SELECT TOP (1) WITH TIES s.ServiceId,
       COUNT(*) AS ServiceCount
FROM dbo.Schedule AS s
WHERE DATEDIFF(WEEK, 0, s.ServiceDate) = DATEDIFF(WEEK, 0, GETDATE()) - 1
GROUP BY s.ServiceId
ORDER BY COUNT(*) DESC;

-- 5. Среднее количество клиентов, обслуживаемых в день.
SELECT CAST(AVG(CAST(DailyClients AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS AverageClientsPerDay
FROM
(
    SELECT ServiceDate, COUNT(DISTINCT ClientId) AS DailyClients
    FROM dbo.Schedule
    GROUP BY ServiceDate
) AS DailySchedule;

-- 6. Количество услуг, оказанных в прошлом месяце.
SELECT COUNT(*) AS ServiceCountLastMonth
FROM dbo.Schedule
WHERE ServiceDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
  AND ServiceDate <  DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);

-- 7. Среднее количество клиентов, обслуженных одним сотрудником.
SELECT CAST(AVG(CAST(ClientCount AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS AverageClientsPerEmployee
FROM
(
    SELECT e.EmployeeId, COUNT(DISTINCT s.ClientId) AS ClientCount
    FROM dbo.Employees AS e
    LEFT JOIN dbo.Schedule AS s ON s.EmployeeId = e.EmployeeId
    GROUP BY e.EmployeeId
) AS EmployeeSchedule;
GO
