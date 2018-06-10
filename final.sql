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
                            COLUMN_NAME                                             
                        FROM USER_TAB_COLUMNS;
                       
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
                
                IF immediate_size < 1
                    THEN
                        DBMS_OUTPUT.PUT_LINE(chr(13) || 'TAMANHO: 0'|| immediate_size || ' MB');
                ELSE    
                        DBMS_OUTPUT.PUT_LINE(chr(13) || 'TAMANHO: '|| immediate_size || ' MB');
                END IF;
                
                DBMS_OUTPUT.PUT_LINE(chr(13) || 'DDL:');
                DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ' || x.object_type || ' (');
                               
                FOR y IN cr_columns LOOP
                    IF UPPER(x.object_name) = y.table_name -- verifica de o nome da TABELA percorrida é o mesmo da COLUNA 
                        THEN                      
                            DBMS_OUTPUT.PUT_LINE(y.column_name || ',');
                    END IF;
                END LOOP;
                
                DBMS_OUTPUT.PUT_LINE(')');
                DBMS_OUTPUT.PUT_LINE(chr(13) || '----------------------------------------------------------------------------------------------------------------------------------------------------'); 
        END IF;
    END LOOP;

END;
/

SET SERVEROUTPUT ON;
EXECUTE pr_inventario();
