<?php


  require "./common2.php";

  if($num==0 || $ForumName==''){
    Header("Location: $forum_url/$forum_page.$ext?$GetVars");
    exit;
  }

  include "$include_path/read_functions.php";

  /////////////////////////////////////////////////////////////////
  // build the search terms array
  // this will build the array to pass to build_sql()

  function build_search_terms($search, $match) {
    $terms=array();

    // if this is an exact phrase match
    if($match==3){
      $terms[]=$search;
    }
    // not exact phrase, break up the terms
    else{
      if ( strstr( $search, '"' ) ){
        //first pull out all the double quoted strings
        if(strstr($search, "\"")){
          $search_string=$search;
          while(ereg('-*"[^"]*"', $search_string, $match)){
            $terms[]=trim(str_replace("\"", "", $match[0]));
            $search_string=substr(strstr($search_string, $match[0]), strlen($match[0]));
          }
        }
        $search = ereg_replace('-*"[^"]*"', '', $search );
      }

      //pull out the rest words in the string
      $regular_terms = explode( " ", $search);

      //merge them all together and return
      while (list ($key, $val) = each ($regular_terms)) {
        if($val!="")
          $terms[]=trim($val);
      }
    }
    return $terms;
  }

  /////////////////////////////////////////////////////////////////
  // build the sql statement's where clause
  // this will build the sql based on the given information

  function  build_terms_clause($terms, $date, $fields, $match){

    global $DB;
    static $where_clause;

    if(empty($where_clause)){
      if($date!=0){
        $cutoff=date("Y-m-d", mktime(0,0,0,date("m"),date("d")-$date));
        $where_clause .= " datestamp >= '$cutoff' AND ";
      }


      while (list ($junk, $term) = each ($terms)) {
        if(substr($term, 0, 1)=="-"){
          if(strstr($DB->type, "postgresql")){
            $notmod="!";
          } else {
            $notmod="NOT ";
          }
          $term=substr($term, 1);
        } else {
          $notmod="";
        }
        reset($fields);
        unset($likeArray);
        while (list ($key, $val) = each ($fields)) {
          $term=addslashes($term);
          if(strstr($DB->type, "postgresql")){
            $likeArray[]=" upper($val) $notmod"."~~ upper('%$term%') ";
          }
          else{
            $likeArray[]=" $val $notmod"."LIKE '%$term%' ";
          }
        }
        $termArray[] = " (".implode( $likeArray, " OR " ).") ";
      }

      $cmptype="AND";
      if($match!=1) $cmptype="OR";
      $where_clause.= " (".implode( $termArray, " $cmptype " ).") ";

      $where_clause.="order by datestamp desc";
    }

    return $where_clause;

  }

  /////////////////////////////////////////////////////////////////
  // build the sql statement
  // this will build the sql based on the given information

  function  build_sql($table_name, $terms, $date, $fields, $match){

    global $ForumTableName;

    $SQL = "select $table_name.id, $table_name.thread, author, subject, datestamp, body from $table_name, $table_name"."_bodies where $table_name.id = $table_name"."_bodies.id and $table_name.approved='Y' AND";

    $SQL.=build_terms_clause($terms, $date, $fields, $match);

    return $SQL;
  }

  if(!isset($fldauthor) && !isset($fldsubject) && !isset($fldbody)){
    $fields[] = "subject";
    $fields[] = "body";
    $fldauthor=0;
    $fldsubject=1;
    $fldbody=1;
  }
  else{
    empty($fldauthor) ? $fldauthor=0 : $fields[] = "author";
    empty($fldsubject) ? $fldsubject=0 : $fields[] = "subject";
    empty($fldbody) ? $fldbody=0 : $fields[] = "body";
  }

  initvar("date", 30);
  initvar("globalsearch");
  initvar("match");
  initvar("start", 1);

  //////////////////////////
  // START NAVIGATION     //
  //////////////////////////

    $menu=array();
    if($ActiveForums>1)
      // Forum List
      addnav($menu, $lForumList, "$forum_page.$ext?f=$ForumParent$GetVars");
    // New Topic
    addnav($menu, $lStartTopic, "$post_page.$ext?f=$num$GetVars");
    // Go To Top
    addnav($menu, $lGoToTop, "$list_page.$ext?f=$num$GetVars");
    // Log Out/Log In
    if($ForumSecurity){
      if(!empty($phorum_auth)){
        addnav($menu, $lLogOut, "login.$ext?logout=1$GetVars");
        addnav($menu, $lMyProfile, "profile.$ext?f=$f&id=$phorum_user[id]$GetVars");
      }
      else{
        addnav($menu, $lLogIn, "login.$ext?f=$f$GetVars");
      }
    }

    $TopLeftNav=getnav($menu);

  //////////////////////////
  // END NAVIGATION       //
  //////////////////////////

  if (empty($search)){
    $search="";
    $searchtext="";
  }
  else{
    $search=trim(stripslashes($search));
    $searchtext = htmlentities($search);
    $terms = build_search_terms($search, $match);
    if(count($terms)>0){

      if($globalsearch){
        $SQL="Select id, name, table_name from $pho_main where";
        if(isset($searchforums)){
          $SQL.=" id in (".implode(",", $searchforums).")";
        }
        else{
          $SQL.=" (active=1 or id=$num)";
        }
        if(empty($phorum_auth)){
          $SQL.=" and security!=".SEC_ALL;
        }
        $q->query($DB, $SQL);
        $row = $q->getrow();
      }
      else{
        $row=array("id"=>$num, "name"=>$ForumName, "table_name"=>$ForumTableName);
      }
      $totalFound=0;
      $messagesCopied=0;
      $messages=array();
      while(is_array($row)){
        $forums[$row["id"]]=$row["name"];
        $SQL=build_sql($row["table_name"], $terms, $date, $fields, $match);
        $results[$row["id"]] = new query($DB, $SQL);
        $numrows=$results[$row["id"]]->numrows();
        if($numrows==0){
          unset($results[$row["id"]]);
        }
        else{
          $results[$row["id"]]->getrow();
          $totalFound+=$numrows;
        }
        if($globalsearch){
          $row = $q->getrow();
        }
        else{
          $row=0;
        }
      }

      if($globalsearch){
        $q->free();
      }


      $winner=1;
      $MessagesCopied=0;
      $MessagesMatched=0;
      while($MessagesCopied<$ForumDisplay && $winner!=0){
        $winner=0;
        reset($results);
        $highdate="";
        while(list($forum, $res)=each($results)){
          if(!empty($res->row)){
            if($res->field("datestamp")>$highdate){
              $highdate=$res->field("datestamp");
              $winner=$forum;
            }
          }
        }

        if($winner!=0){
          $MessagesMatched++;
          if($MessagesMatched>=$start){
            $MessagesCopied++;
            $row=$results[$winner]->row;
            $row["forum"]=$winner;
            $messages["$row[datestamp]-$winner-$row[id]"]=$row;
          }
          $results[$winner]->getrow();
          // if these match then there are no more rows in this result.
          if(empty($results[$winner]->row["id"]) || $row["id"]==$results[$winner]->row["id"]){
            unset($results[$winner]);
          }
        }
      }

    }
  }

  $sTitle=" ".strtolower($lSearch);

  include phorum_get_file_name("header");
