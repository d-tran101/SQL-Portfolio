-- For this project, I downloaded data about reported number of shark attacks over the past 100 years and created a table to insert data into
-- I performed data cleaning techniques to focus on enhancing the quality and structure of the dataset.


CREATE DATABASE shark_attack_encounters;

USE shark_attack_encounters;

-- 1. creating table to import data

CREATE TABLE attacks (
    case_number VARCHAR(255),
    date VARCHAR(255),
    year VARCHAR(255),
    type VARCHAR(255),
    country VARCHAR(255),
    area VARCHAR(255),
    location VARCHAR(255),
    activity VARCHAR(255),
    name VARCHAR(255),
    sex VARCHAR(255),
    age VARCHAR(255),
    injury VARCHAR(255),
    fatal VARCHAR(255), -- (Y/N)
    time VARCHAR(255),
    species VARCHAR(255),
    investigator_or_source VARCHAR(255),
    pdf VARCHAR(255),
    href_formula VARCHAR(255),
    href VARCHAR(255),
    case_number_1 VARCHAR(255),
    case_number_2 VARCHAR(255),
    original_order VARCHAR(255)
);

SET GLOBAL LOCAL_INFILE= ON;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/attacks.csv' INTO TABLE attacks
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- 2. creating a staging table to manipulate and restructre the data without altering the original

CREATE TABLE attacks_staging
LIKE attacks;

INSERT attacks_staging
SELECT *
FROM attacks;


-- 3. drop irrelevant columns that are not needed for analysis

ALTER TABLE attacks_staging
DROP COLUMN pdf,
DROP COLUMN href_formula,
DROP COLUMN href,
DROP COLUMN case_number_1,
DROP COLUMN case_number_2,
DROP COLUMN original_order,
DROP COLUMN investigator_or_source,
DROP COLUMN name,
DROP COLUMN date

-- 4. checking for duplicate entries and removing them
WITH temp as (
SELECT *, ROW_NUMBER() OVER(PARTITION BY case_number, year, type, country, area, location, activity, sex, age, injury, fatal, time, species) duplicate_check
FROM attacks_staging
)
SELECT *
FROM temp
where duplicate_check > 1

CREATE TABLE `attacks_staging2` (
  `case_number` varchar(255) DEFAULT NULL,
  `year` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `area` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `activity` varchar(255) DEFAULT NULL,
  `sex` varchar(255) DEFAULT NULL,
  `age` varchar(255) DEFAULT NULL,
  `injury` varchar(255) DEFAULT NULL,
  `fatal` varchar(255) DEFAULT NULL,
  `time` varchar(255) DEFAULT NULL,
  `species` varchar(255) DEFAULT NULL,
  `duplicate_check` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO attacks_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY case_number, year, type, country, area, location, activity, sex, age, injury, fatal, time, species) duplicate_check
FROM attacks_staging

DELETE FROM attacks_staging2
WHERE duplicate_check > 1

-- 5. deleting entirely blank rows 

DELETE FROM attacks_staging2
WHERE case_number = '' AND year = '' AND type = '' AND country = '' AND area = '' and location = '' and activity = '' and sex = '' and age = '' and injury = '' and fatal = ''

-- standarding and transforming data

-- 6. standardizing and cleaning case_number column

ALTER TABLE attacks_staging2
DROP COLUMN injury

ALTER TABLE attacks_staging2
RENAME COLUMN case_number TO date

UPDATE attacks_staging2
SET date = TRIM(date);

UPDATE attacks_staging2
SET date = REPLACE(date, '.', '-')
WHERE date LIKE '____.__.__%';

UPDATE attacks_staging2
SET date = REGEXP_REPLACE(date, '[a-zA-Z]', '')
WHERE date REGEXP '[a-zA-Z]';

UPDATE attacks_staging2
SET date = TRIM(TRAILING '-' FROM date);

DELETE FROM attacks_staging2
WHERE date LIKE '0___-%'

DELETE FROM attacks_staging2
WHERE date LIKE '_._%'

