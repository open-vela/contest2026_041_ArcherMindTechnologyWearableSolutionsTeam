-- MySQL dump 10.13  Distrib 8.0.35, for Linux (x86_64)
--
-- Host: localhost    Database: elderly_health
-- ------------------------------------------------------
-- Server version	8.0.35

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `admin_audit_logs`
--

DROP TABLE IF EXISTS `admin_audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_audit_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `audit_level` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operator_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operator_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operator_role` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `http_method` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `endpoint` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `module` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resource_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `resource_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resource_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `request_params` json DEFAULT NULL,
  `result_status` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `http_status` smallint DEFAULT NULL,
  `error_code` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `error_message` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration_ms` int DEFAULT NULL,
  `changes` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_aal_operator` (`operator_id`,`created_at`),
  KEY `idx_aal_module_time` (`module`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç®¡ç†å‘˜æ“ä½œå®¡è®¡æ—¥å¿—è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_audit_logs`
--

LOCK TABLES `admin_audit_logs` WRITE;
/*!40000 ALTER TABLE `admin_audit_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `admin_audit_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_login_attempts`
--

DROP TABLE IF EXISTS `admin_login_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_login_attempts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `success` tinyint(1) NOT NULL DEFAULT '0',
  `failure_reason` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `attempted_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ala_username_time` (`username`,`attempted_at`),
  KEY `idx_ala_ip_time` (`source_ip`,`attempted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=122 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç®¡ç†å‘˜ç™»å½•å°è¯•è®°å½•';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_login_attempts`
--

LOCK TABLES `admin_login_attempts` WRITE;
/*!40000 ALTER TABLE `admin_login_attempts` DISABLE KEYS */;
INSERT INTO `admin_login_attempts` VALUES (1,'admin','113.57.23.219',1,'',NULL,'2026-06-29 02:48:18'),(2,'admin','113.57.23.219',1,'',NULL,'2026-06-29 02:53:59'),(3,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:32:05'),(4,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:32:06'),(5,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:32:38'),(6,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:35:55'),(7,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:36:07'),(8,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:36:07'),(9,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:37:01'),(10,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:37:01'),(11,'admin','101.35.231.154',1,'',NULL,'2026-06-29 03:37:40'),(12,'admin','113.57.23.219',1,'',NULL,'2026-06-29 06:20:18'),(13,'admin','101.35.231.154',1,'',NULL,'2026-06-29 06:20:39'),(14,'admin','101.35.231.154',1,'',NULL,'2026-06-29 06:22:01'),(15,'admin','101.35.231.154',1,'',NULL,'2026-06-29 06:22:02'),(16,'admin','101.35.231.154',0,'BAD_PASSWORD',NULL,'2026-06-29 06:26:17'),(17,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:03:43'),(18,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:30:52'),(19,'admin','113.57.23.219',1,'',NULL,'2026-06-29 07:32:21'),(20,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:35:44'),(21,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:36:56'),(22,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:42:49'),(23,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:47:00'),(24,'admin','101.35.231.154',1,'',NULL,'2026-06-29 07:59:07'),(25,'admin','101.35.231.154',1,'',NULL,'2026-06-29 08:01:14'),(26,'admin','101.35.231.154',1,'',NULL,'2026-06-29 08:02:40'),(27,'admin','101.35.231.154',1,'',NULL,'2026-06-29 08:03:28'),(28,'admin','101.35.231.154',1,'',NULL,'2026-06-29 08:07:46'),(29,'admin','101.35.231.154',1,'',NULL,'2026-06-29 08:07:46'),(30,'admin','113.57.23.219',1,'',NULL,'2026-06-29 08:51:53'),(31,'admin','101.35.231.154',1,'',NULL,'2026-06-29 09:33:12'),(32,'admin','101.35.231.154',1,'',NULL,'2026-06-29 09:49:50'),(33,'admin','101.35.231.154',1,'',NULL,'2026-06-29 11:21:51'),(34,'admin','101.35.231.154',1,'',NULL,'2026-06-29 11:26:05'),(35,'admin','101.35.231.154',1,'',NULL,'2026-06-29 11:37:07'),(36,'admin','101.35.231.154',1,'',NULL,'2026-06-29 11:40:46'),(37,'admin','101.35.231.154',1,'',NULL,'2026-06-29 11:53:17'),(38,'admin','172.19.0.1',1,'',NULL,'2026-06-29 11:58:53'),(39,'admin','172.19.0.1',1,'',NULL,'2026-06-29 11:58:53'),(40,'admin','101.35.231.154',1,'',NULL,'2026-06-29 12:38:32'),(41,'admin','101.35.231.154',1,'',NULL,'2026-06-29 12:57:05'),(42,'admin','101.35.231.154',1,'',NULL,'2026-06-29 13:02:51'),(43,'admin','113.57.23.219',1,'',NULL,'2026-06-29 13:23:22'),(44,'admin','101.35.231.154',1,'',NULL,'2026-06-30 01:47:35'),(45,'admin','101.35.231.154',1,'',NULL,'2026-06-30 01:47:36'),(46,'admin','113.57.23.219',1,'',NULL,'2026-06-30 06:37:25'),(47,'admin','113.57.23.219',1,'',NULL,'2026-06-30 06:58:51'),(48,'admin','113.57.23.219',1,'',NULL,'2026-06-30 07:23:17'),(49,'admin','172.19.0.1',0,'BAD_PASSWORD',NULL,'2026-06-30 07:46:34'),(50,'admin','172.19.0.1',0,'BAD_PASSWORD',NULL,'2026-06-30 07:46:35'),(51,'admin','172.19.0.1',0,'BAD_PASSWORD',NULL,'2026-06-30 07:46:51'),(52,'admin','172.19.0.1',1,'',NULL,'2026-06-30 07:47:30'),(53,'admin','172.19.0.1',1,'',NULL,'2026-06-30 07:47:30'),(54,'admin','172.19.0.1',1,'',NULL,'2026-06-30 07:48:21'),(55,'admin','113.57.23.219',1,'',NULL,'2026-06-30 09:18:41'),(56,'admin','113.57.23.219',1,'',NULL,'2026-06-30 10:11:23'),(57,'admin','113.57.23.219',1,'',NULL,'2026-06-30 10:17:16'),(58,'admin','113.57.23.219',1,'',NULL,'2026-06-30 10:21:47'),(59,'admin','113.57.23.219',1,'',NULL,'2026-06-30 10:22:33'),(60,'admin','113.57.23.219',1,'',NULL,'2026-06-30 10:25:36'),(61,'admin','58.19.1.129',1,'',NULL,'2026-06-30 13:26:21'),(62,'admin','58.19.1.129',1,'',NULL,'2026-06-30 13:29:52'),(63,'admin','58.19.1.129',1,'',NULL,'2026-06-30 13:30:13'),(64,'admin','58.19.1.129',1,'',NULL,'2026-06-30 13:32:17'),(65,'admin','58.19.1.129',1,'',NULL,'2026-06-30 13:38:17'),(66,'admin','58.19.1.129',1,'',NULL,'2026-06-30 14:07:07'),(67,'admin','58.19.1.129',1,'',NULL,'2026-06-30 14:09:06'),(68,'admin','58.19.1.129',1,'',NULL,'2026-06-30 14:12:15'),(69,'admin','58.19.1.129',1,'',NULL,'2026-06-30 14:28:49'),(70,'admin','113.57.23.219',1,'',NULL,'2026-07-01 01:25:30'),(71,'admin','113.57.23.219',1,'',NULL,'2026-07-01 01:27:12'),(72,'admin','113.57.23.219',1,'',NULL,'2026-07-01 01:34:24'),(73,'admin','113.57.23.219',1,'',NULL,'2026-07-01 01:59:43'),(74,'admin','113.57.23.219',1,'',NULL,'2026-07-01 02:16:01'),(75,'admin','113.57.23.219',1,'',NULL,'2026-07-01 02:53:50'),(76,'admin','113.57.23.219',1,'',NULL,'2026-07-01 03:43:20'),(77,'admin','113.57.23.219',1,'',NULL,'2026-07-01 06:18:45'),(78,'admin','113.57.23.219',1,'',NULL,'2026-07-01 06:46:27'),(79,'admin','113.57.23.219',1,'',NULL,'2026-07-01 07:37:13'),(80,'admin','113.57.23.219',1,'',NULL,'2026-07-01 07:39:49'),(81,'admin','113.57.23.219',1,'',NULL,'2026-07-01 07:43:48'),(82,'admin','113.57.23.219',1,'',NULL,'2026-07-01 07:45:12'),(83,'admin','113.57.23.219',1,'',NULL,'2026-07-01 07:45:19'),(84,'admin','113.57.23.219',1,'',NULL,'2026-07-01 08:13:18'),(85,'admin','113.57.23.219',1,'',NULL,'2026-07-01 08:19:55'),(86,'admin','113.57.23.219',1,'',NULL,'2026-07-01 08:34:07'),(87,'admin','113.57.23.219',1,'',NULL,'2026-07-01 08:35:39'),(88,'admin','113.57.23.219',1,'',NULL,'2026-07-01 09:02:30'),(89,'admin','113.57.23.219',1,'',NULL,'2026-07-01 09:06:05'),(90,'admin','113.57.23.219',1,'',NULL,'2026-07-01 09:07:14'),(91,'admin','113.57.23.219',1,'',NULL,'2026-07-01 09:10:27'),(92,'admin','58.19.1.129',1,'',NULL,'2026-07-01 13:37:03'),(93,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:46:13'),(94,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:47:07'),(95,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:50:52'),(96,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:53:57'),(97,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:54:39'),(98,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:55:32'),(99,'admin','113.57.23.219',1,'',NULL,'2026-07-02 01:58:03'),(100,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:01:54'),(101,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:05:14'),(102,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:12:16'),(103,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:15:51'),(104,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:20:09'),(105,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:22:30'),(106,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:26:11'),(107,'admin','113.57.23.219',1,'',NULL,'2026-07-02 02:28:36'),(108,'admin','111.183.0.25',1,'',NULL,'2026-07-02 06:25:11'),(109,'admin','113.57.23.219',1,'',NULL,'2026-07-02 07:04:20'),(110,'admin','111.183.0.25',1,'',NULL,'2026-07-02 07:09:30'),(111,'admin','113.57.23.219',1,'',NULL,'2026-07-02 07:26:33'),(112,'admin','113.57.23.219',1,'',NULL,'2026-07-02 08:13:23'),(113,'admin','113.57.23.219',1,'',NULL,'2026-07-02 08:50:40'),(114,'admin','113.57.23.219',1,'',NULL,'2026-07-02 09:04:52'),(115,'admin','113.57.23.219',1,'',NULL,'2026-07-02 09:28:38'),(116,'admin','113.57.23.219',1,'',NULL,'2026-07-02 09:31:24'),(117,'admin','113.57.23.219',1,'',NULL,'2026-07-02 09:53:34'),(118,'admin','113.57.23.219',1,'',NULL,'2026-07-02 10:37:03'),(119,'admin','113.57.23.219',1,'',NULL,'2026-07-02 11:13:37'),(120,'admin','113.57.23.219',1,'',NULL,'2026-07-02 11:48:22'),(121,'admin','113.57.23.219',1,'',NULL,'2026-07-02 11:49:06');
/*!40000 ALTER TABLE `admin_login_attempts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_permissions`
--

DROP TABLE IF EXISTS `admin_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_permissions` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `perm_code` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æƒé™ç ',
  `perm_name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æƒé™åç§°',
  `module` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ‰€å±žæ¨¡å—',
  `action` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ“ä½œ',
  `sensitivity` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LOW' COMMENT 'æ•æ„Ÿçº§',
  `description` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_perms_code` (`perm_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='æƒé™å®šä¹‰è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_permissions`
--

LOCK TABLES `admin_permissions` WRITE;
/*!40000 ALTER TABLE `admin_permissions` DISABLE KEYS */;
INSERT INTO `admin_permissions` VALUES ('5e3b2445-7155-11f1-b8ee-0242ac120011','admin:manage','ç®¡ç†å‘˜ç®¡ç†','admin','manage','CRITICAL',NULL,'2026-06-26 11:51:29'),('5e3b27fb-7155-11f1-b8ee-0242ac120011','admin:read','ç®¡ç†å‘˜æŸ¥çœ‹','admin','read','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b2940-7155-11f1-b8ee-0242ac120011','role:manage','è§’è‰²ç®¡ç†','admin','manage','CRITICAL',NULL,'2026-06-26 11:51:29'),('5e3b29d1-7155-11f1-b8ee-0242ac120011','role:read','è§’è‰²æŸ¥çœ‹','admin','read','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b2a4f-7155-11f1-b8ee-0242ac120011','audit:read','å®¡è®¡æ—¥å¿—æŸ¥çœ‹','admin','read','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7705-7155-11f1-b8ee-0242ac120011','elderly:read','è€äººæ¡£æ¡ˆæŸ¥çœ‹','elderly','read','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b78fa-7155-11f1-b8ee-0242ac120011','elderly:write','è€äººæ¡£æ¡ˆç¼–è¾‘','elderly','write','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7995-7155-11f1-b8ee-0242ac120011','elderly:delete','è€äººæ¡£æ¡ˆåˆ é™¤','elderly','delete','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7a23-7155-11f1-b8ee-0242ac120011','device:read','è®¾å¤‡ä¿¡æ¯æŸ¥çœ‹','device','read','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b7aa7-7155-11f1-b8ee-0242ac120011','device:write','è®¾å¤‡æ³¨å†Œç¼–è¾‘','device','write','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7b29-7155-11f1-b8ee-0242ac120011','device:ota','è®¾å¤‡OTAå‡çº§','device','ota','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7bb7-7155-11f1-b8ee-0242ac120011','device:remote_control','è®¾å¤‡è¿œç¨‹æŽ§åˆ¶','device','remote_control','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7c86-7155-11f1-b8ee-0242ac120011','alarm:read','æŠ¥è­¦æŸ¥çœ‹','alarm','read','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b7d26-7155-11f1-b8ee-0242ac120011','alarm:handle','æŠ¥è­¦å¤„ç†','alarm','handle','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7dca-7155-11f1-b8ee-0242ac120011','alarm:escalate','æŠ¥è­¦å‡çº§','alarm','escalate','CRITICAL',NULL,'2026-06-26 11:51:29'),('5e3b7edc-7155-11f1-b8ee-0242ac120011','alarm:resolve','æŠ¥è­¦è§£å†³','alarm','resolve','HIGH',NULL,'2026-06-26 11:51:29'),('5e3b7f6a-7155-11f1-b8ee-0242ac120011','signin:read','ç­¾åˆ°æŸ¥çœ‹','signin','read','LOW',NULL,'2026-06-26 11:51:29'),('5e3b801e-7155-11f1-b8ee-0242ac120011','signin:proxy','ä»£ç­¾æ“ä½œ','signin','proxy','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b80f1-7155-11f1-b8ee-0242ac120011','patrol:read','å·¡è®¿æŸ¥çœ‹','patrol','read','LOW',NULL,'2026-06-26 11:51:29'),('5e3b81cf-7155-11f1-b8ee-0242ac120011','patrol:write','å·¡è®¿ä»»åŠ¡ç®¡ç†','patrol','write','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b82ba-7155-11f1-b8ee-0242ac120011','report:read','å‘¨æŠ¥æŸ¥çœ‹','report','read','LOW',NULL,'2026-06-26 11:51:29'),('5e3b8389-7155-11f1-b8ee-0242ac120011','report:write','å‘¨æŠ¥ç”Ÿæˆ','report','write','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b845f-7155-11f1-b8ee-0242ac120011','dashboard:read','çœ‹æ¿æŸ¥çœ‹','dashboard','read','LOW',NULL,'2026-06-26 11:51:29'),('5e3b8531-7155-11f1-b8ee-0242ac120011','system:read','ç³»ç»ŸçŠ¶æ€æŸ¥çœ‹','system','read','MEDIUM',NULL,'2026-06-26 11:51:29'),('5e3b860f-7155-11f1-b8ee-0242ac120011','system:manage','ç³»ç»Ÿé…ç½®ç®¡ç†','system','manage','CRITICAL',NULL,'2026-06-26 11:51:29');
/*!40000 ALTER TABLE `admin_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_role_permissions`
--

DROP TABLE IF EXISTS `admin_role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_role_permissions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `permission_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `granted_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `granted_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_perm` (`role_id`,`permission_id`),
  KEY `fk_rp_perm` (`permission_id`),
  CONSTRAINT `fk_rp_perm` FOREIGN KEY (`permission_id`) REFERENCES `admin_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `admin_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=84 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='è§’è‰²æƒé™å…³è”è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_role_permissions`
--

LOCK TABLES `admin_role_permissions` WRITE;
/*!40000 ALTER TABLE `admin_role_permissions` DISABLE KEYS */;
INSERT INTO `admin_role_permissions` VALUES (1,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b2445-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(2,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b27fb-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(3,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7dca-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(4,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7d26-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(5,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7c86-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(6,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7edc-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(7,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b2a4f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(8,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b845f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(9,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7b29-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(10,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7a23-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(11,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7bb7-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(12,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7aa7-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(13,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7995-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(14,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7705-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(15,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b78fa-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(16,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b80f1-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(17,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b81cf-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(18,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b82ba-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(19,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b8389-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(20,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b2940-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(21,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b29d1-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(22,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b801e-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(23,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b7f6a-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(24,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b860f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(25,'5e39ea8b-7155-11f1-b8ee-0242ac120011','5e3b8531-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(32,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b27fb-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(33,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b29d1-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(34,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b2a4f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(35,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7705-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(36,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b78fa-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(37,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7995-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(38,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7a23-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(39,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7aa7-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(40,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7b29-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(41,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7bb7-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(42,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7c86-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(43,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7d26-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(44,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7edc-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(45,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b7f6a-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(46,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b801e-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(47,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b80f1-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(48,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b81cf-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(49,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b82ba-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(50,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b8389-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(51,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b845f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(52,'5e3a1bf1-7155-11f1-b8ee-0242ac120011','5e3b8531-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(63,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b7d26-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(64,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b7c86-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(65,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b845f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(66,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b7a23-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(67,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b7705-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(68,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b80f1-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(69,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b81cf-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(70,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b82ba-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(71,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b801e-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(72,'5e3a1e04-7155-11f1-b8ee-0242ac120011','5e3b7f6a-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(78,'5e3a1ea0-7155-11f1-b8ee-0242ac120011','5e3b7c86-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(79,'5e3a1ea0-7155-11f1-b8ee-0242ac120011','5e3b845f-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(80,'5e3a1ea0-7155-11f1-b8ee-0242ac120011','5e3b7a23-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(81,'5e3a1ea0-7155-11f1-b8ee-0242ac120011','5e3b7705-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(82,'5e3a1ea0-7155-11f1-b8ee-0242ac120011','5e3b82ba-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29'),(83,'5e3a1ea0-7155-11f1-b8ee-0242ac120011','5e3b7f6a-7155-11f1-b8ee-0242ac120011',NULL,'2026-06-26 11:51:29');
/*!40000 ALTER TABLE `admin_role_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_roles`
--

DROP TABLE IF EXISTS `admin_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_roles` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `role_code` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'è§’è‰²ç¼–ç ',
  `role_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'è§’è‰²åç§°',
  `description` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'è§’è‰²æè¿°',
  `is_system` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'æ˜¯å¦ç³»ç»Ÿé¢„ç½®è§’è‰²',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'æ˜¯å¦å¯ç”¨',
  `created_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_roles_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç®¡ç†å‘˜è§’è‰²è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_roles`
--

LOCK TABLES `admin_roles` WRITE;
/*!40000 ALTER TABLE `admin_roles` DISABLE KEYS */;
INSERT INTO `admin_roles` VALUES ('5e39ea8b-7155-11f1-b8ee-0242ac120011','super_admin','è¶…çº§ç®¡ç†å‘˜','ç³»ç»Ÿæœ€é«˜æƒé™ï¼Œç®¡ç†æ‰€æœ‰ç®¡ç†å‘˜å’Œå…¨å±€ç­–ç•¥',1,1,NULL,'2026-06-26 11:51:29','2026-06-26 11:51:29'),('5e3a1bf1-7155-11f1-b8ee-0242ac120011','admin','ç®¡ç†å‘˜','æ—¥å¸¸ç®¡ç†æƒé™ï¼Œå«å…¨éƒ¨ä¸šåŠ¡è¿è¥',1,1,NULL,'2026-06-26 11:51:29','2026-06-26 11:51:29'),('5e3a1e04-7155-11f1-b8ee-0242ac120011','operator','è¿è¥äººå‘˜','æŠ¥è­¦å¤„ç†ã€ç­¾åˆ°ç›‘ç£ã€å·¡è®¿æ‰§è¡Œ',1,1,NULL,'2026-06-26 11:51:29','2026-06-26 11:51:29'),('5e3a1ea0-7155-11f1-b8ee-0242ac120011','viewer','åªè¯»è§‚å¯Ÿå‘˜','æŸ¥çœ‹çœ‹æ¿å’ŒæŠ¥è¡¨ï¼Œæ— æ“ä½œæƒé™',1,1,NULL,'2026-06-26 11:51:29','2026-06-26 11:51:29');
/*!40000 ALTER TABLE `admin_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_sessions`
--

DROP TABLE IF EXISTS `admin_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_sessions` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `admin_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `refresh_token_hash` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `access_token_jti` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `device_info` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `last_active_at` timestamp NULL DEFAULT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `revoked_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_as_admin` (`admin_id`),
  KEY `idx_as_status` (`status`,`expires_at`),
  CONSTRAINT `fk_as_admin` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç®¡ç†å‘˜ä¼šè¯è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_sessions`
--

LOCK TABLES `admin_sessions` WRITE;
/*!40000 ALTER TABLE `admin_sessions` DISABLE KEYS */;
INSERT INTO `admin_sessions` VALUES ('008d389c-74ff-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','0464b51f7d5fdfca28609184456c1cf1ba8ce0ac8b582f6ec415123d4e55bf77','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 03:43:19','2026-07-01 11:43:19',NULL,'2026-07-01 06:18:44',NULL),('02fa24e9-7490-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','9d0a5f72aa3299f765e477a15fadcdead73e76cfca96d810470ff3a41fdd6477','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 14:28:49','2026-06-30 22:28:49',NULL,'2026-07-01 01:27:10',NULL),('035039c0-7391-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','75f6959950b37485eb0e6104fbfb3bc952c0b21ef3106af45889c2d7e1c679a5','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 08:03:28','2026-06-29 16:03:28',NULL,'2026-06-29 13:02:56',NULL),('07867c61-73ba-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','d6c374a3ab91f3c57d159f82097adb06f39156705aef0c1937e954c560631afd','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 12:57:05','2026-06-29 20:57:05',NULL,'2026-06-29 13:02:56',NULL),('07d1fed7-760c-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','52265aa445f7e0edb7efc0006548dce84dd9d65810a6c68a2f0e6a135c55d639','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'active','2026-07-02 11:49:06','2026-07-02 19:49:06',NULL,NULL,NULL),('08b58ad5-746e-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','a4c7345e7eacf82f7151955f74f17521febddb06f5d962f9b3cdecc4fd979b63','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 10:25:36','2026-06-30 18:25:36',NULL,'2026-06-30 13:26:20',NULL),('0a56c219-7520-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','e8a9f833dc7fa8590ba0d08b4fba1e7e78cfb8d344c77e8edf75f71b66ac6b6c','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-07-01 07:39:49','2026-07-01 15:39:49',NULL,'2026-07-01 07:43:46',NULL),('0c6cf550-746c-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','90be9d6987ad592908f25c93cae65238015d46bcfe6a75b272a7a33983fdff48','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 10:11:23','2026-06-30 18:11:23',NULL,'2026-06-30 10:17:15',NULL),('1125f769-7458-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','109728a159ad42cc1ec6b9837f1bc76bd7c542ccc61f4447e443b974cc67b8e8','jti','172.19.0.1','curl/7.81.0',NULL,'revoked','2026-06-30 07:48:21','2026-06-30 15:48:21',NULL,'2026-06-30 09:18:39',NULL),('12d4a7b8-7607-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','e9301cf24498aa23c81cde835b027301d1f6465ed82640549d131042aac1419b','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 11:13:37','2026-07-02 19:13:37',NULL,'2026-07-02 11:49:05',NULL),('161b7c72-75f5-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','756591f05cbbd9e1dbb2c81b89bd34333cbd7e7aa86f8ac76b4c6e39612d7480','jti','113.57.23.219','PostmanRuntime/7.54.0',NULL,'revoked','2026-07-02 09:04:52','2026-07-02 17:04:52',NULL,'2026-07-02 09:28:37',NULL),('169df98d-74f8-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','8e73a8ec792111338f7e0e22054c0d8866f03128ee3fe352fe45f9aec5aa0fda','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 02:53:50','2026-07-01 10:53:50',NULL,'2026-07-01 03:43:18',NULL),('17362add-752c-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','aeb6a6e1b70070e6708f2fd88efb2ba7301b5b764d505ff3311e2184c49e6f50','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 09:06:05','2026-07-01 17:06:05',NULL,'2026-07-01 09:10:26',NULL),('19b8b301-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','96a8a82c7e7bfff72ece9cd51535f21b8502e5b7f7dc85e64c6c9fc24fb41f87','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 03:32:05','2026-06-29 11:32:05',NULL,'2026-06-29 13:02:56',NULL),('1a04356c-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','a282edd732b4eda8a35539985bd86cfafdca8a50db38938b87853bc99bc85f70','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 03:32:06','2026-06-29 11:32:06',NULL,'2026-06-29 13:02:56',NULL),('1aa3e117-75f3-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','8250a0f0e80b1a316722a87f6b75422a25bc427c60987d5ca51c0709f1ab602c','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 08:50:40','2026-07-02 16:50:40',NULL,'2026-07-02 09:28:37',NULL),('1bd76ecf-75b9-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','c1ec28bd94509991ac6a58f88cf67ddb6e3555beaba123b2d8044be1901be221','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0',NULL,'revoked','2026-07-02 01:55:32','2026-07-02 09:55:32',NULL,'2026-07-02 01:57:23',NULL),('1ca257a3-7488-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','6699454522bc7537c8c6095dadcb2704fc6e5c74219bbc66920d0696e81f5882','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 13:32:16','2026-06-30 21:32:16',NULL,'2026-06-30 13:38:15',NULL),('1e48fc7c-73b1-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','32b2fd3b7fa50c9c9d2fc4f66b97ef29cc67495a886f3540a4e29543b8b0d109','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 11:53:17','2026-06-29 19:53:17',NULL,'2026-06-29 13:02:56',NULL),('20917c21-738e-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','82b8c0a0b263f85bb1a3e82024363801ba40b9d87def9bd409e2dd555ae5c7ea','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 07:42:49','2026-06-29 15:42:49',NULL,'2026-06-29 13:02:56',NULL),('237333dc-738d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','093ea45787c8ffa38373efa6ebf234dac3f60722f3fc182fee12606d00169f32','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 07:35:44','2026-06-29 15:35:44',NULL,'2026-06-29 13:02:56',NULL),('26840420-7451-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','7e3e57c180bfb7863bbffe704cd4556957008d53821669cd433500c29bba6c90','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 06:58:51','2026-06-30 14:58:51',NULL,'2026-06-30 09:18:39',NULL),('285ccc68-744e-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','7203d4d35cfca8c705332fc5a714d23d3cd1cc8b304d20a7ee9239b4b738378b','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 06:37:25','2026-06-30 14:37:25',NULL,'2026-06-30 09:18:39',NULL),('2d156bab-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','9063521759c9010d145cd16f2e101aed054726dad06009b3e699cdb3ba194c10','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 03:32:38','2026-06-29 11:32:38',NULL,'2026-06-29 13:02:56',NULL),('3f716475-75e4-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','53a0e39c0e8425f29e0692f1e793d3053acde7075207f4dda41d140c55897376','jti','113.57.23.219','PostmanRuntime/7.54.0',NULL,'revoked','2026-07-02 07:04:20','2026-07-02 15:04:20',NULL,'2026-07-02 08:50:38',NULL),('40b088ce-752c-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','31adec26533fac29948baedd229093f0da22e28e965e9ce1c6dfb7a227355541','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-01 09:07:14','2026-07-01 17:07:14',NULL,'2026-07-01 09:10:26',NULL),('41873f6b-748d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0e047e39831173940f50fa409ce49ebc9ca8ec92493b4b14cb658a4ed840b6c8','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 14:09:06','2026-06-30 22:09:06',NULL,'2026-06-30 14:12:13',NULL),('48f163b2-7487-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','da79cb9baf4bbbb495b792a0ec5986021ebd0c97a85632583199f9f55f439d32','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 13:26:21','2026-06-30 21:26:21',NULL,'2026-06-30 13:29:50',NULL),('4e7882d8-738d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','8364406018ce87060ccd4b05de4f312f9c8a26fd340383c8d10b5920b09fb612','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 07:36:56','2026-06-29 15:36:56',NULL,'2026-06-29 13:02:56',NULL),('5154527f-73ad-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','38e603b9b38390c149a9e18e1a323724253822ae431fdfb0c384ea19511fc99d','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 11:26:05','2026-06-29 19:26:05',NULL,'2026-06-29 13:02:56',NULL),('5a2895ea-75e7-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','6fa87f5fc7fec1371c3ff5c1deac2e4c1945c70775f8c07c30ca1fe08e29d632','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 07:26:33','2026-07-02 15:26:33',NULL,'2026-07-02 08:50:38',NULL),('5e425803-73af-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','204a7d9e7f431cfc00ceef8eb765d04afbbfa90698822bde9b2797cba7a7f38a','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 11:40:46','2026-06-29 19:40:46',NULL,'2026-06-29 13:02:56',NULL),('63dce70a-75bd-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','67697d5b54c52b7e3929ca5240d6204eb81803e2c6be5f876eb8aef63c400bbb','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:26:10','2026-07-02 10:26:10',NULL,'2026-07-02 08:50:38',NULL),('679d624b-7390-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0544273c4a3f635d7667597c7a075bb5cb958d4169028a541077b00663ad2200','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 07:59:07','2026-06-29 15:59:07',NULL,'2026-06-29 13:02:56',NULL),('685b7b37-75f8-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','59fb8c54f35d8ad8c604c87bdf3205c18723f20651fef2a2f7393dab7137363a','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 09:28:38','2026-07-02 17:28:38',NULL,'2026-07-02 09:31:23',NULL),('70422337-73b7-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','5f894506a57400f789838d6efd3e6969d49fa5b70438216b6ca8bf35b89dfd2d','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 12:38:32','2026-06-29 20:38:32',NULL,'2026-06-29 13:02:56',NULL),('7235314e-75bb-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','dab65c6cbff5ffc066e0ef63f28e1b8bfc83b1d358eef08c1bad45179f5f3690','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:12:16','2026-07-02 10:12:16',NULL,'2026-07-02 08:50:38',NULL),('751ba7bd-75b8-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','72413ced975fe428e434ddc69429864af29a9dce4706bc03605a555a3b57ffaa','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 01:50:52','2026-07-02 09:50:52',NULL,'2026-07-02 01:57:23',NULL),('753abbe8-738c-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','1498b35466677cff52301adc3588b9249de755d7c46027680ef400710a9ba09a','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 07:30:52','2026-06-29 15:30:52',NULL,'2026-06-29 13:02:56',NULL),('75c2792a-75b9-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','f7f6c3bf4b441dd5a9b20e2c38f85c075a8b9b05c1766db2eca1d31e73002b0a','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 01:58:03','2026-07-02 09:58:03',NULL,'2026-07-02 08:50:38',NULL),('76d590e4-75ba-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','5951c1c7f0f268d6ed8577673b0700e3e6f36e7c4dc57713117f4b25ead746fd','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:05:14','2026-07-02 10:05:14',NULL,'2026-07-02 08:50:38',NULL),('805e49e3-746d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','64c7bab09e1ff175286218bdf77a4a770d891dd4450857a47d3d1a1e56bda46f','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 10:21:47','2026-06-30 18:21:47',NULL,'2026-06-30 10:22:31',NULL),('8734f62a-74f0-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','d7c0575c52bcc75f949883e484e6f03a8f0d43746b07bcec02bff47ba5e2a8c1','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 01:59:43','2026-07-01 09:59:43',NULL,'2026-07-01 02:15:59',NULL),('8c34ddb1-75bc-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','c9c0fe5857c60e2fc95305c8c1b76c9f0e6f5bdda36c685f59991146e437205e','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:20:09','2026-07-02 10:20:09',NULL,'2026-07-02 08:50:38',NULL),('8c75bd5a-739d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0e16b88737ddcc20626e51c8ea98c6934c2c1b6c82f3ff3017dce6352e85d888','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 09:33:12','2026-06-29 17:33:12',NULL,'2026-06-29 13:02:56',NULL),('90575273-7454-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','b1450f3194b9f5052fcbf264a2cc511c8a9e5c538e1a74d11e72768288bc8a94','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 07:23:17','2026-06-30 15:23:17',NULL,'2026-06-30 09:18:39',NULL),('9595d23a-7518-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','f6710b17444e1fa8c961b5f8aa05cab653402010cbd45f8b5fccf42ed089bcdf','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 06:46:27','2026-07-01 14:46:27',NULL,'2026-07-01 07:37:12',NULL),('97640786-752b-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','aebae62ce92d1a62ac0437e1d8cf762c58b89d176cd49c2a12b3949b703d4d70','jti','113.57.23.219','PostmanRuntime/7.54.0',NULL,'revoked','2026-07-01 09:02:30','2026-07-01 17:02:30',NULL,'2026-07-01 09:06:03',NULL),('989339a8-7520-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','de0e688d6c2272c6e6c448ecbb9dd1a2b8226c917ed030336d984ac4151abb30','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-07-01 07:43:48','2026-07-01 15:43:48',NULL,'2026-07-01 07:45:10',NULL),('99a8384f-7382-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','50a077e2c87a42c0df46eb9ac04958eea1df9bf20a82072611ced6a3f4f556f9','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-29 06:20:18','2026-06-29 14:20:18',NULL,'2026-06-29 13:02:56',NULL),('9b3d2bd0-746d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','05d830dd0047c623a2bb6f059c0ff91d575b6abaf5fc0b7b8e67ef2be09b78f7','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 10:22:32','2026-06-30 18:22:32',NULL,'2026-06-30 10:25:34',NULL),('9ca0bc8c-7391-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','eb67b300f7273c1905fd5b43e88b08c71403c788bed23ba11ef7a558e4f240b6','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 08:07:46','2026-06-29 16:07:46',NULL,'2026-06-29 13:02:56',NULL),('9ce709c5-7391-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','261225f96b53fb1146cfabdd8101ec3fb6196f2b1ccfc8273c206896b50a2588','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 08:07:46','2026-06-29 16:07:46',NULL,'2026-06-29 13:02:56',NULL),('9ff4cad9-7527-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','f0c587a70cb875bad17c8feb61ad00536c31c33ee1554281c7f98449bdc2ee38','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0',NULL,'revoked','2026-07-01 08:34:07','2026-07-01 16:34:07',NULL,'2026-07-01 08:35:38',NULL),('a27f2785-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','1e159419ee91a0866183faac0936ae4889fb91df7d8c0457d1b407b463ee6d23','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 03:35:55','2026-06-29 11:35:55',NULL,'2026-06-29 13:02:56',NULL),('a44956c3-7525-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','340bcf436eab98ef6b0162260bf6df8538c79a5260c16279098d7c6f8888c4f6','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-07-01 08:19:55','2026-07-01 16:19:55',NULL,'2026-07-01 08:35:38',NULL),('a6349196-7382-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','d6111afc790078b2787d5d6fc96c571a51da38d2834cea7f26a949bb4f73f53d','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 06:20:39','2026-06-29 14:20:39',NULL,'2026-06-29 13:02:56',NULL),('a9ce3090-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','c1f722c2a7b6f9d8889fe0ebd18b460f79106df0db2c40ddc0250e94593e526c','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 03:36:07','2026-06-29 11:36:07',NULL,'2026-06-29 13:02:56',NULL),('a9fe03ec-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','37b9c0a0ad71dacb174ce6cbd548f3b5c74181ecb0e02eaeacd7f31d66a32d2d','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 03:36:07','2026-06-29 11:36:07',NULL,'2026-06-29 13:02:56',NULL),('aa720491-738c-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0cf4eb9acf7496b612463de337f01ec6082f60e603a327709c602e00af0247f0','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-29 07:32:21','2026-06-29 15:32:21',NULL,'2026-06-29 13:02:56',NULL),('aa727d87-7388-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','f2fa3d998f47e24474246ab333068a95573ab604087dd19cb1c6dc0b3308b395','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 07:03:43','2026-06-29 15:03:43',NULL,'2026-06-29 13:02:56',NULL),('ab2d9939-7425-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','6081ed3449e4c07f227df4e29f60828599744c4287144c3284969e2eef266c6d','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-30 01:47:35','2026-06-30 09:47:35',NULL,'2026-06-30 09:18:39',NULL),('ab61f1a9-7425-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','f48ea793b03cab75aecb4df1f46a0c6e91bb738c9ed6f07cb4224536889a46b3','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-30 01:47:36','2026-06-30 09:47:36',NULL,'2026-06-30 09:18:39',NULL),('ad5cb5b5-751f-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','ddfd0d6f8bdb0762305cabcf0e75057c79081e57212ff6ab92f95c0ae10f3231','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 07:37:13','2026-07-01 15:37:13',NULL,'2026-07-01 07:43:46',NULL),('af3b6793-7464-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','ceeb23661a06b8acd6da24185e5bb8bf19679679d53883b11dd2484ef7bd749e','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 09:18:41','2026-06-30 17:18:41',NULL,'2026-06-30 10:11:22',NULL),('b251beee-748d-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','1e84c5c892ca82e54365f80fe07ae16c48760fe490fb73635d3cdd14983ebfc3','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 14:12:15','2026-06-30 22:12:15',NULL,'2026-06-30 14:28:48',NULL),('b38183c6-7390-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','76dd6ad2af4e3038f22b049311da472de94f6aa4ad6509997ba4266325cec9a6','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 08:01:14','2026-06-29 16:01:14',NULL,'2026-06-29 13:02:56',NULL),('b39e15b0-752c-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','111edfa2df475f8836795c1298c24a1d2a4eaf2b7c958c0e812131e9b7e975db','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 09:10:27','2026-07-01 17:10:27',NULL,'2026-07-01 13:37:01',NULL),('b3ad269f-73bd-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0bfd31d54a147238c1849d08adcfd0b0c7ba5e1f8272f04b7de6ad49064000d6','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-29 13:23:22','2026-06-29 21:23:22',NULL,'2026-06-30 09:18:39',NULL),('b5f3d7a0-738e-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','ff249d952d46ccd6b133e06aa61d0255b603a285798f7bcaac1ec64b0cebec58','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 07:47:00','2026-06-29 15:47:00',NULL,'2026-06-29 13:02:56',NULL),('b729259a-7514-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','e9edef3f08017c573c010d72a99c5aa5f6108ec3b0d051303680c7ed42ff76cd','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 06:18:45','2026-07-01 14:18:45',NULL,'2026-07-01 06:46:25',NULL),('b7899b99-7524-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','fc31982172191eb3c961e568a75503f613f569ce3d1740b2b6039c8ca565937f','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-07-01 08:13:18','2026-07-01 16:13:18',NULL,'2026-07-01 08:19:53',NULL),('b9e36ac4-73ac-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','f770293d3531d9318e6ed2ce7f2d9dd1038b172482278c58a40374bf8f166c63','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 11:21:51','2026-06-29 19:21:51',NULL,'2026-06-29 13:02:56',NULL),('bab119ee-75bd-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','d1f87ec744ff88d74c51836cba1bb129f1aaccab7b91b5a762073ff2e1c0594c','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:28:36','2026-07-02 10:28:36',NULL,'2026-07-02 08:50:38',NULL),('bfa30db7-74eb-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','7e55190291af52fa6e211849a429ed48018c70d6ad59f3590770a6acfc28138a','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 01:25:30','2026-07-01 09:25:30',NULL,'2026-07-01 01:27:10',NULL),('c6723246-7487-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','53bd9030a0134796ee32f600f1645aebc7a0c16f4ddd34da73bc369e1170dc4d','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 13:29:52','2026-06-30 21:29:52',NULL,'2026-06-30 13:30:11',NULL),('c6e3e9c2-7397-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','8688becabf08952f7a66c7e4e16cbcc57664e0d462bce7c6bceb4253bdb9dd4c','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 NetType/WIFI MicroMessenger/7.0.20.1781(0x6700143B) WindowsWechat(0x63090a13) UnifiedPCWindowsWechat(0xf2541a35) XWEB/20001 Flue',NULL,'revoked','2026-06-29 08:51:53','2026-06-29 16:51:53',NULL,'2026-06-29 13:02:56',NULL),('c7517ad3-7365-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','5f4dfcbb40df2efa64f87320fed947742331e354920c2ad174eefb2567084df9','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-29 02:53:59','2026-06-29 10:53:59',NULL,'2026-06-29 13:02:56',NULL),('c7c1b78b-75de-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','dd1e22d247fdf2bffe462ce894970e192e85f548ae9d7ad1bfa595cc5cca4840','jti','111.183.0.25','okhttp/4.12.0',NULL,'revoked','2026-07-02 06:25:11','2026-07-02 14:25:11',NULL,'2026-07-02 08:50:38',NULL),('ca246633-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','f21b72a60cce59508f6c48885e9c246cb80dcde504ccb46c7530185ff5aa014a','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 03:37:01','2026-06-29 11:37:01',NULL,'2026-06-29 13:02:56',NULL),('ca562758-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','81eb01967a78590aa86a89ae2135a065e30ac12d4dab92d04d4f436eafb445bd','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 03:37:01','2026-06-29 11:37:01',NULL,'2026-06-29 13:02:56',NULL),('caa7d536-7520-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','6037ff1c0afcedd61306c0ffd2ff8a8ce56d2aa1cdaeabc9a18a7f72e0e164a5','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-07-01 07:45:12','2026-07-01 15:45:12',NULL,'2026-07-01 08:07:18',NULL),('cb4b181a-75f8-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','0caf4a4ed1b2db74bdcd778d6305e4bbe774bb87c2459bfc70fab7ee4ef8bc20','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 09:31:24','2026-07-02 17:31:24',NULL,'2026-07-02 09:53:32',NULL),('cdfd19fc-74f2-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','c2ecbca8cb40b5730c9fff2b211e0cb51e278edb9e0c2839c8d37a5b21181670','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 02:16:01','2026-07-01 10:16:01',NULL,'2026-07-01 02:53:48',NULL),('cecf7f52-7520-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','b596b966e7690d301727ded2cbdac50da1885eb00cbd4b3dbe1b14023c5eb89b','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0',NULL,'revoked','2026-07-01 07:45:19','2026-07-01 15:45:19',NULL,'2026-07-01 08:07:18',NULL),('cef269a0-75b7-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','d4b11d847ac0de45162d6f921cff3cf8e01ba2d82c84aba934bbdfc050eccf4b','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 01:46:13','2026-07-02 09:46:13',NULL,'2026-07-02 01:57:23',NULL),('d331baef-7487-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','a1860cbe8f0aaadb7023674d46484d4f66ac806856b926af9b7eb4ee5597f36e','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 13:30:13','2026-06-30 21:30:13',NULL,'2026-06-30 13:32:15',NULL),('d62d1a05-73ba-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','704a02d90318c1a8ca6d4ea819b8906b3c2f7bf2a99b841ccfb00652c342830d','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 13:02:51','2026-06-29 21:02:51',NULL,'2026-06-29 13:02:56',NULL),('d70f18ad-7527-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','075de1d8618d0f389e23adc94a4180e73f0ff2940c6b8c440dc9761c199b0f57','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-07-01 08:35:39','2026-07-01 16:35:39',NULL,'2026-07-01 09:06:03',NULL),('d740a2ab-7382-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','a4557cff443509ab0ac2b10426d4df46b96e46c1a54e4b4d8434be86ccc7651e','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 06:22:01','2026-06-29 14:22:01',NULL,'2026-06-29 13:02:56',NULL),('d78b8ff8-7382-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','06ab3f6f41ac10d1f1f04230f45e02da745005ba41f3bcbf8da2c9863087d2b9','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 06:22:02','2026-06-29 14:22:02',NULL,'2026-06-29 13:02:56',NULL),('dbc8e6b8-73ae-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','e0115f9717d1b80104d7ae3d1c08daf772c194d76eaae5ebf807610ceb942b8a','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 11:37:07','2026-06-29 19:37:07',NULL,'2026-06-29 13:02:56',NULL),('dedad339-746c-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','8d3a8fdd59f22ac7a5a0f69a7edcd38a393cc2907eb24daaecb379daef4cd951','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',NULL,'revoked','2026-06-30 10:17:16','2026-06-30 18:17:16',NULL,'2026-06-30 10:21:46',NULL),('df4604ce-739f-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','3aa58827e0c3107118740f4dd0d5c0babb0e1ff1385ff5428197dfa12fffb9eb','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 09:49:50','2026-06-29 17:49:50',NULL,'2026-06-29 13:02:56',NULL),('e0b77c5a-75bc-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','38c769f1c0979ace38d50dd669707107e2238772e67ee06e9dcae040a62860e0','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:22:30','2026-07-02 10:22:30',NULL,'2026-07-02 08:50:38',NULL),('e19f78e2-736b-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','034e3aed5e1dcfefd2016f449c20f15c4756150f8e95b31ce9368ab954a95ca7','jti','101.35.231.154','curl/7.81.0',NULL,'revoked','2026-06-29 03:37:40','2026-06-29 11:37:40',NULL,'2026-06-29 13:02:56',NULL),('e35d493d-75b8-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','8d2919188372e9c231bd4dff893d8d405572e0d17d6a96b471e1acccf4351013','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 01:53:57','2026-07-02 09:53:57',NULL,'2026-07-02 01:57:23',NULL),('e3d28a17-75fb-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','eafc067c86051c97cfac236ab39010ab7aa0854ec4ed10b8085e2e6c113ea778','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 09:53:34','2026-07-02 17:53:34',NULL,'2026-07-02 11:13:36',NULL),('e51948ab-75ed-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','a0aea12bb059b1b67adf0ff867ed9b453987ca9c02393ea19d5e953a0a2a38a6','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 08:13:23','2026-07-02 16:13:23',NULL,'2026-07-02 08:50:38',NULL),('e6466104-7390-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','5ebe9f6bebe91a9a91c65192e7b8ac0cb00c0238b43c8ff281d314a867f46f03','jti','101.35.231.154','API-Tester/1.0',NULL,'revoked','2026-06-29 08:02:40','2026-06-29 16:02:40',NULL,'2026-06-29 13:02:56',NULL),('e659c9a9-73b1-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','dbda0fa5836c75d6a083cb8e6e23da978ae74b5ac9f038ce978a15d0b448bd16','jti','172.19.0.1','curl/7.81.0',NULL,'revoked','2026-06-29 11:58:53','2026-06-29 19:58:53',NULL,'2026-06-29 13:02:56',NULL),('e68f96ce-73b1-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0ace2e6f467b1e139b9f9cc761eac9ed364ed9b36897e216eb4e157f283db670','jti','172.19.0.1','curl/7.81.0',NULL,'revoked','2026-06-29 11:58:53','2026-06-29 19:58:53',NULL,'2026-06-29 13:02:56',NULL),('ed614e3f-760b-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','46ea0e8cfe2b43a9c5d8d6f75ca13466ba1e7886f30c65452b7028a244aa6263','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 11:48:22','2026-07-02 19:48:22',NULL,'2026-07-02 11:49:05',NULL),('ef28a61e-75b7-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','6436821bed66e9cc2a724654411f5a9f26a0662cca7838fba8b74c86e26e76f5','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 01:47:07','2026-07-02 09:47:07',NULL,'2026-07-02 01:57:23',NULL),('f18cae15-7551-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','6d123b31641dfd4c40be18dac237e5a0541c815dc352d355220d293821f444ab','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 13:37:03','2026-07-01 21:37:03',NULL,'2026-07-02 01:57:23',NULL),('f29d5976-7457-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','334b29860be7a2031dccafa7964c6fe013769c2f3bfb6c57845b5ad648668020','jti','172.19.0.1','curl/7.81.0',NULL,'revoked','2026-06-30 07:47:30','2026-06-30 15:47:30',NULL,'2026-06-30 09:18:39',NULL),('f2ce3b90-7457-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','90588079395d1b208520053b32deb7e116ea6aa8d3e3048168e4788a04e01b5d','jti','172.19.0.1','curl/7.81.0',NULL,'revoked','2026-06-30 07:47:30','2026-06-30 15:47:30',NULL,'2026-06-30 09:18:39',NULL),('f2d5cb04-75bb-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','be13989f2ffaa97e1129ed6e42668e0fd5e8cd220046c11d557ae6b769640314','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:15:51','2026-07-02 10:15:51',NULL,'2026-07-02 08:50:38',NULL),('f359f48f-7488-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','b6bc286f5aec5d6f42b0490204d98d3e84c69a7a3c20efb8721803da809b7eef','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 13:38:17','2026-06-30 21:38:17',NULL,'2026-06-30 14:07:06',NULL),('f6c391dd-7601-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','36f1383d176fdf598c2f6dd45a5d63165237f8b7e0fc5cd0653e6628dd3c7f71','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-02 10:37:03','2026-07-02 18:37:03',NULL,'2026-07-02 11:13:36',NULL),('f85f4540-75e4-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','ed4ed0c4f5fe3288da9e97c6c231fc1f8299e6090f163f061e30d8053007b9ae','jti','111.183.0.25','okhttp/4.12.0',NULL,'revoked','2026-07-02 07:09:30','2026-07-02 15:09:30',NULL,'2026-07-02 08:50:38',NULL),('faea5c4c-748c-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','749fd62fb54aec5c74369f5a8d768c529173287fb8fa9a238e582c4ffa8fea4b','jti','58.19.1.129','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-30 14:07:07','2026-06-30 22:07:07',NULL,'2026-06-30 14:09:04',NULL),('fc26a925-7364-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','e1f00a47fcf9384804b290ffa1f407493352b3fa72e586bbd52518a63cd5d1fa','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-06-29 02:48:18','2026-06-29 10:48:18',NULL,'2026-06-29 13:02:56',NULL),('fc539149-74eb-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','2471687505aaf715c133ca9faa8dd5ba77d8f1934091ae6af22a6a005038e2d9','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 01:27:12','2026-07-01 09:27:12',NULL,'2026-07-01 01:34:22',NULL),('fcb19943-75b8-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','7000286384521e769ff20691608c1e90d01cd95280f10ee7285d3560ec3cb589','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 NetType/WIFI MicroMessenger/7.0.20.1781(0x6700143B) WindowsWechat(0x63090a13) UnifiedPCWindowsWechat(0xf254193e) XWEB/19841 Flue',NULL,'revoked','2026-07-02 01:54:39','2026-07-02 09:54:39',NULL,'2026-07-02 01:57:23',NULL),('fde99e5b-74ec-11f1-8a94-0242ac130003','a3fd193e-72e9-11f1-b8ee-0242ac120011','0bdd22e0101ed66e2ccd3fd92b2dbbc38e14fb67dc630e2af8a0fe5b6601a64a','jti','113.57.23.219','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0',NULL,'revoked','2026-07-01 01:34:24','2026-07-01 09:34:24',NULL,'2026-07-01 01:59:41',NULL),('ffe11d65-75b9-11f1-a296-0242ac130012','a3fd193e-72e9-11f1-b8ee-0242ac120011','233f4bd53d0c47b1f4131988ab11adccbc4f8bb26e47dd04c4d6a50e75097dcb','jti','113.57.23.219','okhttp/4.12.0',NULL,'revoked','2026-07-02 02:01:54','2026-07-02 10:01:54',NULL,'2026-07-02 08:50:38',NULL);
/*!40000 ALTER TABLE `admin_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alarm_handling_logs`
--

DROP TABLE IF EXISTS `alarm_handling_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alarm_handling_logs` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `alarm_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operator_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operator_role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ahl_alarm` (`alarm_id`),
  CONSTRAINT `fk_ahl_alarm` FOREIGN KEY (`alarm_id`) REFERENCES `alarm_records` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alarm_handling_logs`
--

LOCK TABLES `alarm_handling_logs` WRITE;
/*!40000 ALTER TABLE `alarm_handling_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `alarm_handling_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alarm_records`
--

DROP TABLE IF EXISTS `alarm_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alarm_records` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alarm_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alarm_level` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'P2',
  `alarm_source` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'device',
  `vital_snapshot_json` json DEFAULT NULL,
  `location_json` json DEFAULT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `handled_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `handled_at` timestamp NULL DEFAULT NULL,
  `resolved_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `escalated_to` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ar_elderly` (`elderly_id`,`created_at`),
  KEY `idx_ar_level_status` (`alarm_level`,`status`),
  KEY `idx_ar_created` (`created_at`),
  CONSTRAINT `fk_ar_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alarm_records`
--

LOCK TABLES `alarm_records` WRITE;
/*!40000 ALTER TABLE `alarm_records` DISABLE KEYS */;
INSERT INTO `alarm_records` VALUES ('0b3583d9-121f-4fb4-a97e-3e3fb2bd18ac','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-02 11:50:48','2026-07-02 11:51:17'),('1a26ab0d-81ba-4455-a069-4757b86d2401','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 08:48:27','2026-07-01 08:48:47'),('1aefe2b4-a6c1-4c63-8ba5-ead63e1032ea','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 13:38:04','2026-07-01 13:38:17'),('268c7c98-9ccc-43db-a782-4831c0a09c4f','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:10:20','2026-07-01 09:10:47'),('6abf2298-dff6-48ca-945e-f6f67058a32f','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:10:32','2026-07-01 09:10:47'),('6ee302c6-6d3f-48a8-9372-d08302ec9da0','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:10:42','2026-07-01 09:11:17'),('802ab989-40ab-4e4d-965a-35997b62a102','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 13:38:08','2026-07-01 13:38:17'),('8413e242-c9f5-476b-96b6-b595943eb212','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 13:38:33','2026-07-01 13:38:47'),('85b623bb-f605-4b49-930b-771ae64c57c0','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:11:14','2026-07-01 09:11:47'),('85c9dacb-a35d-4a48-ad0e-fefc8e29e0f3','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:10:47','2026-07-01 09:11:17'),('a597c8e4-cb04-4832-88c8-fb2e86d05646','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:10:48','2026-07-01 09:11:17'),('bc8480f1-6077-4b28-bc2c-e84de27edaeb','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 09:10:46','2026-07-01 09:11:17'),('c120092b-175e-446a-a0d7-4bf8503a4199','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 13:38:10','2026-07-01 13:38:17'),('e2fecaf2-8791-4024-9ad2-df7cbb867a8d','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 13:38:09','2026-07-01 13:38:17'),('f3dbda4f-c476-4670-96e9-5af6c5229420','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 08:48:13','2026-07-01 08:48:47'),('f5f3e4c2-8ccb-4615-bb8a-24d047d1cf66','6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,'FALL','P0','device','{\"spo2\": null, \"battery\": null, \"heart_rate\": null, \"temperature\": null}','{\"latitude\": 39.9042, \"longitude\": 116.4074}','FALL','escalated',NULL,NULL,NULL,NULL,'emergency_120','2026-07-01 08:49:26','2026-07-01 08:49:47');
/*!40000 ALTER TABLE `alarm_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `communities`
--

DROP TABLE IF EXISTS `communities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `communities` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_name` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_elderly` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç¤¾åŒºè¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `communities`
--

LOCK TABLES `communities` WRITE;
/*!40000 ALTER TABLE `communities` DISABLE KEYS */;
INSERT INTO `communities` VALUES ('5e4234af-7155-11f1-b8ee-0242ac120011','é˜³å…‰ç¤¾åŒº','XXå¸‚XXåŒºé˜³å…‰è·¯100å·','å¼ ä¸»ä»»','13800001111',0,'2026-06-26 11:51:29','2026-06-26 11:51:29'),('5e423798-7155-11f1-b8ee-0242ac120011','å¹¸ç¦ç¤¾åŒº','XXå¸‚XXåŒºå¹¸ç¦è·¯200å·','æŽä¸»ä»»','13800002222',0,'2026-06-26 11:51:29','2026-06-26 11:51:29'),('5e4238b2-7155-11f1-b8ee-0242ac120011','é•¿å¯¿ç¤¾åŒº','XXå¸‚XXåŒºé•¿å¯¿è·¯300å·','çŽ‹ä¸»ä»»','13800003333',0,'2026-06-26 11:51:29','2026-06-26 11:51:29');
/*!40000 ALTER TABLE `communities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device_heartbeats`
--

DROP TABLE IF EXISTS `device_heartbeats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_heartbeats` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `device_sn` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `battery` int DEFAULT NULL,
  `signal_strength` int DEFAULT NULL,
  `firmware_version` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reported_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dh_sn_time` (`device_sn`,`reported_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_heartbeats`
--

LOCK TABLES `device_heartbeats` WRITE;
/*!40000 ALTER TABLE `device_heartbeats` DISABLE KEYS */;
INSERT INTO `device_heartbeats` VALUES (1,'D20260109',82,3,'2.1.0','2026-06-30 02:54:00'),(2,'D20260109',82,3,'2.1.0','2026-06-30 02:54:09');
/*!40000 ALTER TABLE `device_heartbeats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `devices`
--

DROP TABLE IF EXISTS `devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `devices` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_sn` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'è®¾å¤‡åç§°',
  `device_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'watch',
  `firmware_version` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT '1.0.0',
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'offline',
  `battery` int DEFAULT NULL,
  `signal_strength` int DEFAULT NULL,
  `last_online_at` timestamp NULL DEFAULT NULL,
  `registered_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_devices_sn` (`device_sn`),
  KEY `idx_devices_elderly` (`elderly_id`),
  CONSTRAINT `fk_devices_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='è®¾å¤‡è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devices`
--

LOCK TABLES `devices` WRITE;
/*!40000 ALTER TABLE `devices` DISABLE KEYS */;
INSERT INTO `devices` VALUES ('6b6af9f8-74ff-11f1-a296-0242ac130012','adb3b63d-7463-11f1-8a94-0242ac130003','EH-WATCH-20260103','è®¾å¤‡-EH-WATCH-20260103','BES2700','1.0.0','online',88,5,'2026-07-01 03:47:03','2026-07-01 03:46:19','2026-07-01 03:46:19','2026-07-02 11:06:47'),('70e885ab-74ed-11f1-8a94-0242ac130003','ac13cf0f-7463-11f1-8a94-0242ac130003','EH-WATCH-20260102','è®¾å¤‡-EH-WATCH-20260102','BES2700','1.0.0','online',88,5,'2026-07-01 09:11:51','2026-07-01 01:37:37','2026-07-01 01:37:37','2026-07-02 11:06:47'),('ac2bfc4c-7463-11f1-8a94-0242ac130003','ac13cf0f-7463-11f1-8a94-0242ac130003','EH-WATCH-20260101','è®¾å¤‡-EH-WATCH-20260101','BES2700','1.0.0','online',NULL,NULL,'2026-06-30 10:25:56','2026-06-30 09:11:26','2026-06-30 09:11:26','2026-07-02 11:06:47');
/*!40000 ALTER TABLE `devices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elderly_profiles`
--

DROP TABLE IF EXISTS `elderly_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `elderly_profiles` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `user_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `community_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `community_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ç¤¾åŒºåç§°',
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gender` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'male',
  `birth_date` date DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_contact` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `medical_history_meta` json DEFAULT NULL,
  `allergies_meta` json DEFAULT NULL,
  `medications_meta` json DEFAULT NULL,
  `heart_rate_baseline` double DEFAULT NULL,
  `spo2_baseline` double DEFAULT NULL,
  `temp_baseline` double DEFAULT NULL,
  `care_level` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT 'normal',
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ep_community` (`community_id`),
  KEY `idx_ep_status` (`status`),
  KEY `fk_ep_user` (`user_id`),
  CONSTRAINT `fk_ep_community` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ep_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='è€äººæ¡£æ¡ˆè¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elderly_profiles`
--

LOCK TABLES `elderly_profiles` WRITE;
/*!40000 ALTER TABLE `elderly_profiles` DISABLE KEYS */;
INSERT INTO `elderly_profiles` VALUES ('6b6af9f8-74ff-11f1-a296-0242ac130012',NULL,NULL,NULL,'æµ‹è¯•è€äºº(æ‰‹è¡¨EH-WATCH)','female',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'normal','deleted','2026-07-01 08:47:37','2026-07-02 07:34:36'),('ac13cf0f-7463-11f1-8a94-0242ac130003',NULL,NULL,NULL,'张三','male','1954-03-15','13800138000','å¼ å°æ˜Ž','13900139000','å¹¿ä¸œçœæ·±åœ³å¸‚å—å±±åŒºç§‘æŠ€å›­',NULL,NULL,NULL,NULL,NULL,NULL,'normal','active','2026-06-30 09:11:26','2026-07-01 01:41:15'),('ace72186-7463-11f1-8a94-0242ac130003',NULL,NULL,NULL,'张先生','male','1954-07-02','13800138000','','','湖北省武汉市洪山区',NULL,NULL,NULL,NULL,NULL,NULL,'normal','active','2026-06-30 09:11:27','2026-07-02 11:15:26'),('adb3b63d-7463-11f1-8a94-0242ac130003',NULL,NULL,NULL,'李先生','male','1954-07-02','13800138000','','','湖北省武汉市光谷',NULL,NULL,NULL,NULL,NULL,NULL,'normal','active','2026-06-30 09:11:29','2026-07-02 11:48:47'),('f5d916a8-ef31-4347-96d7-f65180837853','f13b8a80-945f-4ead-a723-560f54a5cf70',NULL,NULL,'喻先生','male','1966-07-02','13800138004','','','湖北省武汉市光谷',NULL,NULL,NULL,NULL,NULL,NULL,'normal','active','2026-07-02 11:49:47','2026-07-02 11:49:53');
/*!40000 ALTER TABLE `elderly_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `family_bindings`
--

DROP TABLE IF EXISTS `family_bindings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `family_bindings` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `relation` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fb_user_elderly` (`user_id`,`elderly_id`),
  KEY `idx_fb_elderly` (`elderly_id`),
  CONSTRAINT `fk_fb_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`),
  CONSTRAINT `fk_fb_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='å®¶åº­ç»‘å®šå…³ç³»è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `family_bindings`
--

LOCK TABLES `family_bindings` WRITE;
/*!40000 ALTER TABLE `family_bindings` DISABLE KEYS */;
/*!40000 ALTER TABLE `family_bindings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `health_reports`
--

DROP TABLE IF EXISTS `health_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `health_reports` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `report_week` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '2026-W25',
  `health_score` int DEFAULT NULL COMMENT '0-100',
  `abnormal_events` int DEFAULT '0',
  `avg_heart_rate` double DEFAULT NULL,
  `avg_spo2` double DEFAULT NULL,
  `total_steps` int DEFAULT NULL,
  `signin_rate` double DEFAULT NULL,
  `trend_summary_json` json DEFAULT NULL,
  `ai_summary` text COLLATE utf8mb4_unicode_ci,
  `suggestions` text COLLATE utf8mb4_unicode_ci,
  `generated_by` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `generated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hr_elderly_week` (`elderly_id`,`report_week`),
  KEY `idx_hr_elderly` (`elderly_id`),
  CONSTRAINT `fk_hr_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `health_reports`
--

LOCK TABLES `health_reports` WRITE;
/*!40000 ALTER TABLE `health_reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `health_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notification_logs`
--

DROP TABLE IF EXISTS `notification_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `recipient_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recipient_type` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notify_channel` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notify_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `external_ref` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sent_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nl_recipient` (`recipient_id`,`created_at`),
  KEY `idx_nl_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification_logs`
--

LOCK TABLES `notification_logs` WRITE;
/*!40000 ALTER TABLE `notification_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `notification_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `patrol_records`
--

DROP TABLE IF EXISTS `patrol_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `patrol_records` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `task_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `staff_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `patrol_type` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'home_visit',
  `patrol_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `health_note` text COLLATE utf8mb4_unicode_ci,
  `mood_score` int DEFAULT NULL COMMENT '1-5',
  `photos_json` json DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'completed',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pr_task` (`task_id`),
  KEY `idx_pr_elderly` (`elderly_id`),
  CONSTRAINT `fk_pr_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`),
  CONSTRAINT `fk_pr_task` FOREIGN KEY (`task_id`) REFERENCES `patrol_tasks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `patrol_records`
--

LOCK TABLES `patrol_records` WRITE;
/*!40000 ALTER TABLE `patrol_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `patrol_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `patrol_tasks`
--

DROP TABLE IF EXISTS `patrol_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `patrol_tasks` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `community_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `task_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'regular',
  `priority` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `assigned_to` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scheduled_date` date DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `note` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pt_elderly` (`elderly_id`),
  KEY `idx_pt_assigned` (`assigned_to`),
  KEY `idx_pt_status` (`status`),
  CONSTRAINT `fk_pt_assigned` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_pt_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `patrol_tasks`
--

LOCK TABLES `patrol_tasks` WRITE;
/*!40000 ALTER TABLE `patrol_tasks` DISABLE KEYS */;
/*!40000 ALTER TABLE `patrol_tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `signin_records`
--

DROP TABLE IF EXISTS `signin_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signin_records` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `signin_method` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'touch',
  `signin_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `proxy_by` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `signin_at` timestamp NULL DEFAULT NULL,
  `signin_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sr_elderly_date` (`elderly_id`,`signin_date`),
  KEY `idx_sr_date` (`signin_date`),
  CONSTRAINT `fk_sr_elderly` FOREIGN KEY (`elderly_id`) REFERENCES `elderly_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `signin_records`
--

LOCK TABLES `signin_records` WRITE;
/*!40000 ALTER TABLE `signin_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `signin_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `system_config`
--

DROP TABLE IF EXISTS `system_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_config` (
  `id` int NOT NULL DEFAULT '1',
  `system_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT 'æ™ºæ…§å…»è€ç…§æŠ¤å¹³å°',
  `signin_start_time` varchar(8) COLLATE utf8mb4_unicode_ci DEFAULT '06:00' COMMENT 'ç­¾åˆ°å¼€å§‹æ—¶é—´',
  `signin_end_time` varchar(8) COLLATE utf8mb4_unicode_ci DEFAULT '10:00' COMMENT 'ç­¾åˆ°æˆªæ­¢æ—¶é—´',
  `signin_reminder_interval` int DEFAULT '30' COMMENT 'ç­¾åˆ°æé†’é—´éš”(åˆ†é’Ÿ)',
  `signin_escalation_timeout` int DEFAULT '60' COMMENT 'ç­¾åˆ°è¶…æ—¶å‡çº§(åˆ†é’Ÿ)',
  `alarm_p0_response_seconds` int DEFAULT '300' COMMENT 'P0æŠ¥è­¦å“åº”æ—¶é™(ç§’)',
  `alarm_p1_escalation_minutes` int DEFAULT '15' COMMENT 'P1æŠ¥è­¦å‡çº§æ—¶é™(åˆ†é’Ÿ)',
  `heart_rate_low` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT '60' COMMENT 'å¿ƒçŽ‡ä¸‹é™',
  `heart_rate_high` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT '100' COMMENT 'å¿ƒçŽ‡ä¸Šé™',
  `blood_oxygen_low` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT '90' COMMENT 'è¡€æ°§ä¸‹é™',
  `temperature_low` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT '36.0' COMMENT 'ä½“æ¸©ä¸‹é™',
  `temperature_high` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT '37.5' COMMENT 'ä½“æ¸©ä¸Šé™',
  `notification_sms` tinyint(1) DEFAULT '1' COMMENT 'çŸ­ä¿¡é€šçŸ¥',
  `notification_phone` tinyint(1) DEFAULT '1' COMMENT 'ç”µè¯é€šçŸ¥',
  `notification_push` tinyint(1) DEFAULT '1' COMMENT 'APPæŽ¨é€',
  `notification_wechat` tinyint(1) DEFAULT '0' COMMENT 'å¾®ä¿¡é€šçŸ¥',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç³»ç»Ÿé…ç½®è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `system_config`
--

LOCK TABLES `system_config` WRITE;
/*!40000 ALTER TABLE `system_config` DISABLE KEYS */;
INSERT INTO `system_config` VALUES (1,'æ™ºæ…§å…»è€ç…§æŠ¤å¹³å°','06:00','10:00',30,60,300,15,'60','100','90','36.0','37.5',1,1,1,0,'2026-07-02 11:06:47');
/*!40000 ALTER TABLE `system_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `username` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'family' COMMENT 'elderly|family|community|admin|super_admin',
  `avatar_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `real_name` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT 'active|disabled|deleted',
  `admin_role_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mfa_secret` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mfa_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `failed_logins` int NOT NULL DEFAULT '0',
  `locked_until` timestamp NULL DEFAULT NULL,
  `password_expire` timestamp NULL DEFAULT NULL,
  `ip_whitelist` text COLLATE utf8mb4_unicode_ci,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_login_ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_username` (`username`),
  UNIQUE KEY `uk_users_phone` (`phone`),
  KEY `idx_users_role` (`role`),
  KEY `idx_users_admin_role` (`admin_role_id`),
  CONSTRAINT `fk_users_admin_role` FOREIGN KEY (`admin_role_id`) REFERENCES `admin_roles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç”¨æˆ·åŸºç¡€è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('a3fd193e-72e9-11f1-b8ee-0242ac120011','admin','$2a$12$7Y1RvQhz8xxVnDnBymeeC.jn62/CsqtlKPM4.F7LpbQh0fU2Ttrl6',NULL,NULL,'super_admin',NULL,'ç³»ç»Ÿç®¡ç†å‘˜','active','5e39ea8b-7155-11f1-b8ee-0242ac120011',NULL,0,0,NULL,NULL,NULL,'2026-07-02 11:49:06','113.57.23.219','2026-06-28 12:05:22','2026-07-02 11:49:06'),('f13b8a80-945f-4ead-a723-560f54a5cf70','elderly_f13b8a80','$2a$12$5/y5szbCw2yZAOEYYsOlV.6N6PfZYw.QOF1rcSPWscH.kWQ/Z74Wa',NULL,NULL,'elderly',NULL,'喻先生','active',NULL,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'2026-07-02 11:49:47','2026-07-02 11:49:47');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vital_signs`
--

DROP TABLE IF EXISTS `vital_signs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vital_signs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `heart_rate` int DEFAULT NULL,
  `spo2` double DEFAULT NULL,
  `temperature` double DEFAULT NULL,
  `steps` int DEFAULT NULL,
  `accel_x` double DEFAULT NULL,
  `accel_y` double DEFAULT NULL,
  `accel_z` double DEFAULT NULL,
  `activity_level` int DEFAULT NULL,
  `posture` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `confidence_hr` double DEFAULT NULL,
  `reported_at` timestamp NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_vs_elderly_time` (`elderly_id`,`reported_at`),
  KEY `idx_vs_device_time` (`device_id`,`reported_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vital_signs`
--

LOCK TABLES `vital_signs` WRITE;
/*!40000 ALTER TABLE `vital_signs` DISABLE KEYS */;
INSERT INTO `vital_signs` VALUES (1,'1','D20260109',72,98,36.5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-06-30 18:20:00','2026-06-30 02:54:33');
/*!40000 ALTER TABLE `vital_signs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vital_signs_hourly`
--

DROP TABLE IF EXISTS `vital_signs_hourly`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vital_signs_hourly` (
  `hour_bucket` date NOT NULL,
  `hour_slot` tinyint NOT NULL COMMENT '0-23',
  `elderly_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `avg_heart_rate` double DEFAULT NULL,
  `max_heart_rate` int DEFAULT NULL,
  `min_heart_rate` int DEFAULT NULL,
  `avg_spo2` double DEFAULT NULL,
  `min_spo2` double DEFAULT NULL,
  `avg_temperature` double DEFAULT NULL,
  `total_steps` int DEFAULT NULL,
  `sample_count` int NOT NULL DEFAULT '0',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`hour_bucket`,`hour_slot`,`elderly_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vital_signs_hourly`
--

LOCK TABLES `vital_signs_hourly` WRITE;
/*!40000 ALTER TABLE `vital_signs_hourly` DISABLE KEYS */;
/*!40000 ALTER TABLE `vital_signs_hourly` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-02 12:08:19
