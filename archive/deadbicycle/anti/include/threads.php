<?php
  if (!isset($$phcollapse)) {
    $$phcollapse=0;
  }
?>
<DIV ALIGN="CENTER"><table width="85%" class="PhorumListTable" width="<?php echo $ForumTableWidth; ?>" cellspacing="0" cellpadding="0" border="0">
<tr>
    <td align="LEFT" width="50%" class="PhorumListHeader" <?php echo bgcolor($ForumTableHeaderColor); ?>><FONT color="<?php echo $ForumTableHeaderFontColor; ?>">&nbsp;<?php echo $lTopics;?><img src="images/trans.gif" border=0 width=1 height=24 align="absmiddle"></font></td>
    <td align="LEFT" width="30%" class="PhorumListHeader"  <?php echo bgcolor($ForumTableHeaderColor); ?> nowrap="nowrap"><FONT color="<?php echo $ForumTableHeaderFontColor; ?>"><?php echo $lAuthor;?>&nbsp;</font></td>
<?php if ( !initvar("read") && $$phcollapse != 0) { ?>
    <td align="LEFT" class="PhorumListHeader" align="center" <?php echo bgcolor($ForumTableHeaderColor); ?> width="40" nowrap="nowrap"><FONT color="<?php echo $ForumTableHeaderFontColor; ?>"><?php echo $lReplies;?>&nbsp;</font></td>
    <td align="LEFT" class="PhorumListHeader" bgcolor="#cce45b" width="75" nowrap="nowrap"><FONT color="<?php echo $ForumTableHeaderFontColor; ?>"><?php echo $lLatest;?></font></td>
<?php }else{ ?>
    <td align="LEFT" class="PhorumListHeader" <?php echo bgcolor($ForumTableHeaderColor); ?> width="115" nowrap="nowrap"><FONT color="<?php echo $ForumTableHeaderFontColor; ?>"><A CLASS="DATE"><?php echo $lDate;?></font></A></td>
<?php } ?>
</tr>
<?php
  $x=0;
  $loc=0;
  @reset($headers);
  $message = @current($headers);
  if(!$read){
    @reset($threads);
    $trec=@current($threads);
  }

  while (is_array($message)){
    if(($x%2)==0){
      $bgcolor=$ForumTableBodyColor1;
      $fcolor=$ForumTableBodyFontColor1;
    }
    else{
      $bgcolor=$ForumTableBodyColor2;
      $fcolor=$ForumTableBodyFontColor2;
    }
    $t_id=$message["id"];
    $t_thread=$message["thread"];
    $t_subject=chop($message["subject"]);
    if(!empty($users[$message["userid"]])){
        $t_author=$users[$message["userid"]]["name"];
        if(isset($moderators[$message["userid"]])){
            $t_author="<strong>$t_author</strong>";
        }
    } else {
        $t_author=chop($message["author"]);
    }
    $t_datestamp = date_format($message["datestamp"]);

    if( ($$phcollapse != 0) && (!$read) ){
      $t_latest=date_format($trec["latest"]);
      $t_maxid=$trec["maxid"];
    }
    $message = next($headers);

    if($t_thread!=$t_id){
      $img = '<img src="images/l.gif" border=0 width=12 align="top">';
      if(is_array($message)){
        if($t_thread==$message["thread"]){
          $img='<img src="images/t.gif" border=0 width=12 align="top">';
        }
      }
    }
    else{
      $img="<img src=\"images/trans.gif\" border=0 width=1 height=21 align=\"absmiddle\">";
      $loc=0;
    }

    if(initvar("id")==$t_id && $read=true){
      $t_subject = "<strong>$t_subject</strong>";
      $t_author = "<strong>$t_author</strong>";
      $t_datestamp = "<strong>$t_datestamp</strong>";
    }
    else{
      $t_subject="$n3b_gif <a href=\"$read_page.$ext?f=$num&i=$t_id&t=$t_thread$GetVars\" target=\"threads\">$t_subject</a>";
    }

    $color=bgcolor($bgcolor);
    echo "<tr>";
    echo '  <td align="LEFT" class="PhorumListRow" '.$color.'><FONT color="'.$fcolor.'">&nbsp;'.$img.'&nbsp;'.$t_subject."&nbsp;</font>";

    if($UseCookies){
      $isnew=false;
      if($$phcollapse != 0 && !$read){
        // collapsed code
        if($use_haveread){
          if ($old_message<$t_maxid) {
            if(!IsSet($haveread[$t_maxid])) {
              $isnew=true;
            }
          }
        }
        elseif($old_message<$t_maxid){
          $isnew=true;
        }
      } else {
        // expanded code
        if ($use_haveread) {
          if ($old_message<$t_id) {
            if(!isset($haveread[$t_id])){
              $isnew=true;
            }
          }
        } elseif ($old_message<$t_id) {
          $isnew=true;
        }
      }
      if($isnew){
        echo "<font class=\"PhorumNewFlag\">".$lNew."</font>";
      }
    }

    echo "</td>";
    echo '  <td align="LEFT" width="40%" class="PhorumListRow" '.$color.' nowrap="nowrap"><FONT color="'.$fcolor.'">'.$t_author.'&nbsp;</font></td>'."";
    if( $$phcollapse != 0 && !$read ){
      $t_count=$trec["tcount"]-1;
      $trec=next($threads);
      echo '  <td align="LEFT" width="15%" class="PhorumListRow"  '.$color.' nowrap="nowrap"><FONT color="'.$fcolor.'" size=-1>'.$t_count."&nbsp;</font></td>";
      echo '  <td align="LEFT" width="35%" class="PhorumListRow" '.$color.' nowrap="nowrap"><FONT color="'.$fcolor.'" size=-1>'.$t_latest."&nbsp;</font></td>";
    }
    else{
      echo '  <td align="LEFT" width="20%" class="PhorumListRow" '.$color.' nowrap="nowrap"><A CLASS="DATE"><FONT color="'.$fcolor.'" size=-2>'.$t_datestamp.'&nbsp;</font></A></td>'."";
    }
    echo "</tr>";
    $x++;
    $loc++;
  } // end while
?>
</table></DIV>