DELETE FROM attacks_staging2
WHERE date like '____-00-00'

UPDATE attacks_staging2
SET date = CASE
    WHEN date LIKE '%-00' THEN REPLACE(date, '-00', '-01')
    ELSE date
END
WHERE date LIKE '%-00';

DELETE FROM attacks_staging2
WHERE date LIKE '%-00%';

UPDATE attacks_staging2
SET date = LEFT(date, 10)

UPDATE attacks_staging2
SET date = REPLACE(REPLACE(date, ',', '-'), '.', '-')

DELETE FROM attacks_staging2
WHERE date LIKE '-%' 

DELETE FROM attacks_staging2
WHERE date = '' 

DELETE FROM attacks_staging2
WHERE STR_TO_DATE(date, '%Y-%m-%d') < '1900-01-01';

ALTER TABLE attacks_staging2
MODIFY COLUMN date DATE;

-- 7. standardizing year column

UPDATE attacks_staging2
SET year = LEFT(date, 4)

-- 8. standardizing and cleaning country column

UPDATE attacks_staging2
SET country = TRIM(country)

UPDATE attacks_staging2
SET country = 'Unknown'
WHERE country = ''

UPDATE attacks_staging2
SET country = CONCAT(UPPER(SUBSTRING(country,1,1)), LOWER(SUBSTRING(country,2,225)))

UPDATE attacks_staging2
SET country = CONCAT(SUBSTRING_INDEX(country, ' ', 1), ' ', UPPER(SUBSTRING(SUBSTRING_INDEX(country, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(country, ' ', -1),2,255))
WHERE LENGTH(country) - LENGTH(REPLACE(country, ' ', '')) = 1;

UPDATE attacks_staging2
SET country = 'USA'
WHERE country LIKE 'Usa'

UPDATE attacks_staging2
SET country = CONCAT(
		SUBSTRING_INDEX(country, ' ', 1), ' ',
		UPPER(SUBSTRING(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ' ', 2), ' ', -1),1,1)), SUBSTRING(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ' ', 2), ' ', -1),2,225), ' ',
		UPPER(SUBSTRING(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ' ', -2), ' ', -1),1,1)), SUBSTRING(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ' ', -2), ' ', -1),2,255))
WHERE LENGTH(country) - LENGTH(REPLACE(country, ' ', '')) = 2;

UPDATE attacks_staging2
SET country = 'United Arab Emirates'
WHERE country LIKE 'United arab emirates%'

UPDATE attacks_staging2
SET country = REPLACE(country, '?', '')
WHERE country LIKE '%?%'

UPDATE attacks_staging2
SET country = 'St. Martin'
WHERE country LIKE 'St.%'

UPDATE attacks_staging2
SET country = 'Sri Lanka'
WHERE country LIKE '%Ceylon%'

UPDATE attacks_staging2
SET country = REPLACE(country, 'Red sea', 'Red Sea')
WHERE country LIKE '%Indian Ocean%'

UPDATE attacks_staging2
SET country = 
	REPLACE(REPLACE(REPLACE(REPLACE(country, 
									'Between portugal & india', 'Between Portugal & India'),
                                    'nicobar islandas', 'Nicobar Islands'),
                                    'Equatorial guinea', 'Equatorial Guinea'),
                                    'Federated states of micronesia', 'Federated States of Micronesia')
WHERE LENGTH(country) - LENGTH(REPLACE(country, ' ', '')) = 3;

UPDATE attacks_staging2
SET country = REPLACE(REPLACE(country, 'vanuatu', 'Vanuatu'), 'cameroon', 'Cameroon')
WHERE LENGTH(country) - LENGTH(REPLACE(country, ' ', '')) = 3;

UPDATE attacks_staging2
SET country = REPLACE(country, 'St helena, british overseas territory',  'St. Helena, British Overseas Territory')
WHERE LENGTH(country) - LENGTH(REPLACE(country, ' ', '')) = 4;

