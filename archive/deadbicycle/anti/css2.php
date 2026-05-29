<?php // einar jónsson <cre@hugi.is>

$fontsize = 9;
$headmargintop = 45;
$headmarginleft = 40;

if (ereg("Netscape6|MSIE.5|Opera.5",$HTTP_USER_AGENT))
  $browser = "current";
elseif (ereg("Opera.4",$HTTP_USER_AGENT))
  $browser = "opera4";
elseif (ereg("Mozilla.4",$HTTP_USER_AGENT))
  $browser = "ns4";
else
  $browser = "unknown";

if ($browser == "opera4")
  $headmargintop += 1;

if ($browser == "ns4")
{
  $fontsize += 1;
  $headmargintop += 18;
}

?>
body { scrollbar-arrow-color: #6f7fcf; scrollbar-3dlight-color: #6D6EA5; scrollbar-highlight-color: #ffffff; scrollbar-face-color: #ffffff; scrollbar-shadow-color: #6D6EA5; scrollbar-track-color: #abb4c7; scrollbar-darkshadow-color: #6D6EA5}
body

{
  margin: 0px;
  background-repeat: repeat-x;
  background-attachment: scroll;
  font-family: verdana, arial;
  background-color: #ffffff;
}

.td
{
  margin: 0px;
  background-repeat: repeat-x;
  background-attachment: scroll;
  font-family: verdana, arial;
}

table
{
  font-family: verdana, arial;
  font-size: <?= $fontsize ?>px;
}

td
{
  font-family: verdana, arial;
  font-size: <?= $fontsize ?>px;
}

a
{
  text-decoration: none; 
  color: #768ABE;
}

body
a:hover
{
  text-decoration: none;
  color: #6F7FCF;
}

a:visited
{
  text-decoration: none;
  color: #6F7FCF;

}

.input
{
  font-family: verdana, arial;
  font-size: <?= $fontsize ?>px;
}

.tenglar
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #ffffff;
  font-style: normal;
}

.user
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #ffffff;
  font-style: normal;
}

.regpass
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  background-color: yellow;
}

a.regpass:link
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  text-decoration: underlined;
}

a.regpass:hover
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  text-decoration: underlined;
}

a.regpass:vlink
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  text-decoration: underlined;
}

a.regpass:active
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  text-decoration: underlined;
}


.lostpass
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #ffffff;
  font-style: normal;
}

.date
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #ffffff;
  font-style: normal;
}
.sendmessage
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #ffffff;
  font-style: normal;
}
.tenglar_main
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768ABE;
  font-style: normal;
}

.maim
{  
  font-family: verdana, arial;
  font-size: 9px;
  color: #768ABE;
  font-style: normal;
}

.adal
{
  font-family: verdana, arial;
  font-size: 9px;
  color: #768ABE;
  font-style: normal;
}

.tenglar_body
{
  bgcolor: #ffffff;
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768ABE;
  font-style: normal;

.reply
{
  bgcolor: #ffffff;
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #323AE0;
  font-style: normal;

}

.bgback { background: #ffffff }

