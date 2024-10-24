
-- 1. attrition rate by categorical variables

-- what is the attrition rate of the dataset?

SELECT 
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    COUNT(CASE WHEN Attrition = 0 then 1 end) as total_non_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees

-- attrition rates by department

SELECT 
	department,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY department

-- top 2 job roles with the highest attrition rate

WITH job_roles_attrition as (
SELECT 
	jobrole,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate,
    DENSE_RANK() OVER(ORDER BY ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) DESC) as attrition_ranking
FROM employees
GROUP BY jobrole
)

SELECT jobrole, attrition_rate
FROM job_roles_attrition
WHERE attrition_ranking <=2

-- attrition rates by gender

SELECT 
	gender,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 THEN 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 THEN 1 end) / COUNT(*)) * 100,2) as attrition_rate,
    ROUND((COUNT(CASE WHEN gender = 'Female' AND Attrition = 1 THEN 1 END) / 
		SUM(COUNT(CASE WHEN Attrition = 1 THEN 1 END)) OVER()) * 100,2) AS female_attrition_rate,
    ROUND((COUNT(CASE WHEN gender = 'Male' AND Attrition = 1 THEN 1 END) / 
		SUM(COUNT(CASE WHEN Attrition = 1 THEN 1 END)) OVER()) * 100,2) AS male_attrition_rate
FROM employees
GROUP BY gender

-- attrition rate by age group

SELECT
	CASE 
		WHEN age > 65 THEN 'Over 65'
        WHEN age between 55 and 64 then '55 - 64'
        WHEN age between 45 and 54 then '44 - 54'
        WHEN age between 35 and 44 then '35 - 44'
        WHEN age between 25 and 34 then '25 - 34'
        WHEN age between 18 and 24 then '18 - 24'
        WHEN age < 18 then 'Under 18'
	END as age_ranges,
	COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY
	CASE 
		WHEN age > 65 THEN 'Over 65'
        WHEN age between 55 and 64 then '55 - 64'
        WHEN age between 45 and 54 then '44 - 54'
        WHEN age between 35 and 44 then '35 - 44'
        WHEN age between 25 and 34 then '25 - 34'
        WHEN age between 18 and 24 then '18 - 24'
        WHEN age < 18 then 'Under 18'
	END
ORDER BY 
	CASE 
		WHEN age > 65 THEN 'Over 65'
        WHEN age between 55 and 64 then '55 - 64'
        WHEN age between 45 and 54 then '44 - 54'
        WHEN age between 35 and 44 then '35 - 44'
        WHEN age between 25 and 34 then '25 - 34'
        WHEN age between 18 and 24 then '18 - 24'
        WHEN age < 18 then 'Under 18'
	END DESC

-- attrition rate by commuting distance

SELECT 
	CASE
		WHEN DistanceFromHome > 20 then 'Long Commute'
        WHEN DistanceFromHome BETWEEN 10 and 20 then 'Medium Commute'
        WHEN DistanceFromHome < 10 then 'Short Commute'
	END as CommuteDistance,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN DistanceFromHome > 20 then 'Long Commute'
        WHEN DistanceFromHome BETWEEN 10 and 20 then 'Medium Commute'
        WHEN DistanceFromHome < 10 then 'Short Commute'
	END

-- attrition rate by business travel frequency

SELECT 
	BusinessTravel,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY BusinessTravel

-- attrition rate by hourly rate

SELECT 
	CASE 
        WHEN hourlyrate > 80 THEN 'Exceptional (> $80)'
        WHEN hourlyrate BETWEEN 71 AND 80 THEN 'Very High ($71 - $80)'
        WHEN hourlyrate BETWEEN 61 AND 70 THEN 'High ($61 - $70)'
        WHEN hourlyrate BETWEEN 41 AND 60 THEN 'Medium ($41 - $60)'
        WHEN hourlyrate BETWEEN 21 AND 40 THEN 'Low ($21 - $40)'
        WHEN hourlyrate BETWEEN 10 AND 20 THEN 'Very Low ($10 - $20)'
        ELSE 'Out of Range'
    END AS HourlyRateRange,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
group by
	CASE 
        WHEN hourlyrate > 80 THEN 'Exceptional (> $80)'
        WHEN hourlyrate BETWEEN 71 AND 80 THEN 'Very High ($71 - $80)'
        WHEN hourlyrate BETWEEN 61 AND 70 THEN 'High ($61 - $70)'
        WHEN hourlyrate BETWEEN 41 AND 60 THEN 'Medium ($41 - $60)'
        WHEN hourlyrate BETWEEN 21 AND 40 THEN 'Low ($21 - $40)'
        WHEN hourlyrate BETWEEN 10 AND 20 THEN 'Very Low ($10 - $20)'
        ELSE 'Out of Range'
    END

-- 2. various factors that affect attrition of an employee

