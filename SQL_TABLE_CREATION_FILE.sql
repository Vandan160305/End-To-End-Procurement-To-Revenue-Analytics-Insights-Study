-- Create brand new database
CREATE DATABASE hyfun_analytics
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Switch to it
USE hyfun_analytics;

-- Verify
SELECT DATABASE() AS current_database;

-- ============================================================================
-- HYFUN ANALYTICS - COMPLETE DATABASE SCHEMA
-- Fresh installation with all 12 tables
-- ============================================================================

USE hyfun_analytics;

-- ============================================================================
-- TABLE 1: FARMERS MASTER
-- ============================================================================

CREATE TABLE farmers_master (
    farmer_id VARCHAR(10) PRIMARY KEY,
    farmer_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    farm_size_acres INT NOT NULL,
    contract_start_date DATE NOT NULL,
    experience_years INT NOT NULL,
    contact_number VARCHAR(20),
    bank_account VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_region (region),
    INDEX idx_contract_date (contract_start_date)
) ENGINE=InnoDB;

SELECT 'Table 1/12 created: farmers_master' AS progress;


-- ============================================================================
-- TABLE 2: PRODUCT MASTER
-- ============================================================================

CREATE TABLE product_master (
    product_sku VARCHAR(30) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(20) NOT NULL,
    weight_kg DECIMAL(5,2) NOT NULL,
    cost_price_inr DECIMAL(10,2) NOT NULL,
    b2b_price_inr DECIMAL(10,2) NOT NULL,
    b2c_mrp_inr DECIMAL(10,2) NOT NULL,
    launch_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_launch_date (launch_date)
) ENGINE=InnoDB;

SELECT 'Table 2/12 created: product_master' AS progress;



-- ============================================================================
-- TABLE 3: POTATO PROCUREMENT
-- ============================================================================

CREATE TABLE potato_procurement (
    batch_id VARCHAR(20) PRIMARY KEY,
    farmer_id VARCHAR(10) NOT NULL,
    procurement_date DATE NOT NULL,
    quantity_mt DECIMAL(10,2) NOT NULL,
    variety VARCHAR(20) NOT NULL,
    quality_grade VARCHAR(20) NOT NULL,
    price_per_mt DECIMAL(10,2) NOT NULL,
    moisture_content DECIMAL(5,2),
    defect_percentage DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (farmer_id) REFERENCES farmers_master(farmer_id),
    INDEX idx_procurement_date (procurement_date),
    INDEX idx_farmer_id (farmer_id),
    INDEX idx_quality (quality_grade)
) ENGINE=InnoDB;

SELECT 'Table 3/12 created: potato_procurement' AS progress;


-- ============================================================================
-- TABLE 4: PRODUCTION BATCHES
-- ============================================================================

CREATE TABLE production_batches (
    batch_id VARCHAR(20) PRIMARY KEY,
    production_date DATE NOT NULL,
    product_sku VARCHAR(30) NOT NULL,
    raw_material_used_mt DECIMAL(10,2) NOT NULL,
    finished_goods_mt DECIMAL(10,2) NOT NULL,
    plant_location VARCHAR(50) NOT NULL,
    shift VARCHAR(20) NOT NULL,
    operator_id VARCHAR(10),
    temperature_celsius DECIMAL(5,2),
    processing_time_hours DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_sku) REFERENCES product_master(product_sku),
    INDEX idx_production_date (production_date),
    INDEX idx_product_sku (product_sku),
    INDEX idx_plant (plant_location),
    INDEX idx_shift (shift)
) ENGINE=InnoDB;

SELECT 'Table 4/12 created: production_batches' AS progress;


-- ============================================================================
-- TABLE 5: QUALITY CONTROL
-- ============================================================================

CREATE TABLE quality_control (
    qc_id VARCHAR(15) PRIMARY KEY,
    batch_id VARCHAR(20) NOT NULL,
    inspection_date DATETIME NOT NULL,
    moisture_level DECIMAL(5,2),
    oil_content DECIMAL(5,2),
    defect_rate DECIMAL(5,2),
    brc_compliance_score INT NOT NULL,
    inspector_name VARCHAR(100),
    status VARCHAR(20) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (batch_id) REFERENCES production_batches(batch_id),
    INDEX idx_inspection_date (inspection_date),
    INDEX idx_batch_id (batch_id),
    INDEX idx_status (status),
    INDEX idx_brc_score (brc_compliance_score)
) ENGINE=InnoDB;

SELECT 'Table 5/12 created: quality_control' AS progress;


-- ============================================================================
-- TABLE 6: MACHINE DOWNTIME
-- ============================================================================

CREATE TABLE machine_downtime (
    downtime_id VARCHAR(15) PRIMARY KEY,
    machine_id VARCHAR(20) NOT NULL,
    plant_location VARCHAR(50) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    duration_hours DECIMAL(5,2) NOT NULL,
    reason VARCHAR(50) NOT NULL,
    production_loss_mt DECIMAL(10,2) DEFAULT 0,
    repair_cost_inr DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_machine (machine_id),
    INDEX idx_plant (plant_location),
    INDEX idx_start_time (start_time),
    INDEX idx_reason (reason)
) ENGINE=InnoDB;

SELECT 'Table 6/12 created: machine_downtime' AS progress;


-- ============================================================================
-- TABLE 7: WASTAGE TRACKING
-- ============================================================================

CREATE TABLE wastage_tracking (
    wastage_id VARCHAR(15) PRIMARY KEY,
    batch_id VARCHAR(20) NOT NULL,
    wastage_date DATE NOT NULL,
    wastage_type VARCHAR(50) NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    recovery_possible VARCHAR(3) NOT NULL,
    cost_impact_inr DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (batch_id) REFERENCES production_batches(batch_id),
    INDEX idx_wastage_date (wastage_date),
    INDEX idx_wastage_type (wastage_type),
    INDEX idx_batch_id (batch_id)
) ENGINE=InnoDB;

