CREATE OR REPLACE FUNCTION `prj.ds.udf_intrpl_latlon`
  (LAT1 FLOAT64, LONG1 FLOAT64, LAT2 FLOAT64, LONG2 FLOAT64, DIST FLOAT64)
RETURNS ARRAY<STRUCT<lat FLOAT64, long FLOAT64>>
LANGUAGE js AS """

  // This function outputs an array of interpolated coordinates
  // between two input points with a specified distance (mi)
  
  // Inputs (FLOAT64): LATITUDE1, LONGITUDE1, LATITUDE2, LONGITUDE2, DISTANCE (mi)
  
  // https://www.movable-type.co.uk/scripts/latlong.html
  
  let φ1 = LAT1 * Math.PI/180, λ1 = LONG1 * Math.PI/180;  // φ, λ in radians
  let φ2 = (LAT2 || LAT1) * Math.PI/180, λ2 = (LONG2 || LONG1) * Math.PI/180;
  
  var retVal = [];
  
  // calculate bearing between the two input coordinates
  const y = Math.sin(λ2-λ1) * Math.cos(φ2);
  const x = Math.cos(φ1)*Math.sin(φ2) -
            Math.sin(φ1)*Math.cos(φ2)*Math.cos(λ2-λ1);
  const brng = Math.atan2(y, x);
  
  // calculate distance (mi) between the two input coordinates
  const R = 3958.8;// earth radius mi
  const Δφ = ((LAT2 || LAT1)-LAT1) * Math.PI/180;
  const Δλ = ((LONG2 || LONG1)-LONG1) * Math.PI/180;
  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const d = R * c; // in miles
  
  if (d <= (DIST || d)) {
    retVal.push({ lat: LAT1, long: LONG1 });
  } else {
    retVal.push({ lat: LAT1, long: LONG1 });
    
    // interpolate all points between input coordinates by input distance
    const δ = (DIST || d)/R; // angular distance (mi)
    
    for (var i = 0; i < Math.floor(d/(DIST || d)); i++) {
      let φ3 = Math.asin( Math.sin(φ1) * Math.cos(δ) +
                Math.cos(φ1) * Math.sin(δ) * Math.cos(brng));
      let λ3 = λ1 + Math.atan2(Math.sin(brng) * Math.sin(δ) * Math.cos(φ1),
               Math.cos(δ) - Math.sin(φ1) * Math.sin(φ3));
               
      φ4 = (φ3 * 180 / Math.PI).toFixed(6);
      λ4 = (λ3 * 180 / Math.PI).toFixed(6);
      
      retVal.push({ lat: φ4, long: λ4 });
      φ1 = φ3, λ1 = λ3;
      
    }
 }
 
  return retVal;
  
""";
