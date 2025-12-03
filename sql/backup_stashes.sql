-- Backup script for Burgershot stashes
CREATE TABLE IF NOT EXISTS `burgershot_stashes_backup` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `backup_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `stash_name` VARCHAR(255) NOT NULL,
  `stash_label` VARCHAR(255),
  `item_count` INT(11) DEFAULT 0,
  `total_weight` INT(11) DEFAULT 0,
  `backup_data` LONGTEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Procedure to backup all burgershot stashes
DELIMITER //
CREATE PROCEDURE BackupBurgershotStashes()
BEGIN
  INSERT INTO burgershot_stashes_backup (stash_name, stash_label, item_count, total_weight, backup_data)
  SELECT 
    name as stash_name,
    label as stash_label,
    (SELECT COUNT(*) FROM JSON_TABLE(data, '$[*]' COLUMNS(name VARCHAR(255) PATH '$.name')) AS items) as item_count,
    weight as total_weight,
    data as backup_data
  FROM ox_inventory 
  WHERE name LIKE 'burgershot_%';
END //
DELIMITER ;