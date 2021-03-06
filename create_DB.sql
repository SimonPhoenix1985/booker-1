SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+02:00";

USE booker;

DROP TABLE IF EXISTS rooms;
CREATE TABLE IF NOT EXISTS rooms
(
idRoom INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
Name VARCHAR(50) NOT NULL,
PRIMARY KEY (idRoom)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS recurrings;
CREATE TABLE IF NOT EXISTS recurrings
(
idRecurring INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
PRIMARY KEY (idRecurring)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS employees;
CREATE TABLE IF NOT EXISTS employees
(
idEmployee INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
Name VARCHAR(50) NOT NULL,
Email VARCHAR(255) NOT NULL,
Password VARCHAR(50) NOT NULL,
IsAdmin TINYINT(1) NOT NULL DEFAULT 0,
SessionId VARCHAR(50) DEFAULT NULL,
PRIMARY KEY (idEmployee)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS appointments;
CREATE TABLE IF NOT EXISTS appointments
(
idAppointment INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
idRoom INT(6) UNSIGNED NOT NULL,
idRecurring INT(6) UNSIGNED NOT NULL,
idEmployee INT(6) UNSIGNED NOT NULL,
Date DATE NOT NULL,
Start TIME NOT NULL,
End TIME NOT NULL,
Description TEXT NOT NULL,
PRIMARY KEY (idAppointment),
FOREIGN KEY (idRoom) REFERENCES rooms (idRoom)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
FOREIGN KEY (idRecurring) REFERENCES recurrings (idRecurring)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
FOREIGN KEY (idEmployee) REFERENCES employees (idEmployee)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

