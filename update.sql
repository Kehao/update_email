DROP PROCEDURE IF EXISTS update_email;
DELIMITER //
CREATE PROCEDURE update_email()
BEGIN
  SET @@global.sql_mode = "NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION";
  SET @@global.innodb_flush_log_at_trx_commit=0;
  SET @@autocommit=0;

--   users
  DROP TABLE IF EXISTS `updated_users`;
  CALL pager("users","mail","update_dev_email",5000,@totalCount,@pageCount);
  ALTER TABLE users RENAME backup_users;
  ALTER TABLE updated_users RENAME users;

--   email_subscriptions
--   DROP TABLE IF EXISTS `email_subscriptions`;
--   CALL pager("email_subscriptions","email","update_dev_email",5000,@totalCount,@pageCount);
--   ALTER TABLE email_subscriptions RENAME backup_email_subscriptions;
--   ALTER TABLE updated_email_subscriptions RENAME email_subscriptions;

-- -- updated_email_subscriptions_global
--   DROP TABLE IF EXISTS `updated_email_subscriptions_global`;
--   CALL pager("email_subscriptions_global","email","update_dev_email",5000,@totalCount,@pageCount);
--   ALTER TABLE email_subscriptions_global RENAME backup_email_subscriptions_global;
--   ALTER TABLE updated_email_subscriptions_global RENAME email_subscriptions_global;

  SET @@global.innodb_flush_log_at_trx_commit=1;
  SET @@autocommit=1;
END //
delimiter ;