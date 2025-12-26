
-- ============================================================================
-- HYFUN ANALYTICS - ADVANCED SQL QUERIES
-- 30+ Interview-Ready Business Intelligence Queries
-- ============================================================================

USE hyfun_analytics;
-- 1,14,20,26,30,31
-- ============================================================================
-- SECTION 1: SUPPLY CHAIN & PROCUREMENT ANALYTICS
-- ============================================================================

-- Query 1: Farmer ROI Analysis - Which farmers are most profitable?
-- Business Value: Identify top performers for contract renewal
SELECT 
    f.farmer_id,
    f.farmer_name,
    f.region,
    f.experience_years,
    COUNT(p.batch_id) as total_deliveries,
    ROUND(SUM(p.quantity_mt), 2) as total_quantity_mt,
    ROUND(AVG(p.quantity_mt), 2) as avg_delivery_size_mt,
    ROUND(SUM(CASE WHEN p.quality_grade = 'Premium' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as premium_rate_percent,
    ROUND(SUM(p.quantity_mt * p.price_per_mt), 2) as total_procurement_cost_inr,
    ROUND(AVG(p.price_per_mt), 2) as avg_price_per_mt
FROM farmers_master f
LEFT JOIN potato_procurement p ON f.farmer_id = p.farmer_id
GROUP BY f.farmer_id, f.farmer_name, f.region, f.experience_years
HAVING total_deliveries >= 3
ORDER BY total_quantity_mt DESC
LIMIT 20;

-- Query 2: Seasonal Procurement Pattern Analysis
-- Business Value: Optimize buying strategy based on harvest seasons
SELECT 
    MONTH(procurement_date) as month_num,
    MONTHNAME(procurement_date) as month_name,
    COUNT(DISTINCT batch_id) as delivery_count,
    SUM(quantity_mt) as total_volume_mt,
    ROUND(AVG(price_per_mt), 2) as avg_price_per_mt,
    ROUND(MIN(price_per_mt), 2) as min_price_per_mt,
    ROUND(MAX(price_per_mt), 2) as max_price_per_mt,
    ROUND(SUM(quantity_mt * price_per_mt), 2) as total_cost_inr,
    ROUND(AVG(CASE WHEN quality_grade = 'Premium' THEN 1 ELSE 0 END) * 100, 2) as premium_percent
FROM potato_procurement
WHERE procurement_date >= DATE_SUB(CURDATE(), INTERVAL 24 MONTH)
GROUP BY MONTH(procurement_date), MONTHNAME(procurement_date)
ORDER BY month_num;


-- Query 3: Regional Quality Comparison
-- Business Value: Identify best regions for quality sourcing
SELECT 
    f.region,
    COUNT(DISTINCT f.farmer_id) as farmer_count,
    COUNT(p.batch_id) as total_batches,
    SUM(p.quantity_mt) as total_volume_mt,
    ROUND(AVG(p.price_per_mt), 2) as avg_price_per_mt,
    ROUND(AVG(p.moisture_content), 2) as avg_moisture_percent,
    ROUND(AVG(p.defect_percentage), 2) as avg_defect_percent,
    SUM(CASE WHEN p.quality_grade = 'Premium' THEN p.quantity_mt ELSE 0 END) as premium_volume_mt,
    ROUND(SUM(CASE WHEN p.quality_grade = 'Premium' THEN p.quantity_mt ELSE 0 END) / SUM(p.quantity_mt) * 100, 2) as premium_share_percent
FROM farmers_master f
JOIN potato_procurement p ON f.farmer_id = p.farmer_id
WHERE p.procurement_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY f.region
ORDER BY premium_share_percent DESC;


-- ============================================================================
-- SECTION 2: PRODUCTION EFFICIENCY ANALYTICS
-- ============================================================================

-- Query 4: Plant Efficiency Comparison
-- Business Value: Identify operational excellence and improvement areas
SELECT 
    plant_location,
    COUNT(DISTINCT batch_id) as total_batches,
    COUNT(DISTINCT DATE(production_date)) as production_days,
    SUM(raw_material_used_mt) as total_raw_input_mt,
    SUM(finished_goods_mt) as total_finished_output_mt,
    ROUND((SUM(finished_goods_mt) / SUM(raw_material_used_mt) * 100), 2) as conversion_rate_percent,
    ROUND(AVG(processing_time_hours), 2) as avg_processing_time_hrs,
    ROUND(SUM(finished_goods_mt) / COUNT(DISTINCT DATE(production_date)), 2) as avg_daily_output_mt,
    -- Cost calculation (assuming ₹20,000 per MT raw material)
    ROUND((SUM(raw_material_used_mt) - SUM(finished_goods_mt)) * 20000, 2) as estimated_waste_cost_inr
FROM production_batches
WHERE production_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY plant_location
ORDER BY conversion_rate_percent DESC;


-- Query 5: Product-wise Production Performance
-- Business Value: Identify which products are most efficiently produced
SELECT 
    pb.product_sku,
    pm.product_name,
    pm.category,
    COUNT(pb.batch_id) as batches_produced,
    SUM(pb.raw_material_used_mt) as total_raw_mt,
    SUM(pb.finished_goods_mt) as total_finished_mt,
    ROUND((SUM(pb.finished_goods_mt) / SUM(pb.raw_material_used_mt) * 100), 2) as conversion_rate_percent,
    ROUND(AVG(pb.processing_time_hours), 2) as avg_time_hours,
    -- Profitability
    ROUND((pm.b2b_price_inr - pm.cost_price_inr), 2) as unit_margin_inr,
    ROUND((pm.b2b_price_inr - pm.cost_price_inr) / pm.b2b_price_inr * 100, 2) as margin_percent
FROM production_batches pb
JOIN product_master pm ON pb.product_sku = pm.product_sku
WHERE pb.production_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY pb.product_sku, pm.product_name, pm.category, pm.b2b_price_inr, pm.cost_price_inr
ORDER BY conversion_rate_percent DESC;


-- Query 6: Shift Performance Analysis
-- Business Value: Optimize labor scheduling
SELECT 
    shift,
    plant_location,
    COUNT(batch_id) as batches_produced,
    SUM(finished_goods_mt) as total_output_mt,
    ROUND(AVG(finished_goods_mt), 2) as avg_batch_size_mt,
    ROUND((SUM(finished_goods_mt) / SUM(raw_material_used_mt) * 100), 2) as conversion_rate_percent,
    ROUND(AVG(processing_time_hours), 2) as avg_processing_time_hrs,
    ROUND(SUM(finished_goods_mt) / SUM(processing_time_hours), 2) as output_per_hour_mt
FROM production_batches
WHERE production_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY shift, plant_location
ORDER BY plant_location, output_per_hour_mt DESC;


-- ============================================================================
-- SECTION 3: QUALITY CONTROL ANALYTICS
-- ============================================================================

-- Query 7: BRC Compliance Trend Analysis
-- Business Value: Ensure export quality standards are maintained
SELECT 
    DATE_FORMAT(qc.inspection_date, '%Y-%m') as month,
    COUNT(qc.qc_id) as total_inspections,
    SUM(CASE WHEN qc.status = 'Approved' THEN 1 ELSE 0 END) as approved_count,
    SUM(CASE WHEN qc.status = 'Rejected' THEN 1 ELSE 0 END) as rejected_count,
    ROUND(AVG(qc.brc_compliance_score), 2) as avg_brc_score,
    ROUND(MIN(qc.brc_compliance_score), 2) as min_brc_score,
    ROUND(SUM(CASE WHEN qc.status = 'Approved' THEN 1 ELSE 0 END) / COUNT(qc.qc_id) * 100, 2) as approval_rate_percent,
    ROUND(SUM(CASE WHEN qc.brc_compliance_score >= 90 THEN 1 ELSE 0 END) / COUNT(qc.qc_id) * 100, 2) as excellent_quality_percent
FROM quality_control qc
WHERE qc.inspection_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(qc.inspection_date, '%Y-%m')
ORDER BY month DESC;

-- Query 8: Quality Issues by Plant
-- Business Value: Target quality improvement efforts
SELECT 
    pb.plant_location,
    COUNT(qc.qc_id) as inspections_done,
    ROUND(AVG(qc.brc_compliance_score), 2) as avg_brc_score,
    ROUND(AVG(qc.defect_rate), 2) as avg_defect_rate_percent,
    SUM(CASE WHEN qc.status = 'Rejected' THEN 1 ELSE 0 END) as rejection_count,
    ROUND(SUM(CASE WHEN qc.status = 'Rejected' THEN 1 ELSE 0 END) / COUNT(qc.qc_id) * 100, 2) as rejection_rate_percent,
    -- Impact on production
    ROUND(SUM(CASE WHEN qc.status = 'Rejected' THEN pb.finished_goods_mt ELSE 0 END), 2) as rejected_volume_mt
FROM quality_control qc
JOIN production_batches pb ON qc.batch_id = pb.batch_id
WHERE qc.inspection_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY pb.plant_location
ORDER BY avg_brc_score DESC;

-- ============================================================================
-- SECTION 4: DOWNTIME & MAINTENANCE ANALYTICS
-- ============================================================================

-- Query 9: Machine Reliability Analysis
-- Business Value: Identify problematic machines for replacement/upgrade
SELECT 
    machine_id,
    plant_location,
    COUNT(downtime_id) as downtime_events,
    ROUND(SUM(duration_hours), 2) as total_downtime_hours,
    ROUND(AVG(duration_hours), 2) as avg_downtime_hours,
    ROUND(SUM(production_loss_mt), 2) as total_production_loss_mt,
    ROUND(SUM(repair_cost_inr), 2) as total_repair_cost_inr,
    -- Calculate revenue loss (assuming ₹240/kg B2B price)
    ROUND(SUM(production_loss_mt) * 1000 * 240, 2) as estimated_revenue_loss_inr,
    -- Most common failure reason
    (SELECT reason 
     FROM machine_downtime md2 
     WHERE md2.machine_id = md.machine_id 
     GROUP BY reason 
     ORDER BY COUNT(*) DESC 
     LIMIT 1) as most_common_issue
FROM machine_downtime md
WHERE start_time >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY machine_id, plant_location
HAVING downtime_events >= 3
ORDER BY total_production_loss_mt DESC
LIMIT 15;


-- Query 10: Downtime Root Cause Analysis
-- Business Value: Focus maintenance efforts on biggest issues
SELECT 
    reason,
    COUNT(downtime_id) as incident_count,
    ROUND(SUM(duration_hours), 2) as total_hours_lost,
    ROUND(AVG(duration_hours), 2) as avg_duration_hours,
    ROUND(SUM(production_loss_mt), 2) as total_production_loss_mt,
    ROUND(SUM(repair_cost_inr), 2) as total_repair_cost_inr,
    ROUND(SUM(duration_hours) / (SELECT SUM(duration_hours) FROM machine_downtime) * 100, 2) as percent_of_total_downtime,
    -- Estimated revenue impact
    ROUND(SUM(production_loss_mt) * 1000 * 240, 2) as estimated_revenue_loss_inr
FROM machine_downtime
WHERE start_time >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY reason
ORDER BY total_production_loss_mt DESC;


-- ============================================================================
-- SECTION 5: WASTAGE & COST OPTIMIZATION
-- ============================================================================

-- Query 11: Wastage Analysis by Type and Plant
-- Business Value: Target waste reduction initiatives
SELECT 
    pb.plant_location,
    w.wastage_type,
    COUNT(w.wastage_id) as wastage_incidents,
    ROUND(SUM(w.quantity_kg), 2) as total_wastage_kg,
    ROUND(SUM(w.cost_impact_inr), 2) as total_cost_impact_inr,
    ROUND(AVG(w.quantity_kg), 2) as avg_wastage_per_incident_kg,
    SUM(CASE WHEN w.recovery_possible = 'Yes' THEN w.quantity_kg ELSE 0 END) as recoverable_kg,
    ROUND(SUM(CASE WHEN w.recovery_possible = 'Yes' THEN w.quantity_kg ELSE 0 END) / SUM(w.quantity_kg) * 100, 2) as recovery_rate_percent
FROM wastage_tracking w
JOIN production_batches pb ON w.batch_id = pb.batch_id
WHERE w.wastage_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY pb.plant_location, w.wastage_type
ORDER BY pb.plant_location, total_cost_impact_inr DESC;

-- Query 12: Monthly Wastage Trend
-- Business Value: Monitor improvement over time
SELECT 
    DATE_FORMAT(w.wastage_date, '%Y-%m') as month,
    COUNT(w.wastage_id) as incidents,
    ROUND(SUM(w.quantity_kg) / 1000, 2) as total_wastage_mt,
    ROUND(SUM(w.cost_impact_inr) / 100000, 2) as cost_impact_lakhs,
    ROUND(SUM(w.quantity_kg) / SUM(pb.finished_goods_mt * 1000) * 100, 2) as wastage_rate_percent
FROM wastage_tracking w
JOIN production_batches pb ON w.batch_id = pb.batch_id
WHERE w.wastage_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(w.wastage_date, '%Y-%m')
ORDER BY month DESC;

-- ============================================================================
-- SECTION 6: B2B CUSTOMER ANALYTICS
-- ============================================================================

-- Query 13: RFM Customer Segmentation (Recency, Frequency, Monetary)
-- Business Value: Prioritize customer relationship management
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.company_name,
        c.customer_type,
        c.country,
        DATEDIFF(CURDATE(), MAX(o.order_date)) as recency_days,
        COUNT(DISTINCT o.order_id) as frequency,
        SUM(o.total_value_inr) as monetary_value,
        AVG(o.total_value_inr) as avg_order_value,
        SUM(CASE WHEN o.payment_status = 'Delayed' THEN 1 ELSE 0 END) as payment_delays
    FROM b2b_customers c
    LEFT JOIN b2b_orders o ON c.customer_id = o.customer_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 24 MONTH)
    GROUP BY c.customer_id, c.company_name, c.customer_type, c.country
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC) as R_score,
        NTILE(5) OVER (ORDER BY frequency DESC) as F_score,
        NTILE(5) OVER (ORDER BY monetary_value DESC) as M_score
    FROM customer_metrics
)
SELECT 
    customer_id,
    company_name,
    customer_type,
    country,
    recency_days,
    frequency as total_orders,
    ROUND(monetary_value, 2) as lifetime_value_inr,
    ROUND(avg_order_value, 2) as avg_order_value_inr,
    payment_delays,
    CASE 
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score <= 2 THEN 'Promising'
        WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2 THEN 'Lost'
        WHEN F_score >= 4 AND M_score <= 2 THEN 'Price Sensitive'
        ELSE 'Regular'
    END as customer_segment,
    CONCAT(R_score, F_score, M_score) as rfm_score
