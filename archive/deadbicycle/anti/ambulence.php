<?php


  require "./common3.php";

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
      $target=$HTTP_REFERER;
    }
    else{
      $target="$forum_url/$forum_page.$ext";
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

  if(empty($forgotpass) && !empty($username) && !empty($password)){
    $uid=phorum_check_login($username, $password);
    if($uid){
      $sess_id=phorum_session_id($HTTP_POST_VARS['username'], $HTTP_POST_VARS["password"]);
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
    $SQL="select username, email from $pho_main"."_auth where username='$lookup' or email='$lookup'";
    $q->query($DB, $SQL);
    $rec=$q->getrow();
    if(!empty($rec["username"])){
        $newpass=substr(md5($username.microtime()), 0, 8);
        $crypt_pass=md5($newpass);
        $SQL="update $pho_main"."_auth set password='$crypt_pass' where username='$rec[username]'";
        $q->query($DB, $SQL);
        mail($rec["email"], $lNewPassword, "$lNewPassBody:\n\n  $lUserName: $rec[username]\n  $lPassword:  $newpass\n\n$lNewPassChange", "From: <$DefaultEmail>");
        $Error=$lNewPassMailed;
    } else {
        $Error=$lNewPassError;
    }
  }

  if(basename($PHP_SELF)=="ambulence.php"){
    $title = " - $lLoginCaption";
    include phorum_get_file_name("header");
  }

  // hack
  $signup_page="register";

  //////////////////////////
  // START NAVIGATION     //
  //////////////////////////

    $menu="";
    if($ActiveForums>1){
      addnav($menu, $lForumList, "$forum_page.$ext?f=0$GetVars");
    }
    addnav($menu, $lRegisterLink, "$signup_page.$ext?f=$f&target=$target$GetVars");
    $nav=getnav($menu);

  //////////////////////////
  // END NAVIGATION       //
  //////////////////////////


  if($Error){
    echo "<p><strong>$Error</strong>";
  }
?>

<table class="PhorumListTable" width="80%" align="center" cellspacing="0" cellpadding="0" border="0">
<tr>
    <td bgcolor="#ffffff">
      
      

<form action="<?php echo "ambulence.php"; ?>" method="post">
<input type="hidden" name="f" value="<?php echo $f; ?>" />
<input type="hidden" name="target" value="<?php echo $target; ?>" />
<input type="hidden" name="forgotpass" value="1" />
<?php echo $PostVars; ?>
<table cellspacing="0" cellpadding="0" border="0">
<TR HEIGHT="14"><TD>&nbsp;</TD></TR>
<tr>
    <td <?php echo bgcolor($default_nav_color); ?>>

        <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">
        <tr>
            <td align="left" bgcolor="#ffffff"><input type="Text" name="lookup" size="30" maxlength="50" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"> <input type="submit" value="<?php echo $lSubmit; ?>" style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; font-color: #768abe; border: 1 solid; border-color: #768abe" /></td>
        </tr><TR HEIGHT="6"><TD></TD></TR>
<tr>
            <td bgcolor="#ffffff"><font color="#768abe"><A CLASS="lostpass"><?php echo $lLostPassExplain; ?></font></A></td>
        </tr>
        
        </table>
    </td>
</tr>
</table>
</form>

<?php
  if(basename($PHP_SELF)=="ambulence.php"){
    include phorum_get_file_name("footer");
  }
?>