UPDATE attacks_staging2
SET country = REPLACE(country, 'indian ocean', 'Indian Ocean')
WHERE LENGTH(country) - LENGTH(REPLACE(country, ' ', '')) = 3;

DELETE FROM attacks_staging2
WHERE country LIKE '%Ocean%'

DELETE from attacks_staging2
WHERE country LIKE '%/%'

UPDATE attacks_staging2
SET country = 'Slovenia'
where country = 'The Balkans'

-- 9. standardizing and cleaning area column

UPDATE attacks_staging2
SET area = TRIM(area)

UPDATE attacks_staging2
SET area = REPLACE(area, '22ºN, 88ºE', 'India')

UPDATE attacks_staging2
SET area = REPLACE(area, '35º39 : 165º8', 'South Island of New Zealand and Australia');

UPDATE attacks_staging2
SET area = 'Unknown'
WHERE area = ''

UPDATE attacks_staging2
SET area = 'Coast of Equatorial Guinea'
WHERE area like '%N%-%W%'

UPDATE attacks_staging2
SET area = 'Panama'
WHERE area = 'PANAMA'

UPDATE attacks_staging2
SET area = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(area, '18S / 50E', 'Coast of Madagascar'), 
		'33N, 68W', 'Coast of North Carolina'), 
		'10ºS, 142ºE', 'Northern Tip of Australia'), 
		'19S, 178?E', 'South Pacific Ocean'), 
		'9.35N 79.35W', 'Panama')

DELETE FROM attacks_staging2
WHERE area like '%off%'

DELETE FROM attacks_staging2
WHERE area REGEXP '^[0-9]'

-- 10. standardizing location column

UPDATE attacks_staging2
SET location = TRIM(location)

UPDATE attacks_staging2
SET location = 'Unknown'
WHERE location = ''

UPDATE attacks_staging2
SET location = REPLACE(location, '?', '')

UPDATE attacks_staging2
SET location = 'Unknown'
WHERE location REGEXP '^[0-9]'

-- 11. standardizing activity column
UPDATE attacks_staging2
SET activity = TRIM(activity)

UPDATE attacks_staging2
SET activity = 'Standing'
WHERE activity LIKE '%Standing%'

UPDATE attacks_staging2
SET activity = 'Fishing, catching, or hunting'
WHERE activity like '%hunting%' or activity like '%catch%' or activity like '%fishing%' or activity like '%netting%' 
or activity like '%fish trap%' or activity like '%net%' or activity like '%crabbing%' or activity like '%clamming%'
or activity like '%spearing%' or activity like '%gathering%' or activity like '%collecting%' or activity like '%lobstering%'
or activity like '%crayfish%' or activity like '%gigging%' or activity like '%shelling%' or activity like '%harpoon%'
or activity like '%tagging%' or activity like '%testing anti-shark%' or activity like '%fisherman%'
or activity like '%shad%' or activity like '%chumming%' or activity like '%shrimping%' or activity like '%hooked%'
or activity like '%hunt%' or activity like '%fish%' or activity like '%pêcheur de bichiques%' or activity like '%angler%'
or activity like '%land a shark%' or activity like '%scooping%'

UPDATE attacks_staging2
SET activity = 'Recreational water sport'
WHERE activity like '%paddl%' or activity like '%surf%' or activity like '%soccer%'  
or activity like '%skiing%' or activity like '%boarding%' or activity like '%kayak%' 
or activity like '%rowing%' or activity like '%boating%' or activity like '%racing%' 
or activity like '%canoeing%' or activity like '%frisbee%' or activity like '%sailing%'
or activity like '%race%' or activity like '%sculling%' or activity like '%record%'
or activity like '%riding waves%' or activity like '%kakaying%'

UPDATE attacks_staging2
SET activity = 'Fell overboard'
where activity like '%overboard%' or activity like '%fell%' or activity like '%knocked%' or activity like '%swept off%'

UPDATE attacks_staging2
SET activity = 'Sea disaster'
where activity like '%hurricane%' or activity like '%sea disaster%' or activity like '%earthquake%' or activity like '%swept%'

