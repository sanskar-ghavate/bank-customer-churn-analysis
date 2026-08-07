create database churn_analysis;

-- Rename table using alter
ALTER TABLE `bank customer churn prediction`
RENAME TO bank_customer_churn;

SELECT * FROM bank_customer_churn

/*============================================================
01. Customer retention prioritization
============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Identify customers who require immediate retention efforts by 
assigning a retention priority score based on their financial, behavioral characteristics
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Create a retention priority score and classify customer
--------------------------------------------------------------------------------------*/

WITH customer_score as (SELECT *,
    (CASE WHEN balance >100000 then 30 ELSE 0 END + 
    CASE WHEN products_number = 1 then 25 ELSE 0 END +
    CASE WHEN active_member = 0 then 20 ELSE 0 END +
    CASE WHEN credit_score < 600 then 15 ELSE 0 END +
    CASE WHEN age > 50 then 10 ELSE 0 END) as retention_priority_score
FROM bank_customer_churn) 
SELECT *, 
CASE 	WHEN retention_priority_score >= 70 then "High_priority"
		WHEN retention_priority_score >= 40 then "Medium"
        ELSE "Low"
        END as priority
FROM customer_score
ORDER BY retention_priority_score DESC;

/*------------------------------------------------------------------------------------
Business Insight

The retention priority score identifying the customers who require the immediate
attention. Bank can prioritize retention efforts and allocate sources more effectively
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Reusable view for further analysis
--------------------------------------------------------------------------------------*/

CREATE VIEW customer_retention as 
WITH customer_score as ( SELECT *,
    (CASE WHEN balance >100000 then 30 ELSE 0 END + 
    CASE WHEN products_number = 1 then 25 ELSE 0 END +
    CASE WHEN active_member = 0 then 20 ELSE 0 END +
    CASE WHEN credit_score < 600 then 15 ELSE 0 END +
    CASE WHEN age > 50 then 10 ELSE 0 END) as retention_priority_score
FROM bank_customer_churn 
ORDER BY retention_priority_score DESC) 
SELECT *, 
CASE 	WHEN retention_priority_score >= 70 then "High_priority"
		WHEN retention_priority_score >= 40 then "Medium"
        ELSE "Low"
        END as priority
FROM customer_score;

/*============================================================
02. Customer segmentation
============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Segment customers based on retention priority, age and country 
to identify high risk customer groups and support targeted retention strategies
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Distribution of customers across retention priority level
--------------------------------------------------------------------------------------*/

SELECT priority, count(*) as customer_count FROM customer_retention 
GROUP BY priority
ORDER BY count(*) DESC;

/*------------------------------------------------------------------------------------
Business Insight

Majority of customers are falling into the low priority segment. however 2097 customers
have been identified as "High Priority" which requires immediate retention efforts

Recommendation

The bank should prioritize the retention campaign for 2097 customers through personalized
engagement, targeted retention offers. Medium priority customers should be monitored 
regularly. low priority customer can be maintained through standard engagement programs
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Country with highest number of critical customer
--------------------------------------------------------------------------------------*/

SELECT country, count(*) as critical_customer 
FROM customer_retention
WHERE priority = 'High_priority'
GROUP BY country
ORDER BY count(*) DESC;

/*------------------------------------------------------------------------------------
Business Insight

France has the highest number of high priority customers (935), followed by Germany (757)
indicating greater retention risk in these markets

Recommendation

Prioritize retention campaign in France, followed by Germany to reduce customer churn.
--------------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Which age group contains the high priority customer
--------------------------------------------------------------------------------------*/

SELECT 
	CASE 
		WHEN age between 18 and 30 then '18-30'
        WHEN age between 31 and 50 then '31-50'
        WHEN age between 50 and 60 then '51-60'
	ELSE '60+'
    END as age_group,
count(*) as priority_customer
FROM customer_retention
WHERE priority = 'High_priority'
GROUP BY age_group
ORDER BY priority_customer DESC;

/*------------------------------------------------------------------------------------
Business Insight

Customers aged 31-50 account for the highest number of high priority customer (1388)
which is most critical age segment for retention

recommendation

Focus retention campaign on customer aged 31-50 through personalized engagement and 
loyalty programs
--------------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Country with highest average Retention Priority Score
--------------------------------------------------------------------------------------*/

