<?php

    require "./common2.php";


    if($phorum_user["moderator"]!=true){
    if(!$phorum_user) {
          header("Location: $list_page.$ext?f=$num$GetVars");
        } else {
          header("Location: $HTTP_REFERER");
        }
      exit;
    }

    if(empty($i) || empty($t)) {
      header("Location: $HTTP_REFERER");
      exit;
    }

    $id=(int)initvar("i");

    //Thats for all those ppl who likes to use different colors in different forums
    if($num!=0){
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


    //////////////////////////
    // START NAVIGATION     //
    //////////////////////////

    addnav($menu, $lGoToPost, "$read_page.$ext?f=$num&i=$i&t=$t$GetVars");

    if($ActiveForums>1){
        // Forum List
        addnav($menu, $lForumList, "$forum_page.$ext?f=$f$GetVars");
    }

    // Go To Top
    addnav($menu, $lGoToTop, "$list_page.$ext?f=$num$GetVars");

    // New Topic
    addnav($menu, $lStartTopic, "$post_page.$ext?f=$num$GetVars");

    // Search
    addnav($menu, $lSearch, "$search_page.$ext?f=$num$GetVars");

    // Log Out/Log In
    if(!empty($phorum_auth)){
        // Log Out
        addnav($menu, $lLogOut, "login.$ext?f=$f&logout=1$GetVars");

        //The profile of the logged in user
        if($id!=$phorum_user["id"])
            addnav($menu, $lMyProfile, "profile.$ext?f=$f&id=$phorum_user[id]$GetVars");
    }
    else{
        // Register
        addnav($menu, $lRegisterLink, "register.$ext?f=$f$GetVars");
        // Log In
        addnav($menu, $lLogIn, "login.$ext?f=$f$GetVars");
    }

    $nav=getnav($menu);

    //////////////////////////
    // END NAVIGATION       //
    //////////////////////////

    switch($mod) {
        case "update":
            if(!get_magic_quotes_gpc()){
              $author = addslashes($author);
              $email = addslashes($email);
              $subject = addslashes($subject);
              $attachment = @addslashes($attachment);
              $body = addslashes($body);
            }

            if($html){
                $body="<HTML>$body</HTML>";
            }

            if($bold){
                $subject="<strong>$subject</strong>";
                $author="<strong>$author</strong>";
            }

            if(is_array($attachments)){

                $del=array();
                while(list($key, $name)=each($attachments)){
                    if(isset($del_attachment[$key])){
                        $del[]=$key;
                        unlink("$AttachmentDir/".$PHORUM['ForumTableName']."/$id"."_$key".strtolower(strrchr($name, ".")));
                    }
                    elseif($new_attachment[$key]!=$name){
                        $SQL="Update ".$PHORUM['ForumTableName']."_attachments set filename='$new_attachment[$key]' where id=$key";
                        $q->query($DB, $SQL);
                    }
                }
                if(count($del)>0){
                    $SQL="Delete from ".$PHORUM['ForumTableName']."_attachments where id in (".implode(",", $del).")";
                    $q->query($DB, $SQL);
                }
            }

            $sSQL="Update $ForumTableName set author='$author', email='$email', subject='$subject' where id=$id";
            $q->query($DB, $sSQL);
            $sSQL="Update ".$PHORUM['ForumTableName']."_bodies set body='$body' where id=$id";
            $q->query($DB, $sSQL);

            header("Location: $read_page.$ext?f=$num&i=$i&t=$t$GetVars");
            exit;
        case "delete":
            include "$include_path/delete_message.php";
            delete_messages($i);
            if($i==$t){
                header("Location: $list_page.$ext?f=$num$GetVars");
            } else {
                header("Location: $read_page.$ext?f=$num&i=$t&t=$t$GetVars");
            }
            exit;
            break;
    }

    if(!empty($i)){
        $sSQL="Select author, email, subject, body from ".$PHORUM['ForumTableName']." as t, ".$PHORUM['ForumTableName']."_bodies as b where t.id=b.id and t.id=$i";
        $q->query($DB, $sSQL);
        $mtext = $q->getrow();
        if(substr($mtext["body"], 0, 6)=="<HTML>"){
            $mtext["body"]=ereg_replace("</*HTML>", "", $mtext["body"]);
            $html=1;
        } else {
            $html=0;
        }
        if(substr($mtext["subject"], 0, 3)=="<strong>"){
            $mtext["subject"]=ereg_replace("</*b>", "", $mtext["subject"]);
            $mtext["author"]=ereg_replace("</*b>", "", $mtext["author"]);
            $bold=1;
        } else {
            $bold=0;
        }
    }


    include phorum_get_file_name("header");

    // is there a message for the user?
    if(!empty($msg)) {
        print "<font class=PhorumForumTitle><strong>$msg</strong></font>";
    }
?>
<form action="<?php echo $PHP_SELF; ?>" method="POST">
<input type="hidden" name="mod" value="update" />
<input type="hidden" name="num" value="<?php echo $num; ?>" />
<input type="hidden" name="i" value="<?php echo $i; ?>" />
<input type="hidden" name="t" value="<?php echo $t; ?>" />
<input type="hidden" name="page" value="<?php echo $page; ?>" />
<input type="hidden" name="html" value="<?php echo $html; ?>" />
<input type="hidden" name="bold" value="<?php echo $bold; ?>" />

<?php
if (isset($mythread)) { ?>
<input type="hidden" name="mythread" value="<?php echo $mythread; ?>" />
<?php
}
?>

<table align="center" cellspacing="0" cellpadding="0" border="0">

<tr>
  <td bgcolor="#ffffff">
    <table class="PhorumListTable" cellspacing="0" cellpadding="2" border="0">

<tr>
    <th align="right" bgcolor="#ffffff"><font color="#768abe">&nbsp;Name:</font></th>
    <td bgcolor="#ffffff"><input type="Text" name="author" value="<?php echo $mtext["author"]; ?>" size="35" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"  /></td>
</tr>
<tr>
    <th align="right" bgcolor="#ffffff"><font color="#768abe">&nbsp;<?php echo $lEmail?>:</font></th>
    <td bgcolor="#ffffff"><input type="Text" name="email" value="<?php echo $mtext["email"]; ?>" size="35" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"  /></td>
</tr>
<tr>
    <th align="right" bgcolor="#ffffff"><font color="#768abe">&nbsp;<?php echo $lFormSubject?>:</font></th>
    <td bgcolor="#ffffff"><input type="Text" name="subject" value="<?php echo $mtext["subject"]; ?>" size="35" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"  /></td>
</tr>
<?php
if($PHORUM['AllowAttachments'] && $PHORUM['ForumAllowUploads'] == 'Y') {
  $SQL="Select id, filename from ".$PHORUM['ForumTableName']."_attachments where message_id=$id";
  $q->query($DB, $SQL);
  while($rec=$q->getrow()){
?>
<input type="hidden" name="attachments[<?php echo $rec["id"]; ?>]" value="<?php echo $rec["filename"]; ?>" />
<tr>
  <th bgcolor="#ffffff"><font color="#768abe">&nbsp;<?php echo $lFormAttachment?> [<?php echo $rec["id"]; ?>]:</font></th>
  <td bgcolor="#ffffff"><input type="Text" name="new_attachment[<?php echo $rec["id"]; ?>]" value="<?php echo $rec["filename"]; ?>" size="35" style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;"" class="TEXT" />&nbsp;&nbsp;<input TYPE="checkbox" name="del_attachment[<?php echo $rec["id"]; ?>]" VALUE="true" /> delete attachment</td>
</tr>
<?php
  }
}
?>
<tr>

    <td bgcolor="#ffffff" colspan=2 width="100%" nowrap="nowrap" align="left"><table cellpadding="5" cellspacing="0" border="0"><tr><td align="CENTER" valign="TOP"><font face="courier"><textarea name="body" cols="35" rows="10" wrap="VIRTUAL"><?php echo htmlspecialchars($mtext["body"]); ?></textarea></font></td></tr></table></td>
</tr>
</td>
</tr>
<tr>
<td bgcolor="#ffffff" colspan="2" align="RIGHT">
    <input type="Submit" name="post" value=" <?php echo $lFormUpdate;?> " style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;"/>&nbsp;<br /><img src="images/trans.gif" width=3 height=3 border=0></td>
    </tr>
    </table>
  </td>
</tr>
</table>
</form>
<?php

  include phorum_get_file_name("footer");
?>
