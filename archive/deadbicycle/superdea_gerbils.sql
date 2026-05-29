# phpMyAdmin MySQL-Dump
# version 2.4.0
# http://www.phpmyadmin.net/ (download page)
#
# Host: localhost
# Generation Time: Apr 13, 2003 at 03:58 AM
# Server version: 3.23.55
# PHP Version: 4.2.3
# Database : `superdea_gerbils`
# --------------------------------------------------------

#
# Table structure for table `access`
#

CREATE TABLE access (
  id int(10) unsigned NOT NULL auto_increment,
  survey_id int(10) unsigned NOT NULL default '0',
  realm char(16) default NULL,
  maxlogin int(10) unsigned default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `access`
#

# --------------------------------------------------------

#
# Table structure for table `designer`
#

CREATE TABLE designer (
  username char(16) NOT NULL default '',
  password char(16) NOT NULL default '',
  auth char(16) NOT NULL default 'BASIC',
  realm char(16) NOT NULL default '',
  fname char(16) default NULL,
  lname char(24) default NULL,
  email char(64) default NULL,
  pdesign enum('Y','N') NOT NULL default 'Y',
  pstatus enum('Y','N') NOT NULL default 'N',
  pdata enum('Y','N') NOT NULL default 'N',
  pall enum('Y','N') NOT NULL default 'N',
  pgroup enum('Y','N') NOT NULL default 'N',
  puser enum('Y','N') NOT NULL default 'N',
  disabled enum('Y','N') NOT NULL default 'N',
  changed timestamp(14) NOT NULL,
  expiration timestamp(14) NOT NULL,
  PRIMARY KEY  (username,realm)
) TYPE=MyISAM;

#
# Dumping data for table `designer`
#

INSERT INTO designer VALUES ('root', '3f268e5b01736f6a', 'BASIC', 'superuser', 'ESP', 'Superuser', NULL, 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'N', 20020703013003, 00000000000000);
# --------------------------------------------------------

#
# Table structure for table `feed`
#

CREATE TABLE feed (
  id int(10) unsigned NOT NULL auto_increment,
  name char(50) NOT NULL default '',
  active smallint(6) NOT NULL default '0',
  description char(255) NOT NULL default '',
  config_suffix char(50) NOT NULL default '',
  folder char(1) NOT NULL default '0',
  parent int(10) unsigned NOT NULL default '0',
  display int(10) unsigned NOT NULL default '0',
  table_name char(50) NOT NULL default '',
  moderation char(1) NOT NULL default 'n',
  email_list char(50) NOT NULL default '',
  email_return char(50) NOT NULL default '',
  email_tag char(50) NOT NULL default '',
  check_dup smallint(5) unsigned NOT NULL default '0',
  multi_level smallint(5) unsigned NOT NULL default '0',
  collapse smallint(5) unsigned NOT NULL default '0',
  flat smallint(5) unsigned NOT NULL default '0',
  lang char(50) NOT NULL default '',
  html char(40) NOT NULL default 'N',
  table_width char(4) NOT NULL default '',
  table_header_color char(7) NOT NULL default '',
  table_header_font_color char(7) NOT NULL default '',
  table_body_color_1 char(7) NOT NULL default '',
  table_body_color_2 char(7) NOT NULL default '',
  table_body_font_color_1 char(7) NOT NULL default '',
  table_body_font_color_2 char(7) NOT NULL default '',
  nav_color char(7) NOT NULL default '',
  nav_font_color char(7) NOT NULL default '',
  allow_uploads char(1) NOT NULL default 'N',
  upload_types char(100) NOT NULL default '',
  upload_size int(10) unsigned NOT NULL default '0',
  max_uploads int(10) unsigned NOT NULL default '0',
  security int(10) unsigned NOT NULL default '0',
  showip smallint(5) unsigned NOT NULL default '1',
  emailnotification smallint(5) unsigned NOT NULL default '1',
  body_color char(7) NOT NULL default '',
  body_link_color char(7) NOT NULL default '',
  body_alink_color char(7) NOT NULL default '',
  body_vlink_color char(7) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY name (name),
  KEY active (active),
  KEY parent (parent),
  KEY security (security)
) TYPE=MyISAM;

#
# Dumping data for table `feed`
#

INSERT INTO feed VALUES (2, 'new', 1, '', '', '0', 0, 30, 'feeds', 'n', '', '', '', 1, 0, 1, 1, 'lang/english.php', '1', '', '', '', '', '', '', '', '', '', 'N', '', 0, 0, 2, 0, 0, '', '', '', '');
# --------------------------------------------------------

#
# Table structure for table `feed_auth`
#

CREATE TABLE feed_auth (
  id int(10) unsigned NOT NULL auto_increment,
  sess_id varchar(32) NOT NULL default '',
  name varchar(50) NOT NULL default '',
  username varchar(50) NOT NULL default '',
  password varchar(50) NOT NULL default '',
  email varchar(200) NOT NULL default '',
  webpage varchar(200) NOT NULL default '',
  image varchar(200) NOT NULL default '',
  icq varchar(50) NOT NULL default '',
  aol varchar(50) NOT NULL default '',
  msn varchar(50) NOT NULL default '',
  yahoo varchar(50) NOT NULL default '',
  jabber varchar(50) NOT NULL default '',
  signature varchar(255) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY name (name),
  KEY username (username),
  KEY sess_id (sess_id),
  KEY password (password)
) TYPE=MyISAM;

#
# Dumping data for table `feed_auth`
#

INSERT INTO feed_auth VALUES (1, '925189ac5f23c7dcee75911f6df2ae05', 'gerald', 'gerald', '6052b90d159180efd0e8fb153005af71', 'gerald@deadbicycle.com', 'http://www.deadbicycle.com', '', 'jump on the bandwagon', 'out of this world', 'harriet', 'black', '', '--------------------\r\ndon\'t worry janet, we\'re friends now.');
INSERT INTO feed_auth VALUES (2, '', 'exploding communist bicycle', 'exploding communist bicycle', '6052b90d159180efd0e8fb153005af71', 'television@anon.com', '', '', 'explode.  undergound.  super.', '7', '1962', 'no.', '', '');
INSERT INTO feed_auth VALUES (63, '7bcc66739a11e415d647e0169012cfe9', 'enokwons', '', '7bcc66739a11e415d647e0169012cfe9', 'enokwons@hotmail.com', '', '', '', 'splediforous', 'caffeeeiine', 'yes', '', '');
INSERT INTO feed_auth VALUES (64, '', 'willa', '', 'fafa80795449eb73c37c25f41875e71b', 'rbnvndrk@dordt.edu', '', '', '', '', '', '', '', '');
INSERT INTO feed_auth VALUES (29, '', 'henry and jill.', '', '6052b90d159180efd0e8fb153005af71', 'henryandjill@mtcnet.net', '', '', '', '', '', '', '', '');
INSERT INTO feed_auth VALUES (27, 'e4ed074045d4c33b53e68abef46e9a5f', 'micklynn', '', 'e4ed074045d4c33b53e68abef46e9a5f', 'micklynn@thinkwonder.com', '', '', '', '', '', '', '', '');
INSERT INTO feed_auth VALUES (28, 'e4ed074045d4c33b53e68abef46e9a5f', 'micklynn2000', '', 'e4ed074045d4c33b53e68abef46e9a5f', 'jim@thinkwonder.com', '', '', '', '', '', '', '', '');
INSERT INTO feed_auth VALUES (62, '8063a4a6fb6cd623f72517129ec06e92', 'clare', '', '8063a4a6fb6cd623f72517129ec06e92', 'claresol@hotmail.com', '', '', '', '', '', '', '', '');
# --------------------------------------------------------

#
# Table structure for table `feed_moderators`
#

CREATE TABLE feed_moderators (
  user_id int(10) unsigned NOT NULL default '0',
  forum_id int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (user_id,forum_id),
  KEY forum_id (forum_id)
) TYPE=MyISAM;

#
# Dumping data for table `feed_moderators`
#

INSERT INTO feed_moderators VALUES (1, 0);
# --------------------------------------------------------

#
# Table structure for table `feeder`
#

CREATE TABLE feeder (
  id int(10) unsigned NOT NULL auto_increment,
  name char(50) NOT NULL default '',
  active smallint(6) NOT NULL default '0',
  description char(255) NOT NULL default '',
  config_suffix char(50) NOT NULL default '',
  folder char(1) NOT NULL default '0',
  parent int(10) unsigned NOT NULL default '0',
  display int(10) unsigned NOT NULL default '0',
  table_name char(50) NOT NULL default '',
  moderation char(1) NOT NULL default 'n',
  email_list char(50) NOT NULL default '',
  email_return char(50) NOT NULL default '',
  email_tag char(50) NOT NULL default '',
  check_dup smallint(5) unsigned NOT NULL default '0',
  multi_level smallint(5) unsigned NOT NULL default '0',
  collapse smallint(5) unsigned NOT NULL default '0',
  flat smallint(5) unsigned NOT NULL default '0',
  lang char(50) NOT NULL default '',
  html char(40) NOT NULL default 'N',
  table_width char(4) NOT NULL default '',
  table_header_color char(7) NOT NULL default '',
  table_header_font_color char(7) NOT NULL default '',
  table_body_color_1 char(7) NOT NULL default '',
  table_body_color_2 char(7) NOT NULL default '',
  table_body_font_color_1 char(7) NOT NULL default '',
  table_body_font_color_2 char(7) NOT NULL default '',
  nav_color char(7) NOT NULL default '',
  nav_font_color char(7) NOT NULL default '',
  allow_uploads char(1) NOT NULL default 'N',
  upload_types char(100) NOT NULL default '',
  upload_size int(10) unsigned NOT NULL default '0',
  max_uploads int(10) unsigned NOT NULL default '0',
  security int(10) unsigned NOT NULL default '0',
  showip smallint(5) unsigned NOT NULL default '1',
  emailnotification smallint(5) unsigned NOT NULL default '1',
  body_color char(7) NOT NULL default '',
  body_link_color char(7) NOT NULL default '',
  body_alink_color char(7) NOT NULL default '',
  body_vlink_color char(7) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY name (name),
  KEY active (active),
  KEY parent (parent),
  KEY security (security)
) TYPE=MyISAM;

#
# Dumping data for table `feeder`
#

INSERT INTO feeder VALUES (1, 'feed', 1, '', '', '0', 0, 30, 'feeding', 'n', '', '', '', 1, 0, 1, 1, 'lang/english.php', '1', '', '', '', '', '', '', '', '', '', 'N', '', 0, 0, 2, 0, 0, '', '', '', '');
# --------------------------------------------------------

#
# Table structure for table `feeder_auth`
#

CREATE TABLE feeder_auth (
  id int(10) unsigned NOT NULL auto_increment,
  sess_id varchar(32) NOT NULL default '',
  name varchar(50) NOT NULL default '',
  username varchar(50) NOT NULL default '',
  password varchar(50) NOT NULL default '',
  email varchar(200) NOT NULL default '',
  webpage varchar(200) NOT NULL default '',
  image varchar(200) NOT NULL default '',
  icq varchar(50) NOT NULL default '',
  aol varchar(50) NOT NULL default '',
  yahoo varchar(50) NOT NULL default '',
  msn varchar(50) NOT NULL default '',
  jabber varchar(50) NOT NULL default '',
  signature varchar(255) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY name (name),
  KEY username (username),
  KEY sess_id (sess_id),
  KEY password (password)
) TYPE=MyISAM;

#
# Dumping data for table `feeder_auth`
#

INSERT INTO feeder_auth VALUES (1, '19361c0ac31c9b503ebd53ee2c662ae2', 'gerald', 'gerald', '6052b90d159180efd0e8fb153005af71', 'gerald@deadbicycle.com', 'http://www.deadbicycle.com', '', 'hello world.', 'not very cool.', 'black.  very black.', 'threshold.', '', '');
# --------------------------------------------------------

#
# Table structure for table `feeder_moderators`
#

CREATE TABLE feeder_moderators (
  user_id int(10) unsigned NOT NULL default '0',
  forum_id int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (user_id,forum_id),
  KEY forum_id (forum_id)
) TYPE=MyISAM;

#
# Dumping data for table `feeder_moderators`
#

INSERT INTO feeder_moderators VALUES (1, 0);
# --------------------------------------------------------

#
# Table structure for table `feeding`
#

CREATE TABLE feeding (
  id int(10) unsigned NOT NULL default '0',
  datestamp datetime NOT NULL default '0000-00-00 00:00:00',
  thread int(10) unsigned NOT NULL default '0',
  parent int(10) unsigned NOT NULL default '0',
  author char(37) NOT NULL default '',
  subject char(255) NOT NULL default '',
  email char(200) NOT NULL default '',
  host char(50) NOT NULL default '',
  email_reply char(1) NOT NULL default 'N',
  approved char(1) NOT NULL default 'N',
  msgid char(100) NOT NULL default '',
  modifystamp int(10) unsigned NOT NULL default '0',
  userid int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY author (author),
  KEY userid (userid),
  KEY datestamp (datestamp),
  KEY subject (subject),
  KEY thread (thread),
  KEY parent (parent),
  KEY approved (approved),
  KEY msgid (msgid),
  KEY modifystamp (modifystamp)
) TYPE=MyISAM;

#
# Dumping data for table `feeding`
#

INSERT INTO feeding VALUES (1, '2002-06-20 03:26:24', 1, 0, 'Admin', 'feed', 'gerald@deadbicycle.com', '', '', 'Y', '<ce2dba87dbe8fcb1ee95d6a24cdc673b.>', 1024602622, 1);
INSERT INTO feeding VALUES (2, '2002-06-20 04:20:04', 1, 1, 'gerald', 'Re: feed', 'gerald@deadbicycle.com', '', '', 'Y', '<feadbad84b0faad0b6124e3e7150fbfc.>', 1024602622, 1);
INSERT INTO feeding VALUES (3, '2002-06-20 04:24:29', 1, 1, 'gerald', 'Re: feed', 'gerald@deadbicycle.com', '', '', 'Y', '<25d1e7127df7a74d7e8e9bf03eeb728a.>', 1024602622, 1);
INSERT INTO feeding VALUES (4, '2002-06-20 14:51:52', 1, 1, 'gerald', 'Re: feed', 'gerald@deadbicycle.com', '', '', 'Y', '<5d677de9c00feafa2a62bf247e075c38.>', 1024602622, 1);
INSERT INTO feeding VALUES (5, '2002-06-20 15:50:22', 1, 1, 'gerald', 'Re: feed', 'gerald@deadbicycle.com', '', '', 'Y', '<ff3f4dc4e94bd45a01c7dd7f1fa22bcd.>', 1024602622, 1);
# --------------------------------------------------------

#
# Table structure for table `feeding_bodies`
#

CREATE TABLE feeding_bodies (
  id int(10) unsigned NOT NULL auto_increment,
  body text NOT NULL,
  thread int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY thread (thread)
) TYPE=MyISAM;

#
# Dumping data for table `feeding_bodies`
#

INSERT INTO feeding_bodies VALUES (1, '/FEED is here!  we just knew you couldn\'t wait for the day, so we\'re giving you everything you\'ve ever dreamed of.\n\nall your dreams are coming true.', 1);
INSERT INTO feeding_bodies VALUES (2, 'all night long we eat marshmallows and tell fairy tales.\n\nwe give our love to the folks at http://www.thinkwonder.com', 1);
INSERT INTO feeding_bodies VALUES (3, 'testing', 1);
INSERT INTO feeding_bodies VALUES (4, 'hey hey we\'re the monkees....', 1);
INSERT INTO feeding_bodies VALUES (5, 'http://www.deadbicycle.com', 1);
# --------------------------------------------------------

#
# Table structure for table `feeds`
#

CREATE TABLE feeds (
  id int(10) unsigned NOT NULL default '0',
  datestamp datetime NOT NULL default '0000-00-00 00:00:00',
  thread int(10) unsigned NOT NULL default '0',
  parent int(10) unsigned NOT NULL default '0',
  author char(37) NOT NULL default '',
  subject char(255) NOT NULL default '',
  email char(200) NOT NULL default '',
  host char(50) NOT NULL default '',
  email_reply char(1) NOT NULL default 'N',
  approved char(1) NOT NULL default 'N',
  msgid char(100) NOT NULL default '',
  modifystamp int(10) unsigned NOT NULL default '0',
  userid int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY author (author),
  KEY userid (userid),
  KEY datestamp (datestamp),
  KEY subject (subject),
  KEY thread (thread),
  KEY parent (parent),
  KEY approved (approved),
  KEY msgid (msgid),
  KEY modifystamp (modifystamp)
) TYPE=MyISAM;

#
# Dumping data for table `feeds`
#

INSERT INTO feeds VALUES (80, '2002-06-16 02:41:21', 79, 79, 'gerald', 'Re: waiting for the m62', 'gerald@deadbicycle.com', '', '', 'Y', '<5df14ab1b8d3264aa4f4d5f48d64b4e7.>', 1024553973, 1);
INSERT INTO feeds VALUES (77, '2002-06-16 01:40:56', 76, 76, 'henry and jill.', 'Re: flying kites on windy days', 'henryandjill@mtcnet.net', '', '', 'Y', '<0d0fa6d95beff0d5064c3de3aa7ba97d.>', 1024206056, 29);
INSERT INTO feeds VALUES (88, '2002-06-18 05:28:24', 79, 83, 'exploding communist bicycle', 'Re: waiting for the m62', 'television@anon.com', '', '', 'Y', '<0f6616124575689ab0e1511febe61129.>', 1024553973, 2);
INSERT INTO feeds VALUES (87, '2002-06-18 05:27:07', 79, 80, 'president george w. bush', 'Re: waiting for the m62', '', '', '', 'Y', '<5d208c6c7916a8cc1277e059a4117c4f.>', 1024553973, 0);
INSERT INTO feeds VALUES (86, '2002-06-18 05:01:52', 79, 83, 'gerald', 'Re: waiting for the m62', 'gerald@deadbicycle.com', '', '', 'Y', '<37f3bdeadfd079176dd8c0aff5568b63.>', 1024553973, 1);
INSERT INTO feeds VALUES (84, '2002-06-16 16:55:06', 79, 80, 'exploding communist bicycle', 'Re: waiting for the m62', 'television@anon.com', '', '', 'Y', '<f4e2170d8afc8d8e5f5ae0b7c2611cf1.>', 1024553973, 2);
INSERT INTO feeds VALUES (98, '2002-06-20 02:19:33', 79, 88, 'padded room', 'Re: waiting for the m62', '', '', '', 'Y', '<4562a26ef0e9235a0866d365ed5d51f5.>', 1024553973, 0);
INSERT INTO feeds VALUES (83, '2002-06-16 15:54:10', 79, 80, 'shoeface', 'Re: waiting for the m62', 'shoes@hotmail.com', '', '', 'Y', '<c865deef9acec2f41b377330be6f8325.>', 1024553973, 30);
# --------------------------------------------------------

#
# Table structure for table `feeds_bodies`
#

CREATE TABLE feeds_bodies (
  id int(10) unsigned NOT NULL auto_increment,
  body text NOT NULL,
  thread int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY thread (thread)
) TYPE=MyISAM;

#
# Dumping data for table `feeds_bodies`
#

INSERT INTO feeds_bodies VALUES (76, 'it\'s so hard, and it really doesn\'t have to be.  i\'m going to put a motor on mine...\n\nit will be great fun.\n\nand relaxing too!!\n\n\n-------------------\n\n[%sig%]', 76);
INSERT INTO feeds_bodies VALUES (78, 'we think that our child could have a lot fun of legos came with real life bricks.  this way the child could mix and match the use of bricks and legos.\n\nit would be perfection in the toy industry, that\'s what it would be.', 78);
INSERT INTO feeds_bodies VALUES (79, 'here we all come.\n\nmarching in from the docks.\n\nhelping out the world.\n\n"hello!"  we say.', 79);
INSERT INTO feeds_bodies VALUES (80, 'i agree.\n\nit\'s something of a problem in our society, i think...\n\n\n-------------------\n\n[%sig%]', 79);
INSERT INTO feeds_bodies VALUES (77, 'you have lost your mind, dear.\n\nlet\'s have us a cookoff.  we will win,  we are sure of it.\n\nwe cook the best hamburgers in town.  sometimes we even put cheese on them...', 76);
INSERT INTO feeds_bodies VALUES (86, 'agreed... 100%\n\n[%sig%]', 79);
INSERT INTO feeds_bodies VALUES (87, 'we all need a little time, fellas.', 79);
INSERT INTO feeds_bodies VALUES (88, 'i like sleeping.  it is fun and i have dreams sometimes about being a lumberjack.', 79);
INSERT INTO feeds_bodies VALUES (83, 'i think you\'ve been staying awake for much too long.\n\neveryone should get at least 8 hours of rest a night.   \n\nfailing to do so could result in poor thinking rationale.', 79);
INSERT INTO feeds_bodies VALUES (84, 'there are many things i wonder if i should be doing instead of cutting the grass and going on long strolls through the park.\n\nso come now, tell me...\nam i wrong?\n\nshould i buy different colored shoelaces?', 79);
INSERT INTO feeds_bodies VALUES (98, 'atom bomb.\n\nthe bomber.', 79);
# --------------------------------------------------------

#
# Table structure for table `gerbils`
#

CREATE TABLE gerbils (
  id int(255) NOT NULL auto_increment,
  r_id int(255) default NULL,
  subject varchar(100) NOT NULL default '',
  msg text NOT NULL,
  timi varchar(50) NOT NULL default '',
  date datetime NOT NULL default '0000-00-00 00:00:00',
  name varchar(100) NOT NULL default '',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `gerbils`
#

INSERT INTO gerbils VALUES (1, NULL, 'You Spy', 'I always knew you\'d come my way.  \r\n\r\nwhat else have you found?', 'Jun.10,  03:54am', '2002-06-10 03:54:14', 'exploding communist bicycle');
INSERT INTO gerbils VALUES (2, NULL, 'Re: You Spy', 'my mother and father don\'t speak anymore and it makes me angry,\r\n\r\ni\'ve suggested counseling, but they\'d have none of it.', 'Jun.10,  03:55am', '2002-06-10 03:55:54', 'dog eat cat');
INSERT INTO gerbils VALUES (3, NULL, 'Re:  You Spy', 'we still have not left the house, john.', 'Jun.11,  01:00pm', '2002-06-11 13:00:35', 'we');
INSERT INTO gerbils VALUES (4, NULL, 'Re:   You Spy', 'don\'t you even miss me?', 'Jun.11,  01:00pm', '2002-06-11 13:00:58', 'larry');
INSERT INTO gerbils VALUES (5, NULL, 'Re: You Spy', 'it\'s all true!  it\'s all true!!', 'Jun.11,  01:16pm', '2002-06-11 13:16:01', 'jonny was a racewalker');
INSERT INTO gerbils VALUES (6, NULL, 'we have built a treehouse', 'that\'s right!  we\'ve built a treehouse for our children! \r\n\r\ncome and play in it!\r\n\r\nit is fun!!', 'Jun.11,  01:54pm', '2002-06-11 13:54:55', 'televisions');
INSERT INTO gerbils VALUES (7, NULL, 'love the water', 'they love the water.\r\nthey love the love.\r\nthey hate their mothers.\r\n\r\nthey miss us.\r\n\r\nthey are far from home.\r\nwent to alabama, probably.', 'Jun.13,  03:52am', '2002-06-13 03:52:43', 'dark fish');
# --------------------------------------------------------

#
# Table structure for table `question`
#

CREATE TABLE question (
  id int(10) unsigned NOT NULL auto_increment,
  survey_id int(10) unsigned NOT NULL default '0',
  name varchar(30) NOT NULL default '',
  type_id int(10) unsigned NOT NULL default '0',
  result_id int(10) unsigned default NULL,
  length int(11) NOT NULL default '0',
  precise int(11) NOT NULL default '0',
  position int(10) unsigned NOT NULL default '0',
  content text NOT NULL,
  required enum('Y','N') NOT NULL default 'N',
  deleted enum('Y','N') NOT NULL default 'N',
  public enum('Y','N') NOT NULL default 'Y',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `question`
#

INSERT INTO question VALUES (1, 1, 'BATTLE', 4, NULL, 0, 10, 0, 'adolf or jim.', 'Y', 'N', 'Y');
# --------------------------------------------------------

#
# Table structure for table `question_choice`
#

CREATE TABLE question_choice (
  id int(10) unsigned NOT NULL auto_increment,
  question_id int(10) unsigned NOT NULL default '0',
  content text NOT NULL,
  value text,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `question_choice`
#

INSERT INTO question_choice VALUES (1, 1, 'adolf', NULL);
INSERT INTO question_choice VALUES (2, 1, 'jim', NULL);
# --------------------------------------------------------

#
# Table structure for table `question_type`
#

CREATE TABLE question_type (
  id int(10) unsigned NOT NULL auto_increment,
  type char(32) NOT NULL default '',
  has_choices enum('Y','N') NOT NULL default 'Y',
  response_table char(32) NOT NULL default '',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `question_type`
#

INSERT INTO question_type VALUES (1, 'Yes/No', 'N', 'response_bool');
INSERT INTO question_type VALUES (2, 'Text Box', 'N', 'response_text');
INSERT INTO question_type VALUES (3, 'Essay Box', 'N', 'response_text');
INSERT INTO question_type VALUES (4, 'Radio Buttons', 'Y', 'response_single');
INSERT INTO question_type VALUES (5, 'Check Boxes', 'Y', 'response_multiple');
INSERT INTO question_type VALUES (6, 'Dropdown Box', 'Y', 'response_single');
INSERT INTO question_type VALUES (8, 'Rate (scale 1..5)', 'Y', 'response_rank');
INSERT INTO question_type VALUES (9, 'Date', 'N', 'response_date');
INSERT INTO question_type VALUES (10, 'Numeric', 'N', 'response_text');
INSERT INTO question_type VALUES (99, 'Page Break', 'N', '');
INSERT INTO question_type VALUES (100, 'Section Text', 'N', '');
# --------------------------------------------------------

#
# Table structure for table `realm`
#

CREATE TABLE realm (
  name char(16) NOT NULL default '',
  title char(64) NOT NULL default '',
  changed timestamp(14) NOT NULL,
  PRIMARY KEY  (name)
) TYPE=MyISAM;

#
# Dumping data for table `realm`
#

INSERT INTO realm VALUES ('superuser', 'ESP System Administrators', 20020702235625);
# --------------------------------------------------------

#
# Table structure for table `respondent`
#

CREATE TABLE respondent (
  username char(16) NOT NULL default '',
  password char(16) NOT NULL default '',
  auth char(16) NOT NULL default 'BASIC',
  realm char(16) NOT NULL default '',
  fname char(16) default NULL,
  lname char(24) default NULL,
  email char(64) default NULL,
  disabled enum('Y','N') NOT NULL default 'N',
  changed timestamp(14) NOT NULL,
  expiration timestamp(14) NOT NULL,
  PRIMARY KEY  (username,realm)
) TYPE=MyISAM;

#
# Dumping data for table `respondent`
#

# --------------------------------------------------------

#
# Table structure for table `response`
#

CREATE TABLE response (
  id int(10) unsigned NOT NULL auto_increment,
  survey_id int(10) unsigned NOT NULL default '0',
  submitted timestamp(14) NOT NULL,
  complete enum('Y','N') NOT NULL default 'N',
  username char(16) default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `response`
#

INSERT INTO response VALUES (1, 1, 20020703014320, 'Y', '207.32.7.228');
INSERT INTO response VALUES (2, 1, 20020703014420, 'Y', '207.32.7.228');
INSERT INTO response VALUES (3, 1, 20020704042726, 'Y', '199.120.69.104');
INSERT INTO response VALUES (4, 1, 20020704052707, 'Y', '199.120.69.104');
# --------------------------------------------------------

#
# Table structure for table `response_bool`
#

CREATE TABLE response_bool (
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  choice_id enum('Y','N') NOT NULL default 'Y',
  PRIMARY KEY  (response_id,question_id)
) TYPE=MyISAM;

#
# Dumping data for table `response_bool`
#

# --------------------------------------------------------

#
# Table structure for table `response_date`
#

CREATE TABLE response_date (
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  response date default NULL,
  PRIMARY KEY  (response_id,question_id)
) TYPE=MyISAM;

#
# Dumping data for table `response_date`
#

# --------------------------------------------------------

#
# Table structure for table `response_multiple`
#

CREATE TABLE response_multiple (
  id int(10) unsigned NOT NULL auto_increment,
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  choice_id int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

#
# Dumping data for table `response_multiple`
#

# --------------------------------------------------------

#
# Table structure for table `response_other`
#

CREATE TABLE response_other (
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  choice_id int(10) unsigned NOT NULL default '0',
  response text,
  PRIMARY KEY  (response_id,question_id,choice_id)
) TYPE=MyISAM;

#
# Dumping data for table `response_other`
#

# --------------------------------------------------------

#
# Table structure for table `response_rank`
#

CREATE TABLE response_rank (
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  choice_id int(10) unsigned NOT NULL default '0',
  rank int(11) NOT NULL default '0',
  PRIMARY KEY  (response_id,question_id,choice_id)
) TYPE=MyISAM;

#
# Dumping data for table `response_rank`
#

# --------------------------------------------------------

#
# Table structure for table `response_single`
#

CREATE TABLE response_single (
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  choice_id int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (response_id,question_id)
) TYPE=MyISAM;

#
# Dumping data for table `response_single`
#

INSERT INTO response_single VALUES (1, 1, 1);
INSERT INTO response_single VALUES (2, 1, 1);
INSERT INTO response_single VALUES (3, 1, 1);
INSERT INTO response_single VALUES (4, 1, 2);
# --------------------------------------------------------

#
# Table structure for table `response_text`
#

CREATE TABLE response_text (
  response_id int(10) unsigned NOT NULL default '0',
  question_id int(10) unsigned NOT NULL default '0',
  response text,
  PRIMARY KEY  (response_id,question_id)
) TYPE=MyISAM;

#
# Dumping data for table `response_text`
#

# --------------------------------------------------------

#
# Table structure for table `survey`
#

CREATE TABLE survey (
  id int(10) unsigned NOT NULL auto_increment,
  name varchar(64) NOT NULL default '',
  owner varchar(16) NOT NULL default '',
  realm varchar(64) NOT NULL default '',
  public enum('Y','N') NOT NULL default 'Y',
  status int(10) unsigned NOT NULL default '0',
  title varchar(255) NOT NULL default '',
  email varchar(64) default NULL,
  subtitle text,
  info text,
  theme varchar(64) default NULL,
  thanks_page varchar(255) default NULL,
  thank_head varchar(255) default NULL,
  thank_body text,
  changed timestamp(14) NOT NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

#
# Dumping data for table `survey`
#

INSERT INTO survey VALUES (1, 'battle01', 'root', 'superuser', 'Y', 1, 'battle 01', '', 'adolf vs. jim', '', NULL, NULL, 'thank you', '', 20020703014306);
# --------------------------------------------------------

#
# Table structure for table `sympoll_auth`
#

CREATE TABLE sympoll_auth (
  uid int(11) NOT NULL auto_increment,
  user varchar(32) NOT NULL default '',
  pass varchar(32) NOT NULL default '',
  access smallint(5) unsigned NOT NULL default '0',
  secret varchar(32) default NULL,
  PRIMARY KEY  (uid)
) TYPE=MyISAM;

#
# Dumping data for table `sympoll_auth`
#

INSERT INTO sympoll_auth VALUES (1, 'gerald', '6052b90d159180efd0e8fb153005af71', 0, 'c301a9cf34715925ed48706a848ab88a');
# --------------------------------------------------------

#
# Table structure for table `sympoll_data`
#

CREATE TABLE sympoll_data (
  pid int(10) unsigned NOT NULL default '0',
  cid int(10) unsigned NOT NULL default '0',
  choice varchar(250) NOT NULL default '',
  votes int(10) unsigned NOT NULL default '0',
  KEY pid (pid)
) TYPE=MyISAM;

#
# Dumping data for table `sympoll_data`
#

INSERT INTO sympoll_data VALUES (1, 1, 'adolf', 220);
INSERT INTO sympoll_data VALUES (1, 2, 'jim', 224);
INSERT INTO sympoll_data VALUES (2, 1, 'yes', 0);
INSERT INTO sympoll_data VALUES (2, 2, 'no', 0);
# --------------------------------------------------------

#
# Table structure for table `sympoll_iplog`
#

CREATE TABLE sympoll_iplog (
  vid varchar(32) NOT NULL default '',
  pid int(10) unsigned NOT NULL default '0',
  voted int(10) unsigned NOT NULL default '0',
  KEY vid (vid),
  KEY pid (pid)
) TYPE=MyISAM;

#
# Dumping data for table `sympoll_iplog`
#

INSERT INTO sympoll_iplog VALUES ('5acd4e3aedabffd48956f961dee45dcd', 1, 1025810788);
# --------------------------------------------------------

#
# Table structure for table `sympoll_list`
#

CREATE TABLE sympoll_list (
  pid int(10) unsigned NOT NULL auto_increment,
  nextcid int(10) unsigned NOT NULL default '0',
  question varchar(250) NOT NULL default '',
  timeStamp int(10) unsigned NOT NULL default '0',
  cookieStamp int(10) unsigned NOT NULL default '0',
  status smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY  (pid)
) TYPE=MyISAM;

#
# Dumping data for table `sympoll_list`
#

INSERT INTO sympoll_list VALUES (1, 3, 'adolf or jim', 1025810737, 1025810737, 10);
INSERT INTO sympoll_list VALUES (2, 3, '1000 words?', 1027495714, 1027495714, 10);

