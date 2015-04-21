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
    
    SELECT CONCAT_WS(',', getColision(tempDate, NewStart, NewEnd, idRoom), colision)
    INTO colision;
    
    INSERT INTO appointments (appointments.Date, appointments.Start, appointments.End, appointments.idRecurring, appointments.idRoom, appointments.idEmployee, appointments.Description)
    VALUES (tempDate, NewStart, NewEnd, 0, idRoom, idEmployee, Description);
            
    SELECT LAST_INSERT_ID() 
    INTO idNewRecurring;
    
    UPDATE appointments 
    SET appointments.idRecurring = idNewRecurring
    WHERE appointments.idAppointment = idNewRecurring;
    
    addApp: LOOP
        
        CASE Recurring
        	
            WHEN '' THEN
            	LEAVE addApp;
            
            WHEN 'weekly' THEN
            	SET tempDate = tempDate + INTERVAL 7 DAY;
            
            WHEN 'bi-weekly' THEN
            	SET tempDate = tempDate + INTERVAL 14 DAY;
            
            WHEN 'monthly' THEN
                SET tempDate = tempDate + INTERVAL 1 MONTH;
                
                IF(WEEKDAY(tempDate) = 5 OR WEEKDAY(tempDate) = 6) THEN
                	SET tempDate = tempDate + INTERVAL (7 - WEEKDAY(tempDate)) DAY;
                END IF;
        
        END CASE;
        
        SELECT CONCAT_WS(',', getColision(tempDate, NewStart, NewEnd, idRoom), colision)
        INTO colision;
        
        INSERT INTO appointments (appointments.Date, appointments.Start, appointments.End, appointments.idRecurring, appointments.idRoom, appointments.idEmployee, appointments.Description)
        VALUES (tempDate, NewStart, NewEnd, idNewRecurring, idRoom, idEmployee, Description);
                        
        SET i = i + 1;
    
        IF (i >= Duration) THEN
            LEAVE addApp;
        END IF;
        
    END LOOP addApp;
    
    IF(colision = '') THEN
    
    	SELECT idNewRecurring AS mess, 1 AS result;
        
        COMMIT;
        
    ELSE
    	
        SELECT colision AS mess, 0 AS result;
        
        ROLLBACK;
        
    END IF;
    
END$$

DROP PROCEDURE IF EXISTS `addEmployee`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addEmployee`(IN `Email` VARCHAR(255) CHARSET utf8, IN `Name` VARCHAR(50) CHARSET utf8, IN `Passw` VARCHAR(50) CHARSET utf8, IN `IsAdmin` TINYINT(1) UNSIGNED)
    MODIFIES SQL DATA
    COMMENT '@Email @Name @Password'
BEGIN
	INSERT INTO employees (employees.Email, employees.Name, employees.Password, employees.IsAdmin)
    VALUES (Email, Name, PASSWORD(Passw), IsAdmin);
    
    SELECT LAST_INSERT_ID() AS newId;
END$$

DROP PROCEDURE IF EXISTS `bkr_sessionDestroy`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `bkr_sessionDestroy`(IN `idEmployee` INT(6) UNSIGNED)
    MODIFIES SQL DATA
    COMMENT '@idEmployee'
BEGIN
	UPDATE employees
    SET employees.SessionId = NULL
    WHERE employees.idEmployee = idEmployee;
    
    SELECT ROW_COUNT() AS result;
END$$

DROP PROCEDURE IF EXISTS `bkr_sessionStart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `bkr_sessionStart`(IN `idEmployee` INT(6) UNSIGNED, IN `SessionId` VARCHAR(50) CHARSET utf8)
    MODIFIES SQL DATA
    COMMENT '@idEmployee @SessionId'
BEGIN
	UPDATE employees
    SET employees.SessionId = SessionId
    WHERE employees.idEmployee = idEmployee;
    
    SELECT ROW_COUNT() AS result;
END$$

