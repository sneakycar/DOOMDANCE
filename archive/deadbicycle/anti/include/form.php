<?php

  if(empty($phorum_auth) && $ForumSecurity > SEC_OPTIONAL && initvar("read")){
    $target=$REQUEST_URI;
    include "./login.php";
    return;
  }
  elseif(!empty($phorum_auth)){
    $author=$phorum_user["name"];
    $email=$phorum_user["email"];
  }
  else{

    $name_cookie="phorum_name";
    if(isset($$name_cookie) && empty($author)){
      $author=$$name_cookie;
    }
    elseif(!isset($author)){
      $author="";
    }

    $email_cookie="phorum_email";
    if(isset($$email_cookie) && empty($email)){
      $email=$$email_cookie;
    }
    elseif(!isset($email)){
      $email="";
    }

  }

  if(get_magic_quotes_gpc()){
    $email=stripslashes($email);
    $author=stripslashes($author);
    if(!empty($subject)) $subject=stripslashes($subject);
    $body=stripslashes($body);
  }

  $quote_button="";

  if(initvar("read")!=false){
    $caption = $lReplyMessage;
    if(!eregi("^re:", $qsubject)){
      $p_subject="Re: ".$qsubject;
    }
    else{
      $p_subject= $qsubject;
    }

    $parent=$id;
    if(!$$phflat){
      $quote = "$qauthor $lWrote:\n";
      $quote .= textwrap("\n$qbody", 63, "\n", "> ") . "\n";
      $quote = htmlspecialchars($quote);
      $quote_button="<input type=\"hidden\" name=\"hide\" value=\"".$quote."\"><script language=\"JavaScript\"><!--\nthis.document.writeln('<input tabindex=\"100\" type=\"Button\" name=\"quote\" value=\"$lQuote\" onClick=\"this.form.body.value=this.form.body.value + this.form.hide.value; this.form.hide.value='+\"''\"+';\">');//--></script>";
    }
    $p_body="";
  }
  else{
    $caption = $lStartTopic;
    $p_subject=initvar("subject");
    $p_body=initvar("body");
  }
  $p_author=$author;
  $p_email=$email;

?>

<?php
  if ($AllowAttachments && $ForumAllowUploads == 'Y' && $ForumMaxUploads<4) {
    $enctype = "multipart/form-data";
  } else {
    $enctype = "application/x-www-form-urlencoded";
  }
