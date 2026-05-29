<?php


  require "./common2.php";

  settype($Error, "string");

  //Thats for all those ppl who likes to use different colors in different forums
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

  if(empty($target)){
    if(isset($HTTP_REFERER)){
      $target="loggedin.php?f=1";
    }
    else{
      $target="loggedin.php?f=1";
    }
  }

  initvar("phorum_auth");

//  $target=str_replace("phorum_auth=$phorum_auth", '', $target);

  if(isset($logout)){
    $SQL="update $pho_main"."_auth set sess_id='' where sess_id='$phorum_auth'";
    $q->query($DB, $SQL);

    unset($phorum_auth);
    SetCookie("phorum_auth",'');
    header("Location: $target");
    exit();
  }

  if(empty($forgotpass) && !empty($name) && !empty($password)){
    $uid=phorum_check_login($name, $password);
    if($uid){
      $sess_id=phorum_session_id($HTTP_POST_VARS['name'], $HTTP_POST_VARS["password"]);
      phorum_login_user($sess_id, $uid);
      if(!strstr($target, "?")){
        $target.="?f=0$GetVars";
      }
      else{
        $target.="$GetVars";
      }
      header("Location: $target");
      exit();
    }
    else{
      $Error=$lLoginError;
    }
  } elseif (!empty($forgotpass)) {
    $SQL="select name, email from $pho_main"."_auth where name='$lookup' or email='$lookup'";
    $q->query($DB, $SQL);
    $rec=$q->getrow();
    if(!empty($rec["name"])){
        $newpass=substr(md5($name.microtime()), 0, 8);
        $crypt_pass=md5($newpass);
        $SQL="update $pho_main"."_auth set password='$crypt_pass' where name='$rec[name]'";
        $q->query($DB, $SQL);
        mail($rec["email"], $lNewPassword, "$lNewPassBody:\n\n  $lname: $rec[name]\n  $lPassword:  $newpass\n\n$lNewPassChange", "From: <$DefaultEmail>");
        $Error=$lNewPassMailed;
    } else {
        $Error=$lNewPassError;
    }
  }

  if(basename($PHP_SELF)=="login.$ext"){
    $title = " - $lLoginCaption";
    include phorum_get_file_name("header");
  }

  // hack
  $signup_page="register";

  //////////////////////////
  // START NAVIGATION     //
  //////////////////////////

    $menu="";
    addnav($menu, $lRegisterLink, "$signup_page.$ext?f=$f&target=$target$GetVars");
    $nav=getnav($menu);

  //////////////////////////
  // END NAVIGATION       //
  //////////////////////////


  if($Error){
    echo "<p><strong>$Error</strong>";
  }
?>
<form action="<?php echo "login.$ext"; ?>" method="post" target="help" />
<input type="hidden" name="f" value="<?php echo $f; ?>" />
<input type="hidden" name="target" value="<?php echo $target; ?>" />
<?php echo $PostVars; ?>

    </td>
</tr>
<tr>
    <td bgcolor="#ffffff">
        <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">
  <tr>
          <td colspan="2" align="RIGHT"><?php echo $nav; ?>::<A HREF="ambulence.php">Password Recovery</A></td>
        </tr>
     
        <tr>
            <td height="21" colspan="2" bgcolor="#ffffff"><FONT color="<?php echo $table_header_font_color; ?>"></font></td>
        </tr>
        <tr>
            <td bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe">&nbsp;Username:</font></td>
            <td bgcolor="#ffffff"><input type="Text" name="name" size="30" maxlength="50" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;" /></td>
        </tr>
        <tr>
            <td bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe">&nbsp;<?php echo $lPassword;?>:</font></td>
            <td bgcolor="#ffffff"><input type="Password" name="password" size="30" maxlength="20" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;" /></td>
        </tr>
        <tr>
            <td bgcolor="#ffffff" nowrap="nowrap">&nbsp;</td>
            <td bgcolor="#ffffff"><input type="submit" value="<?php echo $lLogin; ?>" style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;"/>&nbsp;<br /><img src="images/trans.gif" width=3 height=3 border=0></td>
        </tr>
        </table>
    </td>
</tr>
</table>
</form>
<table cellspacing="0" cellpadding="0" border="0">
<tr>
    <td bgcolor="#ffffff">
      
      


<?php
  if(basename($PHP_SELF)=="login.$ext"){
    include phorum_get_file_name("footer");
  }
?>
