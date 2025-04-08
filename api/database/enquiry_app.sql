-- Create the database
CREATE DATABASE IF NOT EXISTS `enquiry_app`;
USE `enquiry_app`;

-- Create the enquiries table
CREATE TABLE IF NOT EXISTS `enquiries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `mobile` varchar(20) NOT NULL,
  `callback_time` datetime DEFAULT NULL,
  `remark` text DEFAULT NULL,
  `package_name` varchar(255) DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT 0.00,
  `paid_amount` decimal(10,2) DEFAULT 0.00,
  `status` varchar(50) NOT NULL DEFAULT 'New',
  `status_color_code` varchar(20) NOT NULL DEFAULT '#FFA500',
  `status_type` varchar(20) NOT NULL DEFAULT 'default',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample data
INSERT INTO `enquiries` (`name`, `mobile`, `callback_time`, `remark`, `package_name`, `total_amount`, `paid_amount`, `status`, `status_color_code`, `status_type`, `created_at`, `updated_at`) VALUES
('John Doe', '1234567890', DATE_ADD(NOW(), INTERVAL 2 MINUTE), '', 'Basic Package', 1000.00, 900.00, 'Callback', '#FFA500', 'timer', NOW(), NOW()),
('Jane Smith', '0987654321', DATE_ADD(NOW(), INTERVAL 3 MINUTE), '', 'Premium Package', 2500.00, 1500.00, 'Callback', '#FFA500', 'timer', NOW(), NOW()),
('Joseph Sam', '9995634455', DATE_ADD(NOW(), INTERVAL 4 MINUTE), 'Test remark for a little lengthy text for try out.', 'Normal Package', 1500.00, 750.00, 'Callback', '#FFA500', 'timer', NOW(), NOW()),
('Sanu Mohan', '9995637722', DATE_ADD(NOW(), INTERVAL 5 MINUTE), 'Test remark for a little lengthy text.', 'Normal Package', 1500.00, 860.00, 'Callback', '#00FF00', 'timer', NOW(), NOW()),
('Anu Nair', '2455637794', DATE_ADD(NOW(), INTERVAL 6 MINUTE), 'Test remark.', 'Basic Package', 1000.00, 870.00, 'Callback', '#FFA500', 'timer', NOW(), NOW());