?>
<?php
  if(isset($IsError) && $action){
    echo "<p><strong>$IsError</strong>";
  } else {
?>

<form name="sendmessageform" action="post.php" method="post" target="threads" enctype="<?php echo $enctype ?>" onSubmit="post.disabled=true;">
<input type="hidden" name="t" value="<?php  echo $thread; ?>" >
<input type="hidden" name="a" value="post" >
<input type="hidden" name="f" value="<?php echo $num; ?>" >
<input type="hidden" name="p" value="<?php echo $parent; ?>" >
<?php echo $PostVars; ?>
<table align=CENTER cellspacing="0" cellpadding="0" border="0">

<tr>
  <td bgcolor="#ffffff">
    <table width="80%" class="replytable" cellspacing="0" cellpadding="0" border="0">

       <?php if(!empty($phorum_auth) && !empty($p_author)){ ?>
    <tr>
        <td  WIDTH="80%" height="11" ALIGN="RIGHT" bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe"><A CLASS="LOGGED">LOGGED IN:&nbsp;<B><?php echo $p_author; ?></B></font><input type="hidden" name="author" value="<?php echo $p_author; ?>" ></A></td></tr>

    <tr>
       <TD> <input type="hidden" name="email" value="<?php echo $p_email; ?>" ></td>
       
    </tr><TR HEIGHT="11"><TD>&nbsp;</TD></TR>
    <?php } else { ?>
<TABLE>    <tr>
        <td height="11"  bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe"><?php echo $lFormName;?>:</font></TD><TD><input type="Text" name="author" size=30 maxlength=40 style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="<?php echo $p_author; ?>" ></td></TR>
    
    <tr>
        <td height="11" bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe"><?php echo $lFormEmail;?>:</font></TD><TD><input type="Text" name="email" size=30 maxlength=50 style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="<?php echo $p_email; ?>" ></td>
    </tr></TABLE><TR><TD HEIGHT="11">&nbsp;</TD></TR>
    <?php } ?>
    <tr>
       <td height="11" bgcolor="#ffffff" colspan=2 nowrap="nowrap"><font color="#768abe"><?php echo $lFormSubject;?>:</font></td></TR>
<TR><TD HEIGHT="4" colspan=2 BGCOLOR="#ffffff"></TD></TR>
        <TR><td height="11" colspan=2 bgcolor="#ffffff"><input type="Text" name="subject" size=40 style="font-family:Verdana, Geneva; font-size:8pt;border: 1 solid; border-color: #768abe;" maxlength=100" value="<?php echo $p_subject; ?>" ></td>
    </tr>
    <?php
      if ($AllowAttachments && $ForumAllowUploads == 'Y' && $ForumMaxUploads<4) {
        for($x=0;$x<$ForumMaxUploads;$x++){
          echo "<tr>\n";
          echo '    <td height="11" ' . bgcolor($ForumTableBodyColor1) . ' nowrap="nowrap"><font color="' . $ForumTableBodyFontColor1 . '">&nbsp;' . $lFormAttachment . ':</font></td>';
          echo '    <td height="11" ' . bgcolor($ForumTableBodyColor1) . '><input type="File" name="attachment_'.$x.'" size="30" maxlength="64"></td>';
          echo "</tr>";
        }
      }
    ?>
    <TR HEIGHT="11"><TD bgcolor="#ffffff"></TD></TR><tr><TD><A CLASS="forumnormal">Message:</A></TD></TR>
<TR HEIGHT="4"><TD>&nbsp;</TD></TR>
       <TR> <td bgcolor="#ffffff" width="100%" nowrap="nowrap" align="left"><table cellpadding="0" cellspacing="0" border="0"><tr><td align="CENTER" valign="TOP"><font face="courier"><textarea class="forumnormal" name="body" cols="40" rows="10" wrap="VIRTUAL" border: 1 solid; border-color: #768abe;" wrap=virtual style="font-family:Verdana, Geneva; font-size:8pt;"><?php echo $p_body; ?></textarea></font></td></tr></table></td>
    </tr>
    <?php if(!empty($phorum_user["signature"])){ ?>
    <tr>
        <td bgcolor="#ffffff" colspan=2 width="100%" nowrap="nowrap" align="left"><font color="#768abe"><input type="checkbox" name="use_sig" value="Y" checked /><?php echo $lUseSig; ?></font></td>
    </tr>
    <?php } ?>
    <?php if($ForumModeration!="a" && ($ForumAllowEMailNotify || (!empty($phorum_auth)))){ ?>
    <tr>
        <td bgcolor="#ffffff" colspan=2 width="100%" nowrap="nowrap" align="left"><font color="#768abe"><input type="checkbox" name="email_reply" value="Y"><?php echo $lEmailMe; ?></font></td></TR>
    <?php } ?>
    <tr>
        <td width="100%" colspan="2" align="RIGHT" bgcolor="#ffffff">&nbsp;
    <?php  if ($AllowAttachments && $ForumAllowUploads == 'Y' && $ForumMaxUploads>3) { ?>
        <input type="Submit" name="attach" value=" <?php echo $lFormAttach;?> " />&nbsp;
    <?php } ?>
</td>
    <TR><TD>    <input type="Submit" name="post" value=" <?php echo $lFormPost;?> " style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;" />&nbsp;<br /><img src="images/trans.gif" width=3 height=3 border=0></td>
</tr>
    </table>
  </td>
</tr>

</table>
</form>
<?php } ?>