SELECT 'Table 7/12 created: wastage_tracking' AS progress;


-- ============================================================================
-- TABLE 8: B2B CUSTOMERS
-- ============================================================================

CREATE TABLE b2b_customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    customer_type VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(100),
    onboarding_date DATE NOT NULL,
    credit_limit_inr DECIMAL(15,2) NOT NULL,
    credit_period_days INT NOT NULL,
    primary_contact VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_customer_type (customer_type),
    INDEX idx_country (country),
    INDEX idx_onboarding_date (onboarding_date)
) ENGINE=InnoDB;

SELECT 'Table 8/12 created: b2b_customers' AS progress;


-- ============================================================================
-- TABLE 9: B2B ORDERS
-- ============================================================================

CREATE TABLE b2b_orders (
    order_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    order_date DATE NOT NULL,
    product_sku VARCHAR(30) NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    unit_price_inr DECIMAL(10,2) NOT NULL,
    total_value_inr DECIMAL(15,2) NOT NULL,
    delivery_date DATE NOT NULL,
    payment_status VARCHAR(20) NOT NULL,
    invoice_number VARCHAR(20),
    payment_terms VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES b2b_customers(customer_id),
    FOREIGN KEY (product_sku) REFERENCES product_master(product_sku),
    INDEX idx_order_date (order_date),
    INDEX idx_customer_id (customer_id),
    INDEX idx_product_sku (product_sku),
    INDEX idx_payment_status (payment_status),
    INDEX idx_delivery_date (delivery_date)
) ENGINE=InnoDB;

SELECT 'Table 9/12 created: b2b_orders' AS progress;


-- ============================================================================
-- TABLE 10: EXPORT SHIPMENTS
-- ============================================================================

CREATE TABLE export_shipments (
    shipment_id VARCHAR(15) PRIMARY KEY,
    order_id VARCHAR(15) NOT NULL,
    destination_country VARCHAR(50) NOT NULL,
    shipping_method VARCHAR(30) NOT NULL,
    departure_date DATE NOT NULL,
    arrival_date DATE NOT NULL,
    transit_days INT NOT NULL,
    customs_cleared VARCHAR(10) NOT NULL,
    shipping_cost_inr DECIMAL(15,2) NOT NULL,
    container_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES b2b_orders(order_id),
    INDEX idx_order_id (order_id),
    INDEX idx_destination (destination_country),
    INDEX idx_departure_date (departure_date),
    INDEX idx_customs (customs_cleared)
) ENGINE=InnoDB;

SELECT 'Table 10/12 created: export_shipments' AS progress;



-- ============================================================================
-- TABLE 11: B2C SALES
-- ============================================================================

CREATE TABLE b2c_sales (
    transaction_id VARCHAR(15) PRIMARY KEY,
    sale_date DATE NOT NULL,
    city VARCHAR(50) NOT NULL,
    product_sku VARCHAR(30) NOT NULL,
    quantity_units INT NOT NULL,
    mrp DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    final_price DECIMAL(10,2) NOT NULL,
    channel VARCHAR(30) NOT NULL,
    customer_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_sku) REFERENCES product_master(product_sku),
    INDEX idx_sale_date (sale_date),
    INDEX idx_city (city),
    INDEX idx_product_sku (product_sku),
    INDEX idx_channel (channel),
    INDEX idx_customer_type (customer_type)
) ENGINE=InnoDB;

SELECT 'Table 11/12 created: b2c_sales' AS progress;



-- ============================================================================
-- TABLE 12: REVENUE SUMMARY
-- ============================================================================

CREATE TABLE revenue_summary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    revenue_source VARCHAR(10) NOT NULL,
    product_category VARCHAR(20) NOT NULL,
    revenue_inr DECIMAL(15,2) NOT NULL,
    cogs_inr DECIMAL(15,2) NOT NULL,
    gross_margin_inr DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_date (date),
    INDEX idx_source (revenue_source),
    INDEX idx_category (product_category),
    UNIQUE KEY unique_revenue_entry (date, revenue_source, product_category)
) ENGINE=InnoDB;

SELECT 'Table 12/12 created: revenue_summary' AS progress;



-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT '========================' AS '';
SELECT 'ALL TABLES CREATED!' AS status;
SELECT '========================' AS '';

SELECT 
    table_name,
    table_rows AS estimated_rows
FROM information_schema.tables
WHERE table_schema = 'hyfun_analytics'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT 'Ready for data import!' AS next_step;


USE hyfun_analytics;

-- Quick verification
SELECT 
    'farmers_master' AS table_name, COUNT(*) AS records FROM farmers_master
UNION ALL
SELECT 'product_master', COUNT(*) FROM product_master
UNION ALL
SELECT 'potato_procurement', COUNT(*) FROM potato_procurement
UNION ALL
SELECT 'production_batches', COUNT(*) FROM production_batches
UNION ALL
SELECT 'quality_control', COUNT(*) FROM quality_control
UNION ALL
SELECT 'machine_downtime', COUNT(*) FROM machine_downtime
UNION ALL
SELECT 'wastage_tracking', COUNT(*) FROM wastage_tracking
UNION ALL
SELECT 'b2b_customers', COUNT(*) FROM b2b_customers
UNION ALL
SELECT 'b2b_orders', COUNT(*) FROM b2b_orders
UNION ALL
SELECT 'export_shipments', COUNT(*) FROM export_shipments
UNION ALL
SELECT 'b2c_sales', COUNT(*) FROM b2c_sales
UNION ALL
SELECT 'revenue_summary', COUNT(*) FROM revenue_summary;

