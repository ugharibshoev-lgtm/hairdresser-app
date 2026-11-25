/*
   Лабораторная работа 1. Вариант 15 «Парикмахерская».
   Скрипт рассчитан на Microsoft SQL Server.
*/

USE master;
GO

IF DB_ID(N'HairdresserDB') IS NULL
    CREATE DATABASE HairdresserDB;
GO

USE HairdresserDB;
GO

CREATE TABLE dbo.Clients
(
    ClientId    INT IDENTITY(1,1) NOT NULL,
    LastName    NVARCHAR(50) NOT NULL,
    FirstName   NVARCHAR(50) NOT NULL,
    MiddleName  NVARCHAR(50) NULL,
    Phone       VARCHAR(20) NULL,
    Address     NVARCHAR(150) NULL,
    CONSTRAINT PK_Clients PRIMARY KEY (ClientId)
);
GO

CREATE TABLE dbo.Services
(
    ServiceId   INT IDENTITY(1,1) NOT NULL,
    ServiceName NVARCHAR(100) NOT NULL,
    Price       DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Services PRIMARY KEY (ServiceId),
    CONSTRAINT UQ_Services_ServiceName UNIQUE (ServiceName),
    CONSTRAINT CK_Services_Price CHECK (Price >= 0)
);
GO

CREATE TABLE dbo.Employees
(
    EmployeeId  INT IDENTITY(1,1) NOT NULL,
    LastName    NVARCHAR(50) NOT NULL,
    FirstName   NVARCHAR(50) NOT NULL,
    MiddleName  NVARCHAR(50) NULL,
    CONSTRAINT PK_Employees PRIMARY KEY (EmployeeId)
);
GO

CREATE TABLE dbo.Schedule
(
    ScheduleId  INT IDENTITY(1,1) NOT NULL,
    ServiceDate DATE NOT NULL,
    ServiceTime TIME(0) NOT NULL,
    ClientId    INT NOT NULL,
    ServiceId   INT NOT NULL,
    EmployeeId  INT NOT NULL,
    CONSTRAINT PK_Schedule PRIMARY KEY (ScheduleId),
    CONSTRAINT FK_Schedule_Clients FOREIGN KEY (ClientId)
        REFERENCES dbo.Clients (ClientId),
    CONSTRAINT FK_Schedule_Services FOREIGN KEY (ServiceId)
        REFERENCES dbo.Services (ServiceId),
    CONSTRAINT FK_Schedule_Employees FOREIGN KEY (EmployeeId)
        REFERENCES dbo.Employees (EmployeeId)
);
GO

INSERT INTO dbo.Clients (LastName, FirstName, MiddleName, Phone, Address) VALUES
(N'Тарасова', N'Анна',     N'Игоревна',     '80291111111', N'г. Минск, ул. Ленина, 10'),
(N'Иванов',   N'Пётр',     N'Сергеевич',    NULL,          N'г. Минск, ул. Победителей, 25'),
(N'Татарин',  N'Олег',     N'Викторович',   '80292222222', N'г. Минск, ул. Немига, 4'),
(N'Соколова', N'Елена',    N'Андреевна',    '80293333333', N'г. Минск, ул. Сурганова, 8'),
(N'Таранов',  N'Максим',   N'Павлович',     NULL,          N'г. Минск, пр-т Независимости, 40'),
(N'Ковалёв',  N'Дмитрий',  N'Олегович',     '80294444444', N'г. Минск, ул. Кальварийская, 15'),
(N'Орлова',   N'Марина',   N'Владимировна', NULL,          N'г. Минск, ул. Якуба Коласа, 19'),
(N'Петров',   N'Алексей',  N'Николаевич',   '80295555555', N'г. Минск, ул. Купалы, 7'),
(N'Васильева',N'Ольга',    N'Ивановна',     '80296666666', N'г. Минск, ул. Московская, 21'),
(N'Романов',  N'Сергей',   N'Михайлович',   '80297777777', N'г. Минск, ул. Притыцкого, 30');

INSERT INTO dbo.Services (ServiceName, Price) VALUES
(N'Стрижка',             18.00),
(N'Окрашивание волос',   55.00),
(N'Укладка',             12.00),
(N'Маникюр',             25.00);

INSERT INTO dbo.Employees (LastName, FirstName, MiddleName) VALUES
(N'Кузнецова', N'Ирина',     N'Александровна'),
(N'Смирнов',   N'Артём',     N'Викторович'),
(N'Белова',    N'Наталья',   N'Сергеевна'),
(N'Громов',    N'Денис',     N'Олегович');
GO

DECLARE @Today DATE = CAST(GETDATE() AS DATE);
DECLARE @Yesterday DATE = DATEADD(DAY, -1, @Today);
DECLARE @LastWeekDate DATE = DATEADD(DAY, -7, @Today);

INSERT INTO dbo.Schedule (ServiceDate, ServiceTime, ClientId, ServiceId, EmployeeId) VALUES
(@Today,        '09:00', 2, 1, 1),
(@Today,        '10:30', 3, 2, 2),
(@Today,        '12:00', 5, 4, 3),
(@Today,        '14:00', 1, 3, 1),
(@Yesterday,    '11:00', 2, 2, 2),
(@Yesterday,    '15:30', 4, 1, 4),
(@LastWeekDate, '09:30', 6, 3, 3),
(@LastWeekDate, '13:00', 7, 4, 4),
(DATEADD(DAY, -8, @Today), '16:00', 8, 1, 1),
(DATEADD(DAY,  1, @Today), '10:00', 9, 2, 2);
GO

/* Запросы по варианту 15 */

-- 1. Вывести всю таблицу «Расписание».
SELECT ScheduleId, ServiceDate, ServiceTime, ClientId, ServiceId, EmployeeId
FROM dbo.Schedule;

-- 2. Вывести список услуг, цена на которые выше 10 руб.
SELECT ServiceId, ServiceName, Price
FROM dbo.Services
WHERE Price > 10;

-- 3. Вывести коды услуг, оказанных клиенту с кодом 2 вчера.
SELECT DISTINCT ServiceId
FROM dbo.Schedule
WHERE ClientId = 2
  AND ServiceDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));

-- 4. Вывести коды услуг, оказанных сегодня клиентам с кодами 2, 3, 5.
SELECT DISTINCT ServiceId
FROM dbo.Schedule
WHERE ClientId IN (2, 3, 5)
  AND ServiceDate = CAST(GETDATE() AS DATE);

-- 5. Вывести коды сотрудников, оказывавших услуги на прошлой неделе.
SELECT DISTINCT EmployeeId
FROM dbo.Schedule
WHERE DATEDIFF(WEEK, 0, ServiceDate) = DATEDIFF(WEEK, 0, GETDATE()) - 1;

-- 6. Вывести список клиентов, не имеющих телефонов.
SELECT ClientId, LastName, FirstName, MiddleName, Phone, Address
FROM dbo.Clients
WHERE Phone IS NULL;

-- 7. Вывести список клиентов, фамилии которых начинаются на «Та».
SELECT ClientId, LastName, FirstName, MiddleName, Phone, Address
FROM dbo.Clients
WHERE LastName LIKE N'Та%';
GO
