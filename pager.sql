/*=============================================================================================================
--            Procedure        	:            pager
--            Create Date       :            2015-02-03
--            Description       :            General pager with paging state
--            Call example      :            CALL pager("users","mail","update_dev_email",5000,@totalCount,@pageCount);
--            Session variables :            @countSql,@_totalCount
--=============================================================================================================
--=============================================================================================================*/
DROP PROCEDURE IF EXISTS pager;
DELIMITER //

CREATE PROCEDURE pager(
  IN _tableName   VARCHAR(64),
  IN _desc VARCHAR(64),

  IN _callProcedure VARCHAR(64),
  IN _pageSize    INT,

  OUT _totalCount INT,
  OUT _pageCount  INT
)
BEGIN

DECLARE startRow INTEGER DEFAULT 1;
DECLARE pageIndex INTEGER DEFAULT 1;
DECLARE currentCounter INTEGER DEFAULT 0;

DROP TABLE IF EXISTS `db_pager_status`;
CREATE TABLE IF NOT EXISTS `db_pager_status` (
  `table_name` VARCHAR(64),
  `desc` VARCHAR(64),
  `total_count` INTEGER(11),
  `current_count` INTEGER(11),
  PRIMARY KEY (`table_name`,`desc`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET @countSql = CONCAT('SELECT COUNT(*) INTO @_totalCount FROM ', _tableName);
PREPARE countStmt FROM @countSql;
EXECUTE countStmt;
DEALLOCATE PREPARE countStmt;
SET _totalCount = @_totalCount;
SET _totalCount = 1000;

IF (_totalCount <= _pageSize) THEN
  SET _pageCount = 1;
  SET _pageSize = _totalCount;
ELSE IF (_totalCount % _pageSize > 0) THEN
    SET _pageCount = _totalCount / _pageSize + 1;
  ELSE
    SET _pageCount = _totalCount / _pageSize;
  END IF;
END IF;

WHILE (pageIndex <= _pageCount) DO

  SET @callSql = CONCAT(
                        "CALL ",
                        _callProcedure,
                        "(",
                        "'",_tableName,"',",
                        pageIndex,",",
                        _pageSize,
                        ");"
                        );
  PREPARE callStmt FROM @callSql;
  EXECUTE callStmt;
  DEALLOCATE PREPARE callStmt;

  IF(pageIndex < _pageCount) THEN
    SET currentCounter = pageIndex * _pageSize;
  ELSE
    SET currentCounter = _totalCount;
  END IF;

  SET @statusSql = CONCAT('REPLACE INTO db_pager_status(`table_name`,`desc`,`total_count`,`current_count`)',
  			   ' VALUES(\'',_tableName,'\',\'',_desc,'\',',_totalCount,',',currentCounter,');');

  PREPARE statusStmt FROM @statusSql;
  EXECUTE statusStmt;
  DEALLOCATE PREPARE statusStmt;

  SET pageIndex = pageIndex + 1;

END WHILE;

END //
delimiter ;
