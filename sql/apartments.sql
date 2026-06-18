-- ================================================================
-- IMRP Apartments - Database Schema
-- Author: Ragna | Immortal Roleplay
-- Run this SQL before starting the resource for the first time.
-- Tables are also auto-created on resource start.
-- ================================================================

CREATE TABLE IF NOT EXISTS `apartments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `apartment_id` VARCHAR(100) NOT NULL UNIQUE,
    `apartment_name` VARCHAR(100) NOT NULL,
    `apartment_type` VARCHAR(50) NOT NULL,
    `bucket_id` INT NOT NULL,
    `purchase_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expire_date` DATETIME NOT NULL,
    `purchase_type` VARCHAR(20) NOT NULL DEFAULT 'buy',
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_apartment_name` (`apartment_name`),
    INDEX `idx_expire_date` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `apartment_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `apartment_id` VARCHAR(100) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `key_type` VARCHAR(20) NOT NULL DEFAULT 'permanent',
    `granted_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_apartment_id` (`apartment_id`),
    INDEX `idx_citizenid` (`citizenid`),
    UNIQUE KEY `unique_key` (`apartment_id`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `apartment_guests` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `apartment_id` VARCHAR(100) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `invited_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_apartment_id` (`apartment_id`),
    INDEX `idx_citizenid` (`citizenid`),
    UNIQUE KEY `unique_guest` (`apartment_id`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `apartment_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `apartment_id` VARCHAR(100) DEFAULT NULL,
    `action` VARCHAR(100) NOT NULL,
    `details` TEXT DEFAULT NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
