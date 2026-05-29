<?php


  define("PHORUM_ADMIN", 1);

  // if you move the admin out of the phorum dir, change this below.
  chdir("../");

  include "./common.php";

  $admindir = "love";

  include "$admindir/functions.php";

  // set a sensible error level:
  error_reporting  (E_ERROR | E_WARNING | E_PARSE);

  $myname="$PHP_SELF";

  if(empty($forum_url)){
    include "$admindir/pages/install.php";
    exit();
  } elseif($page=="setup"){
    $page="main";
  }

  if(isset($page))
    $page=basename($page);
  else
    $page="main";

  $forum_id = 0;

  include "$admindir/login.php";
  if($DB->connect_id) check_login();

  if($action && file_exists("$admindir/actions/$action.php"))
    include "$admindir/actions/$action.php";
 include "$admindir/header.php";

  if($page=="newforum"){
    $page="new";
    $folder="0";
  }elseif($page=="newfolder"){
    $page="new";
    $folder="1";
  }
  // check for an admin

  if(empty($PHORUM["admin_user"]["forums"][0]) && !empty($DB->connect_id)){
    while(list($fid, $value)=each($PHORUM["admin_user"]["forums"])){
        if($f==$fid){
            $ok=true;
            break;
        }
    }
    reset($PHORUM["admin_user"]["forums"]);

    if(!$ok){
        $page="moderate";
        $f=0;
    }

  }

  if(file_exists("$admindir/pages/$page.php")){
    include "$admindir/pages/$page.php";
  }

  include "$admindir/footer.php";

?>
