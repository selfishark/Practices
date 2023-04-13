USE [training-test]

-- RANKING FUNCTION: Row Number, Rank, Dense Rank


-- THIS RANKING SHOULD PROMPT DIFFERENT RESULTS IF IT HAS DUPLICATES ON 'TP'
SELECT 
	City, 
	Temprature AS tp, 
	[DateTime],
		ROW_NUMBER() OVER (ORDER BY Temprature) AS RowNmbr_tp,
		RANK() OVER (ORDER BY Temprature) AS Rank_tp,
		DENSE_RANK() OVER (ORDER BY Temprature) AS Dense_Rank_tp

FROM [training-test].[dbo].[Weather_API_Table]


-- NTILE
USE [training-test]

SELECT 
	City, 
	Temprature AS tp, 
	[DateTime],
		NTILE (2) OVER (ORDER BY Temprature) AS [NTILE OF 2 ON tp] -- Here the tile is per 2 or 2%;  'Tile per 100' is percentile (100%), 'Tile per 10' is decitile (10%).

FROM [training-test].[dbo].[Weather_API_Table]

GO

-- It is best practice to choose the number of item that goes is a tile rather than the number tiles
SELECT 
	City, 
	Temprature AS tp, 
	[DateTime],
		NTILE ((SELECT COUNT (*)/10 FROM [dbo].[Weather_API_Table])) OVER (ORDER BY Temprature) AS [NTILE OF 10 ITEMS PER TILE ] -- This tile take 10 items per tile.
										-- The Ntile can take an expression for the number of item calculation
FROM [training-test].[dbo].[Weather_API_Table]

ORDER BY City

GO

-- PARTITION A RANKING

SELECT [Car_Number_Historical], [Incident_Cause], [Submitted_By], [Review_Date],
	RANK() OVER (PARTITION BY [Submitted_By] ORDER BY [Review_Date]) AS [LastReviewRank]

FROM [training-test].[dbo].[CAR_Automation]
ORDER BY [Review_Date], [LastReviewRank]

GO


SELECT [Car_Number_Historical], [Incident_Cause], [Submitted_By], [Review_Date],
	NTILE(2) OVER (PARTITION BY [Submitted_By] ORDER BY [Review_Date]) AS [LastReviewRank]

FROM [training-test].[dbo].[CAR_Automation]
ORDER BY [Review_Date], [LastReviewRank]

GO

-- example of partition based on a special charater inside the row:
SELECT
	[Parties_Notified_Internal_External],
		RANK() OVER(PARTITION BY RIGHT ([Parties_Notified_Internal_External], LEN([Parties_Notified_Internal_External]) - CHARINDEX(',', [Parties_Notified_Internal_External])) ORDER BY [Parties_Notified_Internal_External] ) AS RANKORDER

FROM [training-test].[dbo].[CAR_Automation]

GO