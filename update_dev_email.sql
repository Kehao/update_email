DROP PROCEDURE IF EXISTS update_dev_email;
DELIMITER //

CREATE PROCEDURE update_dev_email(
  IN _tableName VARCHAR(64),
  IN _pageIndex INT,
  IN _pageSize  INT
)
BEGIN

DECLARE startRow INTEGER DEFAULT 1;
SET startRow = _pageSize * (_pageIndex - 1);

-- users mail
IF(_tableName = 'users' ) THEN
  CREATE TABLE IF NOT EXISTS `updated_users` LIKE `users`;
  SET @updateUsersSql=CONCAT(" INSERT INTO updated_users(",
                      " uid, name, pass, salt, hash_version, mail, mode, sort, threshold, theme,",
                      " signature, created, access, login, status, timezone, language, locale_name, picture, init, source)",
                      " SELECT uid, name, pass, salt, hash_version,CONCAT('ps-',uid,'@',SUBSTRING_INDEX(mail, '@', -1)) as mail, mode, sort, threshold, theme,",
                      " signature, created, access, login,status, timezone, language, locale_name, picture, init, source",
                      " FROM users",
                      " LIMIT ",startRow,",",_pageSize);

  PREPARE updateUsersStmt FROM @updateUsersSql;
  EXECUTE updateUsersStmt;
  DEALLOCATE PREPARE updateUsersStmt;
  COMMIT;
END IF;

-- email_subscriptions email
IF(_tableName = 'email_subscriptions' ) THEN
CREATE TABLE IF NOT EXISTS `updated_email_subscriptions` LIKE `email_subscriptions`;
SET @updateEmailSubscriptionsSql=CONCAT(" INSERT INTO updated_email_subscriptions(",
                      " id, email, list_id, mail_type, unsub, sub_date, unsub_date, utm_source, utm_medium, utm_content,",
                      " utm_term, utm_campaign, remote_addr, last_engaged, timestamp)",
                      " SELECT id, CONCAT('ps-',id,'@',SUBSTRING_INDEX(email, '@', -1)) as email, list_id, mail_type, unsub, sub_date, unsub_date, utm_source, utm_medium, utm_content,",
                      " utm_term, utm_campaign, remote_addr, last_engaged,timestamp",
                      " FROM email_subscriptions",
                      " LIMIT ",startRow,",",_pageSize);

PREPARE updateEmailSubscriptionsStmt FROM @updateEmailSubscriptionsSql;
EXECUTE updateEmailSubscriptionsStmt;
DEALLOCATE PREPARE updateEmailSubscriptionsStmt;
COMMIT;
END IF;

-- email_subscriptions_global email
IF(_tableName = 'email_subscriptions_global' ) THEN
CREATE TABLE IF NOT EXISTS `updated_email_subscriptions_global` LIKE `email_subscriptions_global`;
SET @updateEmailSubscriptionsGlobalSql=CONCAT(" INSERT INTO updated_email_subscriptions_global(",
                      " id, uid, email, verified, optout, mxerror, mxcount,city, state, zipcode, timezone, country,",
                      " metro_area, timestamp)",
                      " SELECT id, uid, CONCAT('ps-',id,'@',SUBSTRING_INDEX(email, '@', -1)) as email, verified, optout, mxerror, mxcount, city, state, zipcode, timezone, country,",
                      " metro_area, timestamp",
                      " FROM email_subscriptions_global",
                      " LIMIT ",startRow,",",_pageSize);

PREPARE updateEmailSubscriptionsStmt FROM @updateEmailSubscriptionsGlobalSql;
EXECUTE updateEmailSubscriptionsStmt;
DEALLOCATE PREPARE updateEmailSubscriptionsStmt;
COMMIT;
END IF;

END //
delimiter ;
