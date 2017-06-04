-- Adminer 4.3.1 MySQL dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DROP DATABASE IF EXISTS `cpps`;
CREATE DATABASE `cpps` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `cpps`;

DROP TABLE IF EXISTS `epf`;
CREATE TABLE `epf` (
  `ID` int(11) NOT NULL,
  `isagent` tinyint(1) NOT NULL DEFAULT '1',
  `status` mediumtext NOT NULL,
  `currentpoints` int(10) NOT NULL DEFAULT '20',
  `totalpoints` int(10) NOT NULL DEFAULT '100',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `igloos`;
CREATE TABLE `igloos` (
  `ID` int(11) NOT NULL,
  `igloo` int(10) NOT NULL DEFAULT '1',
  `floor` int(10) NOT NULL DEFAULT '0',
  `music` int(10) NOT NULL DEFAULT '0',
  `furniture` longtext NOT NULL,
  `ownedFurns` longtext NOT NULL,
  `ownedIgloos` longtext NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `igloos` (`ID`, `igloo`, `floor`, `music`, `furniture`, `ownedFurns`, `ownedIgloos`) VALUES
(1,	1,	9,	35,	'136|386|230|2|1,649|530|327|1|5,154|298|325|1|1,643|250|172|1|2,',	'1|136,1|649,1|643,1|154,',	'25|2|6'),
(2,	1,	0,	0,	'',	'',	'');

DROP TABLE IF EXISTS `igloo_contest`;
CREATE TABLE `igloo_contest` (
  `ID` int(11) NOT NULL,
  `username` longtext NOT NULL,
  `signup_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `postcards`;
CREATE TABLE `postcards` (
  `postcardID` int(10) NOT NULL AUTO_INCREMENT,
  `recepient` int(10) NOT NULL,
  `mailerName` char(12) NOT NULL,
  `mailerID` int(10) NOT NULL,
  `notes` char(12) NOT NULL,
  `timestamp` int(8) NOT NULL,
  `postcardType` int(5) NOT NULL,
  `isRead` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`postcardID`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `puffles`;
CREATE TABLE `puffles` (
  `puffleID` int(11) NOT NULL AUTO_INCREMENT,
  `ownerID` int(2) NOT NULL,
  `puffleName` char(10) NOT NULL,
  `puffleType` int(2) NOT NULL,
  `puffleEnergy` int(3) NOT NULL DEFAULT '100',
  `puffleHealth` int(3) NOT NULL DEFAULT '100',
  `puffleRest` int(3) NOT NULL DEFAULT '100',
  `puffleWalking` tinyint(1) NOT NULL DEFAULT '0',
  `lastFedTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`puffleID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `stamps`;
CREATE TABLE `stamps` (
  `ID` int(11) NOT NULL,
  `stamps` longtext NOT NULL,
  `stampbook_cover` longtext NOT NULL,
  `restamps` longtext NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `stamps` (`ID`, `stamps`, `stampbook_cover`, `restamps`) VALUES
(1,	'201|200|199|198|197|14|20',	'4%10%5%6%0|14|193|270|0|3%0|20|330|272|0|5',	''),
(2,	'201|200|199|198|197|14',	'',	'')
ON DUPLICATE KEY UPDATE `ID` = VALUES(`ID`), `stamps` = VALUES(`stamps`), `stampbook_cover` = VALUES(`stampbook_cover`), `restamps` = VALUES(`restamps`);

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `ID` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Penguin ID',
  `username` varchar(15) NOT NULL COMMENT 'Penguin Username',
  `nickname` varchar(15) NOT NULL COMMENT 'Penguin Nickname',
  `password` char(255) NOT NULL COMMENT 'Penguin Password',
  `uuid` varchar(50) NOT NULL COMMENT 'Penguin Universal Unique Identification Key',
  `lkey` char(255) NOT NULL COMMENT 'Penguin Login Key',
  `joindate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Penguin Age',
  `coins` int(11) NOT NULL DEFAULT '5000' COMMENT 'Penguin Coins',
  `inventory` longtext NOT NULL COMMENT 'Penguin Inventory',
  `clothing` longtext NOT NULL COMMENT 'Penguin Clothing',
  `ranking` longtext NOT NULL COMMENT 'Staff ranking',
  `buddies` longtext NOT NULL COMMENT 'Penguin Buddies',
  `ignored` longtext NOT NULL COMMENT 'Penguin Ignored Clients',
  `moderation` longtext NOT NULL COMMENT 'Muting and Banning',
  `invalid_logins` int(3) NOT NULL DEFAULT '0' COMMENT 'Account Hijacking Lock',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

INSERT INTO `users` (`ID`, `username`, `nickname`, `password`, `uuid`, `lkey`, `joindate`, `coins`, `inventory`, `clothing`, `ranking`, `buddies`, `ignored`, `moderation`, `invalid_logins`) VALUES
(1,	'Lynx',	'Lynx',	'$2a$15$TkyGq00I32vgJ5zt9bCNRO0VAT2xANcKm9.9why0.YoL/rx7S5uma',	'fc0e6084-08e8-11e6-b512-3e1d05defe78',	'',	'2016-04-08 00:31:46',	129340,	'221|5011',	'{\"color\":11,\"head\":0,\"face\":0,\"neck\":0,\"body\":221,\"hands\":0,\"feet\":0,\"flag\":0,\"photo\":0}',	'{\"isStaff\": \"1\", \"isMed\": \"0\", \"isMod\": \"0\", \"isAdmin\": \"1\", \"rank\": \"6\"}',	'2|Test,',	'',	'{\"isBanned\": \"0\", \"isMuted\": \"0\"}',	2),
(2,	'Test',	'Test',	'$2a$15$rrTaeBdBNMaFWgjaeL/tbuolm0JEcQ83WTxoovXpYYjCa/vwYwXiO',	'36e9fbb6-0fb3-11e6-a148-3e1d05defe78',	'',	'2016-09-07 01:52:32',	5605,	'',	'{\"color\":0,\"head\":\"429\",\"face\":0,\"neck\":0,\"body\":\"0\",\"hands\":0,\"feet\":0,\"flag\":\"0\",\"photo\":\"0\"}',	'{\"isStaff\": \"0\", \"isMed\": \"0\", \"isMod\": \"0\", \"isAdmin\": \"0\", \"rank\": \"1\"}',	'1|Lynx,',	'',	'{\"isBanned\":\"0\",\"isMuted\":\"0\"}',	1)
ON DUPLICATE KEY UPDATE `ID` = VALUES(`ID`), `username` = VALUES(`username`), `nickname` = VALUES(`nickname`), `password` = VALUES(`password`), `uuid` = VALUES(`uuid`), `lkey` = VALUES(`lkey`), `joindate` = VALUES(`joindate`), `coins` = VALUES(`coins`), `inventory` = VALUES(`inventory`), `clothing` = VALUES(`clothing`), `ranking` = VALUES(`ranking`), `buddies` = VALUES(`buddies`), `ignored` = VALUES(`ignored`), `moderation` = VALUES(`moderation`), `invalid_logins` = VALUES(`invalid_logins`);

-- 2017-05-21 01:13:54
