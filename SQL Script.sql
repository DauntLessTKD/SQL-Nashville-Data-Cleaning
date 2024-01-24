-- Creating the DDBB
CREATE DATABASE IF NOT EXISTS cleaning_project;

-- Selecting the DDBB to be used
USE cleaning_project;

-- Here is where you upload the data, with the python script that i leave you in the repo
-- Or if you know how to upload an excel file in MySQL directly

-- (i'm going to let a python script to create the table and upload the data)
-- Looking at the Whole table
SELECT * FROM housing_data;


-- Cleaning Data in SQL Queries
--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

-- Looking at the format of the Date columns
SELECT SaleDate, DATE(SaleDate) AS FormattedSaleDate
FROM housing_data;

-- Trying to update the SaleDate column, it didn't work, so i create a new column
UPDATE housing_data
SET SaleDate = DATE(SaleDate);

-- Creating a new column for the right format of SaleDate column
ALTER TABLE housing_data
ADD SaleDateConverted Date;

-- Updating the new column to the right format
UPDATE housing_data
SET SaleDateConverted = DATE(SaleDate);

-- Looking at how the data is right now
SELECT SaleDateConverted
FROM housing_data;

--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

-- Looking at the data
SELECT *
FROM housing_data
ORDER BY ParcelID;

-- Looking if there is some nulls in the Property Address column
SELECT *
FROM housing_data
WHERE PropertyAddress is null
ORDER BY ParcelID;

-- Looking at the Property address data that is null
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress) AS MergedPropertyAddress
FROM housing_data a
JOIN housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Filling the nulls in the Property column, using another data in the same table
UPDATE housing_data a
JOIN housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address columns, into Individual Columns (Address, City, State)

-- Looking the data
SELECT PropertyAddress
FROM housing_data;

-- Looking at what the property address looks like, splited into two columns.
SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',' , PropertyAddress) - 1) AS PropertyAddress,
SUBSTRING(PropertyAddress, LOCATE(',' , PropertyAddress) + 1, LENGTH(PropertyAddress)) AS PropertyCity
FROM housing_data;

-- Creating the new Property Address column, that is going to have only the Address
ALTER TABLE housing_data
ADD PropertySplitAddress VARCHAR(255);

-- Updating the new column with the corresponding data
UPDATE housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',' , PropertyAddress) - 1);

-- Creating the new Property Address column, that is going to have only the City
ALTER TABLE housing_data
ADD PropertySplitCity VARCHAR(255);

-- Updating the new column with the corresponding data
UPDATE housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',' , PropertyAddress) + 1, LENGTH(PropertyAddress));

-- Checking the new 2 columns at the end of the table
SELECT *
FROM housing_data;

-- Checking the Owner Address column
SELECT OwnerAddress
FROM housing_data;

-- Looking how the Owner address looks splited
SELECT
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS Address,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)) AS City,
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS State
FROM housing_data;

-- Creating the new Property Address column, that is going to have only the Address
ALTER TABLE housing_data
ADD OwnerASplitAddress VARCHAR(255);

-- Updating the new column with the corresponding data
UPDATE housing_data
SET OwnerASplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));

-- Creating the new Property Address column, that is going to have only the City
ALTER TABLE housing_data
ADD OwnerASplitCity VARCHAR(255);

-- Updating the new column with the corresponding data
UPDATE housing_data
SET OwnerASplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1));

-- Creating the new Property Address column, that is going to have only the State
ALTER TABLE housing_data
ADD OwnerASplitState VARCHAR(255);

-- Updating the new column with the corresponding data
UPDATE housing_data
SET OwnerASplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

-- Counting the amount there is for each different data present in the column
SELECT DISTINCT (SoldAsVacant) , COUNT(SoldAsVacant)
FROM housing_data
GROUP BY SoldAsVacant
ORDER BY 2;

-- Checking the data that will be replaced
SELECT SoldAsVacant,
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM housing_data;

-- Changing the Y to Yes and the N to NO
UPDATE housing_data
SET SoldAsVacant = CASE
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Removing Duplicates
-- USING CTE ( It's like a temporary table )
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					PropertyAddress,
                    SalePrice,
                    SaleDate,
                    LegalReference
                    ORDER BY
						UniqueID) row_num
FROM housing_data)

SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- Removing duplicates, you can check if it worked by running the query above
DELETE FROM housing_data
WHERE UniqueID NOT IN (
    SELECT minUniqueID
    FROM (
        SELECT MIN(UniqueID) AS minUniqueID
        FROM housing_data
        GROUP BY
            ParcelID,
            PropertyAddress,
            SalePrice,
            SaleDate,
            LegalReference
    ) AS subquery
);


---------------------------------------------------------------------------------------------------------

-- Deleting Unused Columns

ALTER TABLE housing_data
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;


-- Cheking the final data
SELECT *
FROM housing_data;