?>
<?php
  if(@is_array($terms)){
?>

<table class="PhorumListTable" width="85%" cellspacing="0" cellpadding="4" border="0">
  <tr>
    <?php
      $end=count($messages)+$start-1;
      if($end>0){
        $range="$start-$end $lOf $totalFound";
      }
      else{
        $range="";
      }

    ?>
    <td bgcolor="#ffffff" valign="TOP" nowrap="nowrap"><font color="#663399"  class="PhorumTableHeader">&nbsp;<?php echo "$lSearchResults: $range";?></font></td>
  </tr>
<?php
    $bgcolor=bgcolor($ForumTableBodyColor1);
    if($totalFound>0){
      krsort($messages);
      $message=current($messages);
      $count=$start-1;
      While(is_array($message)){
        $count=$count+1;
        if(!isset($top_id)){
          $top_id=$message["id"];
        }
        $text=format_body($message["body"]);
        $text=chop(substr($text, 0, 200));
        $text=strip_tags($text);
        $text=str_replace(PHORUM_SIG_MARKER, "", $text);
        $link="$read_page.$ext?f=$message[forum]&i=$message[id]&t=$message[thread]$GetVars";
        $subject=chop($message["subject"]);
        $author=chop($message["author"]);
        $datestamp=date_format($message["datestamp"]);
        $forum=$forums[$message["forum"]];
        echo "<tr><td bgcolor=\"white\">\n";
        echo "<table width=\"100%\" cellpadding=\"1\" cellspacing=\"0\">\n";
        echo "  <tr>\n";
        echo "    <td width=\"5%\" nowrap=\"nowrap\" bgcolor=\"#ffdb1f\"><strong>&nbsp;$count.</strong></td>\n";
        echo "    <td width=\"47%\" bgcolor=\"#ffdb1f\"><a href=\"$link\"><strong>$subject</strong></a></td>\n";
        echo "    <td width=\"24%\" bgcolor=\"#ffdb1f\">$author&nbsp;&nbsp;&nbsp;</td>\n";
        echo "    <td width=\"24%\" bgcolor=\"#ffdb1f\">$datestamp</td>\n";
        echo "  </tr>\n";
        echo "</table>\n";
        echo "<blockquote>\n";
        echo "<font class=\"PhorumMessage\">$text</font><br /><br />\n";
        echo "</blockquote>\n";
        echo "</td></tr>\n";
        $last_id=$message["id"];
        $message=next($messages);
      }
    }
    else{
      echo "<tr>\n";
      echo "  <td nowrap=\"nowrap\" bgcolor=\"white\"><strong>$lNoMatches</strong></td>\n";
      echo "</tr>\n";
      $count = 0;
    }

    $prevmatch='';
    $morematch='';


    if($totalFound>$count){
      $startvar=$count+1;
      $morematch="<a href=\"$search_page.$ext?f=$num&search=".urlencode($search)."&globalsearch=$globalsearch&match=$match&date=$date&fldauthor=$fldauthor&fldsubject=$fldsubject&fldbody=$fldbody&start=$startvar$GetVars\"><FONT color=\"#768abe\">$lMoreMatches</font></a>";
    }
    if($start!=1){
      $startvar=$start-$ForumDisplay;
      $prevmatch="<a href=\"$search_page.$ext?f=$num&search=".urlencode($search)."&globalsearch=$globalsearch&match=$match&date=$date&fldauthor=$fldauthor&fldsubject=$fldsubject&fldbody=$fldbody&start=$startvar$GetVars\"><FONT color=\"#768abe\">$lPrevMatches</font></a>";
    }
    if($prevmatch || $morematch){
      echo "<tr>\n  <td colspan=\"3\" bgcolor=\"yellow\">\n";
      echo "<center><br /><br /><div class=nav><FONT color=\"#768abe\"><strong>";
      if($prevmatch) echo $prevmatch;
      if($prevmatch && $morematch) echo '&nbsp;&nbsp;|&nbsp;&nbsp;';
      if($morematch) echo $morematch;
      echo "</font></div><br /><br /></center>\n";
      echo "  </td>\n</tr>\n";
    }

?>
</table>
<br />
<?php
  }
