<?php

  if(empty($phorum_auth) && $ForumSecurity > SEC_OPTIONAL && initvar("read")){
    $target=$REQUEST_URI;
    include "./noiselogin.$ext";
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
    $artist=stripslashes($artist);
    $rating=stripslashes($rating);
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
    $p_artist="";
    $p_rating="";
  }
  else{
    $caption = $lStartTopic;
    $p_subject=initvar("subject");
    $p_body=initvar("body");
    $p_artist=initvar("artist");
    $p_rating=initvar("rating");
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
<form name="sendmessageform" action="makenoises.php" method="post" target="feeder" enctype="<?php echo $enctype ?>">
<input type="hidden" name="t" value="<?php  echo $thread; ?>" >
<input type="hidden" name="a" value="post" >
<input type="hidden" name="f" value="<?php echo $num; ?>" >
<input type="hidden" name="p" value="<?php echo $parent; ?>" >
<INPUT TYPE="hidden" name="subject" value="noisy life">
<input type="hidden" name="email" value="<?php echo $p_email; ?>" >

<?php echo $PostVars; ?>
<table align=CENTER cellspacing="0" cellpadding="0" border="0">

<tr>
  <td>
    <table width="218" class="replytable" cellspacing="0" cellpadding="0" border="0">

<?php if(!empty($phorum_user["moderator"])){ ?>    
   <?php if(!empty($phorum_auth) && !empty($p_author)){ ?>
    <tr>
        <td  WIDTH="100%" height="11" ALIGN="RIGHT" nowrap="nowrap"><font color="#768abe"><A CLASS="LOGGED">LOGGED IN:&nbsp;<B><?php echo $p_author; ?></B></font><input type="hidden" name="author" value="<?php echo $p_author; ?>" ></A></td></tr>

<TR HEIGHT="11"><TD>&nbsp;</TD></TR>   

<table border="0" cellpadding="3" cellspacing="0" width="206">

<tr>
				<td width="136">
					<div align="right">
						<b>artist</b></div>
				</TD>
				<TD>
					<div align="left">
						<input type="text" name="artist" size="24" style="background-color: white; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;"></div>
				</TD>
				</td>
</tr>
<TR>
				<td width="136">
					<div align="right">
						<b>song</b></div>
				</td>
				<td><input type="text" name="body" size="24" style="background-color: white; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;"></td>
			</tr>




<tr>
					<td width="136">
						<div align="right">
							<B>rating</B></div>
					</TD>
					<TD>
						<div align="left">
							<select name="rating" size="1" style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;">
								<option value="10">10</option>
								<option value="9">9</option>
								<option value="8">8</option>
								<option value="7">7</option>
								<option value="6">6</option>
								<option value="5">5</option>
								<option value="4">4</option>
								<option value="3">3</option>
								<option value="2">2</option>
								<option value="1">1</option>
							</select></div>
					</TD>
					</td>
</tr>
<TR>
					<td width="136"></td>
					<td><input type="submit" name="post" value="Go!" style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;"></td>
				</tr>

<?php } else { ?>

<?php } } ?>

</td>
    
    </table>
  </td>
</tr>

</table>
</form>