UPDATE attacks_staging2
SET activity = 'Water leisure activity'
where activity like '%bathing%' or activity like '%standing%' or activity like '%floating%' 
or activity like '%treading%' or activity like '%air mattress%' or activity like '%wading%' 
or activity like '%dangling%' or activity like '%walking%' or activity like '%splashing%' 
or activity like '%Snorkeling%' or activity like '%lying%' or activity like '%shark watching%'
or activity like '%cruising%' or activity like '%playing%' or activity like '%swimming%' or activity like '%diving%' or activity like '%dived%'
or activity like '%stamding%' or activity like '%sitting%' or activity like '%jumping%' or activity like '%raft%' or activity like '%jumped%'
or activity like '%float%' or activity like '%sit%' or activity like '%kneeling%' or activity like '%crawling%' or activity like '%crouching%'

UPDATE attacks_staging2
SET activity = 'Sinking or failure of vessel'
WHERE activity like '%founder%' or activity like '%capsized%' or activity like '%shipwreck%' 
or activity like '%destroyer%' or activity like '%U-177%' or activity like '%vessel%' or activity like '%freighter%' or activity like '%brig%' or activity like '%sunk%'
or activity like '%sunk%' or activity like '%ship%' or activity like '%boat%' or activity like '%barque%' or activity like '%Esso Bolivar%' or activity like '%tug%'
or activity like '%crash%' or activity like '%sank%' or activity like '%steamer%' or activity like '%sinking%' or activity like '%tanker%' or activity like '%skiff%'
or activity like '%engine%' or activity like '%submarine%'

UPDATE attacks_staging2
SET activity = 'Air disaster'
WHERE activity like '%plane%' or activity like '%aircraft%' or activity like '%air%'

UPDATE attacks_staging2
SET activity = 'Irresponsible or dangerous behavior with sharks'
WHERE activity like '%petting%' or activity like '%touching%' or activity like '%removing%' 
or activity like '%chase%' or activity like '%accident%' or activity like '%teasing%' 
or activity like '%finning%' or activity like '%holding%' or activity like '%feeling%' 
or activity like '%put foot%' or activity like '%attack%' or activity like '%grab%' 
or activity like '%filming%' or activity like '%wrangling%' or activity like '%hand feeding%' 
or activity like '%feeding%' or activity like '%picking up%' or activity like '%dragging stranded%' 
or activity like '%thrashing%' or activity like '%pulling shark%' or activity like '%stuffing%'
or activity like '%slapped%' or activity like '%lasso%' or activity like '%shooting%' 
or activity like '%kill%' or activity like '%measuring%'

UPDATE attacks_staging2
SET activity = 'Not specified'
WHERE activity like '%No details%' or activity like '' or activity like '%Unknown%' or activity like '.' or activity like '%SUP%' or activity like '%batin%'

UPDATE attacks_staging2
SET activity = 'Shark convservation or protection efforts'
WHERE activity like '%free the shark%' or activity like '%rescue a shark%' or activity like '%rescuing%' 
or activity like '%anesthetize%' or activity like '%return injured shark%' or activity like '%beached%' 
or activity like '%injured%' or activity like '%away from the beach%' or activity like '%reviving%' 
or activity like '%aid%' or activity like '%lifesaving%'

UPDATE attacks_staging2
SET activity = 'Scientific research'
WHERE activity like '%research%' or activity like '%conduct%' or activity like '%investigating%' or activity like '%NSB Meshing%'

UPDATE attacks_staging2
SET activity = 'Extreme or dangerous challenges'
WHERE activity like '%attempting%' or activity like '%returning%' or activity like '%escaping%'

UPDATE attacks_staging2
SET activity = 'Incidents involving maintenance tasks or routine work'
WHERE activity like '%pulling anchor%' or activity like '%cleaning%' or activity like '%attaching%' 
or activity like '%washing%' or activity like '%dropping anchor%' or activity like '%towing%' or activity like '%batin%'

