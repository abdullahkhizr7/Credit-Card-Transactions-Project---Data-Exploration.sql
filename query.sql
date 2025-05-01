/*  Credit Card Transction Analysis */



--1--
--print top 5 cities with highest spends and their percentage contribution of total credit card spends--

with A as(
select city , cast(sum(amount) as bigint) as spending
from credit_card_transcations
group by city)
,B as (
select *,cast(spending*100.0/sum(spending) over() as decimal(10,2)) as percent_contribution
from A
)
select top 5 * from B
order by spending desc;



--2--
--print highest spend month and amount spent in that month for each card type--

with A as(
select card_type,datepart(MONTH,transaction_date) as expenditure_in_month,sum(amount) as expenditure,
ROW_NUMBER() over(partition by card_type order by sum(amount) desc) as rn
from credit_card_transcations
group by card_type,datepart(month,transaction_date)
)
select * from A
where rn = 1;


--3--
--print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)--

with A as(
select*, sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transcations)
select * from (
select *,rank() over(partition by card_type order by total_spend) as rn
from A 
where total_spend >=1000000
) a 
where rn =1
;



--4--
--find city which had lowest percentage spend for gold card type--

with A as(
select city,card_type,amount
from credit_card_transcations
where card_type = 'Gold'),
B as (
select city,card_type,cast(amount*100.0/sum(amount) over() as decimal(10,10))  as Percent_spent
from A)
select top 1 city, sum(Percent_spent) as city_spent
from B 
group  by city
order by city_spent asc
;



--5--
--print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with A as(
select city,exp_type,sum(amount) as total
from credit_card_transcations
group by city,exp_type
)
,B as(
select *, rank() over(partition by city order by total desc) as rn_desc,
rank() over(partition by city order by total asc) as rn_asc
from A
)
select city,max(case when rn_desc =1 then exp_type end) as highest_expense_type,
min(case when rn_asc =1 then exp_type end) as lowest_expense_type
from B
group by city
;


--6--
--find percentage contribution of spends(among) by females for each expense type--

with A as(
select *
from credit_card_transcations
where gender = 'F')
,B as (
select exp_type,cast(sum(amount) as bigint) as total_spendings
from A
group by exp_type
), C as(
select *, cast(total_spendings*100.0/sum(total_spendings) over() as decimal(10,5)) as Percent_spending
from  B
)
select * from C
;



--7--
--which card and expense type combination saw highest month over month growth in Jan-2014--

with A as (
select card_type,exp_type,datepart(YEAR,transaction_date) as Year_a,
DATEPART(MONTH,transaction_date) as Month_a, 
sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(YEAR,transaction_date),DATEPART(MONTH,transaction_date)
)
select top 1 *,(total_spend-prev_month_exp) as monthly_growth
from
(select *,lag(total_spend,1) over(partition by card_type,exp_type order by  Year_a,Month_a) as prev_month_exp
from A) b
where prev_month_exp is not null and Year_a = 2014 and Month_a = 1
order by monthly_growth desc
;


--8--
--during weekends which city has highest total spend to total no of transcations ratio--

select top 1 city,sum(amount)/count(1) as ratio
from credit_card_transcations
where datepart(WEEKDAY,transaction_date) in (1,7)
group by city
order by ratio desc;


--9--
--which city took least number of days to reach its 500th transaction after the first transaction in that city--

with A as(
select * , ROW_NUMBER() over (partition by city order by transaction_date,transaction_id) as rn	
from credit_card_transcations
)
select top 1   city,datediff(day,min(transaction_date),max(transaction_date)) as difference1
from A
where rn =1 or rn=500
group by city
having count(1)=2
order by difference1