FROM rfm_scores
ORDER BY monetary_value DESC;


-- Query 14: Customer Churn Risk Analysis
-- Business Value: Proactive retention strategies
-- ============================================================================
-- FIXED VERSIONS OF QUERIES WITH ERRORS
-- ============================================================================

USE hyfun_analytics;

-- ============================================================================
-- FIXED QUERY 1: Farmer ROI Analysis
-- Issue: Complex subquery in SELECT causing issues
-- ============================================================================

SELECT 
    f.farmer_id,
    f.farmer_name,
    f.region,
    f.experience_years,
    COUNT(p.batch_id) as total_deliveries,
    ROUND(SUM(p.quantity_mt), 2) as total_quantity_mt,
    ROUND(AVG(p.quantity_mt), 2) as avg_delivery_size_mt,
    ROUND(SUM(CASE WHEN p.quality_grade = 'Premium' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as premium_rate_percent,
    ROUND(SUM(p.quantity_mt * p.price_per_mt), 2) as total_procurement_cost_inr,
    ROUND(AVG(p.price_per_mt), 2) as avg_price_per_mt
FROM farmers_master f
LEFT JOIN potato_procurement p ON f.farmer_id = p.farmer_id
WHERE p.procurement_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY f.farmer_id, f.farmer_name, f.region, f.experience_years
HAVING total_deliveries >= 3
ORDER BY total_quantity_mt DESC
LIMIT 20;

-- ============================================================================
-- FIXED QUERY 14: Customer Churn Risk Analysis
-- Issue: LAG function and complex window function
-- ============================================================================

WITH customer_last_order AS (
    SELECT 
        c.customer_id,
        c.company_name,
        c.customer_type,
        c.country,
        COUNT(o.order_id) as total_orders,
        ROUND(SUM(o.total_value_inr), 2) as total_spent_inr,
        MAX(o.order_date) as last_order_date,
        MIN(o.order_date) as first_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date)) as days_since_last_order
    FROM b2b_customers c
    JOIN b2b_orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.company_name, c.customer_type, c.country
)
SELECT 
    customer_id,
    company_name,
    customer_type,
    country,
    days_since_last_order,
    total_orders,
    total_spent_inr,
    last_order_date,
    DATEDIFF(last_order_date, first_order_date) as customer_lifetime_days,
    CASE 
        WHEN days_since_last_order > 180 THEN 'High Risk - Lost'
        WHEN days_since_last_order > 90 THEN 'High Risk - Churning'
        WHEN days_since_last_order > 60 THEN 'Medium Risk'
        WHEN days_since_last_order > 30 THEN 'Low Risk'
        ELSE 'Active'
    END as churn_risk
