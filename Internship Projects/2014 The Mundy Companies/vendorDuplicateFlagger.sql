/*
VENDOR LIST DUPLICATE FLAGGER
Hunter Gatewood and Matthew Wanner

USAGE INSTRUCTIONS:
*the clearest way to utilize the program is to:
        (1) save the database table to an Excel spreadsheet and ensure the column headers are named exactly:
                'Vendor ID'
                'Vendor Name'
                'Address 1'
                'Address 2'
                'City'
                'State'
                'Zip Code'
                'Phone Number 1'
        (2) upload the sheet to Microsoft SQL, change the name of the encasing database to VendorList, and
                change the name of the table to VendList (you may have to restart Microsoft SQL to do this)
        (3) run the program, adding any additional queries
*though the program does clean up the data, the number of duplicates flagged can be greatly
        increased by first running a variety of sort functions on the data in an Excel spreadsheet
        and correcting obvious data entry errors
*duplicates are flagged by five criteria: name/city/zip (ncz), name/address2/city/state (na2cs),
        name/phone/zip (npz), name/phone/zip and phone/zip both not null (NZP), name/address1/zip (NA1Z)
*if the program won't run, comment everything out, run 'SELECT * FROM sys.tables',
        and delete all tables except sysdiagrams and VendList by running
        'DROP TABLE [table_name1],[table_name2]...'

BASIC STRUCTRUE:
*keep data table VendList untouched except to copy data over to WVList
*create WVList, then clean up data errors field by field
*create several 'DupLists' with criteria for duplicates
*left join WVList and the DupLists to create FinalList, then editing it slightly to produce
        a modified version of WVList which both contains less errors than the origial
        VendList and has duplicates flagged as either 'CERTAIN','LIKELY', or 'POTENTIAL', as well as
        the criteria by which they were marked as such (ncz = name/city/zip all same, na2cs =
        name/address2/city/state all same, etc.)
*/

USE VendorList

--DATA TRANSFER AND CLEAN UP
--copy data over to working table
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'WVList')
    BEGIN DROP TABLE WVList
    END
CREATE TABLE WVList
        (VendorID float,
        VendorName nvarchar(255),
        Address1 nvarchar(255),
        Address2 nvarchar(255),
        City nvarchar(255),
        [State] nvarchar (255),
        CZip float,
        Zip nvarchar (255),
        PhoneNumber nvarchar(255),
        Duplicate nvarchar(255),
        Criteria nvarchar(255))
INSERT INTO WVList
        (VendorID,VendorName,Address1,
        Address2,City,[State],CZip,PhoneNumber)
    SELECT [Vendor ID],[Vendor Name],[Address 1],
            [Address 2],[City],[State],[Zip Code],[Phone Number 1]
    FROM VendList

--clean up vendor name
UPDATE WVList SET VendorName = LTRIM(RTRIM(VendorName))
UPDATE WVList SET VendorName = SUBSTRING(VendorName,1,LEN(VendorName)-1) WHERE VendorName LIKE '%,'
UPDATE WVList SET VendorName = 'AT&T' WHERE VendorName IN ('AT & T','AT &T','AT& T','A T & T')
UPDATE WVList
    SET VendorName = SUBSTRING(VendorName,1,1) + ' ' + SUBSTRING(VendorName,3,1) + ' ' + SUBSTRING(VendorName,5,LEN(VendorName))
    WHERE VendorName LIKE '_._.%'
UPDATE WVList
    SET VendorName = SUBSTRING(VendorName,1,1) + ' ' + SUBSTRING(VendorName,4,1) + ' ' + SUBSTRING(VendorName,6,LEN(VendorName))
    WHERE VendorName LIKE '_. _. %'
UPDATE WVList
    SET VendorName = SUBSTRING(VendorName,1,1) + ' ' + SUBSTRING(VendorName,3,LEN(VendorName)) WHERE VendorName LIKE '_. %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' CTR',' CENTER') WHERE VendorName LIKE '% CTR'
