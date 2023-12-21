/* SQL Project: Data Cleaning In SQL.
Data Source: Unknow.
Dataset Name: Nashville Housing Data.
Project Description: Writing queries to clean, standardize, and correct errors in data. 
RDBMS: SQL SERVER. */

Select *
From NashvilleHousing

--> 1. Cleaning the date column, changing it from a Datetime format to a Date format.

Select SaleDate, Cast(SaleDate as Date)
From ProjectDatabase..NashvilleHousing

Alter Table NashvilleHousing 
Add SaleDate2 Date

Update NashvilleHousing
Set SaleDate2 = Cast(SaleDate as Date)

--> 2. Fixing the null values in the property Address column.

Select Nash.ParcelID, Nash.PropertyAddress, Vill.ParcelID, Vill.PropertyAddress,
ISNULL(Nash.PropertyAddress, Vill.PropertyAddress)
From NashvilleHousing Nash
Join NashvilleHousing Vill
	On Nash.ParcelID = Vill.ParcelID
	And Nash.UniqueID != Vill.UniqueID
Where Nash.PropertyAddress is null

Update Nash
Set PropertyAddress = ISNULL(Nash.PropertyAddress, Vill.PropertyAddress)
From NashvilleHousing Nash
Join NashvilleHousing Vill
	On Nash.ParcelID = Vill.ParcelID
	And Nash.UniqueID != Vill.UniqueID
Where Nash.PropertyAddress is null
	And Nash.UniqueID != Vill.UniqueID

Select *
From NashvilleHousing
Where PropertyAddress Is Null -- Zero(0) result.

--> 3. Splitting the address columns.

--> (i). splitting the property address column

Select PropertyAddress, Substring(PropertyAddress, 1, Charindex(',', PropertyAddress)-1) as Address,
Substring(PropertyAddress, Charindex(',', PropertyAddress)+1, Len(PropertyAddress)) as City
From NashvilleHousing

--> Adding the columns to table

Alter Table NashvilleHousing 
Add PropertyAddress2 Nvarchar(100)

Update NashvilleHousing
Set PropertyAddress2 = Substring(PropertyAddress, 1, Charindex(',', PropertyAddress)-1)

Alter Table NashvilleHousing 
Add PropertyCity Varchar(50)

Update NashvilleHousing
Set PropertyCity = Substring(PropertyAddress, Charindex(',', PropertyAddress)+1, Len(PropertyAddress))

Select *
From NashvilleHousing -- COLUMNS ADDED!

--> (ii). splitting the owners address column

Select OwnerAddress, Parsename(Replace(OwnerAddress, ',', '.'), 3) as OwnersAddress,
Parsename(Replace(OwnerAddress, ',', '.'), 2) as OwnersCity,
Parsename(Replace(OwnerAddress, ',', '.'), 1) as OwnersState
From NashvilleHousing

--> Adding the columns to table

Alter Table NashvilleHousing 
Add OwnersAddress2 Nvarchar(100)

Update NashvilleHousing
Set OwnersAddress2 = Parsename(Replace(OwnerAddress, ',', '.'), 3)

Alter Table NashvilleHousing 
Add OwnersCity Varchar(50)

Update NashvilleHousing
Set OwnersCity = Parsename(Replace(OwnerAddress, ',', '.'), 2)

Alter Table NashvilleHousing 
Add OwnersState Char(10)

Update NashvilleHousing
Set OwnersState = Parsename(Replace(OwnerAddress, ',', '.'), 1)

Select *
From NashvilleHousing -- COLUMNS ADDED!

--> 4. Correcting the typo in the Sold As Vacant Column.

Select Replace(SoldAsVacant, 'Y', 'Yes')
From NashvilleHousing 
Where SoldAsVacant = 'Y' -- FIXED, NO OUTPUT!

Select Replace(SoldAsVacant, 'N', 'No')
From NashvilleHousing 
Where SoldAsVacant = 'N' -- FIXED, NO OUTPUT!

Update NashvilleHousing
Set SoldAsVacant = Replace(SoldAsVacant, 'Y', 'Yes')
Where SoldAsVacant = 'Y'

Update NashvilleHousing
Set SoldAsVacant = Replace(SoldAsVacant, 'N', 'No')
Where SoldAsVacant = 'N'

--> 5. Removing duplicates.


Select *
From (
	Select *, Row_Number() Over(Partition by ParcelID, PropertyAddress,
	SaleDate, SalePrice, LegalReference Order by UniqueID) as Row_Num
	From NashvilleHousing 
	 ) y
Where y.Row_Num != 1

--> (i). Inserting the duplicates into a temp table.

DROP TABLE IF EXISTS #Nashville_Duplicates
Create Table #Nashville_Duplicates 
(
UniqueID int Not Null, ParcelID Nvarchar(50), LandUse Nvarchar(50), PropertyAddress Nvarchar(50),
SaleDate Datetime, SalePrice Money, LegalReference Nvarchar(50), SoldAsVacant Char(10), OwnerName Nvarchar(100), 
OwnersAddress Nvarchar(50), Acreage Numeric, TaxDistrict Nvarchar(50), LandValue int, BuildingValue int, TotalValue int, YearBuilt int,
BedRooms int, FullBath int, HalfBath int, SaleDate2 Date, PropertyAddress2 Nvarchar(50), PropertyCity Varchar(50),
OwnersAddress2 Nvarchar(50), OwnersCity Varchar(50), OwnersState Char(10), Row_Num int
)
Insert Into #Nashville_Duplicates
Select *
From (
Select *, Row_Number() Over(Partition by ParcelID, PropertyAddress,
SaleDate, SalePrice, LegalReference Order by UniqueID) as Row_Num
From NashvilleHousing 
	) y
Where y.Row_Num != 1 

Select *
From #Nashville_Duplicates -- INSERTED!

--> (ii). Deleting the duplicates from the original table

With t1 As
    (
	Select *, Row_Number() Over(Partition by ParcelID, PropertyAddress,
	SaleDate, SalePrice, LegalReference Order by UniqueID) as Row_Num
	From NashvilleHousing 
	)
DELETE
From t1
Where Row_Num != 1 --  NO OUTPUT, DELETED!

--> 6. Dropping unuseful columns.

--> (i). First creating a temp table for the unseful columns before deleting them.

CREATE TABLE #Nashville_Drop_Columns 
(
PropertyAddress Nvarchar(50), 
SaleDate Datetime,
OwnersAddress Nvarchar(50),
TaxDistrict Nvarchar(50)
)
INSERT INTO #Nashville_Drop_Columns
Select PropertyAddress, SaleDate, OwnerAddress, TaxDistrict
From NashvilleHousing 

Select *
From #Nashville_Drop_Columns -- COLUMNS INSERTED!

--> (ii). Deleting the columns.

ALTER TABLE NashvilleHousing
Drop Column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict
