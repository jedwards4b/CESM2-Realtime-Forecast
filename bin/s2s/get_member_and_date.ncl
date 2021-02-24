; common code used in ncl postprocessing scripts
month_abbr = (/"","jan","feb","mar","apr","may","jun","jul","aug","sep", \
                    "oct","nov","dec"/)

if (.not. isvar("date")) then
  date = getenv("CYLC_TASK_CYCLE_POINT")
  if (ismissing(date)) then
    date = "1999-01-18"
  end if
end if
if (.not. isvar("member")) then
  member = getenv("CYLC_TASK_PARAM_member")
  if (ismissing(member)) then
    member = "00"
  end if
end if
do while (strlen(member) .lt. 2)
  member = str_insert(member, "0", 0)
  print ("member len="+strlen(member))
end do
cdate = stringtochar(date)
mm = tostring(cdate(5:6))
yyyy = tostring(cdate(0:3))
day = "  "
if (strlen(cdate) .gt. 7) then
  day = tostring(cdate(8:9))
end if
outdate=day+month_abbr(tointeger(mm))+yyyy
print ("Running for date "+outdate+" and member "+member)
