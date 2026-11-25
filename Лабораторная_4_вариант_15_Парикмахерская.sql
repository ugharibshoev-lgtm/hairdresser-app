/*
   Лабораторная работа 4. Вариант 15 «Парикмахерская».
   Хранимые процедуры и пользовательские функции.
*/

USE HairdresserDB;
GO

-- 1. Процедура: расписание работы на следующую неделю.
CREATE OR ALTER PROCEDURE dbo.usp_NextWeekSchedule
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.ServiceDate,
           s.ServiceTime,
           e.LastName AS EmployeeLastName,
           srv.ServiceName
    FROM dbo.Schedule AS s
    INNER JOIN dbo.Employees AS e ON e.EmployeeId = s.EmployeeId
    INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
    WHERE s.ServiceDate >= DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) + 1, 0)
      AND s.ServiceDate <  DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) + 2, 0)
    ORDER BY s.ServiceDate, s.ServiceTime;
END;
GO

-- 2. Процедура: увеличить на 10% цены услуг, оказанных на прошлой неделе.
CREATE OR ALTER PROCEDURE dbo.usp_IncreaseLastWeekServicePrices
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE srv
    SET Price = ROUND(srv.Price * 1.10, 2)
    FROM dbo.Services AS srv
    WHERE srv.ServiceId IN
    (
        SELECT DISTINCT s.ServiceId
        FROM dbo.Schedule AS s
        WHERE DATEDIFF(WEEK, 0, s.ServiceDate) = DATEDIFF(WEEK, 0, GETDATE()) - 1
    );

    SELECT ServiceId, ServiceName, Price
    FROM dbo.Services
    ORDER BY ServiceId;
END;
GO

-- 3. Процедура: услуги прошлого месяца и выручка. Общая выручка передаётся выходным параметром.
CREATE OR ALTER PROCEDURE dbo.usp_LastMonthServicesRevenue
    @TotalRevenue DECIMAL(12,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT srv.ServiceId,
           srv.ServiceName,
           COUNT(*) AS ServiceCount,
           CAST(SUM(srv.Price) AS DECIMAL(12,2)) AS Revenue
    FROM dbo.Schedule AS s
    INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
    WHERE s.ServiceDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
      AND s.ServiceDate <  DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
    GROUP BY srv.ServiceId, srv.ServiceName;

    SELECT @TotalRevenue = CAST(ISNULL(SUM(srv.Price), 0) AS DECIMAL(12,2))
    FROM dbo.Schedule AS s
    INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
    WHERE s.ServiceDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
      AND s.ServiceDate <  DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
END;
GO

-- 4. Скалярная функция: количество обслуженных клиентов на указанную дату.
CREATE OR ALTER FUNCTION dbo.fn_ClientCountByDate (@ServiceDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @ClientCount INT;

    SELECT @ClientCount = COUNT(DISTINCT ClientId)
    FROM dbo.Schedule
    WHERE ServiceDate = @ServiceDate;

    RETURN ISNULL(@ClientCount, 0);
END;
GO

-- 5. Табличная функция: клиенты, записанные на завтра.
CREATE OR ALTER FUNCTION dbo.fn_ClientsTomorrow()
RETURNS TABLE
AS
RETURN
(
    SELECT c.ClientId,
           c.LastName,
           c.FirstName,
           s.ServiceTime,
           srv.ServiceName
    FROM dbo.Schedule AS s
    INNER JOIN dbo.Clients AS c ON c.ClientId = s.ClientId
    INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
    WHERE s.ServiceDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
);
GO

-- 6. Многострочная табличная функция: график работы на завтра.
CREATE OR ALTER FUNCTION dbo.fn_EmployeeScheduleTomorrow()
RETURNS @Result TABLE
(
    EmployeeId INT,
    EmployeeLastName NVARCHAR(50),
    ServiceTime TIME(0),
    ServiceName NVARCHAR(100),
    Price DECIMAL(10,2),
    ClientLastName NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @Result (EmployeeId, EmployeeLastName, ServiceTime, ServiceName, Price, ClientLastName)
    SELECT e.EmployeeId,
           e.LastName,
           s.ServiceTime,
           srv.ServiceName,
           srv.Price,
           c.LastName
    FROM dbo.Schedule AS s
    INNER JOIN dbo.Employees AS e ON e.EmployeeId = s.EmployeeId
    INNER JOIN dbo.Services AS srv ON srv.ServiceId = s.ServiceId
    INNER JOIN dbo.Clients AS c ON c.ClientId = s.ClientId
    WHERE s.ServiceDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

    RETURN;
END;
GO

/* Выполнение процедур и функций */

EXEC dbo.usp_NextWeekSchedule;

EXEC dbo.usp_IncreaseLastWeekServicePrices;

DECLARE @Revenue DECIMAL(12,2);
EXEC dbo.usp_LastMonthServicesRevenue @TotalRevenue = @Revenue OUTPUT;
SELECT @Revenue AS TotalRevenueLastMonth;

SELECT dbo.fn_ClientCountByDate(CAST(GETDATE() AS DATE)) AS ClientCountToday;

SELECT * FROM dbo.fn_ClientsTomorrow();

SELECT * FROM dbo.fn_EmployeeScheduleTomorrow();
GO
