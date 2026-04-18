WITH Normalized AS
(
	SELECT
		CAST(CASE
			WHEN iceThickness IS NULL THEN NULL
			WHEN iceThickness < 10 THEN iceThickness * 100
			ELSE iceThickness
		END AS float) AS iceThicknessCm,
		CAST(surfaceTemperature AS float) AS surfaceTemperatureC,
		CAST(externalTemperature AS float) AS externalTemperatureC,
		CAST(snowAccumulation AS float) AS snowAccumulationCm,
		CAST(IoTHub.ConnectionDeviceId AS nvarchar(max)) AS location
	FROM IceSensorHub TIMESTAMP BY EventEnqueuedUtcTime
),
Aggregated AS
(
	SELECT
		location,
		System.Timestamp AS [timestamp],
		AVG(iceThicknessCm) AS averageIceThicknessCm,
		MIN(iceThicknessCm) AS minIceThicknessCm,
		MAX(iceThicknessCm) AS maxIceThicknessCm,
		AVG(surfaceTemperatureC) AS averageSurfaceTemperatureC,
		MIN(surfaceTemperatureC) AS minSurfaceTemperatureC,
		MAX(surfaceTemperatureC) AS maxSurfaceTemperatureC,
		MAX(snowAccumulationCm) AS maximumSnowAccumulationCm,
		AVG(externalTemperatureC) AS averageExternalTemperatureC,
		COUNT(*) AS readingCount
	FROM Normalized
	GROUP BY location, TumblingWindow(minute, 5)
),
FinalResult AS
(
	SELECT
		location,
		[timestamp],
		averageIceThicknessCm,
		minIceThicknessCm,
		maxIceThicknessCm,
		averageSurfaceTemperatureC,
		minSurfaceTemperatureC,
		maxSurfaceTemperatureC,
		maximumSnowAccumulationCm,
		averageExternalTemperatureC,
		readingCount,
		CASE
			WHEN averageIceThicknessCm >= 30 AND averageSurfaceTemperatureC <= -2 THEN 'Safe'
			WHEN averageIceThicknessCm >= 25 AND averageSurfaceTemperatureC <= 0 THEN 'Caution'
			ELSE 'Unsafe'
		END AS safetyStatus
	FROM Aggregated
)
SELECT
	location,
	[timestamp],
	averageIceThicknessCm,
	minIceThicknessCm,
	maxIceThicknessCm,
	averageSurfaceTemperatureC,
	minSurfaceTemperatureC,
	maxSurfaceTemperatureC,
	maximumSnowAccumulationCm,
	averageExternalTemperatureC,
	readingCount,
	safetyStatus
INTO [historical-data]
FROM FinalResult;

SELECT
	location,
	[timestamp],
	averageIceThicknessCm,
	minIceThicknessCm,
	maxIceThicknessCm,
	averageSurfaceTemperatureC,
	minSurfaceTemperatureC,
	maxSurfaceTemperatureC,
	maximumSnowAccumulationCm,
	averageExternalTemperatureC,
	readingCount,
	safetyStatus
INTO SensorAggregations
FROM FinalResult;

