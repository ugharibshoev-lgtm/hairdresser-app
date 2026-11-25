/* Удаляет только учебную базу HairdresserDB перед её созданием заново. */

USE master;
GO

IF DB_ID(N'HairdresserDB') IS NOT NULL
BEGIN
    ALTER DATABASE HairdresserDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HairdresserDB;
END;
GO
