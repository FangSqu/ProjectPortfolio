SELECT TOP (1000) [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [ProtfolioProject 2_DataCleaning ].[dbo].[NashvilleHousing]

SElECT* 
FROM NashvilleHousing


--Standardize SaleDate Format


SElECT SaleDate, CONVERT(DATE,SaleDate)
FROM NashvilleHousing
/*
SaleDate included times in hours that serves little perpuse Converting in into Dates
*/

UPDATE NashvilleHousing
SET SaleDate  = CONVERT(DATE,SaleDate)

/* 
SET the target column to replace the original SaleDate with the newly CONVERTED Date Format
*/

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE 

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate)

SELECT SaleDateConverted
From NashvilleHousing

/*
The previous query doesn't resolve properly using the claus UPDATE and CONVERT
Here I added a new column named SaleDateConverted, and specified the value formate as DATE

*/

--Property Address  w/ missing data
SELECT *
FROM NashvilleHousing
--where PropertyAddress is null
ORDER BY ParcelID
/* From the dataset noticed that 'ParcelID' and 'PropertyAddress' is directly related, every property is assigned with an unique parcel ID.
To fill the null values for 'PropertyAddress', I reference it to the 'ParcelID' */

SELECT a.ParcelID, a.[UniqueID ], a.PropertyAddress, b.ParcelID, b.[UniqueID ], b.PropertyAddress, ISNULL(a.propertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress is null
/* Here, I match the Parcel ID where they don't have the same identifing variable, 'UniqueID', using the JOIN statement. 
	Make sure we only select the null values.
	Use ISNULL to create a new coloumn that can has been returned null values from b.Property. */
	

UPDATE a
SET PropertyAddress = ISNULL(a.propertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
	WHERE a.PropertyAddress is null
/*Use UPDATE to edit the values of the table itself*/

--------------------------------------------------------------------
--Breaking up Address into individual columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
CHARINDEX(',', PropertyAddress)
FROM NashvilleHousing

/* CHARINDEX(',', PropertyAddress) is a numerical value where ',' is the positioned at, 
by -1, we can substring whereever it is before the ','.
*/ 

SELECT PropertyAddress
FROM NashvilleHousing

SELECT  
PARSENAME(REPLACE(PropertyAddress,',','.'),1) AS City
,PARSENAME(REPLACE(PropertyAddress,',','.'),2) AS Address
FROM NashvilleHousing

/*Use the action PRASENAME to break up the PropertyAddress.
PRASENAME(Column_1, number of the position of the '.') 
BUT, here we have a ',' so need to change the '.' into a ','.
PREPLEACE(Column_1,"outcome", "target subject")
*/

ALTER TABLE NashvilleHousing 
Add SplitPropertyAddress Varchar(225)
;
UPDATE NashvilleHousing
SET SplitPropertyAddress = PARSENAME(REPLACE(PropertyAddress,',','.'),2)

ALTER TABLE NashvilleHousing 
Add SplitPropertyCity Varchar(225)
;
UPDATE NashvilleHousing
SET SplitPropertyCity = PARSENAME(REPLACE(PropertyAddress,',','.'),1)

--Use ALTER TABLE to add new Column 
--Use Update to add the values SET column1 = new_column


SELECT *
FROM NashvilleHousing

-- Change 'Y' and 'N' into 'Yes' and 'No' in "SoldAsVacant"

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Use the CASE claus to produce a new column with edited values 

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' then 'Yes'
		 WHEN SoldAsVacant = 'N' then 'No'
		 ELSE SoldAsVacant
		 END 
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
		 CASE WHEN SoldAsVacant = 'Y' then 'Yes'
		 WHEN SoldAsVacant = 'N' then 'No'
		 ELSE SoldAsVacant
		 END 

--REMOVE Duplicate Data

--Use PRTITION BY clause to aggregate each duplicated data. 
--This produces a new column indicating how many of the same data has appeared. Therefore duplicated.
--Find that number > 1, using WHERE clause, then delete

WITH CTE_Row_Number_Temp as (
SELECT *, ROW_NUMBER () 
			OVER (PARTITION BY
					ParcelID,
					PropertyAddress,
					SaleDate,
					SalePrice
					ORDER BY UniqueID) AS row_num
FROM NashvilleHousing)
--ORDER BY ParcelID)

SELECT* 
FROM CTE_Row_Number_Temp 
WHERE row_num >1



--Remove unusable columns 
-- Along the way, new usable columns are created, such as SaleDateConverted, the old ones are no longer useful.

SELECT*
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress
	 