UPDATE WVList SET VendorName = REPLACE(VendorName,' CNTR',' CENTER') WHERE VendorName LIKE '% CNTR'
UPDATE WVList SET VendorName = REPLACE(VendorName,' PMT ',' PAYMENT ') WHERE VendorName LIKE '% PMT %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' PMT ',' PAYMENT ') WHERE VendorName LIKE '% PMT %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' PAYMT ',' PAYMENT ') WHERE VendorName LIKE '% PAYMT %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' PMTY ',' PAYMENT ') WHERE VendorName LIKE '% PMTY %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' PYMT ',' PAYMENT ') WHERE VendorName LIKE '% PYMT %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' SUPPORT PAY ',' SUPPORT PAYMENT ') WHERE VendorName LIKE '% SUPPORT PAY CENTER'
UPDATE WVList SET VendorName = VendorName + ' ' + 'CENTER' WHERE VendorName LIKE '% CHILD SUPPORT PAYMENT'
UPDATE WVList SET VendorName = REPLACE(VendorName,' SUPP ',' SUPPORT ') WHERE VendorName LIKE '% SUPP %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' SUPP. ',' SUPPORT ') WHERE VendorName LIKE '% SUPP. %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' SUP. ',' SUPPORT ') WHERE VendorName LIKE '% SUP. %'
UPDATE WVList SET VendorName = REPLACE(VendorName,' ENF.',' ENFORCEMENT') WHERE VendorName LIKE '% SUPPORT ENF.'
UPDATE WVList SET VendorName = REPLACE(VendorName,' ENFORC.',' ENFORCEMENT') WHERE VendorName LIKE '% SUPPORT ENFORC.'
UPDATE WVList SET VendorName = REPLACE(VendorName,' ENFORCE.',' ENFORCEMENT') WHERE VendorName LIKE '% SUPPORT ENFORCE.'
UPDATE WVList SET VendorName = REPLACE(VendorName,' ENFORCE',' ENFORCEMENT') WHERE VendorName LIKE '% SUPPORT ENFORCE'


--clean up address 2 (and address 1)
UPDATE WVList
    SET Address2 = Address1,
            Address1 = NULL
    WHERE LEFT(Address1,5) = 'P. O.' OR
            LEFT(Address1,4) = 'P.O.' OR
            LEFT(Address1,3) = 'P O' OR
            LEFT(Address1,2) IN ('PO','P0')
UPDATE WVList SET Address2 = REPLACE(Address2,'PO','P. O.')
UPDATE WVList SET Address2 = REPLACE(Address2,'P.O.','P. O.')
UPDATE WVList SET Address2 = REPLACE(Address2,'P O','P. O.')
UPDATE WVList SET Address2 = REPLACE(Address2,'P.O','P. O.')
UPDATE WVList SET Address2 = REPLACE(Address2,'P. O.B','P. O. B')
UPDATE WVList SET Address2 = REPLACE(Address2,'P. O.S','P. O. S')
UPDATE WVList SET Address2 = REPLACE(Address2,'P. O..B','P. O. B')
UPDATE WVList SET Address2 = REPLACE(Address2,'STE ','SUITE ')
UPDATE WVList SET Address2 = REPLACE(Address2,'STE. ','SUITE ')
UPDATE WVList SET Address2 = REPLACE(Address2,'STE ','SUITE ')

--clean up address 1
UPDATE WVList SET Address1 = REPLACE(Address1,'  ',' ')
UPDATE WVList SET Address1 = REPLACE(Address1,'   ',' ')
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-1) WHERE Address1 LIKE '%,'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-1) WHERE Address1 LIKE '%.'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-3) + ' STREET' WHERE Address1 LIKE '% ST'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-5) + ' BOULEVARD' WHERE Address1 LIKE '% BLVD'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-3) + ' DRIVE' WHERE Address1 LIKE '% DR'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-3) + ' LANE' WHERE Address1 LIKE '% LN'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-4) + ' AVENUE' WHERE Address1 LIKE '% AVE'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-3) + ' ROAD' WHERE Address1 LIKE '% RD'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-3) + ' COURT' WHERE Address1 LIKE '% CT'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-5) + ' FREEWAY' WHERE Address1 LIKE '% FRWY'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-5) + ' PARKWAY' WHERE Address1 LIKE '% PKWY'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-4) + ' HIGHWAY' WHERE Address1 LIKE '% HWY'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-4) + ' TRAIL' WHERE Address1 LIKE '% TRL'

UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-7) + ' PARKWAY' WHERE Address1 LIKE '% PARKWA'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-4) + ' DRIVE' WHERE Address1 LIKE '% DRI'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-5) + ' DRIVE' WHERE Address1 LIKE '% DRIV'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-4) + ' ROAD' WHERE Address1 LIKE '% ROA'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-3) + ' ROAD' WHERE Address1 LIKE '% RO'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-6) + ' STREET' WHERE Address1 LIKE '% STREE'

UPDATE WVList SET Address1 = REPLACE (Address1,' NORTH ',' N ') WHERE Address1 LIKE '% NORTH %'
UPDATE WVList SET Address1 = REPLACE (Address1,' SOUTH ',' S ') WHERE Address1 LIKE '% SOUTH %'
UPDATE WVList SET Address1 = REPLACE (Address1,' EAST ',' E ') WHERE Address1 LIKE '% EAST %'
UPDATE WVList SET Address1 = REPLACE (Address1,' WEST ',' W ') WHERE Address1 LIKE '% WEST %'
UPDATE WVList SET Address1 = REPLACE (Address1,' N. ',' N ') WHERE Address1 LIKE '%[0-9] N. %'
UPDATE WVList SET Address1 = REPLACE (Address1,' S. ',' S ') WHERE Address1 LIKE '%[0-9] S. %'
UPDATE WVList SET Address1 = REPLACE (Address1,' E. ',' E ') WHERE Address1 LIKE '%[0-9] E. %'
UPDATE WVList SET Address1 = REPLACE (Address1,' W. ',' W ') WHERE Address1 LIKE '%[0-9] W. %'
UPDATE WVList SET Address1 = REPLACE (Address1,' HWY ',' HIGHWAY ') WHERE Address1 LIKE '% HWY [0-9]%'
UPDATE WVList SET Address1 = REPLACE (Address1,' CO. RD. ',' COUNTRY ROAD ') WHERE Address1 LIKE '% CO. RD. %'
UPDATE WVList SET Address1 = REPLACE (Address1,' CR ',' COUNTRY ROAD ') WHERE Address1 LIKE '% CR [0-9]%' OR Address1 LIKE '% CR #%'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,LEN(Address1)-6) + ' AVENUE ' + RIGHT(Address1,1) WHERE Address1 LIKE '% AVE _'
UPDATE WVList SET Address1 = SUBSTRING(Address1,1,1) + ' ' + SUBSTRING(Address1,3,LEN(Address1)) WHERE Address1 LIKE '_. %'

--clean up city
UPDATE WVList SET City = 'HOUSTON' WHERE City IN ('HOUTON','HOUSOTN')

--clean up state
UPDATE WVList SET [State] = 'TX' WHERE [State] IN ('TEXAS','TZ')
UPDATE WVList SET [State] = 'AL' WHERE [State] = 'ALABAMA'
UPDATE WVList SET [State] = 'FL' WHERE [State] IN ('FA','Fl','Florida','FLORIDA')
UPDATE WVList SET [State] = 'GA' WHERE [State] = 'GS'
UPDATE WVList SET [State] = 'KS' WHERE [State] = 'KANSAS'
UPDATE WVList SET [State] = 'MD' WHERE [State] = 'MC'
UPDATE WVList SET [State] = 'NY' WHERE [State] = 'N.Y.'
UPDATE WVList SET [State] = 'OH' WHERE [State] = 'OHIO'
UPDATE WVList SET [State] = 'SC' WHERE [State] = 'S'

