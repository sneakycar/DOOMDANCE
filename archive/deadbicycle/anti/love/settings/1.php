<?php
  // anti/love forum
  $PHORUM['ForumId']=1;
  $PHORUM['ForumActive']='1';
  $PHORUM['ForumName']='anti/love';
  $PHORUM['ForumDescription']='ambulence stuck in traffic';
  $PHORUM['ForumConfigSuffix']='';
  $PHORUM['ForumFolder']='0';
  $PHORUM['ForumParent']='0';
  $PHORUM['ForumLang']='lang/english.php';
  $PHORUM['ForumDisplay']='30';
  $PHORUM['ForumTableName']='traffic';
  $PHORUM['ForumModeration']='n';
  $PHORUM['ForumSecurity']='1';
  $PHORUM['ForumEmailList']='';
  $PHORUM['ForumEmailReturnList']='';
  $PHORUM['ForumEmailTag']='';
  $PHORUM['ForumCheckDup']='1';
  $PHORUM['ForumMultiLevel']='2';
  $PHORUM['ForumCollapse']='0';
  $PHORUM['ForumFlat']='0';
  $PHORUM['ForumAllowHTML']='1';
  $PHORUM['ForumAllowUploads']='N';
  $PHORUM['ForumUploadTypes']='';
  $PHORUM['ForumUploadSize']='0';
  $PHORUM['ForumMaxUploads']='0';
  $PHORUM['ForumTableBodyColor2']='#cce45b';
  $PHORUM['ForumTableBodyFontColor2']='#ffffff';
  $PHORUM['ForumShowIP']='0';
  $PHORUM['ForumAllowEMailNotify']='0';
  $PHORUM['ForumBodyColor']='#ffffff';
  $PHORUM['ForumBodyLinkColor']='#768abe';
  $PHORUM['ForumBodyALinkColor']='#768abe';
  $PHORUM['ForumBodyVLinkColor']='#768abe';
  $PHORUM['ForumTableWidth']='85%';
  $PHORUM['ForumTableHeaderColor']='#cce45b';
  $PHORUM['ForumTableHeaderFontColor']='#ffffff';
  $PHORUM['ForumTableBodyColor1']='#cce45b';
  $PHORUM['ForumTableBodyFontColor1']='#ffffff';
  $PHORUM['ForumNavColor']='#cce45b';
  $PHORUM['ForumNavFontColor']='#768abe';

  // expand the array into vars for legacy code.
  while(list($key, $value)=each($PHORUM)){
    $$key=$PHORUM[$key];
  }

?>