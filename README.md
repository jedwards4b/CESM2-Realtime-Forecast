Files in the bin directory:

getNASAdata.py: Get data from the NASA eosdis server.
  Accepts --date in form yyyy-mm-dd as an input argument
  The ip address of the local system must be registered with NASA contact
  Lei, Guang-dih (GSFC-610.2)[ADNET SYSTEMS INC] <guang-dih.lei@nasa.gov>

getCDASdata.py: Untar and rename sfluxgrbf files from /glade/collections/rda/data
  Accepts --date in form yyyy-mm-dd or yyyy-mm (do entire month) as an input argument

create_landforcing_from_NCEPCFC.ncl: Create datm stream files from CDAS data
  Accepts year and month as inputs and converts all files for that time period
  Updates existing files with new data.

streamfilelib.ncl: Support file for create_landforcing_from_NCEPCFC.ncl
