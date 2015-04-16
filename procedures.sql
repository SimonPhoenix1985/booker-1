SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+02:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- База данных: `booker`
--
USE `user10`;

DELIMITER $$
--
-- Процедуры
--
DROP PROCEDURE IF EXISTS `addAppointment`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addAppointment`(IN `NewDate` DATE, IN `NewStart` TIME, IN `NewEnd` TIME, IN `idRoom` INT(6) UNSIGNED, IN `idEmployee` INT(6) UNSIGNED, IN `Description` TEXT CHARSET utf8, IN `Recurring` ENUM('','weekly','bi-weekly','monthly') CHARSET utf8, IN `Duration` INT(1) UNSIGNED)
    MODIFIES SQL DATA
    COMMENT '@Date @Start @End @idRoom @idEmpl @Descr @Recurring @Duration'
BEGIN

    DECLARE idNewRecurring INT(6) UNSIGNED;
    DECLARE tempDate DATE;
    DECLARE i INT(2) UNSIGNED DEFAULT 0;
    DECLARE colision VARCHAR(50);

    SET tempDate = NewDate;

    SET AUTOCOMMIT = 0;

    START TRANSACTION;

    INSERT INTO recurrings
    VALUES (NULL);

    SELECT LAST_INSERT_ID()
    INTO idNewRecurring;

    addApp: LOOP

    	SELECT CONCAT_WS(',', getColision(tempDate, NewStart, NewEnd, idRoom), colision)
        INTO colision;

        INSERT INTO appointments (appointments.Date, appointments.Start, appointments.End, appointments.idRecurring, appointments.idRoom, appointments.idEmployee, appointments.Description)
        VALUES (tempDate, NewStart, NewEnd, idNewRecurring, idRoom, idEmployee, Description);

        CASE Recurring

            WHEN '' THEN
            LEAVE addApp;

            WHEN 'weekly' THEN
            SET tempDate = tempDate + INTERVAL 7 DAY;

            WHEN 'bi-weekly' THEN
            SET tempDate = tempDate + INTERVAL 14 DAY;

            WHEN 'monthly' THEN
            SET tempDate = tempDate + INTERVAL 1 MONTH;

        END CASE;

        SET i = i + 1;

        IF (i >= Duration) THEN
            LEAVE addApp;
        END IF;

    END LOOP addApp;

    SELECT idNewRecurring, colision;

    IF(colision IS NULL) THEN

    	SELECT idNewRecurring;

        COMMIT;

    ELSE

        SELECT colision;

        ROLLBACK;

    END IF;

END$$

DROP PROCEDURE IF EXISTS `addEmployee`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addEmployee`(IN `Email` VARCHAR(255) CHARSET utf8, IN `Name` VARCHAR(50) CHARSET utf8, IN `Passw` VARCHAR(50) CHARSET utf8)
    MODIFIES SQL DATA
    COMMENT '@Email @Name @Password'
BEGIN
	INSERT INTO employees (employees.Email, employees.Name, employees.Password)
    VALUES (Email, Name, PASSWORD(Passw));

    SELECT LAST_INSERT_ID() AS newId;
END$$

--
-- Функции
--
DROP FUNCTION IF EXISTS `getColision`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getColision`(`NewDate` DATE, `NewStart` TIME, `NewEnd` TIME, `idRoom` INT(6) UNSIGNED) RETURNS varchar(15) CHARSET utf8
    READS SQL DATA
    COMMENT '@Date @Start @End @idRoom'
BEGIN
	RETURN (
        SELECT DISTINCT app.Date
        FROM appointments AS app
        WHERE (
            (NewStart <= app.Start AND app.Start < NewEnd) OR
            (NewStart < app.End AND app.End <= NewEnd) OR
            (app.Start <= NewStart AND NewEnd <= app.End) OR
            (NewStart <= app.Start AND app.End <= NewEnd)
            ) AND
            app.Date = NewDate AND
            app.idRoom = idRoom);
END$$

DELIMITER ;

-- --------------------------------------------------------