CREATE OR REPLACE PROCEDURE pr_inventario
AS
/*------------------------CORSORES-----------------------*/
/*=========================BEGIN=========================*/ 
    CURSOR cr_records IS SELECT
                            TABLE_NAME 
                         FROM SYS.USER_ALL_TABLES;
    CURSOR cr_object IS SELECT 
                            OBJECT_NAME,
                            CREATED,
                            OBJECT_TYPE 
                       FROM USER_OBJECTS;
    CURSOR cr_columns IS SELECT
                        TABLE_NAME,
                        COLUMN_NAME,
                        DATA_TYPE,
                        NULLABLE,                         
                        DATA_PRECISION,
                        DATA_SCALE,
                        CHAR_COL_DECL_LENGTH
                    FROM USER_TAB_COLUMNS;

    CURSOR cr_constraints IS SELECT distinct
                            b.table_name, 
                            a.constraint_name, 
                            a.constraint_type, 
                            b.column_name
                        FROM USER_CONSTRAINTS a
                        INNER JOIN USER_CONS_COLUMNS b 
                        ON b.constraint_name = a.constraint_name;
                       
/*=======================CURSOR END======================*/       
--

/*------------------------VARIAVEIS----------------------*/
/*=========================BEGIN=========================*/                
  retorno varchar (30000);
  registros number:=0;
  codigo_ddl varchar(30000);
  menu varchar(30000);
  tamanhoArquivo number;
  
  immediate_count VARCHAR(50);
  immediate_size VARCHAR(50);
  sql_constraint VARCHAR2(5000) :='';
  between_parentheses VARCHAR2(50) :='';
/*=====================VARIAVEIS END======================*/ 
--

    BEGIN   
    
/*-------------------------USUARIO-----------------------*/
/*=========================BEGIN=========================*/
/*************************IMPRIMIR************************/

        DBMS_OUTPUT.PUT_LINE(chr(13)|| 'USUARIO: ' || USER);
        
/***********************IMPRIMIR END**********************/ 
/*=====================USUARIO END======================*/
--

/*-------------------------OBJETOS-----------------------*/
/*                         TABLE                         */
/*=========================BEGIN=========================*/
    FOR x IN cr_object LOOP
        IF UPPER(x.object_type) = 'TABLE' --verifica se eh uma TABELA 
            THEN
                EXECUTE IMMEDIATE 'select count(*) from ' || x.object_name into immediate_count;
                EXECUTE IMMEDIATE 'SELECT SUM(bytes)/(1024 * 1024) MBytes FROM USER_EXTENTS WHERE UPPER(SEGMENT_NAME) = '''|| x.object_name ||'''' into immediate_size;
                
                DBMS_OUTPUT.PUT_LINE(chr(13) || 'OBJETO: ' || x.object_name);
                DBMS_OUTPUT.PUT_LINE(chr(13) || 'DATA CRIAÇÃO: ' || x.created);
                DBMS_OUTPUT.PUT_LINE(chr(13) || 'TIPO: '|| x.object_type);
                DBMS_OUTPUT.PUT_LINE(chr(13) || 'REGISTROS: '|| immediate_count);
                
                IF immediate_size < 1 -- para adicionar o 0(zero) antes da virgula na impressao
                    THEN
                    DBMS_OUTPUT.PUT_LINE(chr(13) || 'TAMANHO: 0'|| immediate_size || ' MB');
                ELSE    
                    DBMS_OUTPUT.PUT_LINE(chr(13) || 'TAMANHO: '|| immediate_size || ' MB');
                END IF;
                
                DBMS_OUTPUT.PUT_LINE(chr(13) || 'DDL:');
                
                -- inicia o script de CREATE 
                DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ' || x.object_type || ' ' || x.object_name);
                DBMS_OUTPUT.PUT_LINE('(');
                 
                FOR y IN cr_columns LOOP
                    IF UPPER(x.object_name) = UPPER(y.table_name) -- verifica se o nome da TABELA percorrida eh o mesmo da COLUNA 
                        THEN --verifica de o campo eh null ou not null pra imprimir
                        IF UPPER(y.NULLABLE) = 'N'
                            THEN
                            IF UPPER(y.data_type) = 'NUMBER' AND (y.data_precision IS NOT NULL AND y.data_scale IS NOT NULL) -- se a coluna for do tipo NUMBER, imprime NUMBER(2, 7) por exemplo
                                THEN
                                between_parentheses := '(' || y.DATA_PRECISION || ', ' || y.DATA_SCALE || ')'; --imprime entre os parenteses
                                
                                ELSIF y.CHAR_COL_DECL_LENGTH IS NOT NULL --se a coluna for da familia dos CHAR como VARCHAR2 e etc, imprime o tamanho declarado na criacao da coluna
                                    THEN
                                    between_parentheses := '(' || y.CHAR_COL_DECL_LENGTH  || ')'; --imprime entre os parenteses
                            END IF;
                            DBMS_OUTPUT.PUT_LINE(' ' || y.column_name || ' ' || y.data_type || ' ' || between_parentheses || '  NOT NULL'); --imprime not null
                        ELSIF UPPER(y.NULLABLE) = UPPER('Y')
                            THEN
                            DBMS_OUTPUT.PUT_LINE(' ' || y.column_name || ' ' || y.data_type || ' ' || between_parentheses || '  NULL'); --imprime null
                        END IF;
                    END IF;
                END LOOP;

/*-------------------------CONSTRAINTS-------------------------*/
                FOR y IN cr_constraints LOOP
                sql_constraint := '';
                    IF x.object_name = y.table_name
                        THEN
                                             
                            IF UPPER(y.constraint_type) = 'P'
                                THEN
                                sql_constraint := sql_constraint || chr(13) || ' CONSTRAINT ' || y.constraint_name || ' PRIMARY KEY';
                                sql_constraint := sql_constraint || chr(13) || ' (';
                                sql_constraint := sql_constraint || chr(13) || '   ' || y.column_name;
                                sql_constraint := sql_constraint || chr(13) || ' )';
                                                                
                            ELSIF UPPER(y.constraint_type) = 'R'
                                THEN
                                sql_constraint := sql_constraint || chr(13) || ' CONSTRAINT ' || y.constraint_name || ' FOREING KEY';
                                sql_constraint := sql_constraint || chr(13) || ' (';
                                sql_constraint := sql_constraint || chr(13) || '   ' || y.column_name;
                                sql_constraint := sql_constraint || chr(13) || ' )';
                                
                            END IF;
                            
                            --Para imprimir apenas quando existir as constraints de PK ou FK
                            --Para nao imprimir blocos em branco desnecessariamente
                            IF UPPER(y.constraint_type) = 'P' OR UPPER(y.constraint_type) = 'R'
                                THEN
                                    DBMS_OUTPUT.PUT_LINE(sql_constraint);                                
                            END IF;
                    END IF;                    
                END LOOP;               
/*----------------------END CONSTRAINTS-------------------------*/

                DBMS_OUTPUT.PUT_LINE(')');
                DBMS_OUTPUT.PUT_LINE(chr(13) || '----------------------------------------------------------------------------------------------------------------------------------------------------'); 
        END IF;
    END LOOP;

END;
/

SET SERVEROUTPUT ON;
EXECUTE pr_inventario();
