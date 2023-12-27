with data as (
  select
    seller_region,
    country_code,
    brand,
    asin,
    reporting_date,
    brand_aggregation,
    sum(daily_sales_asin_euro) as sales,
    sum(daily_qty_asin) as units,
    sum(daily_discounts_asin_euro) as discounts,
    sum(daily_cogs_asin_euro) as cogs,
    sum(daily_refunds_asin_euro) as refunds,
    sum(daily_sde1_asin_euro) as sde1,
    avg(top_bsr_position) as top_bsr_position,
    avg(bot_bsr_position) as bot_bsr_position,
    sum(daily_sessions_mobile_asin) as sessions_mobile,
    sum(daily_sessions_browser_asin) as sessions_browser,
    sum(daily_sessions_asin) as sessions,
    sum(daily_page_views_mobile_asin) as pageviews_mobile,
    sum(daily_page_views_browser_asin) as pageviews_browser,
    sum(daily_page_views_asin) as pageviews,
  from `yaba-data.base.fct_fe_final_report_everything_asin`
  group by 1, 2, 3, 4, 5, 6
),

top_asins as (
    select
        reporting_date,
        asin,
        country_code,
        round(sum(sde1), 2) as sde1,
    from data
    where
        brand_aggregation is not null
        and asin is not null
        and reporting_date between date_sub(current_date(), interval 6 month) and date_sub(current_date(), interval 2 day)
    group by 1, 2, 3

),

ranked as (
    select
        asin,
        country_code,
        rank() over (order by sum(sde1) desc) as rank,
    from top_asins
    group by 1, 2
),

data_selector as (
    select
        seller_region,
        country_code,
        brand,
        asin,
        reporting_date,
        top_bsr_position,
        bot_bsr_position,
        sales,
        units,
        discounts,
        cogs,
        refunds,
        sde1,
        sessions_mobile,
        sessions_browser,
        sessions,
        pageviews_mobile,
        pageviews_browser,
        pageviews,
        r.rank,
    from data as d
    left join ranked as r
        using (asin, country_code)
),

new_features as (
    select
        seller_region,
        country_code,
        brand,
        asin,
        reporting_date,
        top_bsr_position,
        bot_bsr_position,
        sales,
        safe_divide(sales,avg(sales) over (partition by country_code, asin rows between 90 preceding and current row)) as performance,
        units,
        discounts,
        cogs,
        refunds,
        sde1,
        sessions_mobile,
        sessions_browser,
        sessions,
        pageviews_mobile,
        pageviews_browser,
        pageviews,
        safe_divide(top_bsr_position,sales) as topbsr_sales,
        safe_divide(bot_bsr_position,sales) as botbsr_sales,
        safe_divide(units,sales) as units_sales,
        safe_divide(refunds,sales) as refunds_sales,
        safe_divide(sessions_mobile,sales) as sessionsmobile_sales,
        safe_divide(pageviews,sales) as pageviews_sales,
        safe_divide(top_bsr_position,sde1) as topbsr_sde1,
        safe_divide(bot_bsr_position,sde1) as botbsr_sde1,
        safe_divide(units,sde1) as units_sde1,
        safe_divide(refunds,sde1) as refunds_sde1,
        safe_divide(sessions_mobile,sde1) as sessionsmobile_sde1,
        safe_divide(pageviews,sde1) as pageviews_sde1,
        safe_divide(top_bsr_position,units) as topbsr_units,
        safe_divide(bot_bsr_position,units) as botbsr_units,
        safe_divide(units,units) as units_units,
        safe_divide(refunds,units) as refunds_units,
        safe_divide(sessions_mobile,units) as sessionsmobile_units,
        safe_divide(pageviews,units) as pageviews_units,
        rank,
    from data_selector
)

select * except(rank)
from new_features
where rank < 10 and reporting_date > '2023-06-01'