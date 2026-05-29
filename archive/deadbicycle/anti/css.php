body 
{ 
scrollbar-arrow-color: #000000; 
scrollbar-3dlight-color: #c0c0c0; 
scrollbar-highlight-color: #ffffff; 
scrollbar-face-color: #ffffff; 
scrollbar-shadow-color: #000000; 
scrollbar-track-color: #ffffff; 
scrollbar-darkshadow-color: #000000;
}


<?php 

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
  color: #ffffff;
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
  color: #abb4c7;
  font-style: normal;
}

.user
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
}
BODY, TD, TR, P, UL, OL, LI, INPUT, SELECT, DL, DD, DT, FONT
{
    font-family: Verdana, Arial, Clean, Helvetica, sans-serif;
    font-size: 9px;
}

.PhorumBodyArea
{
    font-family: Verdana, Arial, Clean, Helvetica, sans-serif;
    font-size: 9px;
    width: 100px;
}



a.linkdup
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  text-decoration: underlined
}

.yellowborder
{
    border-style : solid;
    border-color : yellow;
    border-width : 1px;
}

.replytable
{
    border-style : solid;
    border-color : #768abe;
    border-width : 1px;

.PhorumListTable2
{
    border-style : solid;
    border-color : Black;
    border-width : 0px;
}

.PhorumListRow
{
    font-family: Verdana,Geneva,Arial,sans-serif;
    font-size: 9px;
    height: 21px;
}

.PhorumListHeader
{
    font-family: Verdana,Geneva,Arial,sans-serif;
    font-size : 9px;
    font-weight : bold;
    height: 12px;
}

.regpass
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 9px;
  color: #768abe;
  font-style: normal;
  text-decoration: underlined
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
  color: yellow;
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
.PhorumForumTitle
{
    font-family: Verdana,Geneva,Arial,sans-serif;
    font-size : 0px;
    font-weight: bold;
}

.PhorumTableHeader
{
    font-family: Verdana,Geneva,Arial,sans-serif;
    font-size: 9px;
    font-weight: bold;
}

.logged { color: #768abe; 
         text-decoration: none; background: yellow;
	 font-size: 9px;
         font-style:bold;
 }


.reply
{
  font-family:Verdana,Geneva,Arial,sans-serif;
  font-size: 8px;
  color: #768abe;
  font-style: bold;

.PhorumNav
{
    font-family: Verdana,Geneva,Arial,sans-serif;
    font-size: 9px;
}

.PhorumNewFlag
{
    font-family:Verdana,Geneva,Arial,sans-serif;
    font-size: 9px;
    color: Red;
}

.PhorumMessage
{
    font-family: Verdana,Geneva,Arial,sans-serif;
    font-size: 9px;
}
