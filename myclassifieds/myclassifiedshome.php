<? include 'myclassifiedsfuncs.php' ?>
<html><head><title>MyClassifieds</title><META NAME=keywords CONTENT="craigslist, craigs list, jobs, employment, career, housing, apartments, rental, roomate, events, calendar, sale, wanted, resumes, personals, romance, san francisco bay area">
<SCRIPT LANGUAGE="JavaScript"><!--
function goto_URL(object) {
  window.location.href = object.options[object.selectedIndex].value;
}
//--></SCRIPT>
<style>
.useful {font-family: tahoma, sans-serif; font-size: 9pt; font-weight: bold;}
</style>
</head><body bgcolor=#eeeeee>

<table width="90%" cellpadding=0 cellspacing=0>
<tr>
<td align=center width=150>
<font size=5><b><a href=myclassifiedshome.php>myclassifieds</a></font></td>
<td width=15>&nbsp;</td>
<td colspan=3 bgcolor=#cccccc align=center><font size=5><b><font color=#000000>My Site</font></td>
</tr>
<tr><td colspan=8><font size=3>&nbsp;</font></td></tr>
<tr><td valign=top bgcolor=#dddddd align=center width=150 rowspan=2>
</td>
<td width=15 rowspan=2>&nbsp;</td>
<td width="40%" valign=top>
<table width=100% cellpadding=2 cellspacing=1>
<tr>
<td bgcolor=#dddddd><b>&nbsp;<a href="viewitems.php?type=1">lost</a></b><font size=2>&nbsp;&nbsp;(<? getCount(1); ?>)</font></td>
</tr></table>

<table width=100% cellpadding=2 cellspacing=1>
<tr>
<td colspan=2 bgcolor=#dddddd><b>&nbsp;<a href="viewitems.php?type=3">wanted</a></b><font size=2>&nbsp;&nbsp;(<? getCount(3); ?>)</font></td>
</tr>
</table>

<table width=100% cellpadding=2 cellspacing=1>
<tr>
<td colspan=2 bgcolor=#dddddd><b>&nbsp;<a href="viewitems.php?type=5">jobs</a></b><font size=2>&nbsp;&nbsp;(<?getCount(5);?>)</font></td>
</tr>
</table>

<table width="100%" cellpadding=2 cellspacing=1>
<tr>
<td bgcolor=#dddddd>&nbsp;<a href="viewitems.php?type=6"><b>general info</b></a><b></a></b><font size=2>&nbsp;&nbsp;(<? getCount(7);?>)</font></td>
</tr>
</table>

</td><td width=15>&nbsp;</td><td width="40%" align=left valign=top>
<table width="100%" cellpadding=2 cellspacing=1>
<tr>
<td bgcolor=#dddddd>&nbsp;<b><a href="viewitems.php?type=2">found</a></b><font size=2>&nbsp;&nbsp;(<? getCount(2); ?>)</font></td>
</tr>
</table>
<table width="100%" cellpadding=2 cellspacing=1>
<tr>
<td bgcolor=#dddddd>&nbsp;<b><a href="viewitems.php?type=4">free stuff</a></b><font size=2>&nbsp;&nbsp;(<? getCount(4);?>)</font></td>
</tr>
</table>
<table width="100%" cellpadding=2 cellspacing=1>
<tr>
<td bgcolor=#dddddd>&nbsp;<a href="viewitems.php?type=6"><b>housing</b></a><b></a></b><font size=2>&nbsp;&nbsp;(<? getCount(6);?>)</font></td>
</tr>
</table>

</td></tr></table>
</body></html>