UPDATE attacks_staging2
SET activity = 'Accidental shark encounters while doing a activity'
WHERE activity like '%photograph%' or activity like '%photo shoot%' or activity like '%crossing%' 
or activity like '%washing%' or activity like '%dropping anchor%' or activity like '%towing%' or activity like '%hiking%'
or activity like '%parachuted%' or activity like '%resting%' or activity like '%meat%' or activity like '%leaving%'
or activity like '%dragging%' or activity like '%exercising%' or activity like '%waist%' or activity like '%adrift%'
or activity like '%watching seals%' or activity like '%riding%' or activity like '%washed%' or activity like '%plunged%'
or activity like '%life jackets%' or activity like '%from the shore%'

UPDATE attacks_staging2
SET activity = 'Disappearances, investigations into crime, or suicide'
WHERE activity like '%murder%' or activity like '%suicide%' or activity like '%suicide%' 
or activity like '%remains%' or activity like '%Beaumont%' or activity like '%disappear%' or activity like '%body%'

UPDATE attacks_staging2
SET activity = 'Water leisure activity'
WHERE activity like 'Accidental shark encounters while doing a activity'

UPDATE attacks_staging2
SET activity = 'Accidents involving falling overboard from a vessel'
WHERE activity like 'Fell overboard'

-- 12. standardizing sex column

UPDATE attacks_staging2
SET sex = TRIM(sex)

UPDATE attacks_staging2
SET sex = 'Not specified'
WHERE sex = '.' or sex = '' or sex = 'lli' or sex = 'N'

-- 13. standardizing fatal column

UPDATE attacks_staging2
SET fatal = TRIM(fatal)

UPDATE attacks_staging2
SET fatal = 'Not specified'
WHERE fatal = '' or fatal = 'F' or fatal = 'UNKNOWN' or fatal = '2017'

-- 14. decided to drop age column, time column and species column

ALTER TABLE attacks_staging2
DROP COLUMN time,
DROP COLUMN species
DROP COLUMN age;

-- 15. adding month column

ALTER TABLE attacks_staging2
ADD COLUMN month_name VARCHAR(225)

UPDATE attacks_staging2
SET month_name = CASE WHEN date LIKE '____-01-__' THEN 'January'
     WHEN date LIKE '____-02-__' THEN 'February'
     WHEN date LIKE '____-03-__' THEN 'March'
     WHEN date LIKE '____-04-__' THEN 'April'
     WHEN date LIKE '____-05-__' THEN 'May'
     WHEN date LIKE '____-06-__' THEN 'June'
     WHEN date LIKE '____-07-__' THEN 'July'
     WHEN date LIKE '____-08-__' THEN 'August'
     WHEN date LIKE '____-09-__' THEN 'September'
     WHEN date LIKE '____-10-__' THEN 'October'
     WHEN date LIKE '____-11-__' THEN 'November'
     WHEN date LIKE '____-12-__' THEN 'December'
    END

ALTER TABLE attacks_staging2
MODIFY COLUMN month_name VARCHAR(225) AFTER date

-- 16. dropping duplicate_check from beginning

ALTER TABLE attacks_staging2
DROP COLUMN duplicate_check


-- 17. changing data type 

ALTER TABLE attacks_staging2
MODIFY COLUMN month_name VARCHAR(25),
MODIFY COLUMN year INT,
MODIFY COLUMN type VARCHAR(25),
MODIFY COLUMN country VARCHAR(50),
MODIFY COLUMN area VARCHAR(225),
MODIFY COLUMN location VARCHAR(225),
MODIFY COLUMN activity VARCHAR(100),
MODIFY COLUMN sex VARCHAR(25),
MODIFY COLUMN fatal VARCHAR(25)

-- 18. adding primary key to attacks_staging2 for uniqueness

ALTER TABLE attacks_staging2
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE attacks_staging2
MODIFY COLUMN id INT AUTO_INCREMENT FIRST