?>
<form action="<?php echo "$PHP_SELF"; ?>" method="GET">
<?php echo $PostVars; ?>
<input type="hidden" name="f" value="<?php echo $num; ?>" />
<table class="PhorumListTable" width="<?php echo $ForumTableWidth; ?>" border="0" cellspacing="0" cellpadding="2">
  
  <tr>
    <td align="CENTER" valign="MIDDLE" bgcolor="#ffffff">
<table cellspacing="0" cellpadding="2" border="0">
<tr>
    <TD></TD><td bgcolor="#ffffff"><input type="Text" name="search" size="40" style="font-family:Verdana, Geneva; font-size:8pt; border: 1 solid; border-color: #768abe;" value="<?php echo $searchtext; ?>">&nbsp;<FONT COLOR="#768abe"><input type="Submit" value="<?php echo $lSearch;?>" style="background-color: yellow; font-family:Verdana, Geneva; font-size:8pt; color: 768abe; border: 1 solid; border-color: #768abe;/>&nbsp;&nbsp;</td></TR><TR>
<TR><TD HEIGHT="4" BGCOLOR="#ffffff">&nbsp;</TD><TD></TD></TR>
<TR><TD></TD><TD>&nbsp;</TD></TR>
    
</tr>
<TR><TD HEIGHT="7" bgcolor="#ffffff">&nbsp;</TD>

    <td bgcolor="#ffffff"><font color="#663399"><select name="globalsearch"><option value="0" style="font-family:Verdana, Geneva; font-size:8pt; border: 0 solid; border-color: #768abe;" <?php if($globalsearch==0) echo "selected"; ?>><?php echo $lSearchThisForum ?></option><option style="font-family:Verdana, Geneva; font-size:8pt; border: 0 solid; border-color: #768abe;" value="1" <?php if($globalsearch==1) echo "selected"; ?>><?php echo $lSearchAllForums ?></option></select>&nbsp;&nbsp;&nbsp;&nbsp;<select name="match"><option style="font-family:Verdana, Geneva; font-size:8pt; border: 0 solid; border-color: #768abe;" value="1" <?php if($match==1) echo "selected"; ?>><?php echo $lSearchAllWords ?></option><option value="2" <?php if($match==2) echo "selected"; ?>><?php echo $lSearchAnyWords ?></option><option value="3" <?php if($match==3) echo "selected"; ?>><?php echo $lSearchPhrase ?></option></select>&nbsp;&nbsp;&nbsp;&nbsp;<select name="date"><option value="30" <?php if($date==30) echo "selected"; ?>><?php echo $lSearchLast30; ?></option><option value="60" <?php if($date==60) echo "selected"; ?>><?php echo $lSearchLast60; ?></option><option value="90" <?php if($date==90) echo "selected"; ?>><?php echo $lSearchLast90; ?></option>
<option value="180" <?php if($date==180) echo "seleced"; ?>><?php echo $lSearchLast180; ?></option><option value="0" <?php if($date==0) echo "selected"; ?>><?php echo $lSearchAllDates; ?></option></select></font></td></tr>
<tr><TD>&nbsp;</TD></TR>
<TR>    <TD></TD><td bgcolor="#ffffff"><font color="#663399"><input type="checkbox" name="fldauthor" style="font-family:Verdana, Geneva; font-size:8pt; border: 0 solid; border-color: #768abe;" value="1" <?php if($fldauthor==1)  echo "checked"; ?> /> User</TD></TR><TR><TD></TD><TD bgcolor="#ffffff" colspan=2><input type="checkbox" name="fldsubject" value="1" <?php if($fldsubject==1)  echo "checked"; ?> style="font-family:Verdana, Geneva; font-size:8pt; border: 0 solid; border-color: #768abe;" /><?php echo $lFormSubject; ?></TD></TR><TR><TD></TD><TD bgcolor="#ffffff"><input type="checkbox" name="fldbody" style="font-family:Verdana, Geneva; font-size:8pt; border: 0 solid; border-color: #768abe;" value="1" <?php if($fldbody==1)  echo "checked"; ?> /> <?php echo $lMessageBodies; ?>&nbsp;&nbsp;&nbsp;</font></td>
</tr><TR><TD></TD><td bgcolor="#ffffff"></td></TR>
</table>
</font><br /></td>
</td>
</tr>
</table>
</form>
<p>
<?php
  include phorum_get_file_name("footer");
?>
