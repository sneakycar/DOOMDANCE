<?php

  if(empty($action)) $action="view";
  require "./common4.php";
  include "$PHORUM[include]/post_functions.php";

  initvar("done");
  if($action=="edit"){
      initvar("name");
      initvar("password");
      initvar("email");
      initvar("webpage");
      initvar("image");
      initvar("signature");
      initvar("icq");
      initvar("msn");
      initvar("aol");
      initvar("jabber");
      initvar("yahoo");
      initvar("done");
      initvar("Error");
      initvar("process");
  }

  //Thats for all those ppl who likes to use different colors in different forums
  if($f!=0){
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

  //Post Count Function
  function Count_Posts($user_id){
  global $DB,$pho_main;
  //Get list of the forums
  $sql="Select distinct(table_name) from ".$pho_main." where active='1' AND folder='0'";
  $q=new query($DB, $sql);
  $forums=$q->getrow();
  $totalposts=0;
  //Output them in the scipt
  while(is_array($forums)){
    //Count posts in each forum
    $sql="SELECT count(*) as posts FROM $forums[table_name] WHERE userid='$user_id'";
    $query=new query($DB, $sql);
    $rec=$query->getrow();
    $posts=$rec['posts'];
    //Add Them To totals
    $totalposts=$totalposts+$posts;
    $forums=$q->getrow();
  }
  return $totalposts;
  }

  if($id){
    $user_id=$id;
    $SQL="Select * from $pho_main"."_auth where id='$user_id'";
    $q->query($DB, $SQL);
    $rec=$q->getrow();
    if(!is_array($rec))
      $error=$lNoUser;
    $UserName=$rec["username"];
  }else{
    $error=$lNoId;
  }
  $title = " - $lUserProfile";
  if(!empty($password) && !empty($checkpassword)){
  $ChangePass=false;
  if($password!=$checkpassword)
    $EditError=$lNoPassMacth;
  else
    $ChangePass=true;
  }

  if(!empty($name) && !empty($email)){
    if($password!=$checkpassword){
        $EditError=$lNoPassMacth;
    } elseif(censor_check(array($name, $email, $webpage, $image, $signature, $icq, $msn, $aol, $yahoo, $jabber))) {
        $EditError=$lRegistrationCensor;
    } else {


        $safe_name=htmlspecialchars($name);
        $safe_email=htmlspecialchars($email);
        $safe_webpage=htmlspecialchars($webpage);
        $safe_image=htmlspecialchars($image);
        $safe_signature=htmlspecialchars($signature);
        $safe_icq=htmlspecialchars($icq);
        $safe_msn=htmlspecialchars($msn);
        $safe_aol=htmlspecialchars($aol);
        $safe_yahoo=htmlspecialchars($yahoo);
        $safe_jabber=htmlspecialchars($jabber);

        if(!get_magic_quotes_gpc()){
            $safe_name=addslashes($safe_name);
            $safe_email=addslashes($safe_email);
            $safe_webpage=addslashes($safe_webpage);
            $safe_image=addslashes($safe_image);
            $safe_signature=addslashes($safe_signature);
            $safe_icq=addslashes($safe_icq);
            $safe_msn=addslashes($safe_msn);
            $safe_aol=addslashes($safe_aol);
            $safe_yahoo=addslashes($safe_yahoo);
            $safe_jabber=addslashes($safe_jabber);
        }

        $SQL="select id, name, email from ".$pho_main."_auth where (name='$safe_name' or email='$safe_email')";
        if(!empty($id)) $SQL.=" and id!=$user_id";
        //run query
        $q->query($DB,$SQL);
        if($q->numrows()>0){
          $check=$q->getrow();
          if(strtolower($check['name'])==strtolower($name))
            $EditError=$lDupName;
          if(strtolower($check['email'])==strtolower($email))
            $EditError=$lDupEmail;
          if($password!=$checkpassword)
            $EditError=$lNoPassMacth;
        } elseif(!empty($phorum_auth) && $UserName==$phorum_user["username"]) {
          // Change Password.
          $passsql="";
          if(!empty($ChangePass)){
            $crypt_pass=md5($password);
            $passsql=" password='$crypt_pass',";
          }
          $sSQL="UPDATE $pho_main"."_auth SET name='$safe_name',$passsql email='$safe_email', webpage='$safe_webpage', image='$safe_image', signature='$safe_signature', icq='$safe_icq', msn='$safe_msn', aol='$safe_aol', yahoo='$safe_yahoo', jabber='$safe_jabber'  WHERE id='$id'";
          $q->query($DB, $sSQL);
          $done=true;

          header("Location: $forum_url/feedprofile.$ext?f=$f&id=$id$GetVars");
          exit();
        }
    }
  }elseif(!empty($process)){
    $EditError=$lFillInAll;
  }
  include phorum_get_file_name("header");

  //////////////////////////
  // START NAVIGATION     //
  //////////////////////////

    if($ActiveForums>1)
      // Forum List
      addnav($menu, $lForumList, "$forum_page.$ext?f=$ForumParent$GetVars");
      // Go To Top
      addnav($menu, $lGoToTop, "$list_page.$ext?f=$num$GetVars");

      // New Topic
      addnav($menu, $lStartTopic, "$post_page.$ext?f=$num$GetVars");

      // Search
      addnav($menu, $lSearch, "$search_page.$ext?f=$num$GetVars");
      //Thats for stuff below


    // Log Out/Log In
    if(!empty($phorum_auth)){
      // Log Out
      addnav($menu, $lLogOut, "login.$ext?f=$f&logout=1$GetVars");
      if($id!=$phorum_user["id"])
        //The profile of the logged in user
        addnav($menu, $lMyProfile, "feedprofile.$ext?f=$num&id=$phorum_user[id]$GetVars");
    }
    else{
      // Register
      addnav($menu, $lRegisterLink, "register.$ext?f=$f$GetVars");
      // Log In
      addnav($menu, $lLogIn, "login.$ext?f=$f$GetVars");
    }

    if($action=="edit")
      //Back
      addnav($menu, $lBack, "feedprofile.$ext?f=$num&id=$id$GetVars");

    $nav=getnav($menu);

  //////////////////////////
  // END NAVIGATION       //
  //////////////////////////

//If user Edits Profile, and He did submit it yet.
if(($action=='edit' && !$done) || !empty($EditError)){
//Security, so that only Owner could edit it.
//NO go
if(empty($phorum_auth) || ($UserName!=$phorum_user["username"])){
?>
<table cellspacing="0" cellpadding="0" border="0">
<tr>
    <td><?php echo $nav; ?></td>
</tr>
<tr>
    <td>
        <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">
        <tr>
            <td height="21" ><FONT color="<?php echo $table_header_font_color; ?>">&nbsp;<?php echo $lEditProfileErrorTitle; ?></font></td>
        </tr>
        <tr>
            <td  nowrap="nowrap"><font color="#669933"><?php echo $lEditProfileError; ?></font></td>
        </tr>
        </table>
    </td>
</tr>
</table>
<?php
// Its yours
}else{
  if(!empty($EditError))
    echo "<p><strong>$EditError</strong>";
?>
<SCRIPT LANGUAGE="JavaScript">
    function textlimit(field, limit) {
        if (field.value.length > limit)
            field.value = field.value.substring(0, limit);
    }
</script>
<form action="<?php echo $PHP_SELF; ?>?f=<?php echo $f; ?>&id=<?php echo $id; ?>" method="post">
<input type="hidden" name="process" value="1" />
<input type="hidden" name="target" value="<?php echo $target; ?>" />
<input type="hidden" name="id" value="<?php echo $user_id; ?>" />
<?php echo $PostVars; ?>
<table width="300" cellspacing="0" cellpadding="0" border="0">

<tr>
    <td>
        <table width="80%" class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">
         
<tr>
            <td height="21" colspan="2" ><FONT color="#768abe"></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lFormName;?>*:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="name" size="30" maxlength="50" value="<?php echo $rec['name']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lFormEmail;?>*:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="email" size="30" maxlength="50" value="<?php echo $rec['email']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
<tr>
            <td  align="right" nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lImageURL;?>:&nbsp;&nbsp;</font></td>
            <td><input type="text" name="image" size="30" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;" maxlength="100" value="<?php echo $rec['image']; ?>" /></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lNewPass;?>:&nbsp;&nbsp;</font></td>
            <td ><input type="password" name="password" size="20" maxlength="20" value="" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lPassAgain; ?>:&nbsp;&nbsp;</font></td>
            <td ><input type="password" name="checkpassword" size="20" maxlength="20" value=""style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;" /></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lWebpage;?>:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="webpage" size="30" maxlength="100" value="<?php echo $rec['webpage']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">Says to the world:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="icq" size="30" maxlength="50" value="<?php echo $rec['icq']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">Coolness factor:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="aol" size="30" maxlength="50" value="<?php echo $rec['aol']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        <tr>
            <td align="right"  nowrap="nowrap"><font color="#669933">Choice love:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="msn" size="30" maxlength="50" value="<?php echo $rec['msn']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        <tr>
            <td align="right"  nowrap><font color="#669933">Take your coffee:&nbsp;&nbsp;</font></td>
            <td ><input type="text" name="yahoo" size="30" maxlength="50" value="<?php echo $rec['yahoo']; ?>" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"/></td>
        </tr>
        
        <tr>
            <td  nowrap>&nbsp;</td>
            <td ><input type="submit" value="<?php echo $lUpdateProfile; ?>" style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;"/>&nbsp;<br /><img src="images/trans.gif" width=3 height=3 border=0></td>
        </tr>
        </table>
    </td>
</tr>
</table>
</form>
<?php }//END if(empty($phorum_auth) || ($rec["username"]!=$phorum_user["username"]))
//If there was any errors, Output them in that table.
}elseif(isset($error)){ ?>
<table cellspacing="0" cellpadding="0" border="0">
<tr>
    <td bgcolor="orange">
      <table cellspacing="0" cellpadding="2" border="0">
        <tr>
          <td><?php echo $nav; ?></td>
        </tr>
      </table>
    </td>
</tr>
<tr>
    <td <?php echo bgcolor($nav_color); ?>>
        <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0" width="100%">
        <tr>
            <td height="21"><FONT color="<?php echo $table_header_font_color; ?>">&nbsp;<?php echo $lEditProfileErrorTitle; ?></font></td>
        </tr>
        <tr>
            <td nowrap><font color="#669933"><?php echo $error; ?></font></td>
        </tr>
        </table>
    </td>
</tr>
</table>
<?php //Show the Profile
}else{ ?>
<table cellspacing="0" cellpadding="0" border="0" width="<?php echo $table_width; ?>">
<tr>
    <td>
        <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0" width="80%">
        <tr>
            <td height="21" align="right" colspan="2"  width="100%">
            <?php  //Show [Edit Profile] if you are logged on and profile is yours.
            if(!empty($phorum_auth) && ($rec["username"]==$phorum_user["username"]))
                echo "&nbsp;&nbsp;</font><a href='$PHP_SELF?f=$f&id=$id&action=edit'><font color=\"#768abe\"><B>$lEditProfile</B></font></a>";
            ?>
            </font></td>
        </tr>
        <tr>
           <td width="100%" valign="top">
                <table cellspacing="0" cellpadding="2" border="0">
                <tr>
 <td colspan="2" align="center" ><?php if($rec['image']) echo "<img src=\"$rec[image]\" border=\"1\" border color=\"#ccff00\">"; ?></td>
            <?php if($done){ ?>
                </TR><TR>
                    <td align="right" nowrap colspan=2><font color="#669933">&nbsp;<strong><?php echo $lProfileUpdated; ?></strong></td>
                </tr>
                <?php } ?>
                <tr>
                    <td align="right"  nowrap><font color="#669933">&nbsp;<?php echo $lName;?>:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><B><?php echo $rec['name']; ?></B></font></td>
                </tr>
                <tr>
                    <td align="right" " nowrap><font color="#669933">&nbsp;<?php echo $lPosts;?>:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><?php echo Count_Posts($user_id); ?></font></td>
                </tr>
                <?php if($rec['email']){ ?>
                <tr>
                    <td align="right"  nowrap><font color="#669933">&nbsp;<?php echo $lEmail;?>:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><a class="linkdup" href="<?php echo htmlencode("mailto:".$rec['email']); ?>"><?php echo htmlencode($rec['email']); ?></a></font></td>
                </tr>
                <?php }
                if($rec['webpage']){ ?>
                <tr>
                    <td align="right" align="right"  nowrap="nowrap"><font color="#669933">&nbsp;<?php echo $lWebpage;?>:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><a class="linkdup" href="<?php echo $rec['webpage']; ?>" target="_blank"><?php echo $rec['webpage']; ?></a></font></td>
                </tr>
                <?php }
                if($rec['icq']){ ?>
                <tr>
                    <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;Says to the World:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><?php echo $rec['icq']; ?></font></td>
                </tr>
                <?php }
                if($rec['aol']){ ?>
                <tr>
                    <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;Coolness factor:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><?php echo $rec['aol']; ?></a></font></td>
                </tr>
                <?php }
                if($rec['msn']){ ?>
                <tr>
                    <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;Choice love:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><?php echo $rec['msn']; ?></font></td>
                </tr>
                <?php }
                if($rec['yahoo']){ ?>
                <tr>
                    <td align="right"  nowrap="nowrap"><font color="#669933">&nbsp;Takes the coffee:&nbsp;&nbsp;</font></td>
                    <td ><font color="#768abe"><?php echo $rec['yahoo']; ?></font></td>
                </tr>
                <?php }
                // show the sig to the user if it is their profile.
                //Also HTML is all converted, so you will see all the html, we should probably change it so it would show all html as in post, but not right now.
                if($rec["signature"] && ($rec["username"]==$phorum_user["username"])){ ?>
                
                <?php } ?>
                </table>
            </td>
        </tr>
        </table>
    </td>
</tr>
</table>
<?php   } //END if($action=='edit' && !$done)

  include phorum_get_file_name("footer");
?>
