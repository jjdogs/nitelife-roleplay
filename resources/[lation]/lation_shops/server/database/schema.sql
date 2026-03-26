CREATE TABLE IF NOT EXISTS lation_shops (
    shop_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    title VARCHAR(100) DEFAULT NULL,
    subtitle VARCHAR(255) DEFAULT NULL,
    currency VARCHAR(10) DEFAULT '$',

    balance INT DEFAULT 0,

    blip JSON NOT NULL,
    locations JSON NOT NULL,

    categories JSON NOT NULL,
    payment_methods JSON NOT NULL,
    item_whitelist JSON DEFAULT NULL,
    revenue_shares JSON DEFAULT NULL,

    random_prices_enabled BOOLEAN DEFAULT FALSE,
    random_prices_percentage INT DEFAULT 10,

    operating_hours JSON DEFAULT NULL,
    job_restriction JSON DEFAULT NULL,
    item_requirement JSON DEFAULT NULL,
    hide_all_category BOOLEAN DEFAULT FALSE,

    shop_mode ENUM('buy', 'sell', 'both') DEFAULT 'buy',
    sell_price_percentage TINYINT UNSIGNED DEFAULT NULL,
    sell_payment_source JSON DEFAULT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lation_shops_inventory (
    shop_id VARCHAR(50),
    item_name VARCHAR(50),
    label VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    category VARCHAR(50) DEFAULT NULL,
    icon VARCHAR(255) DEFAULT NULL,
    price INT NOT NULL,
    base_price INT DEFAULT NULL,
    stock INT DEFAULT NULL,
    max_stock INT DEFAULT NULL,
    display_order INT DEFAULT 0,
    metadata JSON DEFAULT NULL,
    license VARCHAR(50) DEFAULT NULL,
    job_restriction JSON DEFAULT NULL,
    sell_price INT DEFAULT NULL,
    sell_enabled TINYINT(1) NOT NULL DEFAULT 1,
    sell_hidden TINYINT(1) NOT NULL DEFAULT 0,
    
    PRIMARY KEY(shop_id, item_name),
    FOREIGN KEY(shop_id) REFERENCES lation_shops(shop_id) ON DELETE CASCADE,
    INDEX(shop_id),
    INDEX(category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lation_shops_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shop_id VARCHAR(50),
    transaction_type ENUM('income', 'expense', 'sell') NOT NULL,
    amount INT DEFAULT 0,
    item_name VARCHAR(50) DEFAULT NULL,
    quantity INT DEFAULT NULL,
    player_id VARCHAR(50) DEFAULT NULL,
    player_name VARCHAR(100) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY(shop_id) REFERENCES lation_shops(shop_id) ON DELETE CASCADE,
    INDEX(shop_id, created_at),
    INDEX(shop_id, transaction_type),
    INDEX(transaction_type),
    INDEX(player_id),
    INDEX(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
