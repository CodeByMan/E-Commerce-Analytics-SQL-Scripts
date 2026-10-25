USE master;

IF DB_ID(N'Brz_Ecomerce') IS NULL
    EXEC(N'CREATE DATABASE Brz_Ecomerce');
