<?php


  if(empty($f)) $f="0";

  require "./common.php";

  if($ActiveForums==1){
    $sSQL="Select id, folder from $pho_main where active=1";
    $q->query($DB, $sSQL);
    $rec=$q->getrow();
    if($rec["folder"]==0){
      header("Location: $forum_url/list.php?f=1&t=1&a=1");
      exit();
    }
  }

  $title = " - $lForumList";
  include phorum_get_file_name("header");

  if($f!=0){
    $level='';
    if($ForumParent!=0){
      $level="f=$ForumParent";
    }
    $table_width=$ForumTableWidth;
    $table_header_color=$ForumTableHeaderColor;
    $table_header_font_color=$ForumTableHeaderFontColor;
    $table_body_color_1=$ForumTableBodyColor1;
    $table_body_font_color_1=$ForumTableBodyFontColor1;
    $nav_color=$ForumNavColor;
    $nav_font_color=$ForumNavFontColor;

    addnav($menu, $lUpLevel, "$forum_page.$ext?$level$GetVars");
  }
  else{
    $table_width=$default_table_width;
    $table_header_color=$default_table_header_color;
    $table_header_font_color=$default_table_header_font_color;
    $table_body_color_1=$default_table_body_color_1;
    $table_body_font_color_1=$default_table_body_font_color_1;
    $nav_color=$default_nav_color;
    $nav_font_color=$default_nav_font_color;
  }

  //////////////////////////
  // START NAVIGATION     //
  //////////////////////////

    // Log Out/Log In
    if(isset($phorum_auth)){
      addnav($menu, $lLogOut, "login.$ext?logout=1$GetVars");
      addnav($menu, $lMyProfile, "profile.$ext?f=$f&id=$phorum_user[id]$GetVars");
    }
    else{
      $SQL="Select max(security) as sec from $pho_main";
      $q->query($DB, $SQL);
      if($q->field("sec", 0)){
          $url="login.$ext";
          if(!empty($f)) $url.="?f=$f";
          addnav($menu, $lLogIn, $url);
      }
    }

  //////////////////////////
  // END NAVIGATION       //
  //////////////////////////


  if(isset($menu) && is_array($menu)){
    $TopNav=getnav($menu);
?>
<table width="<?php echo $table_width; ?>" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td bgcolor="#cce45b" valign="TOP" nowrap="nowrap"><FONT COLOR="#ffffff"><?php echo $TopNav; ?></FONT></td>
  </tr>
</table>
<?php
  }
?>
<table class="PhorumListTable" width="85%" cellspacing="0" cellpadding="0" border="0">
<tr>
    <td class="PhorumTableHeader" width="5%" colspan="3" bgcolor="#cce45b"><FONT color="#ffffff">&nbsp;<?php echo $lAvailableForums;?></font></td>
</tr>
<?php
  if(isset($q)){
    $sSQL="Select id, name, table_name, parent, folder, description from ".$pho_main." where active=1 and parent=$f order by folder desc";
    if($SortForums) $sSQL.=", name";
    $q->query($DB, $sSQL);
    $rec=$q->getrow();
  } else {
    $rec = "";
  }

  if(is_array($rec)){
    while(is_array($rec)){
      $empty=false;
      $name=$rec["name"];
      $num=$rec["id"];
      $description=$rec["description"];
      if(!$rec["folder"]){
        $sSQL="select count(*) as posts from $rec[table_name] where approved='Y'";
        $tq = new query($DB, $sSQL);
        if($tq->numrows()){
          $trec=$tq->getrow();
          $num_posts=$trec["posts"];
        }
        else{
          $num_posts='0';
        }
        $sSQL="select max(datestamp) as max_date from $rec[table_name] where approved='Y'";
        $tq->query($DB, $sSQL);
        $trec=$tq->getrow();
        if(empty($trec["max_date"])){
          $last_post_date="";
        }
        else{
          $last_post_date=date_format($trec["max_date"]);
        }
        $posts="$lNumPosts: <strong>$num_posts</strong>&nbsp;&nbsp;";
        $last="$lLastPostDate: <strong>$last_post_date</strong>";
        $url="$list_page.$ext?f=$num$GetVars";
      }

      else{
        $last=$lForumFolder;
        $url="$forum_page.$ext?f=$num$GetVars";
      }

?>

<tr>
  <td nowrap="nowrap" bgcolor="#cce45b"><FONT color="#ffffff"> <a href="<?php echo $url; ?>"><?php echo $name; ?></a></td>
  <td nowrap="nowrap" bgcolor="#cce45b">&nbsp;&nbsp;<?php echo $posts; ?></td>
  <td nowrap="nowrap" bgcolor="#cce45b">&nbsp;&nbsp;<?php echo $last; ?></td>
</tr>
<tr>
  <td colspan=3 bgcolor="#cce45b"><FONT color="<?php echo $table_body_font_color_1; ?>"><blockquote><br /><?php echo $description; ?></blockquote></font></td>
</tr>
<?php
      $rec=$q->getrow();

    }

  }

  else{
?>

<?php
  }
?>
</table>
<?php
  include phorum_get_file_name("footer");
?>