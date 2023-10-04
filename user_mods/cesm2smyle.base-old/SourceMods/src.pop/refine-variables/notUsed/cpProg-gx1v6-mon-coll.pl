#!/usr/bin/perl

#  usage: files.perl < list

 while(<>)
 {
         @vars = split(/\s+/,$_);
         $ivar = @vars[0];
	 #print("ivar = $ivar\n");
         print("grep \"$ivar\" gx1v7_tavg_contents | grep -v \"_$ivar\"  | grep  \"1  \" \n");
         #print("grep \"$ivar\" gx1v7_tavg_contents | grep -v \"_$ivar\"  | grep -v \"$ivar_\" | grep -v \"4  \" \n");
 }

# grep "DIA_IMPVF_SALT" gx1v7_tavg_contents | grep -v "4  "
# grep "KPP_SRC_SALT" gx1v7_tavg_contents | grep -v "_KPP_SRC_SALT"
# grep "SALT" gx1v7_tavg_contents | grep -v "_SALT" | grep -v "SALT_"
