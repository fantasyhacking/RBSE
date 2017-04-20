-- Adminer 4.3.0 MySQL dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

CREATE DATABASE `purecp` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `purecp`;

DROP TABLE IF EXISTS `donations`;
CREATE TABLE `donations` (
  `ID` int(11) NOT NULL,
  `username` longtext NOT NULL,
  `donation` int(11) NOT NULL,
  `donate_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `epf`;
CREATE TABLE `epf` (
  `ID` int(11) NOT NULL,
  `isagent` tinyint(1) NOT NULL DEFAULT '1',
  `status` mediumtext NOT NULL,
  `currentpoints` int(10) NOT NULL DEFAULT '20',
  `totalpoints` int(10) NOT NULL DEFAULT '100',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `epf` (`ID`, `isagent`, `status`, `currentpoints`, `totalpoints`) VALUES
(1,	1,	'1',	3,	100),
(2,	1,	'1',	20,	100);

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
(1,	1,	0,	0,	'',	'',	''),
(2,	1,	0,	0,	'',	'',	'');

DROP TABLE IF EXISTS `igloo_contest`;
CREATE TABLE `igloo_contest` (
  `ID` int(11) NOT NULL,
  `username` longtext NOT NULL,
  `signup_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


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
  PRIMARY KEY (`puffleID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `stamps`;
CREATE TABLE `stamps` (
  `ID` int(11) NOT NULL,
  `stamps` longtext NOT NULL,
  `cover` longtext NOT NULL,
  `restamps` longtext NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `stamps` (`ID`, `stamps`, `cover`, `restamps`) VALUES
(1,	'201|200|199|198|197|14',	'',	''),
(2,	'201|200|199|198|197',	'',	'');

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
(1,	'Lynx',	'Lynx',	'$2a$15$TkyGq00I32vgJ5zt9bCNRO0VAT2xANcKm9.9why0.YoL/rx7S5uma',	'fc0e6084-08e8-11e6-b512-3e1d05defe78',	'',	'2016-04-08 00:31:46',	7770,	'221%106%103%',	'{\"face\":\"0\",\"neck\":\"0\",\"hand\":\"0\",\"color\":\"8\",\"head\":\"0\",\"flag\":\"0\",\"feet\":0,\"body\":\"0\",\"photo\":\"0\"}',	'{\"isStaff\": \"1\", \"isMed\": \"0\", \"isMod\": \"0\", \"isAdmin\": \"1\", \"rank\": \"6\"}',	'',	'',	'{\"isBanned\": \"\", \"isMuted\": \"0\"}',	2),
(2,	'Test',	'Test',	'$2a$15$rrTaeBdBNMaFWgjaeL/tbuolm0JEcQ83WTxoovXpYYjCa/vwYwXiO',	'36e9fbb6-0fb3-11e6-a148-3e1d05defe78',	'',	'2016-09-07 01:52:32',	5765,	'',	'{\"color\":0,\"head\":\"429\",\"neck\":0,\"face\":0,\"flag\":\"0\",\"hand\":\"0\",\"photo\":\"0\",\"feet\":0,\"body\":\"0\"}',	'{\"isStaff\": \"0\", \"isMed\": \"0\", \"isMod\": \"0\", \"isAdmin\": \"0\", \"rank\": \"1\"}',	'',	'',	'{\"isBanned\":\"0\",\"isMuted\":0}',	1);

-- 2017-04-20 02:05:48