--clean up zip codes (and change data type)
UPDATE WVList SET CZip = REPLACE(CZip,' ','')
UPDATE WVList SET CZip = REPLACE(CZip,'-','')
UPDATE WVList SET Zip = LEFT(CAST(CAST(CZip AS decimal(18,0)) AS nvarchar(18)),5)
ALTER TABLE WVList DROP COLUMN CZip
UPDATE WVList SET Zip = NULL WHERE Zip = '0'
UPDATE WVList SET Zip = LEFT(Zip,5)
UPDATE WVList SET Zip = NULL WHERE LEN(Zip) != 5
UPDATE WVList SET Zip = '00000' WHERE Zip IS NULL  --for equality purposes, returned to NULL during cleanup

--clean up phone numbers
UPDATE WVList SET PhoneNumber = LEFT(PhoneNumber,14)
UPDATE WVList
    SET PhoneNumber = '(000) 000-0000'
    WHERE LEN(PhoneNumber) != 14 OR
            LEFT(PhoneNumber,2) IN ('(0','(1') OR
            PhoneNumber IS NULL  --for equality purposes, returned to NULL during cleanup


--DUPLICATE FLAGGING
--potential name/city/zip duplicates (ncz)
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'nczDupList')
    BEGIN DROP TABLE nczDupList
    END
CREATE TABLE nczDupList
        (VN_1 nvarchar(255),
        C_1 nvarchar(255),
        Z_1 nvarchar(255))
INSERT INTO nczDupList(VN_1,C_1,Z_1)
    SELECT VendorName,City,Zip
    FROM WVList
    WHERE 1=1
    GROUP BY VendorName,City,Zip
    HAVING COUNT(*) > 1

--likely name/add2/city/state duplicates (na2cs)
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'na2csDupList')
    BEGIN DROP TABLE na2csDupList
    END
CREATE TABLE na2csDupList
        (VN_2 nvarchar(255),
        A2_2 nvarchar(255),
        C_2 nvarchar(255),
        S_2 nvarchar(255))
INSERT INTO na2csDupList(VN_2,A2_2,C_2,S_2)
    SELECT VendorName,Address2,City,[State]
    FROM WVList
    WHERE 1=1
    GROUP BY VendorName,Address2,City,[State]
    HAVING COUNT(*) > 1

--likely name/zip/phone duplicates (npz)
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'npzDupList')
    BEGIN DROP TABLE npzDupList
    END
CREATE TABLE npzDupList
        (VN_3 nvarchar(255),
        PN_3 nvarchar(255),
        Z_3 nvarchar(255))
INSERT INTO npzDupList(VN_3,PN_3,Z_3)
    SELECT VendorName,PhoneNumber,Zip
    FROM WVList
    WHERE 1=1
    GROUP BY VendorName,PhoneNumber,Zip
    HAVING COUNT(*) > 1

--certain name/zip/phone duplicates (NZP) (where zip and phone are also not blank)
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'NZPDupList')
    BEGIN DROP TABLE NZPDupList
    END
CREATE TABLE NZPDupList
        (VN_4 nvarchar(255),
        Z_4 nvarchar(255),
        PN_4 nvarchar(255))
INSERT INTO NZPDupList(VN_4,Z_4,PN_4)
    SELECT VendorName,Zip,PhoneNumber
    FROM WVList
    WHERE Zip != '00000' AND PhoneNumber != '(000) 000-0000'
    GROUP BY VendorName,Zip,PhoneNumber
    HAVING COUNT(*) > 1

--certain name/add1 duplicates (NA1Z)
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'NA1ZDupList')
    BEGIN DROP TABLE NA1ZDupList
    END
CREATE TABLE NA1ZDupList
        (VN_5 nvarchar(255),
        A1_5 nvarchar(255),
        Z_5 nvarchar(255))
INSERT INTO NA1ZDupList (VN_5,A1_5,Z_5)
    SELECT VendorName,Address1,Zip
    FROM WVList
    WHERE 1=1
    GROUP BY VendorName,Address1,Zip
    HAVING COUNT(*) > 1


--final joins and updates
IF EXISTS(SELECT * FROM sys.tables WHERE name = 'FinalList')
    BEGIN DROP TABLE FinalList
    END

