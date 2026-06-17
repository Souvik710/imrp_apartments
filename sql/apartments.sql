CREATE TABLE IF NOT EXISTS player_apartments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    apartment VARCHAR(50) NOT NULL,
    roomid VARCHAR(100) NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expire_date TIMESTAMP NOT NULL,
    UNIQUE KEY unique_apartment (citizenid, apartment),
    INDEX idx_citizenid (citizenid),
    INDEX idx_expire_date (expire_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER $$
CREATE TRIGGER prevent_duplicate_apartment
BEFORE INSERT ON player_apartments
FOR EACH ROW
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count
    FROM player_apartments
    WHERE citizenid = NEW.citizenid 
    AND apartment = NEW.apartment 
    AND expire_date > NOW();
    
    IF existing_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Player already owns this active apartment';
    END IF;
END$$
DELIMITER ;