FROM customer_last_order
WHERE days_since_last_order > 30
ORDER BY total_spent_inr DESC, days_since_last_order DESC;

-- Query 15: Top Customers by Revenue
-- Business Value: Focus on key accounts
SELECT 
    c.customer_id,
    c.company_name,
    c.customer_type,
    c.country,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(SUM(o.total_value_inr), 2) as total_revenue_inr,
    ROUND(AVG(o.total_value_inr), 2) as avg_order_value_inr,
    ROUND(SUM(o.quantity_kg) / 1000, 2) as total_volume_mt,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) as customer_tenure_days,
    -- Payment behavior
    ROUND(SUM(CASE WHEN o.payment_status = 'Paid' THEN o.total_value_inr ELSE 0 END) / SUM(o.total_value_inr) * 100, 2) as payment_reliability_percent,
    -- Revenue contribution
    ROUND(SUM(o.total_value_inr) / (SELECT SUM(total_value_inr) FROM b2b_orders) * 100, 2) as revenue_contribution_percent
FROM b2b_customers c
JOIN b2b_orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY c.customer_id, c.company_name, c.customer_type, c.country
ORDER BY total_revenue_inr DESC
LIMIT 20;

-- ============================================================================
-- SECTION 7: EXPORT MARKET ANALYTICS
-- ============================================================================

