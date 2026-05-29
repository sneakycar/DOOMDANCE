<?php

$read=true;

require "./common4.php";
require "$include_path/read_functions.php";


$thread=(int)initvar("t");
$action=(int)initvar("a");
$id=(int)initvar("i");
$qsubject=initvar("s");

include phorum_get_file_name("header");
require "$include_path/feedform.php";
include phorum_get_file_name("footer");
?>