SELECT * INTO FinalList
    FROM WVList
    LEFT JOIN nczDupList
        ON WVList.VendorName = nczDupList.VN_1 AND
                WVList.City = nczDupList.C_1 AND
                WVList.Zip = nczDupList.Z_1
    LEFT JOIN na2csDupList
        ON WVList.VendorName = na2csDupList.VN_2 AND
                WVList.Address2 = na2csDupList.A2_2 AND
                WVList.City = na2csDupList.C_2 AND
                WVList.[State] = na2csDupList.S_2
    LEFT JOIN npzDupList
        ON WVList.VendorName = npzDupList.VN_3 AND
                WVList.PhoneNumber = npzDupList.PN_3 AND
                WVList.Zip = npzDupList.Z_3
    LEFT JOIN NZPDupList
        ON WVList.VendorName = NZPDupList.VN_4 AND
                WVList.Zip = NZPDupList.Z_4 AND
                WVList.PhoneNumber = NZPDupList.PN_4
    LEFT JOIN NA1ZDupList
        ON WVList.VendorName = NA1ZDupList.VN_5 AND
                WVList.Address1 = NA1ZDupList.A1_5 AND
                WVList.Zip = NA1ZDupList.Z_5

UPDATE FinalList SET Duplicate = 'POTENTIAL' WHERE VN_1 IS NOT NULL
UPDATE FinalList SET Duplicate = 'LIKELY' WHERE VN_2 IS NOT NULL
UPDATE FinalList SET Duplicate = 'LIKELY' WHERE VN_3 IS NOT NULL
UPDATE FinalList SET Duplicate = 'CERTAIN' WHERE VN_4 IS NOT NULL
UPDATE FinalList SET Duplicate = 'CERTAIN' WHERE VN_5 IS NOT NULL

UPDATE FinalList SET Criteria = Criteria + '/ncz' WHERE VN_1 IS NOT NULL AND Criteria IS NOT NULL
UPDATE FinalList SET Criteria = 'ncz' WHERE VN_1 IS NOT NULL AND Criteria IS NULL
UPDATE FinalList SET Criteria = Criteria + '/na2cs' WHERE VN_2 IS NOT NULL AND Criteria IS NOT NULL
UPDATE FinalList SET Criteria = 'na2cs' WHERE VN_2 IS NOT NULL AND Criteria IS NULL
UPDATE FinalList SET Criteria = Criteria + '/npz' WHERE VN_3 IS NOT NULL AND Criteria IS NOT NULL
UPDATE FinalList SET Criteria = 'npz' WHERE VN_3 IS NOT NULL AND Criteria IS NULL
UPDATE FinalList SET Criteria = Criteria + '/NZP' WHERE VN_4 IS NOT NULL AND Criteria IS NOT NULL
UPDATE FinalList SET Criteria = 'NZP' WHERE VN_4 IS NOT NULL AND Criteria IS NULL
UPDATE FinalList SET Criteria = Criteria + '/NA1Z' WHERE VN_5 IS NOT NULL AND Criteria IS NOT NULL
UPDATE FinalList SET Criteria = 'NA1Z' WHERE VN_5 IS NOT NULL AND Criteria IS NULL

UPDATE FinalList SET Zip = NULL WHERE Zip = '00000'
UPDATE FinalList SET PhoneNumber = NULL WHERE PhoneNumber = '(000) 000-0000'

ALTER TABLE FinalList DROP COLUMN VN_1,C_1,Z_1,VN_2,A2_2,C_2,S_2,VN_3,PN_3,Z_3,VN_4,Z_4,PN_4,VN_5,A1_5,Z_5


SELECT * FROM FinalList WHERE Duplicate IS NOT NULL ORDER BY Duplicate,VendorName,Zip DESC,Address1,Address2


--ADD ANY ADDITIONAL QUERIES HERE


DROP TABLE nczDupList,na2csDupList,npzDupList,NZPDupList,NA1ZDupList
DROP TABLE FinalList
DROP TABLE WVList