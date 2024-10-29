# Atlantic Zone Off-Shelf Monitoring Program (AZOMP)  

https://www.bio.gc.ca/science/monitoring-monitorage/azomp-pmzao/azomp-pmzao-en.php  

This repository contains the data and code used for AZOMP. For convenience if you are working from RStudio, open the Reporting.Rproj file. Reports beginning in 2023 are generated using csasdown (https://github.com/pbs-assess/csasdown), e.g.: `csasdown::draft(type="techreport", directory="TechReport_2023")`.  

**Cruise_dates.csv* contains the start and end date of in situ sampling along the AR7W line on each annual mission.  
**AZOMP_polygon_season_bounds.csv** contains the start of the "spring", "summer", and "fall" seasons as defined by the bloom phenology within each polygon.  
