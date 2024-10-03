/*
Copyright 2019 The Vitess Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

%{
package tiny_parser

//import "fmt"
//import "strings"
//import "runtime/debug"

func setParseTree(yylex interface{}, stmt Statement) {
  yylex.(*Tokenizer).ParseTree = stmt
}

func setAllowComments(yylex interface{}, allow bool) {
  yylex.(*Tokenizer).AllowComments = allow
}

func incNesting(yylex interface{}) bool {
  yylex.(*Tokenizer).nesting++
  if yylex.(*Tokenizer).nesting == 200 {
    return true
  }
  return false
}

func decNesting(yylex interface{}) {
  yylex.(*Tokenizer).nesting--
}

func statementSeen(yylex interface{}) {
  if yylex.(*Tokenizer).stopAfterFirstStmt {
    yylex.(*Tokenizer).stopped = true
  }
}

func yyPosition(yylex interface{}) int {
  return yylex.(*Tokenizer).Position
}

func yyOldPosition(yylex interface{}) int {
  return yylex.(*Tokenizer).OldPosition
}

func yySpecialCommentMode(yylex interface{}) bool {
  tkn := yylex.(*Tokenizer)
  return tkn.specialComment != nil
}

%}

%union {
  empty         struct{}
  statement     Statement
  selStmt       SelectStatement
  ins           *Insert
  byt           byte
  bytes         []byte
  bytes2        [][]byte
  str           string
  int           int
  strs          []string
  selectExprs   SelectExprs
  selectExpr    SelectExpr
  columns       Columns
  exprs         Exprs
  boolVal       BoolVal
  boolean       bool
  sqlVal        *SQLVal
  colTuple      ColTuple
  values        Values
  aliasedvalues AliasedValues
  valTuple      ValTuple
  into		*Into
  colName       *ColName
  tableExprs    TableExprs
  tableExpr     TableExpr
  colIdent 	ColIdent
  tableName	TableName
  expr 		Expr
  tableIdent	TableIdent
}

%token LEX_ERROR

%token <bytes> FOR_SYSTEM_TIME
%token <bytes> FOR_VERSION

// There is no need to define precedence for the JSON
// operators because the syntax is restricted enough that
// they don't cause conflicts.
%token <empty> JSON_EXTRACT_OP JSON_UNQUOTE_EXTRACT_OP

// DDL Tokens
//%token <bytes> CREATE ALTER DROP RENAME ANALYZE ADD ALL MODIFY CHANGE
//%token <bytes> SCHEMA TABLE INDEX INDEXES VIEW TO IGNORE IF PRIMARY COLUMN SPATIAL FULLTEXT KEY_BLOCK_SIZE CHECK
//%token <bytes> ACTION CASCADE CONSTRAINT FOREIGN NO REFERENCES RESTRICT
//%token <bytes> FIRST AFTER LAST
//%token <bytes> SHOW DESCRIBE EXPLAIN DATE ESCAPE REPAIR OPTIMIZE TRUNCATE FORMAT EXTENDED
//%token <bytes> MAXVALUE PARTITION REORGANIZE LESS THAN PROCEDURE TRIGGER TRIGGERS FUNCTION
//%token <bytes> STATUS VARIABLES WARNINGS ERRORS KILL CONNECTION
//%token <bytes> SEQUENCE ENABLE DISABLE
//%token <bytes> EACH ROW BEFORE FOLLOWS PRECEDES DEFINER INVOKER
//%token <bytes> INOUT OUT DETERMINISTIC CONTAINS READS MODIFIES SQL SECURITY TEMPORARY ALGORITHM MERGE TEMPTABLE UNDEFINED
//%token <bytes> EVENT EVENTS SCHEDULE EVERY STARTS ENDS COMPLETION PRESERVE CASCADED
//%token <bytes> INSTANT INPLACE COPY
//%token <bytes> DISCARD IMPORT
//%token <bytes> SHARED EXCLUSIVE
//%token <bytes> WITHOUT VALIDATION
//%token <bytes> COALESCE EXCHANGE REBUILD REMOVE PARTITIONING

// SIGNAL Tokens
//%token <bytes> CLASS_ORIGIN SUBCLASS_ORIGIN MESSAGE_TEXT MYSQL_ERRNO CONSTRAINT_CATALOG CONSTRAINT_SCHEMA
//%token <bytes> CONSTRAINT_NAME CATALOG_NAME SCHEMA_NAME TABLE_NAME COLUMN_NAME CURSOR_NAME SIGNAL RESIGNAL SQLSTATE

// Stored Procedure Tokens
//%token <bytes> DECLARE CONDITION CURSOR CONTINUE EXIT UNDO HANDLER FOUND SQLWARNING SQLEXCEPTION FETCH OPEN CLOSE
//%token <bytes> LOOP LEAVE ITERATE REPEAT UNTIL WHILE DO RETURN

// Permissions Tokens
//%token <bytes> USER IDENTIFIED ROLE REUSE GRANT GRANTS REVOKE NONE ATTRIBUTE RANDOM PASSWORD INITIAL AUTHENTICATION
//%token <bytes> SSL X509 CIPHER ISSUER SUBJECT ACCOUNT EXPIRE NEVER OPTION OPTIONAL ADMIN PRIVILEGES
//%token <bytes> MAX_QUERIES_PER_HOUR MAX_UPDATES_PER_HOUR MAX_CONNECTIONS_PER_HOUR MAX_USER_CONNECTIONS FLUSH
//%token <bytes> FAILED_LOGIN_ATTEMPTS PASSWORD_LOCK_TIME UNBOUNDED REQUIRE PROXY ROUTINE TABLESPACE CLIENT SLAVE
//%token <bytes> EXECUTE FILE RELOAD REPLICATION SHUTDOWN SUPER USAGE LOGS ENGINE ERROR GENERAL HOSTS
//%token <bytes> OPTIMIZER_COSTS RELAY SLOW USER_RESOURCES NO_WRITE_TO_BINLOG CHANNEL

// Dynamic Privilege Tokens
//%token <bytes> APPLICATION_PASSWORD_ADMIN AUDIT_ABORT_EXEMPT AUDIT_ADMIN AUTHENTICATION_POLICY_ADMIN BACKUP_ADMIN
//%token <bytes> BINLOG_ADMIN BINLOG_ENCRYPTION_ADMIN CLONE_ADMIN CONNECTION_ADMIN ENCRYPTION_KEY_ADMIN FIREWALL_ADMIN
//%token <bytes> FIREWALL_EXEMPT FIREWALL_USER FLUSH_OPTIMIZER_COSTS FLUSH_STATUS FLUSH_TABLES FLUSH_USER_RESOURCES
//%token <bytes> GROUP_REPLICATION_ADMIN GROUP_REPLICATION_STREAM INNODB_REDO_LOG_ARCHIVE INNODB_REDO_LOG_ENABLE
//%token <bytes> NDB_STORED_USER PASSWORDLESS_USER_ADMIN PERSIST_RO_VARIABLES_ADMIN REPLICATION_APPLIER
//%token <bytes> REPLICATION_SLAVE_ADMIN RESOURCE_GROUP_ADMIN RESOURCE_GROUP_USER ROLE_ADMIN SENSITIVE_VARIABLES_OBSERVER
//%token <bytes> SESSION_VARIABLES_ADMIN SET_USER_ID SHOW_ROUTINE SKIP_QUERY_REWRITE SYSTEM_VARIABLES_ADMIN
//%token <bytes> TABLE_ENCRYPTION_ADMIN TP_CONNECTION_ADMIN VERSION_TOKEN_ADMIN XA_RECOVER_ADMIN

// Replication Tokens
//%token <bytes> REPLICA REPLICAS SOURCE STOP RESET FILTER LOG MASTER
//%token <bytes> SOURCE_HOST SOURCE_USER SOURCE_PASSWORD SOURCE_PORT SOURCE_CONNECT_RETRY SOURCE_RETRY_COUNT SOURCE_AUTO_POSITION
//%token <bytes> REPLICATE_DO_TABLE REPLICATE_IGNORE_TABLE

// Transaction Tokens
//%token <bytes> BEGIN START TRANSACTION COMMIT ROLLBACK SAVEPOINT WORK RELEASE CHAIN

// Type Tokens
%token <bytes> BIT TINYINT SMALLINT MEDIUMINT INT INTEGER BIGINT INTNUM SERIAL INT1 INT2 INT3 INT4 INT8
%token <bytes> REAL DOUBLE FLOAT_TYPE DECIMAL NUMERIC DEC FIXED PRECISION
%token <bytes> TIME TIMESTAMP DATETIME
%token <bytes> CHAR VARCHAR BOOL CHARACTER VARBINARY NCHAR NVARCHAR NATIONAL VARYING VARCHARACTER
%token <bytes> TEXT TINYTEXT MEDIUMTEXT LONGTEXT LONG
%token <bytes> BLOB TINYBLOB MEDIUMBLOB LONGBLOB JSON ENUM
%token <bytes> GEOMETRY POINT LINESTRING POLYGON GEOMETRYCOLLECTION MULTIPOINT MULTILINESTRING MULTIPOLYGON

// Lock tokens
%token <bytes> LOCAL LOW_PRIORITY SKIP LOCKED

// Type Modifiers
%token <bytes> NULLX AUTO_INCREMENT APPROXNUM SIGNED UNSIGNED ZEROFILL SRID

// Supported SHOW tokens
%token <bytes> COLLATION DATABASES SCHEMAS TABLES FULL PROCESSLIST COLUMNS FIELDS ENGINES PLUGINS

// SET tokens
%token <bytes> NAMES CHARSET GLOBAL SESSION ISOLATION LEVEL READ WRITE ONLY REPEATABLE COMMITTED UNCOMMITTED SERIALIZABLE
%token <bytes> ENCRYPTION

// Functions
%token <bytes> CURRENT_TIMESTAMP NOW DATABASE CURRENT_DATE CURRENT_USER
%token <bytes> CURRENT_TIME LOCALTIME LOCALTIMESTAMP
%token <bytes> UTC_DATE UTC_TIME UTC_TIMESTAMP
%token <bytes> REPLACE
%token <bytes> CONVERT CAST POSITION
%token <bytes> SUBSTR SUBSTRING
%token <bytes> TRIM LEADING TRAILING BOTH
%token <bytes> GROUP_CONCAT SEPARATOR
%token <bytes> TIMESTAMPADD TIMESTAMPDIFF EXTRACT
%token <bytes> GET_FORMAT

// Window functions
%token <bytes> OVER WINDOW GROUPING GROUPS
%token <bytes> CURRENT ROWS RANGE
%token <bytes> AVG BIT_AND BIT_OR BIT_XOR COUNT JSON_ARRAYAGG JSON_OBJECTAGG MAX MIN STDDEV_POP STDDEV STD STDDEV_SAMP
%token <bytes> SUM VAR_POP VARIANCE VAR_SAMP CUME_DIST DENSE_RANK FIRST_VALUE LAG LAST_VALUE LEAD NTH_VALUE NTILE
%token <bytes> ROW_NUMBER PERCENT_RANK RANK

// Table functions
%token <bytes> DUAL JSON_TABLE PATH

// Table options
%token <bytes> AVG_ROW_LENGTH CHECKSUM TABLE_CHECKSUM COMPRESSION DIRECTORY DELAY_KEY_WRITE ENGINE_ATTRIBUTE INSERT_METHOD MAX_ROWS
%token <bytes> MIN_ROWS PACK_KEYS ROW_FORMAT SECONDARY_ENGINE SECONDARY_ENGINE_ATTRIBUTE STATS_AUTO_RECALC STATS_PERSISTENT
%token <bytes> STATS_SAMPLE_PAGES STORAGE DISK MEMORY DYNAMIC COMPRESSED REDUNDANT
%token <bytes> COMPACT LIST HASH PARTITIONS SUBPARTITION SUBPARTITIONS

// Prepared statements
%token <bytes> PREPARE DEALLOCATE

// Match
%token <bytes> MATCH AGAINST BOOLEAN LANGUAGE WITH QUERY EXPANSION

// Time Unit Tokens
%token <bytes> MICROSECOND SECOND MINUTE HOUR DAY WEEK MONTH QUARTER YEAR
%token <bytes> SECOND_MICROSECOND
%token <bytes> MINUTE_MICROSECOND MINUTE_SECOND
%token <bytes> HOUR_MICROSECOND HOUR_SECOND HOUR_MINUTE
%token <bytes> DAY_MICROSECOND DAY_SECOND DAY_MINUTE DAY_HOUR
%token <bytes> YEAR_MONTH

// Spatial Reference System Tokens
%token <bytes> NAME SYSTEM

// MySQL reserved words that are currently unused.
%token <bytes> ACCESSIBLE ASENSITIVE
%token <bytes> CUBE
%token <bytes> DELAYED DISTINCTROW
%token <bytes> EMPTY
%token <bytes> FLOAT4 FLOAT8
%token <bytes> GET
%token <bytes> HIGH_PRIORITY
%token <bytes> INSENSITIVE IO_AFTER_GTIDS IO_BEFORE_GTIDS LINEAR
%token <bytes> MASTER_BIND MASTER_SSL_VERIFY_SERVER_CERT MIDDLEINT
%token <bytes> PURGE
%token <bytes> READ_WRITE RLIKE
%token <bytes> SENSITIVE SPECIFIC SQL_BIG_RESULT SQL_SMALL_RESULT

%token <bytes> UNUSED DESCRIPTION LATERAL MEMBER RECURSIVE
%token <bytes> BUCKETS CLONE COMPONENT DEFINITION ENFORCED NOT_ENFORCED EXCLUDE FOLLOWING GEOMCOLLECTION GET_MASTER_PUBLIC_KEY HISTOGRAM HISTORY
%token <bytes> INACTIVE INVISIBLE MASTER_COMPRESSION_ALGORITHMS MASTER_PUBLIC_KEY_PATH MASTER_TLS_CIPHERSUITES MASTER_ZSTD_COMPRESSION_LEVEL
%token <bytes> NESTED NETWORK_NAMESPACE NOWAIT NULLS OJ OLD ORDINALITY ORGANIZATION OTHERS PERSIST PERSIST_ONLY PRECEDING PRIVILEGE_CHECKS_USER PROCESS
%token <bytes> REFERENCE REQUIRE_ROW_FORMAT RESOURCE RESPECT RESTART RETAIN SECONDARY SECONDARY_LOAD SECONDARY_UNLOAD
%token <bytes> THREAD_PRIORITY TIES VCPU VISIBLE INFILE

// MySQL unreserved keywords that are currently unused
%token <bytes> ACTIVE AGGREGATE ANY ARRAY ASCII AT AUTOEXTEND_SIZE

// Generated Columns
%token <bytes> GENERATED ALWAYS STORED VIRTUAL

// TODO: categorize/organize these somehow later
%token <bytes> NVAR PASSWORD_LOCK

%left <bytes> OR
%left <bytes> XOR
%left <bytes> AND
%right <bytes> NOT '!'
%left <bytes> BETWEEN CASE WHEN THEN ELSE ELSEIF END
%left <bytes> '=' '<' '>' LE GE NE NULL_SAFE_EQUAL IS LIKE REGEXP IN ASSIGNMENT_OP
%nonassoc  UNBOUNDED // ideally should have same precedence as IDENT
%nonassoc ID NULL PARTITION RANGE ROWS GROUPS PRECEDING FOLLOWING
%left <bytes> '|'
%left <bytes> '&'
%left <bytes> SHIFT_LEFT SHIFT_RIGHT
%left <bytes> '+' '-'
%left <bytes> '*' '/' DIV '%' MOD
%left <bytes> '^'
%right <bytes> '~' UNARY
%left <bytes> COLLATE
%right <bytes> BINARY UNDERSCORE_ARMSCII8 UNDERSCORE_ASCII UNDERSCORE_BIG5 UNDERSCORE_BINARY UNDERSCORE_CP1250
%right <bytes> UNDERSCORE_CP1251 UNDERSCORE_CP1256 UNDERSCORE_CP1257 UNDERSCORE_CP850 UNDERSCORE_CP852 UNDERSCORE_CP866
%right <bytes> UNDERSCORE_CP932 UNDERSCORE_DEC8 UNDERSCORE_EUCJPMS UNDERSCORE_EUCKR UNDERSCORE_GB18030 UNDERSCORE_GB2312
%right <bytes> UNDERSCORE_GBK UNDERSCORE_GEOSTD8 UNDERSCORE_GREEK UNDERSCORE_HEBREW UNDERSCORE_HP8 UNDERSCORE_KEYBCS2
%right <bytes> UNDERSCORE_KOI8R UNDERSCORE_KOI8U UNDERSCORE_LATIN1 UNDERSCORE_LATIN2 UNDERSCORE_LATIN5 UNDERSCORE_LATIN7
%right <bytes> UNDERSCORE_MACCE UNDERSCORE_MACROMAN UNDERSCORE_SJIS UNDERSCORE_SWE7 UNDERSCORE_TIS620 UNDERSCORE_UCS2
%right <bytes> UNDERSCORE_UJIS UNDERSCORE_UTF16 UNDERSCORE_UTF16LE UNDERSCORE_UTF32 UNDERSCORE_UTF8 UNDERSCORE_UTF8MB3 UNDERSCORE_UTF8MB4
%right <bytes> INTERVAL
%nonassoc <bytes> '.'

//%type <expr> tuple_expression
//
//%token <bytes> SELECT INSERT UPDATE DELETE FROM WHERE GROUP HAVING ORDER BY LIMIT OFFSET
//%token <bytes> STRING HEX ID BIT_LITERAL INTEGRAL FLOAT HEXNUM VALUE_ARG
//%type <bytes> reserved_keyword qualified_column_name_safe_reserved_keyword non_reserved_keyword column_name_safe_keyword function_call_keywords non_reserved_keyword2 non_reserved_keyword3 all_non_reserved id_or_non_reserved
//%type <colIdent> sql_id reserved_sql_id col_alias as_ci_opt using_opt existing_window_name_opt
//%type <colIdents> reserved_sql_id_list
//%type <colIdent> ins_column
//%type <columns> ins_column_list ins_column_list_opt column_list paren_column_list column_list_opt
%type <tableIdent> table_id reserved_table_id
//%type <colTuple> col_tuple
%type <exprs> expression_list
//%type <values> tuple_list row_list
//%type <tableName> table_name load_into_table_name into_table_name delete_table_name
//%type <boolVal> boolean_value
%type <valTuple> tuple_or_empty
%type <expr> expression value_expression value
//%type <colName> column_name
//
//%type <ins> insert_data insert_data_alias insert_data_select insert_data_values

//%token <bytes> ADMIN AFTER AGAINST ALGORITHM ALWAYS ARRAY AT AUTHENTICATION AUTOEXTEND_SIZE AUTO_INCREMENT AVG_ROW_LENGTH BEGIN SERIAL BIT BOOL BOOLEAN BUCKETS CASCADED CATALOG_NAME CHAIN CHANNEL CHARSET CHECKSUM CIPHER CLASS_ORIGIN CLIENT CLONE CLOSE COALESCE COLLATION COLUMNS COLUMN_NAME COMMIT COMPACT COMPRESSED COMPRESSION COMMITTED CONNECTION COMPLETION COMPONENT CONSTRAINT_CATALOG CONSTRAINT_NAME CONSTRAINT_SCHEMA CONTAINS CURRENT CURSOR_NAME

%left <bytes> EXCEPT
%left <bytes> UNION
%left <bytes> INTERSECT
%token <bytes> SELECT STREAM INSERT UPDATE DELETE FROM WHERE GROUP HAVING ORDER BY LIMIT OFFSET FOR CALL
%token <bytes> DISTINCT AS EXISTS ASC DESC DUPLICATE DEFAULT SET LOCK UNLOCK KEYS OF
%token <bytes> OUTFILE DUMPFILE DATA LOAD LINES TERMINATED ESCAPED ENCLOSED OPTIONALLY STARTING
%right <bytes> UNIQUE KEY
%token <bytes> SYSTEM_TIME CONTAINED VERSION VERSIONS
%token <bytes> VALUES LAST_INSERT_ID SQL_CALC_FOUND_ROWS
%token <bytes> NEXT VALUE SHARE MODE
%token <bytes> SQL_NO_CACHE SQL_CACHE
%left <bytes> JOIN STRAIGHT_JOIN LEFT RIGHT INNER OUTER CROSS NATURAL USE FORCE
%left <bytes> ON USING
%token <empty> '(' ',' ')' '@' ':'
%nonassoc <bytes> STRING
%token <bytes> ID HEX INTEGRAL FLOAT HEXNUM VALUE_ARG LIST_ARG COMMENT COMMENT_KEYWORD BIT_LITERAL
%token <bytes> NULL TRUE FALSE OFF
%right <bytes> INTO

%type <values> tuple_list
%type <colIdent> ins_column
%type <columns> ins_column_list
%type <colIdent> sql_id reserved_sql_id
%type <ins> insert_data insert_data_alias insert_data_values
%type <bytes> column_name_safe_keyword
%type <tableName> table_name into_table_name
//%token <bytes> INSERT INTO STRING
//%token <bytes> ID HEX INTEGRAL FLOAT HEXNUM VALUE_ARG LIST_ARG COMMENT COMMENT_KEYWORD BIT_LITERAL
//%token <bytes> NULL VALUE VALUES
//%type <str> insert_or_replace
%type <bytes> reserved_keyword non_reserved_keyword non_reserved_keyword2 non_reserved_keyword3
%type <statement> any_command command insert_statement

// duplicates
%token <bytes> ROW DATE ATTRIBUTE ACCOUNT ERROR

%start any_command

%%

any_command:
  command
  {
    setParseTree(yylex, $1)
  }
| command ';'
  {
    setParseTree(yylex, $1)
    statementSeen(yylex)
  }

command:
  insert_statement
  {
    $$ = $1
  }

insert_statement:
  //insert_or_replace into_table_name insert_data_alias
  INSERT into_table_name insert_data_alias
  {
    // insert_data returns a *Insert pre-filled with Columns & Values
    ins := $3
    ins.Action = InsertStr
    ins.Table = $2
    $$ = ins
  }
| REPLACE into_table_name insert_data_alias
    {
      // insert_data returns a *Insert pre-filled with Columns & Values
      ins := $3
      ins.Action = ReplaceStr
      ins.Table = $2
      $$ = ins
    }
insert_data:
  insert_data_values
  {
    $$ = $1
  }
| openb closeb insert_data_values
  {
    $3.Columns = []ColIdent{}
    $$ = $3
  }
| openb ins_column_list closeb insert_data_values
  {
    $4.Columns = $2
    $$ = $4
  }

openb:
  '('
  {
    if incNesting(yylex) {
      yylex.Error("max nesting level reached")
      return 1
    }
  }

closeb:
  ')'
  {
    decNesting(yylex)
  }

ins_column_list:
  ins_column
  {
    $$ = Columns{$1}
  }
| ins_column_list ',' ins_column
  {
    $$ = append($$, $3)
  }

ins_column:
// TODO: This throws away the qualifier, not a huge deal for insert into, but is incorrect
 reserved_sql_id '.' reserved_sql_id
  {
    $$ = $3
  }
| reserved_sql_id
  {
    $$ = $1
  }
| column_name_safe_keyword
  {
    $$ = NewColIdent(string($1))
  }
| non_reserved_keyword2
  {
    $$ = NewColIdent(string($1))
  }
| non_reserved_keyword3
  {
    $$ = NewColIdent(string($1))
  }
//| ESCAPE
//  {
//    $$ = NewColIdent(string($1))
//  }

insert_data_values:
  value_or_values tuple_list
  {
    $$ = &Insert{Rows: &AliasedValues{Values: $2}}
  }
| openb insert_data_values closeb
  {
    $$ = $2
  }

tuple_list:
  tuple_or_empty
  {
    $$ = Values{$1}
  }
| tuple_list ',' tuple_or_empty
  {
    $$ = append($1, $3)
  }


tuple_or_empty:
  row_opt openb expression_list closeb
  {
     $$ = ValTuple($3)
  }
| row_opt openb closeb
  {
    $$ = ValTuple{}
  }

//values_statement:
//  VALUES row_list
//  {
//    $$ = &ValuesStatement{Rows: $2}
//  }

//row_list:
//  row_opt row_tuple
//  {
//    $$ = Values{$2}
//  }
//| row_list ',' row_opt row_tuple
//  {
//    $$ = append($$, $4)
//  }
//
//tuple_expression:
//  row_tuple
//  {
//    if len($1) == 1 {
//      $$ = &ParenExpr{$1[0]}
//    } else {
//      $$ = $1
//    }
//  }
//
//row_tuple:
//  openb expression_list closeb
//  {
//    $$ = ValTuple($2)
//  }

row_opt:
  {}
| ROW
  {}


expression_list:
  expression
  {
    $$ = Exprs{$1}
  }
| expression_list ',' expression
  {
    $$ = append($1, $3)
  }

value_or_values:
  VALUES
| VALUE

into_table_name:
  INTO table_name
  {
    $$ = $2
  }
| table_name
  {
    $$ = $1
  }

//insert_or_replace:
//  INSERT
//  {
//    $$ = InsertStr
//  }
//| REPLACE
//  {
//    $$ = ReplaceStr
//  }

table_name:
  table_id
  {
    $$ = TableName{Name: $1}
  }
| table_id '.' reserved_table_id
  {
    $$ = TableName{DbQualifier: $1, Name: $3}
  }
| column_name_safe_keyword
  {
    $$ = TableName{Name: NewTableIdent(string($1))}
  }
| non_reserved_keyword2
  {
    $$ = TableName{Name: NewTableIdent(string($1))}
  }
//| function_call_keywords
//  {
//    $$ = TableName{Name: NewTableIdent(string($1))}
//  }
//| ACCOUNT
//  {
//    $$ = TableName{Name: NewTableIdent(string($1))}
//  }

table_id:
  ID
  {
    $$ = NewTableIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }


reserved_table_id:
  table_id
| reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }
| non_reserved_keyword2
  {
    $$ = NewTableIdent(string($1))
  }
| non_reserved_keyword3
  {
    $$ = NewTableIdent(string($1))
  }

//
//tuple_expression:
//  row_tuple
//  {
//    if len($1) == 1 {
//      $$ = &ParenExpr{$1[0]}
//    } else {
//      $$ = $1
//    }
//  }
//
//row_tuple:
//  openb expression_list closeb
//  {
//    $$ = ValTuple($2)
//  }
//
//expression_list:
//  expression
//  {
//    $$ = Exprs{$1}
//  }
//| expression_list ',' expression
//  {
//    $$ = append($1, $3)
//  }
//
expression:
 value_expression
  {
    $$ = $1
  }

value:
  STRING
  {
    $$ = NewStrVal($1)
  }
| DATE STRING
  {
    $$ = NewStrVal($2)
  }
| TIME STRING
  {
    $$ = NewStrVal($2)
  }
| TIMESTAMP STRING
  {
    $$ = NewStrVal($2)
  }
| HEX
  {
    $$ = NewHexVal($1)
  }
| BIT_LITERAL
  {
    $$ = NewBitVal($1)
  }
| INTEGRAL
  {
    $$ = NewIntVal($1)
  }
| FLOAT
  {
    $$ = NewFloatVal($1)
  }
| HEXNUM
  {
    $$ = NewHexNum($1)
  }
| VALUE_ARG
  {
    $$ = NewValArg($1)
  }
| NULL
  {
    $$ = &NullVal{}
  }

value_expression:
  value
  {
    $$ = $1
  }
//| ACCOUNT
//  {
//    $$ = &ColName{Name: NewColIdent(string($1))}
//  }
//| FORMAT
//  {
//    $$ = &ColName{Name: NewColIdent(string($1))}
//  }
//| boolean_value
//  {
//    $$ = $1
//  }
//| column_name
//  {
//    $$ = $1
//  }
//| column_name_safe_keyword
//  {
//    $$ = &ColName{Name: NewColIdent(string($1))}
//  }
//| tuple_expression
//  {
//    $$ = $1
//  }
//
//boolean_value:
//  TRUE
//  {
//    $$ = BoolVal(true)
//  }
//| FALSE
//  {
//    $$ = BoolVal(false)
//  }
//
//
//column_name:
//  sql_id
//  {
//    $$ = &ColName{Name: $1}
//  }
//| non_reserved_keyword2
//  {
//    $$ = &ColName{Name: NewColIdent(string($1))}
//  }
//| table_id '.' reserved_sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: $3}
//  }
//| table_id '.' non_reserved_keyword2
//  {
//    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: NewColIdent(string($3))}
//  }
//| table_id '.' column_name_safe_keyword
//  {
//    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: NewColIdent(string($3))}
//  }
//| table_id '.' ACCOUNT
//  {
//    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: NewColIdent(string($3))}
//  }
//| table_id '.' FORMAT
//  {
//    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: NewColIdent(string($3))}
//  }
//| column_name_safe_keyword '.' sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{Name: NewTableIdent(string($1))}, Name: $3}
//  }
//| qualified_column_name_safe_reserved_keyword '.' reserved_sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{Name: NewTableIdent(string($1))}, Name: $3}
//  }
//| non_reserved_keyword2 '.' reserved_sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{Name: NewTableIdent(string($1))}, Name: $3}
//  }
//| non_reserved_keyword2 '.' FULL
//  {
//    $$ = &ColName{Qualifier: TableName{Name: NewTableIdent(string($1))}, Name: NewColIdent(string($3))}
//  }
//| ACCOUNT '.' reserved_sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{Name: NewTableIdent(string($1))}, Name: $3}
//  }
//| FORMAT '.' reserved_sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{Name: NewTableIdent(string($1))}, Name: $3}
//  }
//| function_call_keywords
//  {
//    $$ = &ColName{Name: NewColIdent(string($1))}
//  }
//| table_id '.' reserved_table_id '.' reserved_sql_id
//  {
//    $$ = &ColName{Qualifier: TableName{DbQualifier: $1, Name: $3}, Name: $5}
//  }
//
//function_call_keywords:
//  CAST
//| POSITION
//| TRIM
//
//table_id:
//  ID
//  {
//    $$ = NewTableIdent(string($1))
//  }
//| non_reserved_keyword
//  {
//    $$ = NewTableIdent(string($1))
//  }
//
//expression_list:
//  expression
//  {
//    $$ = Exprs{$1}
//  }
//| expression_list ',' expression
//  {
//    $$ = append($1, $3)
//  }
//
//tuple_or_empty:
//  row_opt openb expression_list closeb
//  {
//     $$ = ValTuple($3)
//  }
//| row_opt openb closeb
//  {
//    $$ = ValTuple{}
//  }
//
//tuple_list:
//  tuple_or_empty
//  {
//    $$ = Values{$1}
//  }
//| tuple_list ',' tuple_or_empty
//  {
//    $$ = append($1, $3)
//  }
//
//value_or_values:
//  VALUES
//| VALUE
//
//insert_data_values:
//  value_or_values tuple_list
//  {
//    $$ = &Insert{Rows: &AliasedValues{Values: $2}}
//  }
//| openb insert_data_values closeb
//  {
//    $$ = $2
//  }
//
//insert_data:
//  insert_data_values
//  {
//    $$ = $1
//  }
//| openb closeb insert_data_values
//  {
//    $3.Columns = []ColIdent{}
//    $$ = $3
//  }
//| openb ins_column_list closeb insert_data_values
//  {
//    $4.Columns = $2
//    $$ = $4
//  }
//
insert_data_alias:
  insert_data
  {
    $$ = $1
  }
//| insert_data as_opt table_alias column_list_opt
//  {
//    $$ = $1
//    // Rows is guarenteed to be an *AliasedValues here.
//    rows := $$.Rows.(*AliasedValues)
//    rows.As = $3
//    if $4 != nil {
//        rows.Columns = $4
//    }
//    $$.Rows = rows
//  }

//sql_id:
//  ID
//  {
//    $$ = NewColIdent(string($1))
//  }
//| non_reserved_keyword
//  {
//    $$ = NewColIdent(string($1))
//  }
//
reserved_sql_id:
  sql_id
| reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }


sql_id:
  ID
  {
    $$ = NewColIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }

column_name_safe_keyword:
  AVG
//
// ACCESSIBLE ADD ALL
reserved_keyword:
  ACCESSIBLE
//| ADD
//| ALL
//

non_reserved_keyword:
//  ACTION
 ACTIVE
//| ADMIN
//| AFTER
//| AGAINST
//| ALGORITHM
//| ALWAYS
//| ARRAY
//| AT
//| AUTHENTICATION
//| AUTOEXTEND_SIZE
//| AUTO_INCREMENT
//| AVG_ROW_LENGTH
//| BEGIN
//| SERIAL
//| BIT
//| BOOL
//| BOOLEAN
//| BUCKETS
//| CASCADED
//| CATALOG_NAME
//| CHAIN
//| CHANNEL
//| CHARSET
//| CHECKSUM
//| CIPHER
//| CLASS_ORIGIN
//| CLIENT
//| CLONE
//| CLOSE
//| COALESCE
//| COLLATION
//| COLUMNS
//| COLUMN_NAME
//| COMMIT
//| COMPACT
//| COMPRESSED
//| COMPRESSION
//| COMMITTED
//| CONNECTION
//| COMPLETION
//| COMPONENT
//| CONSTRAINT_CATALOG
//| CONSTRAINT_NAME
//| CONSTRAINT_SCHEMA
//| CONTAINS
//| CURRENT
//| CURSOR_NAME

non_reserved_keyword2:
  ATTRIBUTE

non_reserved_keyword3:
  ACCOUNT
//| FORMAT

