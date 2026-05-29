<?php


  define("PHORUM_ADMIN", 1);
  require "./common.php";
  $title = $lForumDown;
  include phorum_get_file_name("header");
?>
<center>
<table class="PhorumListTable" width="<?php echo $default_table_width; ?>" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td class="PhorumTableHeader" <?php echo bgcolor($default_table_header_color); ?> valign="TOP" nowrap="nowrap"><font color="<?php echo $default_table_header_font_color; ?>">&nbsp;<?php echo $lForumDown; ?></font></td>
  </tr>
  <tr>
    <td width="100%" align="LEFT" valign="MIDDLE" <?php echo bgcolor($default_table_body_color_2); ?>><font color="<?php echo $default_table_body_font_color_1; ?>"><?php echo $lForumDownNotice; ?></font><br /></td>
  </tr>
</table>
</center>
<?php

  include phorum_get_file_name("footer");
?>