SELECT country, round(AVG(retention_priority_score),2) as average_retention_priority_score
FROM customer_retention
GROUP BY country
ORDER BY average_retention_priority_score DESC
limit 1;

/*============================================================
03. Customer Risk Analysis
============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Analyze the financial profile of high priority customer to understand their 
characteristics and determine the overall customer risk.
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Average balance of each priority group
--------------------------------------------------------------------------------------*/
 
SELECT priority, round(AVG(balance),2) as average_balance
FROM customer_retention
GROUP BY priority
ORDER BY average_balance DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
credit score analysis for priority group
--------------------------------------------------------------------------------------*/

SELECT priority, round(AVG(credit_score),2) as average_credit_score
FROM customer_retention
GROUP BY priority
ORDER BY average_credit_score DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Average profiles of high_priority customer
--------------------------------------------------------------------------------------*/

SELECT count(*) as total_high_priority_customer,
round(AVG(age),0) as average_age,
round(AVG(balance),2) as average_balance,
round(AVG(credit_score),2) as average_credit_score,
round(AVG(estimated_salary),2) as average_estimated_salary,
round(AVG(tenure),2) as average_tenure,
round(AVG(products_number),2) as average_products
FROM customer_retention
WHERE priority = "High_priority";

/*------------------------------------------------------------------------------------
Business Insight

High priority customers typically have a average balance of 1,30,312, an averaga age of 
40 years, own only one product

Recommendation

Prioritized personalized retention strategies and cross selling opportunities for
high value customers with only one product. 
--------------------------------------------------------------------------------------*/

/*============================================================
04. Financial Risk Analysis
==============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Measure the financial impact caused by the high value customer by evaluating balances
at risk, CLV & country wise financial impact
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Average balance of each priority group
--------------------------------------------------------------------------------------*/

SELECT priority, 
count(*) as total_customer,
round(sum(balance),2) as total_balance_at_risk
FROM customer_retention
GROUP BY priority
ORDER BY total_balance_at_risk DESC;

/*------------------------------------------------------------------------------------
Business Insight

Medium priority customer have highest balance at risk (341.05 million) followed by
High priority customer (273.27 million).

Recommendation

Focus retention efforts on Medium and High priority customers to protects the bank deposits.
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
countries With highest balance at risk
--------------------------------------------------------------------------------------*/

SELECT country, round(sum(balance),2) as balance_at_risk
FROM customer_retention
WHERE priority = 'High_priority'
GROUP BY country
ORDER BY balance_at_risk DESC;


/*------------------------------------------------------------------------------------
Business Insight

France has the highest balance at risk (122.29 million) followed germany (96.94 million)
indicating greatest financial exposures in these countries

Recommendation

Prioritize retention efforts in France and Germany to minimize potential financial
losses from high value customers
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Age group contributing the highest balance at risk
--------------------------------------------------------------------------------------*/

SELECT 
	CASE 
		WHEN age between 18 and 30 then '18-30'
        WHEN age between 31 and 50 then '31-50'
        WHEN age between 50 and 60 then '51-60'
	ELSE '60+'
    END as age_group,
count(*) as priority_customer, 
round(sum(balance),2) as highest_balance_at_risk
FROM customer_retention
WHERE priority = 'High_priority'
GROUP BY age_group
ORDER BY priority_customer DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Country WITH highest CLV value at risk
--------------------------------------------------------------------------------------*/

SELECT country,
round(sum(balance * tenure),2) as estimated_CLV_at_risk
FROM customer_retention
WHERE priority = 'High_priority'
GROUP BY country
ORDER BY estimated_CLV_at_risk DESC;

/*------------------------------------------------------------------------------------
Business Insight

France has the highest estimated CLV at risk (609.31 million) followed by Germany
(485.82 million) indicating potential long term revenue loss.

Recommendation

Prioritize retention strategies in France & Germany to minimize the long term customer 
CLV loss
--------------------------------------------------------------------------------------*/

/*============================================================
05. Customer Churn & Retention Analysis
==============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Idnetifying the key factors influencing the customer churn by analyzing customer
behaviour across age, tenure, product, gENDer and account activity to support the 
retention decisions.
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Churn rate within each priority level
--------------------------------------------------------------------------------------*/

