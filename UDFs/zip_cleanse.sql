CREATE OR REPLACE FUNCTION `prj.udf.udf_clns_zip`(x ANY TYPE) AS (
-- This UDF takes postal codes that were either zip5 or zip9 that were
-- transformed to integers and reconverts them back to strings with
-- leading zeros and grabs only the zip5 version.
  ( SELECT
      SUBSTR(
        UPPER(
          CASE 
            WHEN REGEXP_CONTAINS(TRIM(CAST(x AS STRING)) , r'^[0-9]{1,5}$')
              THEN LPAD(TRIM(CAST(x AS STRING)), 5, '0')
            WHEN REGEXP_CONTAINS(TRIM(CAST(x AS STRING)) , r'^[0-9]{6,}$')
              THEN LPAD(TRIM(CAST(x AS STRING)), 9, '0')
            ELSE TRIM(CAST(x AS STRING))
          END
        )
      ,0,5)  
  )
);
