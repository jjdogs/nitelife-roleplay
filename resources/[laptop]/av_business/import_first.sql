CREATE TABLE IF NOT EXISTS `av_items` (
  `job` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `image` longtext DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `weight` varchar(50) DEFAULT NULL,
  `ingredients` longtext DEFAULT NULL,
  `prop` varchar(50) DEFAULT NULL,
  `price` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `av_business` (
  `name` varchar(50) NOT NULL,
  `job` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `data` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `av_society` (
  `job` varchar(50) DEFAULT NULL,
  `money` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `av_billing` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `invoiceid` varchar(100) DEFAULT NULL,
  `customerIdentifier` varchar(100) DEFAULT NULL,
  `customerName` varchar(100) DEFAULT NULL,
  `customerPhone` varchar(100) DEFAULT NULL,
  `senderName` varchar(100) DEFAULT NULL,
  `senderIdentifier` varchar(100) DEFAULT NULL,
  `society` varchar(100) DEFAULT NULL,
  `amount` int(11) DEFAULT 0,
  `title` varchar(100) DEFAULT NULL,
  `description` longtext DEFAULT '{}',
  `issued` varchar(50) DEFAULT NULL,
  `paid` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `av_business_discounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(50) NOT NULL,
  `job` varchar(50) NOT NULL,
  `discount` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `type` enum('percentage','amount') NOT NULL,
  `generated` int(11) NOT NULL,
  `employee` varchar(60) NOT NULL,
  `limit` int(11) DEFAULT NULL,
  `expires` int(11) DEFAULT NULL,
  `redeemed` int(11) DEFAULT 0,
  `enabled` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `job` (`job`),
  KEY `code_index` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE av_items 
ADD COLUMN cashier INT DEFAULT 1;