SELECT priority, count(*) as total_customer,
sum(churn) as churned_customers,
round((sum(churn)*100)/count(*),2) as churn_rate_perc
FROM customer_retention
GROUP BY priority
ORDER BY churn_rate_perc DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Gender with highest churn rate
--------------------------------------------------------------------------------------*/

SELECT gender, count(*) as total_customer,
sum(churn) as churned_customer,
round((sum(churn) *100/count(*)),2) as churn_rate
FROM customer_retention
GROUP BY gender;

/*------------------------------------------------------------------------------------
Business Insight

Female customers have higher churn rate (25.07%) than male customers(16.46%).

Recommendation

Perform a root cause analysis to identify why female customers are leaving and
implement the retention strategies.
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
tenure with highest churn rate
--------------------------------------------------------------------------------------*/

SELECT CASE
		WHEN tenure <= 2 then '0-2 Years'
        WHEN tenure <= 5 then '3-5 Years'
        WHEN tenure <= 8 then '6-8 Years'
		ELSE '9+ Years'
END as tenure_group,
count(*) as customers,
round((sum(churn) *100/count(*)),2) as churn_rate
FROM customer_retention
GROUP BY tenure_group
ORDER BY churn_rate DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Which product segment has highest churn rate
--------------------------------------------------------------------------------------*/

SELECT products_number, count(*) as total_customer,
round((sum(churn) *100/count(*)),2) as churn_rate
FROM customer_retention
GROUP BY products_number
ORDER BY churn_rate DESC;


/*------------------------------------------------------------------------------------
Business Insight

Customers with 1 product have a high churn rate (27.17%) and represent the largest
customer segment indicating the retention opportunity 	

Recommendation

Increase a cross selling efforts for customers with 1 product to improve engagement
and reduce churn
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Inactive high priority customer by country
--------------------------------------------------------------------------------------*/

SELECT country, count(*) as inactive_priority_customer
FROM customer_retention
WHERE priority = 'High_priority' and active_member = 0
GROUP BY country
ORDER BY inactive_priority_customer DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
long-tenure customers are unexpectedly at risk?
--------------------------------------------------------------------------------------*/

SELECT customer_id, country, tenure
FROM customer_retention
WHERE tenure >=5 and priority = "High_priority"
ORDER BY retention_priority_score DESC, tenure DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Country wise count of long tenure critical customer
--------------------------------------------------------------------------------------*/

SELECT country, count(*) as long_tenure_risk_customer
FROM customer_retention
WHERE tenure >=5 and priority = "High_priority"
GROUP BY country
ORDER BY long_tenure_risk_customer DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Customer with high_credit_score but still churned
--------------------------------------------------------------------------------------*/

SELECT customer_id, country, credit_score,balance, tenure, products_number, active_member
FROM customer_retention
WHERE churn = 1 
and credit_score >=700
ORDER BY credit_score DESC;

/*------------------------------------------------------------------------------------
Business Insight

Customers with credit score of 700 or above still churned. indicating credit card alone 
not influencing the customer churn

Recommendation

Analyze the service usage and engagement of high credit score customers to identify non
financial factors influencing for the churn
--------------------------------------------------------------------------------------*/

/*============================================================
06. Customer Prioritization
============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Prioritize customers for retention campaign by ranking them according to retention risk
and customer who are close to becoming high priority CASEs 
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Rank customers within each country by retention priority.
--------------------------------------------------------------------------------------*/

SELECT customer_id, country, retention_priority_score, priority,
DENSE_RANK() over (PARTITION by country ORDER BY retention_priority_score DESC) as country_rank
FROM customer_retention
ORDER BY country, country_rank;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Customer who have balance above their country's average balance.
--------------------------------------------------------------------------------------*/

WITH country_balance as
(SELECT customer_id, country, balance, priority,
round(AVG(balance) over (PARTITION by country),2) as country_AVG_balance
FROM customer_retention)
SELECT customer_id, country, balance, country_AVG_balance,
round(balance - country_AVG_balance,2) as balance_above_average
FROM country_balance
WHERE balance > country_AVG_balance
AND priority = 'High_priority'
ORDER BY country, balance DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Active customer close to become the high_priority_customer
--------------------------------------------------------------------------------------*/

