
-- removing duplicates in 'Question' column

UPDATE hr_employee_survey_responses
SET Question = '7. This last year, I have had opportunities at work to learn and grow'
WHERE Question LIKE '7. %';

UPDATE hr_employee_survey_responses
SET Question = '10. Overall I am satisfied with my job'
Where Question LIKE '10. %';


-- total responses to survey questions

SELECT 
    Question, 
    COUNT(DISTINCT Response_ID) AS total_unique_responses_per_question, 
    (SELECT COUNT(DISTINCT Response_ID) AS total_unique_responses FROM hr_employee_survey_responses) as total_unique_responses
FROM hr_employee_survey_responses
WHERE Status = 'Complete'
GROUP BY Question
ORDER BY CAST(Question AS UNSIGNED);

-- survey responses to each question by category

SELECT Question, 
	COUNT(CASE WHEN Response = 1 then 1 end) as Strongly_Disagree,
    COUNT(CASE WHEN Response = 2 then 1 end) as Disagree,
    COUNT(CASE WHEN Response = 3 then 1 end) as Agree,
    COUNT(CASE WHEN Response = 4 then 1 end) as Strongly_Agree,
	COUNT(CASE WHEN Response = 0 then 1 end) as Not_Applicable
FROM hr_employee_survey_responses
WHERE Status = 'Complete'
GROUP BY Question

-- survey question that respondents agree with the most

WITH strongly_agree_cnt as (
SELECT 
	Question, 
    COUNT(DISTINCT Response_ID) as n_responses,
    RANK() OVER(ORDER BY COUNT(DISTINCT Response_ID) DESC) as rnk
FROM hr_employee_survey_responses
WHERE Response = 4 and Status = 'Complete'
GROUP BY Question
)
SELECT Question, n_responses
from strongly_agree_cnt
where rnk = 1

-- survey question that respondents disagree with the most

WITH strongly_disagree_cnt as (
SELECT 
	Question, 
    COUNT(DISTINCT Response_ID) as n_responses,
    RANK() OVER(ORDER BY COUNT(DISTINCT Response_ID) DESC) as rnk
FROM hr_employee_survey_responses
WHERE Response = 1 and Status = 'Complete'
GROUP BY Question
)
SELECT Question, n_responses
from strongly_disagree_cnt
where rnk = 1

-- average response per question

SELECT Question, ROUND(AVG(Response),0) as avg_response
FROM hr_employee_survey_responses
GROUP BY Question


-- count of responses per department

SELECT Department, COUNT(DISTINCT Response_ID) as n_responses
FROM hr_employee_survey_responses
WHERE Status = 'Complete'
GROUP BY Department

-- most 'strongly disagreed' responses per department

SELECT Department, COUNT(DISTINCT Response_ID) as n_responses
FROM hr_employee_survey_responses
WHERE Status = 'Complete' and Response = 4
GROUP BY Department
ORDER BY n_responses DESC

-- most 'strongly agreed' responses per department

SELECT Department, COUNT(DISTINCT Response_ID) as n_responses
FROM hr_employee_survey_responses
WHERE Status = 'Complete' and Response = 1
GROUP BY Department
ORDER BY n_responses DESC



