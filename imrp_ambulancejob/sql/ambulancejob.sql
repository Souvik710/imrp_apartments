-- =========================================================
-- IMRP Ambulance Job - Database Schema
-- Framework: QBX Core | Author: Ragna
-- Server: IMMORTAL ROLEPLAY
-- =========================================================

-- -----------------------------------------------------------
-- EMS Patients - Tracks patient injury/medical records
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_patients` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `injuries` LONGTEXT DEFAULT NULL,
    `blood_level` INT NOT NULL DEFAULT 100,
    `pain_level` INT NOT NULL DEFAULT 0,
    `is_dead` TINYINT(1) NOT NULL DEFAULT 0,
    `last_treated_by` VARCHAR(50) DEFAULT NULL,
    `last_treated_at` TIMESTAMP NULL DEFAULT NULL,
    `insurance_type` VARCHAR(20) DEFAULT NULL,
    `insurance_expires` TIMESTAMP NULL DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_citizenid` (`citizenid`),
    INDEX `idx_insurance` (`insurance_type`, `insurance_expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- EMS Reports - Medical reports filed by EMS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_id` VARCHAR(50) NOT NULL,
    `author_citizenid` VARCHAR(50) NOT NULL,
    `author_name` VARCHAR(100) NOT NULL,
    `patient_citizenid` VARCHAR(50) NOT NULL,
    `patient_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `injuries_found` LONGTEXT DEFAULT NULL,
    `treatment_given` LONGTEXT DEFAULT NULL,
    `diagnosis` TEXT DEFAULT NULL,
    `outcome` VARCHAR(50) DEFAULT 'treated',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_report_id` (`report_id`),
    INDEX `idx_patient` (`patient_citizenid`),
    INDEX `idx_author` (`author_citizenid`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- EMS Calls - Dispatch / emergency calls
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_calls` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `call_id` VARCHAR(50) NOT NULL,
    `caller_citizenid` VARCHAR(50) DEFAULT NULL,
    `caller_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `call_type` VARCHAR(50) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `location` VARCHAR(255) DEFAULT NULL,
    `coords_x` FLOAT DEFAULT NULL,
    `coords_y` FLOAT DEFAULT NULL,
    `coords_z` FLOAT DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `responding_units` INT NOT NULL DEFAULT 0,
    `assigned_to` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `responded_at` TIMESTAMP NULL DEFAULT NULL,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uk_call_id` (`call_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- EMS Insurance - Patient insurance records
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_insurance` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `insurance_type` VARCHAR(20) NOT NULL DEFAULT 'basic',
    `discount_percent` INT NOT NULL DEFAULT 25,
    `purchased_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY `uk_citizen_insurance` (`citizenid`, `is_active`),
    INDEX `idx_expires` (`expires_at`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- EMS Logs - Activity / duty logs
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `action` VARCHAR(100) NOT NULL,
    `details` TEXT DEFAULT NULL,
    `target_citizenid` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_action` (`action`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- EMS Staff - Staff roster / extra data
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_staff` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `rank` INT NOT NULL DEFAULT 0,
    `rank_label` VARCHAR(50) NOT NULL DEFAULT 'Trainee EMT',
    `callsign` VARCHAR(20) DEFAULT NULL,
    `specialization` VARCHAR(50) DEFAULT NULL,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_duty` TIMESTAMP NULL DEFAULT NULL,
    `total_hours` FLOAT NOT NULL DEFAULT 0,
    `total_treatments` INT NOT NULL DEFAULT 0,
    `total_revives` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY `uk_citizenid` (`citizenid`),
    INDEX `idx_rank` (`rank`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- EMS Billing - Treatment billing records
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ems_billing` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `bill_id` VARCHAR(50) NOT NULL,
    `patient_citizenid` VARCHAR(50) NOT NULL,
    `patient_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `ems_citizenid` VARCHAR(50) NOT NULL,
    `ems_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `amount` INT NOT NULL DEFAULT 0,
    `original_amount` INT NOT NULL DEFAULT 0,
    `discount_applied` INT NOT NULL DEFAULT 0,
    `reason` VARCHAR(255) NOT NULL DEFAULT 'Medical Treatment',
    `status` VARCHAR(20) NOT NULL DEFAULT 'unpaid',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uk_bill_id` (`bill_id`),
    INDEX `idx_patient` (`patient_citizenid`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