-- attrition rate by education rating

SELECT
	CASE
		WHEN education = 1 THEN 'Below College'
        WHEN education = 2 THEN 'Associate'
        WHEN education = 3 THEN 'Bachelor'
        WHEN education = 4 THEN 'Master'
        WHEN education = 5 THEN 'Doctor'
	END as education_levels,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY
	CASE
		WHEN education = 1 THEN 'Below College'
        WHEN education = 2 THEN 'Associate'
        WHEN education = 3 THEN 'Bachelor'
        WHEN education = 4 THEN 'Master'
        WHEN education = 5 THEN 'Doctor' 
	END

-- attrition rate by environment satisifaction rating

SELECT
	CASE
		WHEN EnvironmentSatisfaction = 1 THEN 'Low'
        WHEN EnvironmentSatisfaction = 2 THEN 'Medium'
        WHEN EnvironmentSatisfaction = 3 THEN 'High'
        WHEN EnvironmentSatisfaction = 4 THEN 'Very High'
	END as Environment_Satisfaction,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN EnvironmentSatisfaction = 1 THEN 'Low'
        WHEN EnvironmentSatisfaction = 2 THEN 'Medium'
        WHEN EnvironmentSatisfaction = 3 THEN 'High'
        WHEN EnvironmentSatisfaction = 4 THEN 'Very High'
	END
    
-- attrition rate by job involvement rating

SELECT 
	CASE
		WHEN JobInvolvement = 1 THEN 'Low'
        WHEN JobInvolvement = 2 THEN 'Medium'
        WHEN JobInvolvement = 3 THEN 'High'
        WHEN JobInvolvement = 4 THEN 'Very High'
	END as Job_Involvement,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN JobInvolvement = 1 THEN 'Low'
        WHEN JobInvolvement = 2 THEN 'Medium'
        WHEN JobInvolvement = 3 THEN 'High'
        WHEN JobInvolvement = 4 THEN 'Very High'
	END

-- attrition rate by job satisifcation rating

SELECT 
	CASE
		WHEN JobSatisfaction = 1 THEN 'Low'
        WHEN JobSatisfaction = 2 THEN 'Medium'
        WHEN JobSatisfaction = 3 THEN 'High'
        WHEN JobSatisfaction = 4 THEN 'Very High'
	END as Job_Satisfaction,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN JobSatisfaction = 1 THEN 'Low'
        WHEN JobSatisfaction = 2 THEN 'Medium'
        WHEN JobSatisfaction = 3 THEN 'High'
        WHEN JobSatisfaction = 4 THEN 'Very High'
	END


-- attrition rate by performance rating

SELECT 
	CASE
		WHEN PerformanceRating = 1 THEN 'Low'
        WHEN PerformanceRating = 2 THEN 'Medium'
        WHEN PerformanceRating = 3 THEN 'High'
        WHEN PerformanceRating = 4 THEN 'Very High'
	END as Performance_Rating,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN PerformanceRating = 1 THEN 'Low'
        WHEN PerformanceRating = 2 THEN 'Medium'
        WHEN PerformanceRating = 3 THEN 'High'
        WHEN PerformanceRating = 4 THEN 'Very High'
	END

-- attrition rate by relationship satisfaction rating

SELECT 
	CASE
		WHEN RelationshipSatisfaction = 1 THEN 'Low'
        WHEN RelationshipSatisfaction = 2 THEN 'Medium'
        WHEN RelationshipSatisfaction = 3 THEN 'High'
        WHEN RelationshipSatisfaction = 4 THEN 'Very High'
	END as Relationship_Satisfaction,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN RelationshipSatisfaction = 1 THEN 'Low'
        WHEN RelationshipSatisfaction = 2 THEN 'Medium'
        WHEN RelationshipSatisfaction = 3 THEN 'High'
        WHEN RelationshipSatisfaction = 4 THEN 'Very High'
	END

-- attrition rate by worklife balance rating

SELECT 
	CASE
		WHEN WorkLifeBalance = 1 THEN 'Bad'
        WHEN WorkLifeBalance = 2 THEN 'Good'
        WHEN WorkLifeBalance = 3 THEN 'Better'
        WHEN WorkLifeBalance = 4 THEN 'Best'
	END as WorkLife_Balance,
	COUNT(*) as total_employees,
    COUNT(CASE WHEN Attrition = 1 then 1 end) as total_attrition,
    ROUND((COUNT(CASE WHEN Attrition = 1 then 1 end) / COUNT(*)) * 100,2) as attrition_rate
FROM employees
GROUP BY 
	CASE
		WHEN WorkLifeBalance = 1 THEN 'Bad'
        WHEN WorkLifeBalance = 2 THEN 'Good'
        WHEN WorkLifeBalance = 3 THEN 'Better'
        WHEN WorkLifeBalance = 4 THEN 'Best'
	END
