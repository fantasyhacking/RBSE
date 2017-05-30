<?php

class MySQL {

    public function __construct($arrDatabaseConfig) {
        $this->config = $arrDatabaseConfig;
        $this->connection = new mysqli($arrDatabaseConfig['host'], $arrDatabaseConfig['username'], $arrDatabaseConfig['password'], $arrDatabaseConfig['database']);
    }

    public function checkUsernameExists($strUsername) {
        $resStmt = $this->connection->prepare("SELECT username FROM users WHERE username = ?");
        $resStmt->bind_param('s', $strUsername);
        $resStmt->execute();
        $resStmt->bind_result($existingUsername);
        $resStmt->fetch();
        $resStmt->close();
        if (strtoupper($strUsername) == strtoupper($existingUsername)) {
            return true;
        }
        else {
            return false;
        }
    }

    public function registerPenguin($strUsername, $strPassword, $strUUID) {
        $strClothing = json_encode(array(
            "color" => 1,
            "head" => 0,
            "face" => 0,
            "neck" => 0,
            "body" => 0,
            "hands" => 0,
            "feet" => 0,
            "flag" => 0,
            "photo" => 0
        ));
        $strRanking = json_encode(array(
            "isStaff" => 0,
            "isMed" => 0,
            "isMod" => 0,
            "isAdmin" => 0,
            "rank" => 1
        ));
        $strModeration = json_encode(array(
            "isBanned" => 0,
            "isMuted" => 0
        ));
        $strBasicStamps = join('|', array(
            201,
            200,
            199,
            198,
            197,
            14
        ));
        $strInventory = join('|', array(
            221,
            10123,
            16009,
            7004,
            193
        ));

        $resStmt = $this->connection->prepare("INSERT INTO " . $this->config['tables'][1] . " (username, nickname, password, uuid, clothing, ranking, moderation, inventory) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $resStmt->bind_param('ssssssss', $strUsername, $strUsername, $strPassword, $strUUID, $strClothing, $strRanking, $strModeration, $strInventory);
        $resStmt->execute();
        $resStmt->close();

        $intPengID = $resStmt->insert_id;

        $resStmtTwo = $this->connection->prepare("INSERT INTO " . $this->config['tables'][2] . " (ID) VALUES (?)");
        $resStmtTwo->bind_param('i', $intPengID);
        $resStmtTwo->execute();
        $resStmtTwo->close();

        $resStmtThree = $this->connection->prepare("INSERT INTO " . $this->config['tables'][3] . " (recepient, mailerName, mailerID, timestamp, postcardType) VALUES (?, ?, ?, ?, ?)");
        $mailerName = 'sys';
        $mailerID = 0;
        $timeStamp = time();
        $postcardID = 125;
        $resStmtThree->bind_param('isiii', $intPengID, $mailerName, $mailerID, $timeStamp, $postcardID);
        $resStmtThree->execute();
        $resStmtThree->close();

        $resStmtFour = $this->connection->prepare("INSERT INTO " . $this->config['tables'][4] . " (ID, stamps, restamps) VALUES (?, ?, ?)");
        $resStmtFour->bind_param('iss', $intPengID, $strBasicStamps, $strBasicStamps);
        $resStmtFour->execute();
		$resStmtFour->close();
		
        $resStmtFive = $this->connection->prepare("INSERT INTO " . $this->config['tables'][5] . " (ID) VALUES (?)");
        $resStmtFive->bind_param('i', $intPengID);
        $resStmtFive->execute();
        $resStmtFive->close();

    }

}

?>
