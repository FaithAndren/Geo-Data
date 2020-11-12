CREATE OR REPLACE FUNCTION `prj.ds.udf_strt_std`(STRT STRING, STRT2 STRING) AS 
(
  ( /*
    This UDF standardizes the address street field(s), line 1 and line 2,
    to increase match rate when joining postal address data from
    two different sources.
	  
    TWO INPUTS: 
      ADDR_LINE_1
      , ADDR_LINE_2 ('' if none)
	  
    Note:
      This does not use all of the standardization rules
      laid out by the usps, so it should **not** be used
      as a mailing address. It's only meant to join addresses
      from two different sources together.
	  
      E.g.:
        We abbreviate all directionals and suffixes which is not how to
        properly standardize addresses.
      */
      WITH 
        SFX AS
          ( SELECT
              CAST(t AS STRUCT<f0_ STRING, f1_ ARRAY<STRING>>).f0_ ABBR
              , CAST(t AS STRUCT<f0_ STRING, f1_ ARRAY<STRING>>).f1_ ALTS
            FROM
              UNNEST([

                -- Directionals
                -- https://pe.usps.com/text/pub28/28c2_045.htm
                -- https://pe.usps.com/text/pub28/28api_007.htm
                  ('N', ['NORTH', 'NORTE'])
                  , ('NE', ['NORTHEAST', 'NORESTE', 'NORTH-EAST'])
                  , ('E', ['EAST', 'ESTE'])
                  , ('SE', ['SOUTHEAST', 'SURESTE', 'SOUTH-EAST'])
                  , ('S', ['SOUTH', 'SUR'])
                  , ('SW', ['SOUTHWEST', 'SOUTH-WEST', 'SUROESTE'])
                  , ('W', ['WEST', 'OESTE'])
                  , ('NW', ['NORTHWEST', 'NORTH-WEST', 'NOROESTE'])

                -- Secondary Unit Designators
                -- https://pe.usps.com/text/pub28/28apc_003.htm
                  , ('#', 
                      [ 'APARTMENT', 'APT', 'APARTAMENTO', 'NUM'
                        , 'NUMBER', 'PMB' -- Private Mailbox Number
                        , 'ROOM', 'RM', 'SUITE', 'STE', 'UNIT', 'NBR'
                      ]
                    )    
                  , ('BLDG', ['BUILDING'])
                  , ('FL', ['FLOOR'])
                  , ('HNGR', ['HANGER'])
                  , ('BSMT', ['BASEMENT'])
                  , ('LBBY', ['LOBBY'])
                  , ('PH', ['PENTHOUSE'])
                  , ('FRNT', ['FRONT'])
                  , ('LOWR', ['LOWER'])
                  , ('UPPR', ['UPPER', 'UPR'])
                  , ('SPC', ['SPACE'])
                  , ('OFC', ['OFFICE'])
                  , ('DEPT', ['DEPARTMENT', 'DEPARTAMENTO'])
                  
                -- Numbers
                  , ('1ST', ['FIRST', 'PRIMERA', 'PRIMERO'])
                  , ('2ND', ['SECOND', 'SEGUNDA', 'SEGUNDO'])
                  , ('3RD', ['THIRD', 'TERCERA', 'TERCERO'])
                  , ('4TH', ['FOURTH', 'CUARTA', 'CUARTO'])
                  , ('5TH', ['FIFTH', 'QUINTA', 'QUINTO'])
                  , ('6TH', ['SIXTH', 'SEXTA', 'SEXTO'])
                  , ('7TH', ['SEVENTH','SEPTIMA', 'SEPTIMO'])
                  , ('8TH', ['EIGHTH', 'OCTAVA', 'OCTAVO'])
                  , ('9TH', ['NINTH', 'NOVENA', 'NOVENO'])
                  , ('10TH', ['TENTH', 'DECIMA', 'DECIMO'])
                  , ('11TH', ['ELEVENTH', 'UNDECIMA', 'UNDECIMO'])
                  , ('12TH', ['TWELFTH', 'DUODECIMA', 'DUODECIMO'])
                  , ('13TH', ['THIRTEENTH', 'DECIMOTERCERA', 'DECIMOTERCERO'])
                  , ('14TH', ['FOURTEENTH', 'DECIMOCUARTA', 'DECIMOCUARTO'])
                  , ('15TH', ['FIFTEENTH', 'DECIMOQUINTA', 'DECIMOQUINTO'])
                  , ('16TH', ['SIXTEENTH', 'DECIMOSEXTA', 'DECIMOSEXTO'])
                  , ('17TH', ['SEVENTEENTH', 'DECIMOSEPTIMA', 'DECIMOSEPTIMO'])
                  , ('18TH', ['EIGHTEENTH', 'DECIMOCTAVA', 'DECIMOCTAVO'])
                  , ('19TH', ['NINETEENTH', 'DECIMONOVENA', 'DECIMONOVENO'])
                  , ('20TH', ['TWENTIETH', 'VIGESIMA', 'VIGESIMO'])

                -- Street Suffixes
                -- https://pe.usps.com/text/pub28/28apc_002.htm
                -- https://pe.usps.com/text/pub28/28c2_044.htm
                -- https://pe.usps.com/text/pub28/28api_006.htm
                  , ('ALT', ['ALTURA']), ('ALTS', ['ALTURAS'])
                  , ('ALY', ['ALLEE', 'ALLEY', 'ALLY', 'CALLEJÓN'])
                  , ('ANX', ['ANEX', 'ANNEX', 'ANNX']), ('ARC', ['ARCADE'])
                  , ('AVE', ['AV', 'AVEN', 'AVENU', 'AVENUE', 'AVN', 'AVNUE', 'AVENIDA'])
                  , ('BDA', ['BARRIADA']), ('BYU', ['BAYOO', 'BAYOU'])
                  , ('BCH', ['BEACH']), ('BND', ['BEND']), ('BO', ['BARRIO'])
                  , ('BLF', ['BLUF', 'BLUFF']), ('BLFS', ['BLUFFS', 'BLUFS'])
                  , ('BTM', ['BOT', 'BOTTM', 'BOTTOM'])
                  , ('BLVD', ['BOUL', 'BOULEVARD', 'BOULV'])
                  , ('BR', ['BRNCH', 'BRANCH']), ('BRG', ['BRDGE', 'BRIDGE'])
                  , ('BRK', ['BROOK']), ('BRKS', ['BROOKS']), ('BG', ['BURG'])
                  , ('BGS', ['BURGS']), ('BYP', ['BYPA', 'BYPAS', 'BYPASS', 'BYPS'])         
                  , ('CIR', ['CIRC', 'CIRCL', 'CIRCLE', 'CRCL', 'CRCLE', 'CIRCULO'])
                  , ('CIRS', ['CIRCLES']), ('CLB', ['CLUB']), ('CLF', ['CLIFF'])
                  , ('CLFS', ['CLIFFS']), ('CLL', ['CALLE']), ('CMN', ['COMMON'])
                  , ('CMNS', ['COMMONS']), ('CMT', ['CAMINITO'])
                  , ('COR', ['CORNER']), ('CER', ['CERRADA']), ('CORS', ['CORNERS'])         
                  , ('CP', ['CAMP', 'CMP']), ('CPE', ['CAPE'])       
                  , ('CRES', ['CRESCENT', 'CRSENT', 'CRSNT']), ('CRK', ['CREEK'])
                  , ('CRSE', ['COURSE']), ('CRST', ['CREST'])
                  , ('CSWY', ['CAUSEWAY', 'CAUSWA']), ('CT', ['COURT'])
                  , ('CTR', ['CEN', 'CENT', 'CENTER', 'CENTR', 'CENTRE', 'CNTER', 'CNTR'])
                  , ('CTRS', ['CENTERS']), ('CTS', ['COURTS']), ('CURV', ['CURVE'])
                  , ('CV', ['COVE']), ('CVS', ['COVES']), ('CYN', ['CANYN', 'CANYON', 'CNYN'])
                  , ('DL', ['DALE']), ('DM', ['DAM']), ('DR', ['DRIV', 'DRIVE', 'DRV'])
                  , ('DRS', ['DRIVES']), ('DV', ['DIV', 'DIVIDE', 'DVD'])
                  , ('ENT', ['ENTRADA']), ('EST', ['ESTATE', 'ESTANCIAS'])          
                  , ('EXPY', ['EXP', 'EXPR', 'EXPRESS', 'EXPRESSWAY', 'EXPW'])
                  , ('EXT', ['EXTENSION', 'EXTN', 'EXTNSN']), ('FLD', ['FIELD'])
                  , ('EXTS', ['EXTENSIONS']), ('ESTS', ['ESTATES'])
                  , ('FLDS', ['FIELDS']), ('FLS', ['FALLS']), ('FLT', ['FLAT'])
                  , ('FLTS', ['FLATS']), ('FRD', ['FORD']), ('FRDS', ['FORDS'])
                  , ('FRG', ['FORG', 'FORGE']), ('FRGS', ['FORGES']), ('FRK', ['FORK'])
                  , ('FRKS', ['FORKS']), ('FRST', ['FOREST', 'FORESTS'])
                  , ('FRY', ['FERRY', 'FRRY']), ('FT', ['FORT', 'FRT'])
                  , ('FWY', ['FREEWAY', 'FREEWY', 'FRWAY', 'FRWY'])
                  , ('GDN', ['GARDEN', 'GARDN', 'GRDEN', 'GRDN'])
                  , ('GDNS', ['GARDENS', 'GRDNS']), ('GLN', ['GLEN'])
                  , ('GLNS', ['GLENS']), ('GRN', ['GREEN']), ('GRNS', ['GREENS'])
                  , ('GRV', ['GROV', 'GROVE']), ('GRVS', ['GROVES'])
                  , ('GTWY', ['GATEWAY', 'GATEWY', 'GATWAY', 'GTWAY'])
                  , ('HBR', ['HARB', 'HARBOR', 'HARBR', 'HRBOR'])
                  , ('HBRS', ['HARBORS']), ('HL', ['HILL']), ('HLS', ['HILLS'])
                  , ('HOLW', ['HLLW', 'HOLLOW', 'HOLLOWS', 'HOLWS'])
                  , ('HTS', ['HEIGHTS', 'HT']), ('HVN', ['HAVEN'])
                  , ('HWY', ['HIGHWAY', 'HIGHWY', 'HIWAY', 'HIWY', 'HWAY'])
                  , ('INLT', ['INLET']), ('IS', ['ISLAND', 'ISLND'])
                  , ('ISLE', ['ISLES']), ('ISS', ['ISLANDS', 'ISLNDS'])
                  , ('JCT', ['JCTION', 'JCTN', 'JUNCTION', 'JUNCTN', 'JUNCTON'])
                  , ('JCTS', ['JCTNS', 'JUNCTIONS']), ('KNL', ['KNOL', 'KNOLL'])
                  , ('KNLS', ['KNOLLS']), ('KY', ['KEY']), ('KYS', ['KEYS'])
                  , ('LCK', ['LOCK']), ('LCKS', ['LOCKS'])
                  , ('LDG', ['LDGE', 'LODG', 'LODGE']), ('LF', ['LOAF'])
                  , ('LGT', ['LIGHT']), ('LGTS', ['LIGHTS']), ('LK', ['LAKE'])
                  , ('LKS', ['LAKES']), ('LN', ['LANE']), ('LNDG', ['LANDING', 'LNDNG'])
                  , ('LOOP', ['LOOPS']), ('MDW', ['MEADOW'])
                  , ('MDWS', ['MEADOWS', 'MEDOWS']), ('ML', ['MILL'])
                  , ('MLS', ['MILLS']), ('MNR', ['MANOR']), ('MNRS', ['MANORS'])
                  , ('MSN', ['MISSION', 'MISSN', 'MSSN']), ('MT', ['MNT', 'MOUNT'])
                  , ('MTN', ['MNTAIN', 'MNTN', 'MOUNTAIN', 'MOUNTIN', 'MTIN'])
                  , ('MTNS', ['MNTNS', 'MOUNTAINS']), ('MTWY', ['MOTORWAY'])
                  , ('NCK', ['NECK']), ('OPAS', ['OVERPASS']), ('ORCH', ['ORCHARD', 'ORCHRD'])
                  , ('OVAL', ['OVL']), ('PARK', ['PARKS', 'PRK']), ('PATH', ['PATHS'])
                  , ('PKWY', ['PARKWAY', 'PARKWAYS', 'PARKWY', 'PKWAY', 'PKWYS', 'PKY'])
                  , ('PIKE', ['PIKES']), ('PL', ['PLACE']), ('PLN', ['PLAIN'])
                  , ('PLNS', ['PLAINS']), ('PLZ', ['PLAZA', 'PLZA']), ('PNE', ['PINE'])
                  , ('PNES', ['PINES']), ('PR', ['PRAIRIE', 'PRR']), ('PRT', ['PORT'])
                  , ('PRTS', ['PORTS']), ('PSGE', ['PASSAGE']), ('PT', ['POINT'])
                  , ('PTS', ['POINTS']), ('RADL', ['RAD', 'RADIAL', 'RADIEL'])
                  , ('RD', ['ROAD']), ('RDG', ['RDGE', 'RIDGE']), ('RDGS', ['RIDGES'])
                  , ('RDS', ['ROADS']), ('RIV', ['RIVER', 'RIVR', 'RVR'])
                  , ('RNCH', ['RANCH', 'RANCHES', 'RNCHS']), ('RPD', ['RAPID'])
                  , ('RPDS', ['RAPIDS']), ('RST', ['REST']), ('RTE', ['ROUTE'])
                  , ('SHL', ['SHOAL']), ('SHLS', ['SHOALS']), ('SHR', ['SHOAR', 'SHORE'])
                  , ('SHRS', ['SHOARS', 'SHORES']), ('SKWY', ['SKYWAY'])
                  , ('SMT', ['SUMIT', 'SUMITT', 'SUMMIT'])
                  , ('SPG', ['SPNG', 'SPRING', 'SPRNG']), ('SPUR', ['SPURS'])
                  , ('SPGS', ['SPNGS', 'SPRINGS', 'SPRNGS'])
                  , ('SQ', ['SQR', 'SQRE', 'SQU', 'SQUARE'])
                  , ('SQS', ['SQRS', 'SQUARES']), ('ST', ['STR', 'STREET', 'STRT'])
                  , ('STA', ['STATION', 'STATN', 'STN'])
                  , ('STRA', ['STRAV', 'STRAVEN', 'STRAVENUE', 'STRAVN', 'STRVN', 'STRVNUE'])
                  , ('STRM', ['STREAM', 'STREME']), ('STS', ['STREETS'])
                  , ('TER', ['TERR', 'TERRACE', 'TERRAZA'])
                  , ('TPKE', ['TRNPK', 'TURNPIKE', 'TURNPK'])
                  , ('TRAK', ['TRACK', 'TRACKS', 'TRK', 'TRKS'])
                  , ('TRCE', ['TRACE', 'TRACES']), ('TRFY', ['TRAFFICWAY'])        
                  , ('TRL', ['TRAIL', 'TRAILS', 'TRLS']), ('TRLR', ['TRAILER', 'TRLRS'])
                  , ('TUNL', ['TUNEL', 'TUNLS', 'TUNNEL', 'TUNNELS', 'TUNNL'])
                  , ('UN', ['UNION']), ('TRWY', ['THROUGHWAY']), ('UNS', ['UNIONS'])
                  , ('UPAS', ['UNDERPASS', 'UNDERPAS', 'UNDERPS', 'UNDRPAS', 'UNDRPS', 'UDRPS'])
                  , ('VIA', ['VDCT', 'VIADCT', 'VIADUCT']), ('VL', ['VILLE'])
                  , ('VIS', ['VIST', 'VISTA', 'VST', 'VSTA'])
                  , ('VLG', ['VILL', 'VILLAG', 'VILLAGE', 'VILLG', 'VILLIAGE'])
                  , ('VLGS', ['VILLAGES']), ('VLYS', ['VALLEYS']), ('VWS', ['VIEWS'])
                  , ('VLY', ['VALLEY', 'VALLY', 'VLLY']), ('VW', ['VIEW'])
                  , ('WALK', ['WALKS']), ('WAY', ['WY']), ('WL', ['WELL']), ('WLS', ['WELLS'])
                  , ('XING', ['CROSSING', 'CRSSNG', 'CROSNG', 'CRSING', 'CRSNG', 'CRSSING'])
                  , ('XRD', ['CROSSROAD', 'CROSRD', 'CROSSRD', 'CRSRD'])
                  , ('XRDS', ['CROSSROADS', 'CROSRDS', 'CROSSRDS', 'CRSRDS'])
                  , ('CARR', ['CARRETERA']), ('COND', ['CONDOMINIO'])
                  , ('COOP', ['COOPERATIVA']), ('EDIF', ['EDIFICIO'])
                  , ('JARD', ['JARDINES']), ('MANS', ['MANSIONES'])
                  , ('PARC', ['PARCELAS']), ('QBDA', ['QUEBRADA'])
                  , ('REPTO', ['REPARTO']), ('RES', ['RESIDENCIAL'])
                  , ('SECT', ['SECTOR']), ('SECC', ['SECCION'])
                  , ('URB', ['URBANIZACION']), ('PSO', ['PASEO'])
                  , ('PLA', ['PLACITA']), ('RCH', ['RANCHO'])
                  , ('VER', ['VEREDA']), ('BL', ['BLOQUE']), ('VIL', ['VILLA'])
                  , ('CAS', ['CASERIO']), ('CORP', ['CORPORACION'])
                  , ('HOSP', ['HOSPITAL']), ('IND', ['INDUSTRIAL'])     
              ]) t
          )
        , SFX2 AS
          ( SELECT 
              PRE
              , ABBR POST
            FROM 
              SFX
              , UNNEST(ARRAY_CONCAT([ABBR],ALTS)) PRE
          )
        , TKN1 AS
          ( SELECT
              TOKEN
              , OFFSET OFST
            FROM
              UNNEST(
                SPLIT(
                
                  REGEXP_REPLACE(
                    TRIM(
                      REGEXP_REPLACE(

                        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(

                          REGEXP_REPLACE(REGEXP_REPLACE(
                          REGEXP_REPLACE(REGEXP_REPLACE(
                          REGEXP_REPLACE(REGEXP_REPLACE(
                          REGEXP_REPLACE(REGEXP_REPLACE(

                            REGEXP_REPLACE(
                              REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                  REGEXP_REPLACE(UPPER(
                                    CONCAT(
                                      STRT
                                      , CASE 
                                          WHEN REGEXP_CONTAINS(TRIM(STRT2), '^[0-9]+') 
                                            THEN CONCAT(' # ', STRT2)
                                          WHEN TRIM(STRT2) != '' 
                                            THEN CONCAT(' ', STRT2)
                                        ELSE '' END
                                    )
                                  ),'\\.','')
                                , r"#", ' # ')
                              , ',', ' ')
                            , r'[\s][\s]+', ' ')

                          -- Note, there is currently a bug in GCP where
                          -- this will not work if there are two side by side
                          , '(^| )(NORTH( |-)?EAST|N( |-)E|(NORTE|NOR)( |-)?ESTE)( |$)', ' NE ')
                          , '(^| )(SOUTH( |-)?EAST|S( |-)E|SUR( |-)?ESTE)( |$)', ' SE ')
                          , '(^| )(SOUTH( |-)?WEST|S( |-)W|SUR( |-)?OESTE)( |$)', ' SW ')
                          , '(^| )(NORTH( |-)?WEST|N( |-)W|(NORTE|NOR)( |-)?OESTE)( |$)', ' NW ')
                          , '(^| )(# )?P(OST)?( )?(O(FFICE)?|0)( )?(BOX|BIN)( #)?( |$)', ' PO BOX ')
                          , '(^| )(# )?APARTADO(S)?( )?(POSTAL|DE CORREO(S)?)?( )?(#)?( |$)'
                            , ' APARTADO ')
                          , 'APARTADO', ' APARTADO ')
                          , 'PO BOX|(^| )POB( |$)', ' PO BOX ')

                        , r'[\[\{]', '('), r'[\]\}]', ')'), r'[ÁÀÄÂÃÅ]', 'A'), r'[ÍÏÎÌ]', 'I')
                        , r'[ÓÖÒÔÐÕØ]', 'O'), r'[ÉÈÊË]', 'E'), r'[Ñ]', 'N'), r'[ÚÜÛÙ]', 'U')
                        , r'[Ç]', 'C'), r'[ÝŸ]', 'Y'), r'[Ž]', 'Z')

                      , r'[^A-Z0-9#\-\\/\(\) &]', '')
                    ), r'[\s][\s]+', ' ')
                    
                , " ")
              ) TOKEN WITH OFFSET
          )
        , TKN2 AS
          ( SELECT
              A.*
              , B.POST
            FROM TKN1 A
            LEFT JOIN SFX2 B
              ON A.TOKEN = B.PRE
          )
      SELECT
        --REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            STRING_AGG(
                CASE WHEN POST IS NOT NULL THEN POST ELSE TOKEN END
                , ' ' ORDER BY OFST
              )
            , r'( #)+', r' #')
          , r'( )?#$', r'')
          --, r'[\s][\s]+', ' ')
      FROM TKN2
  )
);