-- Query 16: Export Performance by Country
-- Business Value: Identify high-potential markets for expansion
SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) as customer_count,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(SUM(o.total_value_inr) / 10000000, 2) as revenue_crores,
    ROUND(SUM(o.quantity_kg) / 1000, 2) as volume_mt,
    ROUND(AVG(o.unit_price_inr), 2) as avg_unit_price_inr,
    -- Export logistics
    COUNT(DISTINCT es.shipment_id) as shipment_count,
    ROUND(AVG(es.transit_days), 1) as avg_transit_days,
    ROUND(AVG(es.shipping_cost_inr), 2) as avg_shipping_cost_inr,
    ROUND(SUM(CASE WHEN es.customs_cleared = 'Yes' THEN 1 ELSE 0 END) / COUNT(es.shipment_id) * 100, 2) as customs_clearance_rate_percent,
    -- Profitability (shipping cost as % of revenue)
    ROUND(SUM(es.shipping_cost_inr) / SUM(o.total_value_inr) * 100, 2) as logistics_cost_percent
FROM b2b_customers c
JOIN b2b_orders o ON c.customer_id = o.customer_id
LEFT JOIN export_shipments es ON o.order_id = es.order_id
WHERE c.country != 'India'
  AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY c.country
ORDER BY revenue_crores DESC;


