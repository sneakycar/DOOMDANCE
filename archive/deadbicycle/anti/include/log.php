<script language="JavaScript" type="text/javascript">
<!--
function sendmessage ( selectedtype )
{
  document.sendmessageform.send.value = selectedtype ;
  document.sendmessageform.submit() ;
}
-->
</script>



<script type="text/javascript">
function locate()
{
location="http://www.deadbicycle.com/anti/index.php"
}
</script>

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



<?php echo $PostVars; ?>
<table align=CENTER cellspacing="0" cellpadding="0" border="0">

<tr>
  <td bgcolor="#ffffff">
    <table width="80%" class="replytable" cellspacing="0" cellpadding="0" border="0">

       <?php if(!empty($phorum_auth) && !empty($p_author)){ ?>
    <tr>
        <td  WIDTH="80%" height="11" ALIGN="RIGHT" bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe"><A CLASS="LOGGED">LOGGED IN:&nbsp;<B><?php echo $p_author; ?></B></font><input type="hidden" name="author" value="<?php echo $p_author; ?>" ></A></td></tr>
  <tr><TD HEIGHT="8">&nbsp;</TD></TR><TR>
          <td align="right"><?php echo empty($TopLeftNav) ? "&nbsp;" : $TopLeftNav; ?></td>
        </tr>        


<TR>
<TD>     <TD> <input type="hidden" name="email" value="<?php echo $p_email; ?>" ></td></TD><TR><TD>

</TD>
</TR>
  
       
    
    <?php } else { ?>
<TABLE>    <tr> <tr>
        <td  WIDTH="80%" height="11" ALIGN="RIGHT" bgcolor="#ffffff" nowrap="nowrap"><font color="#768abe"><A CLASS="LOGGED">YOU ARE NOT LOGGED IN, MY FRIEND&nbsp;<B></B></td></tr><TR>
  
        <td height="11"  bgcolor="#ffffff" nowrap="nowrap"></td></TR><TR>
          <td align="right"><?php echo empty($TopLeftNav) ? "&nbsp;" : $TopLeftNav; ?></td>
        </tr>        

    
    <?php } ?>

    </table>
  </td>
</tr>

</table>


</form>
