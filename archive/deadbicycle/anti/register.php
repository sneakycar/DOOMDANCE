<?php


  require "./common2.php";
  include "$PHORUM[include]/post_functions.php";
  if($f>0){
    $table_width=$ForumTableWidth;
    $table_header_color=$ForumTableHeaderColor;
    $table_header_font_color=$ForumTableHeaderFontColor;
    $table_body_color_1=$ForumTableBodyColor1;
    $table_body_font_color_1=$ForumTableBodyFontColor1;
    $nav_color=$ForumNavColor;
  }
  else{
    $table_width=$default_table_width;
    $table_header_color=$default_table_header_color;
    $table_header_font_color=$default_table_header_font_color;
    $table_body_color_1=$default_table_body_color_1;
    $table_body_font_color_1=$default_table_body_font_color_1;
    $nav_color=$default_nav_color;
  }


  initvar("name");
  initvar("password");
  initvar("email");
  initvar("webpage");
  initvar("image");
  initvar("signature");
  initvar("icq");
  initvar("yahoo");
  initvar("aol");
  initvar("jabber");
  initvar("msn");
  initvar("done");
  initvar("Error");
  initvar("process");

  if(empty($target)){
    if(isset($HTTP_REFERER)){
      $target=$HTTP_REFERER;
    }
    else{
      $target="$forum_url/$forum_page.$ext";
    }
  }

  if(!empty($name) && !empty($email) && !empty($password) && !empty($checkpassword)){
    if($password!=$checkpassword){
      $Error=$lNoPassMacth;
    } elseif(censor_check(array($name, $email, $webpage, $image, $signature, $icq, $yahoo, $aol, $msn, $jabber))) {
      $Error=$lRegistrationCensor;
    } else {

        $safe_name=htmlspecialchars($name);
        $safe_email=htmlspecialchars($email);
        $safe_webpage=htmlspecialchars($webpage);
        $safe_image=htmlspecialchars($image);
        $safe_signature=htmlspecialchars($signature);
        $safe_icq=htmlspecialchars($icq);
        $safe_yahoo=htmlspecialchars($yahoo);
        $safe_aol=htmlspecialchars($aol);
        $safe_msn=htmlspecialchars($msn);
        $safe_jabber=htmlspecialchars($jabber);

        if(!get_magic_quotes_gpc()){
            $safe_name=addslashes($safe_name);
            $safe_email=addslashes($safe_email);
            $safe_webpage=addslashes($safe_webpage);
            $safe_image=addslashes($safe_image);
            $safe_signature=addslashes($safe_signature);
            $safe_icq=addslashes($safe_icq);
            $safe_yahoo=addslashes($safe_yahoo);
            $safe_aol=addslashes($safe_aol);
            $safe_msn=addslashes($safe_msn);
            $safe_jabber=addslashes($safe_jabber);
        }


        $SQL="select name, email from ".$pho_main."_auth where (name='$safe_name' or email='$safe_email')";
        //run query
        $q->query($DB,$SQL);
        if($q->numrows()>0){
            $rec=$q->getrow();
           
            if(strtolower($rec['name'])==strtolower($name))
                $Error=$lDupName;
            if(strtolower($rec['email'])==strtolower($email))
                $Error=$lDupEmail;
        }else{
          $md5_pass=md5($password);
          $id=$DB->nextid($pho_main."_auth");
          $SQL="Insert into $pho_main"."_auth
                (id, name, email, webpage, image, password, signature, icq, yahoo, aol, msn, jabber)
                values
                ($id, '$safe_name', '$safe_email', '$safe_webpage', '$safe_image', '$md5_pass', '$safe_signature', '$safe_icq', '$safe_yahoo', '$safe_aol', '$safe_msn', '$safe_jabber')";
          $q->query($DB, $SQL);
          echo $q->error();
          if($DB->type=="mysql")
              $id=$DB->lastid();
          $sess_id=md5($name.$password);
          phorum_login_user($sess_id, $id);
          $done=true;
        }
    }
  }
  elseif($process){
    $Error=$lFillInAll;
  }

  $title = " - $lRegisterCaption";
  include phorum_get_file_name("header");

  // hack
  $login_page="login";

  //////////////////////////
  // START NAVIGATION     //
  //////////////////////////

    if(count($ActiveForums)>1){
      addnav($menu, $lForumList, "$forum_page.$ext?f=$ForumParent$GetVars");
    }
    addnav($menu, $lLoginLink, "$login_page.$ext?f=$f&target=$target$GetVars");
    $nav=getnav($menu);

  //////////////////////////
  // END NAVIGATION       //
  //////////////////////////
  if($Error)
    echo "<p><strong>$Error</strong>";
  if(!$done){ ?>
<SCRIPT LANGUAGE="JavaScript">
    function textlimit(field, limit) {
        if (field.value.length > limit)
            field.value = field.value.substring(0, limit);
    }
</script>
<form action="<?php echo $PHP_SELF; ?>" method="post">
<input type="hidden" name="process" value="1" />
<input type="hidden" name="target" value="<?php echo $target; ?>" />
<input type="hidden" name="f" value="<?php echo $f; ?>" />
<?php echo $PostVars; ?>
<table align="center" cellspacing="0" cellpadding="0" border="0">
<tr>
    <td bgcolor="#ffffff">
        <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">
 <tr>
            <td bgcolor="#ffffff" align="right"><font color="#768abe">&nbsp;<?php echo $lUserName;?>:&nbsp;&nbsp;</font></td>
            <td bgcolor="#ffffff"><input type="text" name="name" size="30" maxlength="50" style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="<?php echo $name; ?>" /></td>
        </tr>
              
 <tr>
            <td bgcolor="#ffffff" align="right"><font color="#768abe">&nbsp;<?php echo $lFormEmail;?>:&nbsp;&nbsp;</font></td>
            <td bgcolor="#ffffff"><input type="text" name="email" size="30" maxlength="50" style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="<?php echo $email; ?>" /></td>
        </tr>
        <tr>
            <td bgcolor="#ffffff" align="right"><font color="#669933">&nbsp;<?php echo $lPassword;?>:&nbsp;&nbsp;</font></td>
            <td bgcolor="#ffffff"><input type="password" name="password" size="20" maxlength="20" style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="" /></td>
        </tr>
        <tr>
            <td bgcolor="#ffffff" align="right"><font color="#669933">&nbsp;<?php echo $lPassAgain; ?>:&nbsp;&nbsp;</font></td>
            <td bgcolor="#ffffff"><input type="password" name="checkpassword" size="20" maxlength="20" style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="" /></td>
        </tr>
        
        <tr>
            <td bgcolor="#ffffff" nowrap="nowrap">&nbsp;</td>
            <td bgcolor="#ffffff"><input type="submit" value="<?php echo $lRegister; ?>" style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe; background-color:yellow;" />&nbsp;<br /><img src="images/trans.gif" width=3 height=3 border=0></td>
        </tr>
        </table>
</form>
<?php
    }else{
      if(empty($QUERY_STRING) || substr($target, -1)!="?"){
        $target.="?$GetVars";
      }
      else{
        $target="&$GetVars";
      }
?>


<script language='JavaScript'>
<!-- //
if (window.name == 'help')
       // dynamic Web request to update the toolbar
	 parent.threads.location='list.php?f=1';
// -->
</script>


<META HTTP-EQUIV="refresh" 
    CONTENT="0; 
    URL=logged.php?f=1">

<DIV ALIGN="CENTER"><table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">
<tr>
    <td height="21" bgcolor="#ffffff"><FONT color="#669933">&nbsp;<?php echo $lRegisterThanks; ?></font></td>
</tr>
<tr>
    <td bgcolor="#ffffff" nowrap="nowrap"><font color="#669933"><a href="<?php echo $target; ?>"></font></td>
</tr>
<TR><TD><CENTER><IMG width="20" height="4" SRC="images/load.gif"></CENTER></TD></TR>
</table></DIV>
<?php } ?>
<?php
  include phorum_get_file_name("footer");
?>