-- Query 17: Shipping Method Efficiency
-- Business Value: Optimize logistics costs
SELECT 
    shipping_method,
    destination_country,
    COUNT(shipment_id) as shipment_count,
    ROUND(AVG(transit_days), 1) as avg_transit_days,
    ROUND(MIN(transit_days), 0) as min_transit_days,
    ROUND(MAX(transit_days), 0) as max_transit_days,
    ROUND(AVG(shipping_cost_inr), 2) as avg_shipping_cost_inr,
    ROUND(SUM(shipping_cost_inr), 2) as total_shipping_cost_inr,
    -- Calculate cost per day
    ROUND(AVG(shipping_cost_inr / transit_days), 2) as cost_per_transit_day_inr
FROM export_shipments
WHERE departure_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY shipping_method, destination_country
HAVING shipment_count >= 5
ORDER BY destination_country, avg_shipping_cost_inr;

-- ============================================================================
-- SECTION 8: PRODUCT PERFORMANCE ANALYTICS
-- ============================================================================

-- Query 18: Product BCG Matrix (Boston Consulting Group)
-- Business Value: Portfolio management - which products to grow/divest
WITH product_performance AS (
    SELECT 
        pm.product_sku,
        pm.product_name,
        pm.category,
        -- B2B metrics
        COALESCE(SUM(bo.total_value_inr), 0) as b2b_revenue,
        -- B2C metrics
        COALESCE(SUM(bc.final_price * bc.quantity_units), 0) as b2c_revenue,
        -- Total
        COALESCE(SUM(bo.total_value_inr), 0) + COALESCE(SUM(bc.final_price * bc.quantity_units), 0) as total_revenue,
        -- Margin
        ROUND((pm.b2b_price_inr - pm.cost_price_inr) / pm.b2b_price_inr * 100, 2) as margin_percent,
        -- Market growth (YoY)
        DATEDIFF(CURDATE(), pm.launch_date) as days_since_launch
    FROM product_master pm
    LEFT JOIN b2b_orders bo ON pm.product_sku = bo.product_sku 
        AND bo.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    LEFT JOIN b2c_sales bc ON pm.product_sku = bc.product_sku 
        AND bc.sale_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY pm.product_sku, pm.product_name, pm.category, pm.b2b_price_inr, pm.cost_price_inr, pm.launch_date
)
SELECT 
    product_sku,
    product_name,
    category,
    ROUND(total_revenue / 100000, 2) as revenue_lakhs,
    margin_percent,
    ROUND(total_revenue / (SELECT SUM(total_revenue) FROM product_performance) * 100, 2) as market_share_percent,
    CASE 
        WHEN total_revenue > (SELECT AVG(total_revenue) FROM product_performance)
             AND margin_percent > 30 THEN '⭐ Star Products'
        WHEN total_revenue > (SELECT AVG(total_revenue) FROM product_performance)
             AND margin_percent <= 30 THEN '💰 Cash Cows'
        WHEN total_revenue <= (SELECT AVG(total_revenue) FROM product_performance)
             AND margin_percent > 30 AND days_since_launch < 730 THEN '❓ Question Marks'
        ELSE '🐕 Dogs'
    END as bcg_category,
    CASE
        WHEN total_revenue > (SELECT AVG(total_revenue) FROM product_performance)
             AND margin_percent > 30 THEN 'Invest & Grow'
        WHEN total_revenue > (SELECT AVG(total_revenue) FROM product_performance)
             AND margin_percent <= 30 THEN 'Maintain & Harvest'
        WHEN total_revenue <= (SELECT AVG(total_revenue) FROM product_performance)
             AND margin_percent > 30 AND days_since_launch < 730 THEN 'Invest Selectively'
        ELSE 'Divest or Reposition'
    END as recommendation
FROM product_performance
ORDER BY total_revenue DESC;


-- Query 19: Product Sales Velocity
-- Business Value: Inventory and production planning
SELECT 
    pm.product_sku,
    pm.product_name,
    pm.category,
    -- B2B velocity
    COUNT(DISTINCT bo.order_id) as b2b_order_count,
    ROUND(SUM(bo.quantity_kg) / 1000, 2) as b2b_volume_mt,
    ROUND(SUM(bo.quantity_kg) / 1000 / 12, 2) as b2b_monthly_avg_mt,
    -- B2C velocity
    COUNT(DISTINCT bc.transaction_id) as b2c_transaction_count,
    SUM(bc.quantity_units) as b2c_units_sold,
    ROUND(SUM(bc.quantity_units) / 12, 0) as b2c_monthly_avg_units,
    -- Combined revenue
    ROUND((COALESCE(SUM(bo.total_value_inr), 0) + COALESCE(SUM(bc.final_price * bc.quantity_units), 0)) / 100000, 2) as total_revenue_lakhs
FROM product_master pm
LEFT JOIN b2b_orders bo ON pm.product_sku = bo.product_sku 
    AND bo.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
