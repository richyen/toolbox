--
-- Create demo database
--

CREATE DATABASE mysql_demo;
USE mysql_demo;

--
-- Table structure for table `phone_catalog`
--

DROP TABLE IF EXISTS `phone_catalog`;
CREATE TABLE `phone_catalog` (
  `ssn` varchar(255),
  `name` varchar(255) DEFAULT NULL,
  `phone_number` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  PRIMARY KEY (ssn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Data for table `phone_catalog`
--

LOCK TABLES `phone_catalog` WRITE;
INSERT INTO `phone_catalog` VALUES ('543-21-6789','John Doe','559-299-4906','123 Main St., Naperville, IL, 43434');
UNLOCK TABLES;
