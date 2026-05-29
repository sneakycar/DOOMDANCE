<?php

  if(empty($phorum_auth) && $ForumSecurity > SEC_OPTIONAL && initvar("read")){
    $target=$REQUEST_URI;
    include "./login.$ext";
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
  if(isset($IsError) && $action){
    echo "<p><strong>$IsError</strong>";
  }
?>

<?php
  if ($AllowAttachments && $ForumAllowUploads == 'Y' && $ForumMaxUploads<4) {
    $enctype = "multipart/form-data";
  } else {
    $enctype = "application/x-www-form-urlencoded";
  }
?>



<form name="sendmessageform" action="castlepost.php" method="post" target="castle" enctype="<?php echo $enctype ?>" >
<input type="hidden" name="t" value="<?php  echo $thread; ?>" >
<input type="hidden" name="a" value="post" >
<input type="hidden" name="f" value="<?php echo $num; ?>" >
<input type="hidden" name="p" value="<?php echo $parent; ?>" >
<input type="hidden" name="subject" size="40" maxlength="20" value="castle" >
<input type="hidden" name="author" value="castlebuilder">
<input type="hidden" name="email" value="anon" >


<?php echo $PostVars; ?>
<table border="0" cellpadding="0" cellspacing="0" width="145">
<?php if(!empty($phorum_auth) && !empty($p_author)){ ?>
						<tr>
							<td align="right" width="148" valign="bottom"> <input type="text" name="body" size="8" maxlength="15" style="background-color: #cccccc; font-family:Verdana, Geneva, sans serif; font-size:8pt; color: #9b9b9b; border: 1 solid; border-color: #000000;"><?php echo $p_body; ?><input type="submit" name="post" style="background-color: #ccff00; font-family:Verdana, Geneva; font-size:7pt; color: #000000; border: 1 solid; border-color: #000000;" value="add";"><img src="images/trans.gif" width=3 height=3 border=0></td>
						</tr>
    




    <?php } else { ?>
						<tr>
							<td align="right" width="148" valign="bottom"> <input type="text" name="body" size="8" maxlength="15" style="background-color: #cccccc; font-family:Verdana, Geneva, sans serif; font-size:8pt; color: #9b9b9b; border: 1 solid; border-color: #000000;"><?php echo $p_body; ?><input type="submit" name="post" style="background-color: #ccff00; font-family:Verdana, Geneva; font-size:7pt; color: #000000; border: 1 solid; border-color: #000000;" value="add";"><img src="images/trans.gif" width=3 height=3 border=0></td>
						</tr>
   
       
   
<?php } ?>

					</table>
</form>