DROP PROCEDURE IF EXISTS `deleteAppointment`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteAppointment`(IN `idAppn` INT(6) UNSIGNED, IN `isRecurring` BOOLEAN)
    MODIFIES SQL DATA
    COMMENT '@idAppn @isRecurring'
BEGIN
	IF(isRecurring = 0) THEN
		SELECT * 
        FROM appointments AS app
        WHERE (app.Date + INTERVAL app.Start HOUR_SECOND) > NOW()
        	AND app.idAppointment = idAppn;
    ELSE
    	SELECT *
        FROM appointments as app
        WHERE app.idRecurring = (
            					SELECT app.idRecurring 
            					FROM appointments AS app
            					WHERE app.idAppointment = idAppn)
        	AND (app.Date + INTERVAL app.Start HOUR_SECOND) > NOW();
    END IF;
END$$

DROP PROCEDURE IF EXISTS `getAllEmpl`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllEmpl`()
    READS SQL DATA
BEGIN
	SELECT empl.idEmployee, empl.Name, empl.Email, empl.IsAdmin
    FROM employees AS empl;
END$$

DROP PROCEDURE IF EXISTS `getAppnDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAppnDetails`(IN `idAppn` INT(6) UNSIGNED)
    READS SQL DATA
    COMMENT '@idAppn'
BEGIN
	SELECT UNIX_TIMESTAMP(app.Date) AS Date, UNIX_TIMESTAMP(app.Start) AS Start, UNIX_TIMESTAMP(app.End) AS End, app.Description, app.Submitted
    FROM appointments AS app
    WHERE app.idAppointment = idAppn;
END$$

DROP PROCEDURE IF EXISTS `getAppnsByMonthRoom`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAppnsByMonthRoom`(IN `Year` VARCHAR(4) CHARSET utf8, IN `Month` VARCHAR(2) CHARSET utf8, IN `idRoom` INT(6) UNSIGNED)
    READS SQL DATA
    COMMENT '@Year @Month @idRoom'
BEGIN
	SELECT app.idAppointment, app.Date, UNIX_TIMESTAMP(app.Start) AS Start, UNIX_TIMESTAMP(app.End) AS End
    FROM appointments AS app
    WHERE YEAR(app.Date) = Year AND
    	MONTH(app.Date) = Month AND
        app.idRoom = idRoom;
END$$

DROP PROCEDURE IF EXISTS `getEmplByCookie`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getEmplByCookie`(IN `idUser` INT(6) UNSIGNED, IN `SessionId` VARCHAR(50) CHARSET utf8, IN `isAdmin` BOOLEAN)
    READS SQL DATA
    COMMENT '@idUser @SessionId @isAdmin'
BEGIN
	SELECT empl.idEmployee, empl.Name, empl.Email, empl.IsAdmin
    FROM employees AS empl
    WHERE empl.idEmployee = idUser AND
    	empl.SessionId = SessionId AND
        empl.IsAdmin = isAdmin;
END$$

DROP PROCEDURE IF EXISTS `getEmplByEml`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getEmplByEml`(IN `Email` VARCHAR(255) CHARSET utf8)
    READS SQL DATA
    COMMENT '@Email'
BEGIN
	SELECT empl.idEmployee
    FROM employees AS empl
    WHERE empl.Email = Email;
END$$

DROP PROCEDURE IF EXISTS `getEmplByEmlPass`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getEmplByEmlPass`(IN `Email` VARCHAR(255) CHARSET utf8, IN `Passw` VARCHAR(50) CHARSET utf8)
    READS SQL DATA
    COMMENT '@Email @Password'
BEGIN
	SELECT empl.idEmployee, empl.IsAdmin
    FROM employees AS empl
    WHERE empl.Email = Email AND
    	empl.Password = PASSWORD(Passw);
END$$

DROP PROCEDURE IF EXISTS `getRooms`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getRooms`()
    READS SQL DATA
BEGIN
	SELECT rm.idRoom, rm.Name
    FROM rooms AS rm;
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