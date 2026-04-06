
CREATE TABLE IF NOT EXISTS `character_oil` (
  `charId` varchar(50) NOT NULL,
  `controller` text NOT NULL DEFAULT json_object(),
  `blending` text NOT NULL DEFAULT json_object(),
  `fuel86` int(11) NOT NULL DEFAULT 0,
  `fuel89` int(11) NOT NULL DEFAULT 0,
  `fuel92` int(11) NOT NULL DEFAULT 0,
  `fuel95` int(11) NOT NULL DEFAULT 0,
  `normal` int(11) DEFAULT 0,
  `premium` int(11) DEFAULT 0,
  PRIMARY KEY (`charId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE `gas_stations` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(50) NOT NULL DEFAULT '0' COLLATE 'utf8_general_ci',
	`money` INT(11) NOT NULL DEFAULT '0',
	`created` DATE NULL DEFAULT curdate(),
	`tablet` VARCHAR(255) NULL DEFAULT json_object() COLLATE 'utf8_general_ci',
	`fuelpump` VARCHAR(255) NULL DEFAULT json_object() COLLATE 'utf8_general_ci',
	`price` INT(11) NULL DEFAULT '0',
	`pedcoords` VARCHAR(255) NULL DEFAULT json_object() COLLATE 'utf8_general_ci',
	PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE IF NOT EXISTS `gas_stations_employees` (
  `station` int(11) DEFAULT NULL,
  `charId` varchar(50) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `grade` tinyint(1) DEFAULT NULL,
  UNIQUE KEY `id` (`station`,`charId`) USING BTREE,
  KEY `station` (`station`),
  CONSTRAINT `FK__gas_stations` FOREIGN KEY (`station`) REFERENCES `gas_stations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE IF NOT EXISTS `gas_stations_logs` (
  `station` int(11) DEFAULT NULL,
  `text` text DEFAULT NULL,
  `employee` varchar(255) DEFAULT NULL,
  `log_type` varchar(50) DEFAULT NULL,
  `date` date DEFAULT curdate(),
  KEY `FK_gas_stations_logs_gas_stations` (`station`),
  CONSTRAINT `FK_gas_stations_logs_gas_stations` FOREIGN KEY (`station`) REFERENCES `gas_stations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE IF NOT EXISTS `gas_stations_pumps` (
  `pumpId` int(11) NOT NULL AUTO_INCREMENT,
  `station` int(11) DEFAULT NULL,
  `x` float DEFAULT NULL,
  `y` float DEFAULT NULL,
  `z` float DEFAULT NULL,
  `w` float DEFAULT NULL,
  `price` text DEFAULT json_object(),
  `upgrade` tinyint(4) DEFAULT 1,
  PRIMARY KEY (`pumpId`),
  KEY `FK_gas_stations_pumps_gas_stations` (`station`),
  CONSTRAINT `FK_gas_stations_pumps_gas_stations` FOREIGN KEY (`station`) REFERENCES `gas_stations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE IF NOT EXISTS `gas_stations_tanks` (
  `tankId` int(11) NOT NULL AUTO_INCREMENT,
  `station` int(11) DEFAULT NULL,
  `fuelType` tinyint(4) DEFAULT 86,
  `amount` int(11) DEFAULT 0,
  `upgrade` tinyint(4) DEFAULT 1,
  PRIMARY KEY (`tankId`),
  KEY `FK_gas_stations_tanks_gas_stations` (`station`),
  CONSTRAINT `FK_gas_stations_tanks_gas_stations` FOREIGN KEY (`station`) REFERENCES `gas_stations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `oil_rig` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charId` varchar(50) NOT NULL DEFAULT '0',
  `x` float NOT NULL DEFAULT 0,
  `y` float NOT NULL DEFAULT 0,
  `z` float NOT NULL DEFAULT 0,
  `w` float NOT NULL DEFAULT 0,
  `speed` tinyint(4) NOT NULL DEFAULT 0,
  `temp` int(11) NOT NULL DEFAULT 0,
  `normal` int(11) NOT NULL DEFAULT 0,
  `premium` int(11) NOT NULL DEFAULT 0,
  `lastused` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;