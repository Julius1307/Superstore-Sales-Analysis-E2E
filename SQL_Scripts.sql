-- PROYECTO: Dashboard Ejecutivo Superstore
-- OBJETIVO: Creación de base de datos y normalización a Modelo Estrella (1 Fact, 3 Dim).
-- HERRAMIENTA: SQL Server
-- AUTOR: Julius Ormeño

-- 1. Crear la Dimensión de Productos (Limpia)
SELECT DISTINCT 
    [Product ID], 
    [Category], 
    [Sub-Category], 
    [Product Name]
INTO Dim_Product
FROM Raw_Superstore_Temp;

-- 2. Crear la Dimensión de Clientes
SELECT DISTINCT 
    [Customer ID], 
    [Customer Name], 
    [Segment]
INTO Dim_Customer
FROM Raw_Superstore_Temp;

-- 3. Crear la Dimensión de Ubicación (con un ID único)
SELECT DISTINCT 
    DENSE_RANK() OVER(ORDER BY Country, State, City, [Postal Code]) as Location_ID,
    Country,
    Region,
    State,
    City,
    [Postal Code]
INTO Dim_Location
FROM Raw_Superstore_Temp;

-- Primero, borramos la tabla de hechos si se alcanzó a crear a medias
IF OBJECT_ID('Fact_Sales', 'U') IS NOT NULL DROP TABLE Fact_Sales;

-- 4. Crear la Tabla de Hechos con limpieza profunda
SELECT 
    TRY_CAST([Row ID] AS INT) as Row_ID,
    [Order ID],
    TRY_CAST([Order Date] AS DATE) as Order_Date,
    TRY_CAST([Ship Date] AS DATE) as Ship_Date,
    [Ship Mode],
    [Customer ID],
    [Product ID],
    l.Location_ID,
    -- Limpieza de Sales: quitamos símbolos raros y manejamos decimales
    TRY_CAST(REPLACE(REPLACE([Sales], '$', ''), ',', '.') AS DECIMAL(18,2)) as Sales,
    TRY_CAST([Quantity] AS INT) as Quantity,
    TRY_CAST(REPLACE(REPLACE([Discount], '%', ''), ',', '.') AS DECIMAL(18,4)) as Discount,
    TRY_CAST(REPLACE(REPLACE([Profit], '$', ''), ',', '.') AS DECIMAL(18,2)) as Profit
INTO Fact_Sales
FROM Raw_Superstore_Temp r
JOIN Dim_Location l 
    ON r.City = l.City 
    AND r.State = l.State 
    AND r.[Postal Code] = l.[Postal Code];

SELECT TOP 20 * FROM Fact_Sales;