SELECT *
 FROM PortfolioProject.dbo.NashvilleHousing

--Standardize/Change Date Format

SELECT SaleDateConverted, CONVERT(date,SaleDate)
 FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 ADD SaleDateConverted Date;

 UPDATE PortfolioProject.dbo.NashvilleHousing
  SET SaleDateConverted = CONVERT(date,SaleDate)

--Populate and Clean Property Address Data. The goal is to replace Property Address that has Null values with the appropriate values. 

SELECT *
 FROM PortfolioProject.dbo.NashvilleHousing
  ORDER BY ParcelID

--Join the Nashville Housing table with it self. I am doing this to get a side-by-side view of the Property Address with null values against the ParcelID.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
 FROM PortfolioProject.dbo.NashvilleHousing a
  JOIN PortfolioProject.dbo.NashvilleHousing b
   ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
	 WHERE a.PropertyAddress is null

--Using ISNULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
 FROM PortfolioProject.dbo.NashvilleHousing a
  JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
	 WHERE a.PropertyAddress is null

--Update Nashville Housing table A with the corrected Property Address populated to replace the null values. When doing joins in an update statement, use alias of table name instead of table names. 

UPDATE a
 SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
  FROM PortfolioProject.dbo.NashvilleHousing a
  JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
	 WHERE a.PropertyAddress is null

--Breaking out PropertyAddress into individual columns (Address, City). I will use substring and character index (CHARINDEX). CHARINDEX gives the position of a specified value, so it is usually a number. 

SELECT PropertyAddress
 FROM PortfolioProject.dbo.NashvilleHousing

 SELECT 
  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address,
   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
 FROM PortfolioProject.dbo.NashvilleHousing

 --Creating new columns to accomodate the split values. 

 ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 ADD Property_Split_Address Nvarchar(255);

 UPDATE PortfolioProject.dbo.NashvilleHousing
  SET Property_Split_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 ADD Property_Split_City Nvarchar(255);

 UPDATE PortfolioProject.dbo.NashvilleHousing
  SET Property_Split_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--Breaking out OwnerAddress into individual columns (Address, City, State). I will be using PARSENAME statement.

SELECT 
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
 FROM PortfolioProject.dbo.NashvilleHousing

--Creating new columns to accomodate the split values.

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 ADD Owner_Split_Address Nvarchar(255);

 UPDATE PortfolioProject.dbo.NashvilleHousing
  SET Owner_Split_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 ADD Owner_Split_City Nvarchar(255);

 UPDATE PortfolioProject.dbo.NashvilleHousing
  SET Owner_Split_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 ADD Owner_Split_State Nvarchar(255);

 UPDATE PortfolioProject.dbo.NashvilleHousing
  SET Owner_Split_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--Change Y and N to Yes and No in "Sold as Vacant" field. I will use CASE statement.

SELECT Distinct(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
 FROM PortfolioProject.dbo.NashvilleHousing
  GROUP BY SoldAsVacant
   ORDER BY 2

SELECT SoldAsVacant,
 CASE When SoldAsVacant = 'Y' Then 'Yes'
      When SoldAsVacant = 'N' Then 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing
  SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
      When SoldAsVacant = 'N' Then 'No'
	 ELSE SoldAsVacant
	 END

--Remove duplicates using CTE. Deleted the duplicate rows and changed the delete statement back to a select statement. 

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
FROM PortfolioProject.dbo.NashvilleHousing
 --ORDER BY ParcelID
 )
SELECT *
 FROM RowNumCTE
  WHERE row_num > 1
   ORDER BY PropertyAddress

--Delete unused columns. Remember to never delete columns from your raw data. 

SELECT *
 FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 DROP COLUMN OwnerAddress, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
 DROP COLUMN SaleDate, TaxDistrict