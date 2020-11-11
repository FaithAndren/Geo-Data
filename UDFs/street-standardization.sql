CREATE OR REPLACE FUNCTION `prj.ds.udf_strt_std`
  (STRT STRING)
AS (
( /*
    This UDF standardizes the address street field(s), line 1 and line 2,
    to increase match rate when joining postal address data from
    two different sources.
    
    INPUT:
      CONCAT(
        ADDR_LINE_1
        , CASE WHEN TRIM(ADDR_LINE_2) != ''
          THEN CONCAT(' # ', ADDR_LINE_2) ELSE '' END
        )
        
    Note:
      This does not use all of the standardization rules
      laid out by the usps, so it should **not** be used
      as a mailing address. It's only meant to join addresses
      from two different sources together.
      
      E.g.:
      We abbreviate all directionals and suffixes which is not how to
      properly standardize addresses.
        
      */
      
      WITH SFX AS
        ( SELECT
            CAST(t AS STRUCT<f0_ STRING, f1_ STRING, f2_ STRING>).f0_ VAR
            , CAST(t AS STRUCT<f0_ STRING, f1_ STRING, f2_ STRING>).f1_ PRIM
            , CAST(t AS STRUCT<f0_ STRING, f1_ STRING, f2_ STRING>).f2_ ABBR
          FROM
            UNNEST([
              ('ALLEE','ALLEY','ALY'), ('ALLEY','ALLEY','ALY'), ('ALLY','ALLEY','ALY')
              , ('ALY','ALLEY','ALY'), ('ANEX','ANEX','ANX'), ('ANNEX','ANEX','ANX')
              , ('ANNX','ANEX','ANX'), ('ANX','ANEX','ANX'), ('ARC','ARCADE','ARC')
              , ('ARCADE','ARCADE','ARC'), ('AV','AVENUE','AVE'), ('AVE','AVENUE','AVE')
              , ('AVEN','AVENUE','AVE'), ('AVENU','AVENUE','AVE'), ('AVENUE','AVENUE','AVE')
              , ('AVN','AVENUE','AVE'), ('AVNUE','AVENUE','AVE'), ('BAYOO','BAYOU','BYU')
              , ('BAYOU','BAYOU','BYU'), ('BCH','BEACH','BCH'), ('BEACH','BEACH','BCH')
              , ('BEND','BEND','BND'), ('BG','BURG','BG'), ('BGS','BURGS','BGS')
              , ('BLF','BLUFF','BLF'), ('BLFS','BLUFFS','BLFS'), ('BLUF','BLUFF','BLF')
              , ('BLUFF','BLUFF','BLF'), ('BLUFFS','BLUFFS','BLFS')
              , ('BLVD','BOULEVARD','BLVD'), ('BND','BEND','BND'), ('BOT','BOTTOM','BTM')
              , ('BOTTM','BOTTOM','BTM'), ('BOTTOM','BOTTOM','BTM')
              , ('BOUL','BOULEVARD','BLVD'), ('BOULEVARD','BOULEVARD','BLVD')
              , ('BOULV','BOULEVARD','BLVD'), ('BR','BRANCH','BR'), ('BRANCH','BRANCH','BR')
              , ('BRDGE','BRIDGE','BRG'), ('BRG','BRIDGE','BRG'), ('BRIDGE','BRIDGE','BRG')
              , ('BRK','BROOK','BRK'), ('BRKS','BROOKS','BRKS'), ('BRNCH','BRANCH','BR')
              , ('BROOK','BROOK','BRK'), ('BROOKS','BROOKS','BRKS'), ('BTM','BOTTOM','BTM')
              , ('BURG','BURG','BG'), ('BURGS','BURGS','BGS'), ('BYP','BYPASS','BYP')
              , ('BYPA','BYPASS','BYP'), ('BYPAS','BYPASS','BYP'), ('BYPASS','BYPASS','BYP')
              , ('BYPS','BYPASS','BYP'), ('BYU','BAYOU','BYU'), ('CAMP','CAMP','CP')
              , ('CANYN','CANYON','CYN'), ('CANYON','CANYON','CYN'), ('CAPE','CAPE','CPE')
              , ('CAUSEWAY','CAUSEWAY','CSWY'), ('CAUSWA','CAUSEWAY','CSWY')
              , ('CEN','CENTER','CTR'), ('CENT','CENTER','CTR'), ('CENTER','CENTER','CTR')
              , ('CENTERS','CENTERS','CTRS'), ('CENTR','CENTER','CTR')
              , ('CENTRE','CENTER','CTR'), ('CIR','CIRCLE','CIR'), ('CIRC','CIRCLE','CIR')
              , ('CIRCL','CIRCLE','CIR'), ('CIRCLE','CIRCLE','CIR')
              , ('CIRCLES','CIRCLES','CIRS'), ('CIRS','CIRCLES','CIRS'), ('CLB','CLUB','CLB')
              , ('CLF','CLIFF','CLF'), ('CLFS','CLIFFS','CLFS'), ('CLIFF','CLIFF','CLF')
              , ('CLIFFS','CLIFFS','CLFS'), ('CLUB','CLUB','CLB'), ('CMN','COMMON','CMN')
              , ('CMNS','COMMONS','CMNS'), ('CMP','CAMP','CP'), ('CNTER','CENTER','CTR')
              , ('CNTR','CENTER','CTR'), ('CNYN','CANYON','CYN'), ('COMMON','COMMON','CMN')
              , ('COMMONS','COMMONS','CMNS'), ('COR','CORNER','COR')
              , ('CORNER','CORNER','COR'), ('CORNERS','CORNERS','CORS')
              , ('CORS','CORNERS','CORS'), ('COURSE','COURSE','CRSE'), ('COURT','COURT','CT')
              , ('COURTS','COURTS','CTS'), ('COVE','COVE','CV'), ('COVES','COVES','CVS')
              , ('CP','CAMP','CP'), ('CPE','CAPE','CPE'), ('CRCL','CIRCLE','CIR')
              , ('CRCLE','CIRCLE','CIR'), ('CREEK','CREEK','CRK'), ('CRES','CRESCENT','CRES')
              , ('CRESCENT','CRESCENT','CRES'), ('CREST','CREST','CRST')
              , ('CRK','CREEK','CRK'), ('CROSSING','CROSSING','XING')
              , ('CROSSROAD','CROSSROAD','XRD'), ('CROSSROADS','CROSSROADS','XRDS')
              , ('CRSE','COURSE','CRSE'), ('CRSENT','CRESCENT','CRES')
              , ('CRSNT','CRESCENT','CRES'), ('CRSSNG','CROSSING','XING')
              , ('CRST','CREST','CRST'), ('CSWY','CAUSEWAY','CSWY'), ('CT','COURT','CT')
              , ('CTR','CENTER','CTR'), ('CTRS','CENTERS','CTRS'), ('CTS','COURTS','CTS')
              , ('CURV','CURVE','CURV'), ('CURVE','CURVE','CURV'), ('CV','COVE','CV')
              , ('CVS','COVES','CVS'), ('CYN','CANYON','CYN'), ('DALE','DALE','DL')
              , ('DAM','DAM','DM'), ('DIV','DIVIDE','DV'), ('DIVIDE','DIVIDE','DV')
              , ('DL','DALE','DL'), ('DM','DAM','DM'), ('DR','DRIVE','DR')
              , ('DRIV','DRIVE','DR'), ('DRIVE','DRIVE','DR'), ('DRIVES','DRIVES','DRS')
              , ('DRS','DRIVES','DRS'), ('DRV','DRIVE','DR'), ('DV','DIVIDE','DV')
              , ('DVD','DIVIDE','DV'), ('EST','ESTATE','EST'), ('ESTATE','ESTATE','EST')
              , ('ESTATES','ESTATES','ESTS'), ('ESTS','ESTATES','ESTS')
              , ('EXP','EXPRESSWAY','EXPY'), ('EXPR','EXPRESSWAY','EXPY')
              , ('EXPRESS','EXPRESSWAY','EXPY'), ('EXPRESSWAY','EXPRESSWAY','EXPY')
              , ('EXPW','EXPRESSWAY','EXPY'), ('EXPY','EXPRESSWAY','EXPY')
              , ('EXT','EXTENSION','EXT'), ('EXTENSION','EXTENSION','EXT')
              , ('EXTENSIONS','EXTENSIONS','EXTS'), ('EXTN','EXTENSION','EXT')
              , ('EXTNSN','EXTENSION','EXT'), ('EXTS','EXTENSIONS','EXTS')
              , ('FALL','FALL','FALL'), ('FALLS','FALLS','FLS'), ('FERRY','FERRY','FRY')
              , ('FIELD','FIELD','FLD'), ('FIELDS','FIELDS','FLDS'), ('FLAT','FLAT','FLT')
              , ('FLATS','FLATS','FLTS'), ('FLD','FIELD','FLD'), ('FLDS','FIELDS','FLDS')
              , ('FLS','FALLS','FLS'), ('FLT','FLAT','FLT'), ('FLTS','FLATS','FLTS')
              , ('FORD','FORD','FRD'), ('FORDS','FORDS','FRDS'), ('FOREST','FOREST','FRST')
              , ('FORESTS','FOREST','FRST'), ('FORG','FORGE','FRG'), ('FORGE','FORGE','FRG')
              , ('FORGES','FORGES','FRGS'), ('FORK','FORK','FRK'), ('FORKS','FORKS','FRKS')
              , ('FORT','FORT','FT'), ('FRD','FORD','FRD'), ('FRDS','FORDS','FRDS')
              , ('FREEWAY','FREEWAY','FWY'), ('FREEWY','FREEWAY','FWY'), ('FRG','FORGE','FRG')
              , ('FRGS','FORGES','FRGS'), ('FRK','FORK','FRK'), ('FRKS','FORKS','FRKS')
              , ('FRRY','FERRY','FRY'), ('FRST','FOREST','FRST'), ('FRT','FORT','FT')
              , ('FRWAY','FREEWAY','FWY'), ('FRWY','FREEWAY','FWY'), ('FRY','FERRY','FRY')
              , ('FT','FORT','FT'), ('FWY','FREEWAY','FWY'), ('GARDEN','GARDEN','GDN')
              , ('GARDENS','GARDENS','GDNS'), ('GARDN','GARDEN','GDN')
              , ('GATEWAY','GATEWAY','GTWY'), ('GATEWY','GATEWAY','GTWY')
              , ('GATWAY','GATEWAY','GTWY'), ('GDN','GARDEN','GDN')
              , ('GDNS','GARDENS','GDNS'), ('GLEN','GLEN','GLN'), ('GLENS','GLENS','GLNS')
              , ('GLN','GLEN','GLN'), ('GLNS','GLENS','GLNS'), ('GRDEN','GARDEN','GDN')
              , ('GRDN','GARDEN','GDN'), ('GRDNS','GARDENS','GDNS'), ('GREEN','GREEN','GRN')
              , ('GREENS','GREENS','GRNS'), ('GRN','GREEN','GRN'), ('GRNS','GREENS','GRNS')
              , ('GROV','GROVE','GRV'), ('GROVE','GROVE','GRV'), ('GROVES','GROVES','GRVS')
              , ('GRV','GROVE','GRV'), ('GRVS','GROVES','GRVS'), ('GTWAY','GATEWAY','GTWY')
              , ('GTWY','GATEWAY','GTWY'), ('HARB','HARBOR','HBR'), ('HARBOR','HARBOR','HBR')
              , ('HARBORS','HARBORS','HBRS'), ('HARBR','HARBOR','HBR')
              , ('HAVEN','HAVEN','HVN'), ('HBR','HARBOR','HBR'), ('HBRS','HARBORS','HBRS')
              , ('HEIGHTS','HEIGHTS','HTS'), ('HIGHWAY','HIGHWAY','HWY')
              , ('HIGHWY','HIGHWAY','HWY'), ('HILL','HILL','HL'), ('HILLS','HILLS','HLS')
              , ('HIWAY','HIGHWAY','HWY'), ('HIWY','HIGHWAY','HWY'), ('HL','HILL','HL')
              , ('HLLW','HOLLOW','HOLW'), ('HLS','HILLS','HLS'), ('HOLLOW','HOLLOW','HOLW')
              , ('HOLLOWS','HOLLOW','HOLW'), ('HOLW','HOLLOW','HOLW')
              , ('HOLWS','HOLLOW','HOLW'), ('HRBOR','HARBOR','HBR'), ('HT','HEIGHTS','HTS')
              , ('HTS','HEIGHTS','HTS'), ('HVN','HAVEN','HVN'), ('HWAY','HIGHWAY','HWY')
              , ('HWY','HIGHWAY','HWY'), ('INLET','INLET','INLT'), ('INLT','INLET','INLT')
              , ('IS','ISLAND','IS'), ('ISLAND','ISLAND','IS'), ('ISLANDS','ISLANDS','ISS')
              , ('ISLE','ISLE','ISLE'), ('ISLES','ISLE','ISLE'), ('ISLND','ISLAND','IS')
              , ('ISLNDS','ISLANDS','ISS'), ('ISS','ISLANDS','ISS')
              , ('JCT','JUNCTION','JCT'), ('JCTION','JUNCTION','JCT')
              , ('JCTN','JUNCTION','JCT'), ('JCTNS','JUNCTIONS','JCTS')
              , ('JCTS','JUNCTIONS','JCTS'), ('JUNCTION','JUNCTION','JCT')
              , ('JUNCTIONS','JUNCTIONS','JCTS'), ('JUNCTN','JUNCTION','JCT')
              , ('JUNCTON','JUNCTION','JCT'), ('KEY','KEY','KY'), ('KEYS','KEYS','KYS')
              , ('KNL','KNOLL','KNL'), ('KNLS','KNOLLS','KNLS'), ('KNOL','KNOLL','KNL')
              , ('KNOLL','KNOLL','KNL'), ('KNOLLS','KNOLLS','KNLS'), ('KY','KEY','KY')
              , ('KYS','KEYS','KYS'), ('LAKE','LAKE','LK'), ('LAKES','LAKES','LKS')
              , ('LAND','LAND','LAND'), ('LANDING','LANDING','LNDG'), ('LANE','LANE','LN')
              , ('LCK','LOCK','LCK'), ('LCKS','LOCKS','LCKS'), ('LDG','LODGE','LDG')
              , ('LDGE','LODGE','LDG'), ('LF','LOAF','LF'), ('LGT','LIGHT','LGT')
              , ('LGTS','LIGHTS','LGTS'), ('LIGHT','LIGHT','LGT'), ('LIGHTS','LIGHTS','LGTS')
              , ('LK','LAKE','LK'), ('LKS','LAKES','LKS'), ('LN','LANE','LN')
              , ('LNDG','LANDING','LNDG'), ('LNDNG','LANDING','LNDG'), ('LOAF','LOAF','LF')
              , ('LOCK','LOCK','LCK'), ('LOCKS','LOCKS','LCKS'), ('LODG','LODGE','LDG')
              , ('LODGE','LODGE','LDG'), ('LOOP','LOOP','LOOP'), ('LOOPS','LOOP','LOOP')
              , ('MALL','MALL','MALL'), ('MANOR','MANOR','MNR'), ('MANORS','MANORS','MNRS')
              , ('MDW','MEADOWS','MDWS'), ('MDWS','MEADOWS','MDWS'), ('MEADOW','MEADOW','MDW')
              , ('MEADOWS','MEADOWS','MDWS'), ('MEDOWS','MEADOWS','MDWS')
              , ('MEWS','MEWS','MEWS'), ('MILL','MILL','ML'), ('MILLS','MILLS','MLS')
              , ('MISSION','MISSION','MSN'), ('MISSN','MISSION','MSN'), ('ML','MILL','ML')
              , ('MLS','MILLS','MLS'), ('MNR','MANOR','MNR'), ('MNRS','MANORS','MNRS')
              , ('MNT','MOUNT','MT'), ('MNTAIN','MOUNTAIN','MTN'), ('MNTN','MOUNTAIN','MTN')
              , ('MNTNS','MOUNTAINS','MTNS'), ('MOTORWAY','MOTORWAY','MTWY')
              , ('MOUNT','MOUNT','MT'), ('MOUNTAIN','MOUNTAIN','MTN')
              , ('MOUNTAINS','MOUNTAINS','MTNS'), ('MOUNTIN','MOUNTAIN','MTN')
              , ('MSN','MISSION','MSN'), ('MSSN','MISSION','MSN'), ('MT','MOUNT','MT')
              , ('MTIN','MOUNTAIN','MTN'), ('MTN','MOUNTAIN','MTN')
              , ('MTNS','MOUNTAINS','MTNS'), ('MTWY','MOTORWAY','MTWY'), ('NCK','NECK','NCK')
              , ('NECK','NECK','NCK'), ('OPAS','OVERPASS','OPAS'), ('ORCH','ORCHARD','ORCH')
              , ('ORCHARD','ORCHARD','ORCH'), ('ORCHRD','ORCHARD','ORCH')
              , ('OVAL','OVAL','OVAL'), ('OVERPASS','OVERPASS','OPAS')
              , ('OVL','OVAL','OVAL'), ('PARK','PARK','PARK'), ('PARKS','PARKS','PARK')
              , ('PARKWAY','PARKWAY','PKWY'), ('PARKWAYS','PARKWAYS','PKWY')
              , ('PARKWY','PARKWAY','PKWY'), ('PASS','PASS','PASS')
              , ('PASSAGE','PASSAGE','PSGE'), ('PATH','PATH','PATH'), ('PATHS','PATH','PATH')
              , ('PIKE','PIKE','PIKE'), ('PIKES','PIKE','PIKE'), ('PINE','PINE','PNE')
              , ('PINES','PINES','PNES'), ('PKWAY','PARKWAY','PKWY')
              , ('PKWY','PARKWAY','PKWY'), ('PKWYS','PARKWAYS','PKWY')
              , ('PKY','PARKWAY','PKWY'), ('PL','PLACE','PL'), ('PLACE','PLACE','PL')
              , ('PLAIN','PLAIN','PLN'), ('PLAINS','PLAINS','PLNS'), ('PLAZA','PLAZA','PLZ')
              , ('PLN','PLAIN','PLN'), ('PLNS','PLAINS','PLNS'), ('PLZ','PLAZA','PLZ')
              , ('PLZA','PLAZA','PLZ'), ('PNE','PINE','PNE'), ('PNES','PINES','PNES')
              , ('POINT','POINT','PT'), ('POINTS','POINTS','PTS'), ('PORT','PORT','PRT')
              , ('PORTS','PORTS','PRTS'), ('PR','PRAIRIE','PR'), ('PRAIRIE','PRAIRIE','PR')
              , ('PRK','PARK','PARK'), ('PRR','PRAIRIE','PR'), ('PRT','PORT','PRT')
              , ('PRTS','PORTS','PRTS'), ('PSGE','PASSAGE','PSGE'), ('PT','POINT','PT')
              , ('PTS','POINTS','PTS'), ('RAD','RADIAL','RADL'), ('RADIAL','RADIAL','RADL')
              , ('RADIEL','RADIAL','RADL'), ('RADL','RADIAL','RADL'), ('RAMP','RAMP','RAMP')
              , ('RANCH','RANCH','RNCH'), ('RANCHES','RANCH','RNCH'), ('RAPID','RAPID','RPD')
              , ('RAPIDS','RAPIDS','RPDS'), ('RD','ROAD','RD'), ('RDG','RIDGE','RDG')
              , ('RDGE','RIDGE','RDG'), ('RDGS','RIDGES','RDGS'), ('RDS','ROADS','RDS')
              , ('REST','REST','RST'), ('RIDGE','RIDGE','RDG'), ('RIDGES','RIDGES','RDGS')
              , ('RIV','RIVER','RIV'), ('RIVER','RIVER','RIV'), ('RIVR','RIVER','RIV')
              , ('RNCH','RANCH','RNCH'), ('RNCHS','RANCH','RNCH'), ('ROAD','ROAD','RD')
              , ('ROADS','ROADS','RDS'), ('ROUTE','ROUTE','RTE'), ('ROW','ROW','ROW')
              , ('RPD','RAPID','RPD'), ('RPDS','RAPIDS','RPDS'), ('RST','REST','RST')
              , ('RTE','ROUTE','RTE'), ('RUE','RUE','RUE'), ('RUN','RUN','RUN')
              , ('RVR','RIVER','RIV'), ('SHL','SHOAL','SHL'), ('SHLS','SHOALS','SHLS')
              , ('SHOAL','SHOAL','SHL'), ('SHOALS','SHOALS','SHLS'), ('SHOAR','SHORE','SHR')
              , ('SHOARS','SHORES','SHRS'), ('SHORE','SHORE','SHR')
              , ('SHORES','SHORES','SHRS'), ('SHR','SHORE','SHR'), ('SHRS','SHORES','SHRS')
              , ('SKWY','SKYWAY','SKWY'), ('SKYWAY','SKYWAY','SKWY'), ('SMT','SUMMIT','SMT')
              , ('SPG','SPRING','SPG'), ('SPGS','SPRINGS','SPGS'), ('SPNG','SPRING','SPG')
              , ('SPNGS','SPRINGS','SPGS'), ('SPRING','SPRING','SPG')
              , ('SPRINGS','SPRINGS','SPGS'), ('SPRNG','SPRING','SPG')
              , ('SPRNGS','SPRINGS','SPGS'), ('SPUR','SPUR','SPUR'), ('SPURS','SPURS','SPUR')
              , ('SQ','SQUARE','SQ'), ('SQR','SQUARE','SQ'), ('SQRE','SQUARE','SQ')
              , ('SQRS','SQUARES','SQS'), ('SQS','SQUARES','SQS'), ('SQU','SQUARE','SQ')
              , ('SQUARE','SQUARE','SQ'), ('SQUARES','SQUARES','SQS'), ('ST','STREET','ST')
              , ('STA','STATION','STA'), ('STATION','STATION','STA')
              , ('STATN','STATION','STA'), ('STN','STATION','STA'), ('STR','STREET','ST')
              , ('STRA','STRAVENUE','STRA'), ('STRAV','STRAVENUE','STRA')
              , ('STRAVEN','STRAVENUE','STRA'), ('STRAVENUE','STRAVENUE','STRA')
              , ('STRAVN','STRAVENUE','STRA'), ('STREAM','STREAM','STRM')
              , ('STREET','STREET','ST'), ('STREETS','STREETS','STS')
              , ('STREME','STREAM','STRM'), ('STRM','STREAM','STRM'), ('STRT','STREET','ST')
              , ('STRVN','STRAVENUE','STRA'), ('STRVNUE','STRAVENUE','STRA')
              , ('STS','STREETS','STS'), ('SUMIT','SUMMIT','SMT'), ('SUMITT','SUMMIT','SMT')
              , ('SUMMIT','SUMMIT','SMT'), ('TER','TERRACE','TER'), ('TERR','TERRACE','TER')
              , ('TERRACE','TERRACE','TER'), ('THROUGHWAY','THROUGHWAY','TRWY')
              , ('TPKE','TURNPIKE','TPKE'), ('TRACE','TRACE','TRCE')
              , ('TRACES','TRACE','TRCE'), ('TRACK','TRACK','TRAK')
              , ('TRACKS','TRACK','TRAK'), ('TRAFFICWAY','TRAFFICWAY','TRFY')
              , ('TRAIL','TRAIL','TRL'), ('TRAILER','TRAILER','TRLR')
              , ('TRAILS','TRAIL','TRL'), ('TRAK','TRACK','TRAK'), ('TRCE','TRACE','TRCE')
              , ('TRFY','TRAFFICWAY','TRFY'), ('TRK','TRACK','TRAK'), ('TRKS','TRACK','TRAK')
              , ('TRL','TRAIL','TRL'), ('TRLR','TRAILER','TRLR'), ('TRLRS','TRAILER','TRLR')
              , ('TRLS','TRAIL','TRL'), ('TRNPK','TURNPIKE','TPKE')
              , ('TRWY','THROUGHWAY','TRWY'), ('TUNEL','TUNNEL','TUNL')
              , ('TUNL','TUNNEL','TUNL'), ('TUNLS','TUNNEL','TUNL')
              , ('TUNNEL','TUNNEL','TUNL'), ('TUNNELS','TUNNEL','TUNL')
              , ('TUNNL','TUNNEL','TUNL'), ('TURNPIKE','TURNPIKE','TPKE')
              , ('TURNPK','TURNPIKE','TPKE'), ('UN','UNION','UN')
              , ('UNDERPASS','UNDERPASS','UPAS'), ('UNION','UNION','UN')
              , ('UNIONS','UNIONS','UNS'), ('UNS','UNIONS','UNS'), ('UPAS','UNDERPASS','UPAS')
              , ('VALLEY','VALLEY','VLY'), ('VALLEYS','VALLEYS','VLYS')
              , ('VALLY','VALLEY','VLY'), ('VDCT','VIADUCT','VIA'), ('VIA','VIADUCT','VIA')
              , ('VIADCT','VIADUCT','VIA'), ('VIADUCT','VIADUCT','VIA'), ('VIEW','VIEW','VW')
              , ('VIEWS','VIEWS','VWS'), ('VILL','VILLAGE','VLG'), ('VILLAG','VILLAGE','VLG')
              , ('VILLAGE','VILLAGE','VLG'), ('VILLAGES','VILLAGES','VLGS')
              , ('VILLE','VILLE','VL'), ('VILLG','VILLAGE','VLG')
              , ('VILLIAGE','VILLAGE','VLG'), ('VIS','VISTA','VIS'), ('VIST','VISTA','VIS')
              , ('VISTA','VISTA','VIS'), ('VL','VILLE','VL'), ('VLG','VILLAGE','VLG')
              , ('VLGS','VILLAGES','VLGS'), ('VLLY','VALLEY','VLY'), ('VLY','VALLEY','VLY')
              , ('VLYS','VALLEYS','VLYS'), ('VST','VISTA','VIS'), ('VSTA','VISTA','VIS')
              , ('VW','VIEW','VW'), ('VWS','VIEWS','VWS'), ('WALK','WALK','WALK')
              , ('WALKS','WALKS','WALK'), ('WALL','WALL','WALL'), ('WAY','WAY','WAY')
              , ('WAYS','WAYS','WAYS'), ('WELL','WELL','WL'), ('WELLS','WELLS','WLS')
              , ('WL','WELL','WL'), ('WLS','WELLS','WLS'), ('WY','WAY','WAY')
              , ('XING','CROSSING','XING'), ('XRD','CROSSROAD','XRD')
              , ('XRDS','CROSSROADS','XRDS')
            ]) AS t

        )
        , TKN1 AS
          ( SELECT
              TOKEN
              , OFFSET OFST
            FROM
              UNNEST(
                SPLIT(
                  REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                    REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                      REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                          TRIM(
                              UPPER(
                                REGEXP_REPLACE(
                                  REGEXP_REPLACE(
                                    REGEXP_REPLACE(
                                      REGEXP_REPLACE(STRT,'\\.','')
                                      , r"#", '# ')
                                    , ',', ' '
                                  )
                                  , r'[\s][\s]+', ' '
                                )
                              )
                            )
                              ,'^NORTH EAST |^N E ', 'NE '),' NORTH EAST | N E ', ' NE '),' NORTH EAST$| N E$', ' NE')
                            ,'^SOUTH EAST |^S E ', 'SE '),' SOUTH EAST | S E ', ' SE '),' SOUTH EAST$| S E$', ' SE')
                          ,'^NORTH WEST |^N W ', 'NW '),' NORTH WEST | N W ', ' NW '),' NORTH WEST$| N W$', ' NW')
                        ,'^SOUTH WEST |^S W ', 'SW '),' SOUTH WEST | S W ', ' SW '),' SOUTH WEST$| S W$', ' SW')
                  , " "
                )
              ) TOKEN WITH OFFSET
        )
      , TKN2 AS
        ( SELECT
            A.*
            , B.PRIM
            , B.ABBR
          FROM TKN1 A
          LEFT JOIN SFX B
            ON A.TOKEN = B.VAR
        )
  SELECT
    REGEXP_REPLACE(REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              STRING_AGG(
                CASE
                  WHEN ABBR IS NOT NULL THEN ABBR
                  ELSE
                      REGEXP_REPLACE(
                        REGEXP_REPLACE(
                          REGEXP_REPLACE(
                            REGEXP_REPLACE(
                              REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                  REGEXP_REPLACE(
                                    REGEXP_REPLACE(TOKEN
                                    , '^NORTHEAST$|^NORESTE$|^NORTH-EAST$', 'NE')
                                  , '^NORTHWEST$|^NOROESTE$|^NORTH-WEST$', 'NW')
                                , '^SOUTHEAST$|^SURESTE$|^SOUTH-EAST$', 'SE')
                              , '^SOUTHWEST$|^SUROESTE$|^SOUTH-WEST$', 'SW')
                            , '^EAST$|^ESTE$', 'E')
                          , '^NORTH$|^NORTE$', 'N')
                        , '^SOUTH$|^SUR$', 'S')
                      , '^WEST$|^OESTE$', 'W')
                END
                , ' ' ORDER BY OFST
              )
            , ',',' ')
          , CONCAT(
                ' APT | BLDG | BSMT | FL | LOT | PH | NBR '
                , '| APARTMENT | BUILDING | BASEMENT | FLOOR '
                , '| PENTHOUSE | NUMBER | ROOM | TRAILER | OFFICE '
                , '| RM | STE | SUITE | UNIT | TRLR | OFC '
              ), ' # ')
        , r'[\s][\s]+', ' ')
      , r'( #)+', r' #')
    ,"'",""),'"','')
  FROM TKN2
 )
;