LEFT JOIN b2c_sales bc ON pm.product_sku = bc.product_sku 
    AND bc.sale_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY pm.product_sku, pm.product_name, pm.category
ORDER BY total_revenue_lakhs DESC;


-- ============================================================================
-- SECTION 9: B2C RETAIL ANALYTICS
-- ============================================================================

-- Query 20: City-wise B2C Performance
-- Business Value: Expansion strategy for 100-city target
SELECT 
    city,
    COUNT(DISTINCT transaction_id) as transactions,
    SUM(quantity_units) as units_sold,
    ROUND(SUM(final_price), 2) as total_revenue_inr,
    ROUND(AVG(final_price), 2) as avg_transaction_value,
    ROUND(SUM(final_price) / COUNT(DISTINCT transaction_id), 2) as revenue_per_transaction,
    ROUND(AVG(discount_percent), 2) as avg_discount_percent,
    ROUND(SUM(mrp * quantity_units) - SUM(final_price), 2) as total_discount_given_inr,
    ROUND(SUM(CASE WHEN channel = 'Modern Trade' THEN final_price ELSE 0 END) / SUM(final_price) * 100, 2) as modern_trade_percent,
    ROUND(SUM(CASE WHEN channel = 'Online Platform' THEN final_price ELSE 0 END) / SUM(final_price) * 100, 2) as online_percent,
    ROUND(SUM(CASE WHEN customer_type = 'Regular' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as regular_customer_percent
FROM b2c_sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY city
ORDER BY total_revenue_inr DESC;



-- Query 21: Channel Performance Comparison
-- Business Value: Optimize retail channel strategy
SELECT
channel,
COUNT(DISTINCT transaction_id) as transaction_count,
SUM(quantity_units) as total_units,
ROUND(SUM(final_price) / 100000, 2) as revenue_lakhs,
ROUND(AVG(final_price), 2) as avg_transaction_value,
ROUND(AVG(discount_percent), 2) as avg_discount_percent,
-- Customer loyalty
ROUND(SUM(CASE WHEN customer_type = 'Loyalty Member' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as loyalty_member_percent,
-- Revenue contribution
ROUND(SUM(final_price) / (SELECT SUM(final_price) FROM b2c_sales) * 100, 2) as revenue_share_percent
FROM b2c_sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY channel
ORDER BY revenue_lakhs DESC;

-- ============================================================================
-- SECTION 10: FINANCIAL ANALYTICS
-- ============================================================================
-- Query 22: Monthly Revenue Trend (B2B + B2C)
-- Business Value: Track progress toward ₹1,500 Cr target
SELECT
DATE_FORMAT(date, '%Y-%m') as month,
revenue_source,
SUM(revenue_inr) / 10000000 as revenue_crores,
SUM(cogs_inr) / 10000000 as cogs_crores,
SUM(gross_margin_inr) / 10000000 as gross_margin_crores,
ROUND(SUM(gross_margin_inr) / SUM(revenue_inr) * 100, 2) as margin_percent
FROM revenue_summary
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(date, '%Y-%m'), revenue_source
ORDER BY month DESC, revenue_source;


-- Query 23: Category-wise Profitability
-- Business Value: Product mix optimization
SELECT
product_category,
revenue_source,
ROUND(SUM(revenue_inr) / 10000000, 2) as revenue_crores,
ROUND(SUM(gross_margin_inr) / 10000000, 2) as gross_margin_crores,
ROUND(SUM(gross_margin_inr) / SUM(revenue_inr) * 100, 2) as margin_percent,
ROUND(SUM(revenue_inr) / (SELECT SUM(revenue_inr) FROM revenue_summary) * 100, 2) as revenue_contribution_percent
FROM revenue_summary
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY product_category, revenue_source
ORDER BY revenue_crores DESC;


-- Query 24: Year-over-Year Growth Analysis
-- Business Value: Measure business momentum
WITH monthly_revenue AS (
SELECT
DATE_FORMAT(date, '%Y') as year,
DATE_FORMAT(date, '%m') as month,
SUM(revenue_inr) as monthly_revenue
FROM revenue_summary
GROUP BY DATE_FORMAT(date, '%Y'), DATE_FORMAT(date, '%m')
)
SELECT
curr.year,
curr.month,
ROUND(curr.monthly_revenue / 10000000, 2) as current_revenue_crores,
ROUND(prev.monthly_revenue / 10000000, 2) as previous_year_crores,
ROUND((curr.monthly_revenue - prev.monthly_revenue) / prev.monthly_revenue * 100, 2) as yoy_growth_percent
FROM monthly_revenue curr
LEFT JOIN monthly_revenue prev
ON curr.month = prev.month AND curr.year = prev.year + 1
WHERE prev.monthly_revenue IS NOT NULL
ORDER BY curr.year DESC, curr.month DESC;

-- ============================================================================
-- SECTION 11: EXECUTIVE DASHBOARD QUERIES
-- ============================================================================
-- Query 25: Executive Summary - Key Metrics
-- Business Value: One-stop overview for leadership
SELECT
'Total Revenue (Last 12M)' as metric,
CONCAT('₹', ROUND(SUM(revenue_inr) / 10000000, 2), ' Cr') as value
FROM revenue_summary
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
UNION ALL
SELECT
'Gross Margin %',
CONCAT(ROUND(SUM(gross_margin_inr) / SUM(revenue_inr) * 100, 2), '%')
FROM revenue_summary
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
UNION ALL
SELECT
'B2B Customers',
CONCAT(COUNT(DISTINCT customer_id), ' active')
FROM b2b_orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
UNION ALL
SELECT
'B2C Cities',
CONCAT(COUNT(DISTINCT city), ' cities')
FROM b2c_sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
UNION ALL
SELECT
'Production Volume',
CONCAT(ROUND(SUM(finished_goods_mt), 0), ' MT')
FROM production_batches
WHERE production_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
UNION ALL
SELECT
'Avg BRC Compliance',
CONCAT(ROUND(AVG(brc_compliance_score), 1), '/100')
FROM quality_control
WHERE inspection_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
UNION ALL
SELECT
'Export Countries',
CONCAT(COUNT(DISTINCT country), ' markets')
FROM b2b_customers
WHERE country != 'India';



-- Query 26: Top 10 Issues Requiring Immediate Attention
-- Business Value: Prioritize action items
-- Part 1: High-Value Customers at Risk
SELECT 
    'High-Value Customer at Risk' as issue_type,
    CONCAT(c.company_name, ' (₹', ROUND(SUM(o.total_value_inr) / 100000, 2), 'L)') as details,
    DATEDIFF(CURDATE(), MAX(o.order_date)) as severity,
    'Contact for retention' as action
FROM b2b_customers c
JOIN b2b_orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name
HAVING SUM(o.total_value_inr) > 1000000 
   AND DATEDIFF(CURDATE(), MAX(o.order_date)) > 90
ORDER BY SUM(o.total_value_inr) DESC
LIMIT 3;

-- Part 2: Delayed Payments
SELECT 
    'Delayed Payment' as issue_type,
    CONCAT('Order ', order_id, ' - ₹', ROUND(total_value_inr / 100000, 2), 'L') as details,
    DATEDIFF(CURDATE(), order_date) as severity,
    'Follow up with customer' as action
FROM b2b_orders
WHERE payment_status = 'Delayed'
ORDER BY total_value_inr DESC
LIMIT 3;

-- Part 3: Low BRC Compliance
SELECT 
    'Low BRC Compliance' as issue_type,
    CONCAT(pb.plant_location, ' - Score: ', ROUND(AVG(qc.brc_compliance_score), 0)) as details,
    100 - ROUND(AVG(qc.brc_compliance_score), 0) as severity,
    'Quality audit required' as action
FROM quality_control qc
JOIN production_batches pb ON qc.batch_id = pb.batch_id
WHERE qc.inspection_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY pb.plant_location
HAVING AVG(qc.brc_compliance_score) < 90
LIMIT 2;

-- Part 4: High Wastage
SELECT 
    'High Wastage' as issue_type,
    CONCAT(pb.plant_location, ' - ', w.wastage_type, ': ₹', ROUND(SUM(w.cost_impact_inr) / 100000, 2), 'L') as details,
    ROUND(SUM(w.cost_impact_inr) / 100000, 0) as severity,
    'Process improvement needed' as action
FROM wastage_tracking w
JOIN production_batches pb ON w.batch_id = pb.batch_id
WHERE w.wastage_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY pb.plant_location, w.wastage_type
HAVING SUM(w.cost_impact_inr) > 100000
ORDER BY SUM(w.cost_impact_inr) DESC
LIMIT 2;

-- ============================================================================
-- SECTION 12: ADVANCED ANALYTICS
-- ============================================================================
-- Query 27: Cohort Analysis - Customer Retention
-- Business Value: Understand customer lifecycle
WITH first_purchase AS (
SELECT
customer_id,
DATE_FORMAT(MIN(order_date), '%Y-%m') as cohort_month,
MIN(order_date) as first_order_date
FROM b2b_orders
GROUP BY customer_id
),
monthly_orders AS (
SELECT
o.customer_id,
DATE_FORMAT(o.order_date, '%Y-%m') as order_month,
SUM(o.total_value_inr) as monthly_revenue
FROM b2b_orders o
GROUP BY o.customer_id, DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
fp.cohort_month,
COUNT(DISTINCT fp.customer_id) as cohort_size,
COUNT(DISTINCT CASE WHEN mo.order_month = fp.cohort_month THEN fp.customer_id END) as month_0,
COUNT(DISTINCT CASE WHEN mo.order_month = DATE_FORMAT(DATE_ADD(fp.first_order_date, INTERVAL 1 MONTH), '%Y-%m') THEN fp.customer_id END) as month_1,
COUNT(DISTINCT CASE WHEN mo.order_month = DATE_FORMAT(DATE_ADD(fp.first_order_date, INTERVAL 3 MONTH), '%Y-%m') THEN fp.customer_id END) as month_3,
COUNT(DISTINCT CASE WHEN mo.order_month = DATE_FORMAT(DATE_ADD(fp.first_order_date, INTERVAL 6 MONTH), '%Y-%m') THEN fp.customer_id END) as month_6,
COUNT(DISTINCT CASE WHEN mo.order_month = DATE_FORMAT(DATE_ADD(fp.first_order_date, INTERVAL 12 MONTH), '%Y-%m') THEN fp.customer_id END) as month_12
FROM first_purchase fp
LEFT JOIN monthly_orders mo ON fp.customer_id = mo.customer_id
WHERE fp.cohort_month >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 24 MONTH), '%Y-%m')
GROUP BY fp.cohort_month
ORDER BY fp.cohort_month DESC;

-- Query 28: Price Elasticity Analysis
-- Business Value: Optimize pricing strategy
WITH price_volume AS (
SELECT
product_sku,
DATE_FORMAT(order_date, '%Y-%m') as month,
AVG(unit_price_inr) as avg_price,
SUM(quantity_kg) as total_volume
FROM b2b_orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY product_sku, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
pm.product_sku,
pm.product_name,
ROUND(MIN(pv.avg_price), 2) as min_price,
ROUND(MAX(pv.avg_price), 2) as max_price,
ROUND(AVG(pv.avg_price), 2) as avg_price,
ROUND(MIN(pv.total_volume), 0) as min_volume_kg,
ROUND(MAX(pv.total_volume), 0) as max_volume_kg,
ROUND(AVG(pv.total_volume), 0) as avg_volume_kg,
ROUND((MAX(pv.avg_price) - MIN(pv.avg_price)) / MIN(pv.avg_price) * 100, 2) as price_variance_percent
FROM product_master pm
JOIN price_volume pv ON pm.product_sku = pv.product_sku
GROUP BY pm.product_sku, pm.product_name
HAVING COUNT(DISTINCT pv.month) >= 6
ORDER BY price_variance_percent DESC;


-- Query 29: Predictive: Next Month's Production Requirement
-- Business Value: Production planning based on trends
WITH monthly_demand AS (
SELECT
product_sku,
DATE_FORMAT(order_date, '%Y-%m') as month,
SUM(quantity_kg) / 1000 as demand_mt
FROM b2b_orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY product_sku, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
pm.product_sku,
pm.product_name,
pm.category,
ROUND(AVG(md.demand_mt), 2) as avg_monthly_demand_mt,
ROUND(MAX(md.demand_mt), 2) as peak_demand_mt,
ROUND(MIN(md.demand_mt), 2) as min_demand_mt,
ROUND(STDDEV(md.demand_mt), 2) as demand_volatility,
-- Forecast next month (avg + 10% buffer)
ROUND(AVG(md.demand_mt) * 1.1, 2) as recommended_production_mt,
-- Raw material needed (assuming 83% conversion)
ROUND(AVG(md.demand_mt) * 1.1 / 0.83, 2) as raw_material_needed_mt
FROM product_master pm
JOIN monthly_demand md ON pm.product_sku = md.product_sku
GROUP BY pm.product_sku, pm.product_name, pm.category
ORDER BY avg_monthly_demand_mt DESC;


-- Query 30: Market Basket Analysis - Products Bought Together
-- Business Value: Cross-selling opportunities
WITH order_combinations AS (
    SELECT 
        o1.customer_id,
        o1.order_date,
        o1.product_sku as product_a,
        o2.product_sku as product_b
    FROM b2b_orders o1
    JOIN b2b_orders o2 
        ON o1.customer_id = o2.customer_id 
        AND o1.order_date = o2.order_date
        AND o1.product_sku < o2.product_sku
    WHERE o1.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
)
SELECT 
    pm1.product_name as product_1,
    pm2.product_name as product_2,
    COUNT(*) as times_bought_together,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM b2b_orders WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)), 2) as occurrence_percent
FROM order_combinations oc
JOIN product_master pm1 ON oc.product_a = pm1.product_sku
JOIN product_master pm2 ON oc.product_b = pm2.product_sku
GROUP BY pm1.product_name, pm2.product_name
HAVING times_bought_together >= 3
ORDER BY times_bought_together DESC
LIMIT 20;
-- ============================================================================
-- BONUS: Data Quality Check Query
-- ============================================================================
-- Query 31: Data Quality Dashboard
SELECT 'Total Farmers' as metric, COUNT(*) as count FROM farmers_master
UNION ALL
SELECT 'Total Products', COUNT(*) FROM product_master
UNION ALL
SELECT 'B2B Customers', COUNT(*) FROM b2b_customers
UNION ALL
SELECT 'Production Batches (Last 30 days)', COUNT(*) 
FROM production_batches 
WHERE production_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
UNION ALL
SELECT 'Pending Payments', COUNT(*)
FROM b2b_orders 
WHERE payment_status IN ('Delayed', 'Pending')
UNION ALL
SELECT 'Low BRC Score Batches', COUNT(*)
FROM quality_control 
WHERE brc_compliance_score < 85 
  AND inspection_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT '✅ All fixed queries loaded successfully!' as status;


