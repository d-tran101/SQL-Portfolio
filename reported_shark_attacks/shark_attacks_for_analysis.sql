USE shark_attack_encounters;

CREATE VIEW shark_attacks_analysis AS
SELECT
	id,
	date,
    month_name,
    year,
    type,
    country,
    area,
    location,
    activity,
    sex,
    fatal
FROM attacks_staging2

SELECT *
FROM shark_attacks_analysis