SELECT customer_id, country, retention_priority_score, priority
FROM customer_retention
WHERE active_member = 1
and retention_priority_score between 60 and 70
ORDER BY retention_priority_score DESC;

/*------------------------------------------------------------------------------------
Business Insight

Active customers have retention score close to the high priority threshold, providing an 
opportunity for early retention intervention

Recommendation

Engage this customers to prevent them from moving into the High priority segment.
--------------------------------------------------------------------------------------*/

/*============================================================
07. Revenue Growth Opportunity
==============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Identify the cross selling and premium banking opportunities to increase the revenue
while retaining valuable customers.
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Customers having the highest cross-selling opportunity.
--------------------------------------------------------------------------------------*/

SELECT customer_id, country, balance, credit_score
FROM customer_retention 
WHERE 	products_number = 1 and
		active_member = 1 and
        balance > 100000 and
        credit_score >= 650 and
        churn = 0
ORDER BY balance DESC, credit_score DESC;

/*------------------------------------------------------------------------------------
Business Insight

The identified customers are financially strong, active and currently use only one product.
ideal for cross selling opportunities

Recommendation

Offer personalized cross selling campaigns to encourage these customers for additional 
banking product and increase CLV.
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Count of customers in the country having cross-selling opportunity.
--------------------------------------------------------------------------------------*/

SELECT country, count(*) as cross_sell_customer
FROM customer_retention
WHERE 	products_number = 1 and
		active_member = 1 and
        balance > 100000 and
        credit_score >= 650 and
        churn = 0
GROUP BY country
ORDER BY cross_sell_customer DESC;

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Customers eligible for premium banking services.
--------------------------------------------------------------------------------------*/

SELECT customer_id, country, balance, credit_score, tenure FROM customer_retention 
WHERE balance > 100000 
and credit_score >=700 
and active_member = 1
and tenure >5 
and churn = 0
ORDER BY balance DESC, credit_score DESC;

/*------------------------------------------------------------------------------------
Business Insight

The identified customers have high deposits, higher credit score, active and highly loyal.

Recommendation

Enroll this high tier customers into a exclusive VIP banking tier with dedicated
relationship manager, premium wealth management perks.
--------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Countries with highest number of premium Banking Customer.
--------------------------------------------------------------------------------------*/

SELECT country, count(*) as premium_customer 
FROM customer_retention 
WHERE balance > 100000 
and credit_score >=700 
and active_member = 1
and tenure >5 
and churn = 0
GROUP BY country
ORDER BY premium_customer DESC;


/*============================================================
08. Executive Summary
==============================================================*/

/*------------------------------------------------------------------------------------
Business Objective
--------------------------------------------------------------------------------------
Provide a consolidated country wise summary of customer churn, retention priority, 
financial risk to support the strategic business decision making
------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
Analysis
--------------------------------------------------------------------------------------
Country Wise Executive Summary.
--------------------------------------------------------------------------------------*/

SELECT country, count(*) as total_customers,
round((sum(churn) *100/count(*)),2) as churn_rate_perc,
round(AVG(balance),2) as AVG_balance,
round(AVG(credit_score),2) as AVG_credit_score,
sum(CASE WHEN priority = 'High_priority' then 1 ELSE 0 END) as high_priority_customer,
round(sum(CASE WHEN priority = 'High_priority' then balance ELSE 0 END),2) as balance_at_risk
FROM customer_retention
GROUP BY country 
ORDER BY balance_at_risk DESC;


/*------------------------------------------------------------------------------------
Business Insight

Germany has the highest churn rate (32.44%), while france has the largest number of 
high priority customer (935) and highest balance at risk (122.29 million)

Recommendation

Prioritize retention initiatives in Germany to reduce churn and focus on France to 
protect the high value customers and deposits
--------------------------------------------------------------------------------------*/

/*=======================================================================
Project Conclusion

High Priority customers Contributes the highest financial risk.
Germany shows the highest retention risk. 
Customer aged '50-60' shows the highest churn. 
Inactive customers are more likely to churn. 
Customer WITH one product presents a strong cross-selling opportunity. 
Premium banking opportunities exist among loyal high-balance customers. 

=========================================================================*/
