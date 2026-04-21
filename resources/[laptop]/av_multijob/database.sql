CREATE TABLE IF NOT EXISTS `player_groups` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `group` VARCHAR(50) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `grade` TINYINT(3) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;