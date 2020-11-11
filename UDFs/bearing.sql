CREATE OR REPLACE FUNCTION `prj.ds.udf_bearing`
  (LAT1 FLOAT64, LONG1 FLOAT64, LAT2 FLOAT64, LONG2 FLOAT64)
RETURNS FLOAT64
LANGUAGE js AS """

  // This funcation outputs the intial bearing in degrees between two points
  // ( also referred to as the forward azimuth )
  
  // Inputs (FLOAT64): LATITUDE1, LONGITUDE1, LATITUDE2, LONGITUDE2
  
  // https://www.movable-type.co.uk/scripts/latlong.html
  
  const φ1 = LAT1 * Math.PI/180; // φ, λ in radians
  const φ2 = LAT2 * Math.PI/180;
  const λ1 = LONG1 * Math.PI/180;
  const λ2 = LONG2 * Math.PI/180;
  const y = Math.sin(λ2-λ1) * Math.cos(φ2);
  const x = Math.cos(φ1) * Math.sin(φ2) -
            Math.sin(φ1) * Math.cos(φ2) * Math.cos(λ2-λ1);
  const θ = Math.atan2(y, x);
  return (θ*180/Math.PI + 360) % 360; // in degrees
  
""";
