/* Data Cleaning and Standardization for Housing Dataset */

/* Step 1: Retrieve All Records from the Nashville Housing Table */
SELECT *
FROM AnalystProject..NashvilleHousing;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 2: Standardize Date Format */
/* Alter the SaleDate column to remove time, keeping only the date */
ALTER TABLE AnalystProject..NashvilleHousing
ALTER COLUMN SaleDate DATE;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 3: Identify Missing Property Address Data */
/* Fetch entries with NULL PropertyAddress for review */
SELECT *
FROM AnalystProject..NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 4: Self-Join to Fill in Missing Property Address Information */
/* Retrieve non-null addresses to populate missing data */
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
       ISNULL(a.PropertyAddress, b.PropertyAddress) AS FilledAddress
FROM AnalystProject..NashvilleHousing a
JOIN AnalystProject..NashvilleHousing b ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

/* Update missing PropertyAddress with available data */
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM AnalystProject..NashvilleHousing a
JOIN AnalystProject..NashvilleHousing b ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

/* Verify updated PropertyAddress entries */
SELECT PropertyAddress
FROM AnalystProject..NashvilleHousing;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 5: Split Property Address into Individual Components (Address, City, State) */
/* Display current PropertyAddress for reference */
SELECT PropertyAddress
FROM AnalystProject..NashvilleHousing;

/* Extract Address and City from the PropertyAddress */
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM AnalystProject..NashvilleHousing;

/* Add a new column for the split Property Address */
ALTER TABLE AnalystProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

/* Update the new column with extracted Address */
UPDATE AnalystProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

/* Add a new column for the split City */
ALTER TABLE AnalystProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

/* Update the new column with extracted City */
UPDATE AnalystProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

/* Verify updates */
SELECT *
FROM AnalystProject..NashvilleHousing;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 6: Extract Owner Address Components */
/* Display OwnerAddress for reference */
SELECT OwnerAddress
FROM AnalystProject..NashvilleHousing;

/* Extract Owner Address components (Street, City, State) */
SELECT
    OwnerAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerStreet,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM AnalystProject..NashvilleHousing;

/* Add a new column for the split Owner Street */
ALTER TABLE AnalystProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

/* Update the new column with extracted Owner Street */
UPDATE AnalystProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

/* Add a new column for the split Owner City */
ALTER TABLE AnalystProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

/* Update the new column with extracted Owner City */
UPDATE AnalystProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

/* Add a new column for the split Owner State */
ALTER TABLE AnalystProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

/* Update the new column with extracted Owner State */
UPDATE AnalystProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

/* Verify updates */
SELECT *
FROM AnalystProject..NashvilleHousing;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 7: Standardize "Sold as Vacant" Field */
/* Check distinct values for SoldAsVacant */
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM AnalystProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

/* Transform codes to human-readable format */
SELECT SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS SoldAsVacantNew
FROM AnalystProject..NashvilleHousing;

/* Update SoldAsVacant with descriptive values */
UPDATE AnalystProject..NashvilleHousing
SET SoldAsVacant = CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 8: Remove Duplicate Records */
/* Identify duplicates based on key columns */
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM AnalystProject..NashvilleHousing
)
/* Delete duplicates, keeping only the first instance */
DELETE
FROM RowNumCTE
WHERE row_num > 1;

/*-----------------------------------------------------------------------------------------------------*/

/* Step 9: Clean Up Unused Columns */
/* View current structure of the table */
SELECT *
FROM AnalystProject..NashvilleHousing;

/* Drop unused columns to streamline the dataset */
ALTER TABLE AnalystProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

