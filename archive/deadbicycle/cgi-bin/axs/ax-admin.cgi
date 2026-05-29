#!/usr/bin/perl --
require 5;

=item overview


	
=cut

my $VERSION = '2.3.0.0025';
my %FORM = ();
my %PREF = ();
my %const = ();

my $all_code = <<'END_OF_CODE';

# You should place the log.txt and axs.dat files in the same directory as
# this script.  If you do, you won't have to change the variables below.
# If you want to put the files somewhere else, enter the full path to these
# files:

$LogFile = 'log.txt';
$prefs = 'axs.dat';

#	Other examples:
#	$LogFile = '/usr/www/users/xav/log.txt';
#	$LogFile = 'c:/axs/log.txt';



# Enter your anchor page. This will form a link at the top of each AXS
# output document:

$link_url = '../index.html';
$link_title = 'deadbicycLe.com';

# Once the script is working to your satisfaction, set the $AllowDebug
# variable to zero:

$AllowDebug = 0;

# ________________________________________________________________________

# Protect AXS with a username and password.  Both are case sensitive.  You
# can leave them blank to disable password locking.  This is the default:

$Username = 'db';
$Password = 'germ347';

#	Other examples:
#	$Username = 'root';
#	$Password = 'IronMAN';

# You can allow anyone access to your graphs, while continuing to protect
# your "Customize" page with a username and password.  If you do this,
# web visitors will be free to view your statistics, but they won't be
# able to delete the log file or change your settings.  To allow web
# visitors to see your graphs without entering a username or password, set
# this to 1:

$AllowAnonymousForGraphs = 0; # set to 1 to allow

# ________________________________________________________________________

# Most of you shouldn't have to change anything below this line.  If you
# try the script out and it doesn't work, the help files will suggest
# changes to the following lines.

# The request method can be either GET or POST.  Setting the method to GET
# will cause the username and password data to be exposed to the web server
# logs.  Using GET is inadvisable if others have access to your web server
# logs.
$Request_Method = 'POST';

# The URL to this script:
$This_Script_Address = &query_env('SCRIPT_NAME');

# The admininstrator's email address - use *single* quotes:
$Admin_Email_Address = &query_env('SERVER_ADMIN', 'nebulous@deadbicycle.com');
#	Example:
#	$Admin_Email_Address = 'president@whitehouse.gov';

# Your favorite network lookup services:
$nslookup = 'http://www.xav.com/cgi-bin/nslookup.cgi';
$whois = 'http://www.xav.com/scripts/axs/whois.pl?a=';

# Alternate (previous) whois script was:
# $whois = 'http://www.networksolutions.com/cgi-bin/whois/whois?';

# AXS can collapse web addresses which include the default document.
# This prevents you from having two database entries for a single file,
# like http://www.ms.com/ and http://www.ms.com/index.html:

$DefaultDoc = 'index.html';

# If you'd like, local files can show up as their HTML title instead of
# their URL.  For example, visits to http://www.xav.com/ would show up in
# your graphs as "Home Page".  To use this option, enter the URL-title
# pairs below, and set the top variable to "1":

$UseLocalAddressTitlePairs = 0; # Set to "1" to enable.
%LocalAddressTitlePairs = (
	'http://www.xav.com/' , 'Home Page',
	'http://www.xav.com/scripts/' , 'Scripts Page',
	'http://www.xav.com/scripts/axs/' , 'AXS Script Page',
	);

# Uncomment this line if you receive errors about invalid Content-Type
# headers.  (to support command-line parameters, the HTTP headers are
# only sent back if the SERVER_SOFTWARE env var is defined; most web
# servers should set this, but if you're doesn't then you have to set
# it manually by uncommenting the line below)
#$ENV{'SERVER_SOFTWARE'} = 1;

# No further editing is necessary, but feel free to play around.  The
# first 1,000 lines of this script are straight HTML and JavaScript, so
# you can safely customize the look and feel of the output even if you
# don't know Perl.
#
# ________________________________________________________________________


%GraphOptions = (
	's01' => 'Web Browser (Netscape 3.01 Gold)',
	's02' => 'Abbreviated Browser (Netscape 3.X)',

	's02a' => 'Browser Wars (Netscape)',

	's03' => 'Operating System (Windows 98)',
	's04' => 'Visitor Top Level Domains (.com)',
	's05' => 'Visitor 1-level Domain (deadbicycle.com)',
	's06' => 'Visitor Full (dialup-123.deadbicycle.com)',
	's07' => 'Visitor IP Address (206.134.243.3)',
	's08' => 'Hits from Other Sites (Full URL)',
	's09' => 'Hits from Other Sites (Domain Only)',
	's10' => 'Hyperlinks Followed From This Site',
	's11' => 'Hits to Local Documents',
	's12' => 'Average Number of Hits Per Visitor',
	's13' => 'Hits By Day of Year',
	's14' => 'Hits By Day of the Week',
	's15' => 'Hits By Hour of the Day',
	);

@DatabaseOptions = ('Sort All by Time','Sort All by Visitor','Visitor Flow Only');

@LongWeekDays = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
@ShortWeekDays = ('SUN','MON','TUE','WED','THU','FRI','SAT');
@LongMonths = ('January','February','March','April','May','June','July','August','September','October','November','December');
@ShortMonths = ('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC');
@ShortDayNames = ('YEST','TOD','TOM');


my %tldx = ();
my %sldx = ();
my %statesx = ();



$total_corrupt_rows = 0;

sub Header {
return <<"END_OF_HTML";

<HTML>
<HEAD>
	<TITLE></TITLE>
	<META NAME="robots" CONTENT="none">
        <LINK REL="stylesheet" HREF="/global.css" TYPE="text/css">
	<STYLE TYPE="text/css">
	<!--
	BODY,DIV,P,TABLE,TR,TD,SPAN {
		font-family:verdana;
		font-size:10pt;
		}
	SPAN.textlink {
		cursor:text;
		text-decoration:none;
		color:#000000;
		}
	//-->
	</STYLE>
<SCRIPT><!--
	document.write('<STYLE>.hand{cursor:hand}</STYLE>');
//--></SCRIPT>
</HEAD>
<BODY>

END_OF_HTML

	}


sub HTML_Header {
	return <<"EOM";

<CENTER>
	<B>[deadbicycLe.com]</B><FONT SIZE=-1> statistics<BR><FONT SIZE=-2>
	[<A HREF="$This_Script_Address" class="forumnormal">main menu</A>]
	[<A HREF="$This_Script_Address?Target=Preferences" class="forumnormal">customize</A>]
	[<A HREF="$link_url" class="forumnormal">$link_title</A>]</FONT>
</CENTER>
<BR>

	
EOM

	}


sub Footer {
	my ($b_is_login) = @_;

	print '<!--#echo banner=""-->';


	if ($b_is_login) {

print <<"EOM";

<P ALIGN="center"><FONT SIZE=-2>
	[<A HREF="$This_Script_Address" class="forumnormal">main menu</A>]
	[<A HREF="$This_Script_Address?Target=Preferences" class="forumnormal">customize</A>]
	[<A HREF="$This_Script_Address?Target=LogOut" class="forumnormal">log out</A>]

EOM

	foreach ('pl','cgi') {
		if (-e "ax.$_") {
			print "[<A HREF=\"ax.$_?debugme\">tagging instructions</A>]";
			last;
			}
		}

print <<"EOM";
</FONT>
</P>

EOM
		}
	print <<"EOM";

<CENTER>


</CENTER>
</FONT>
</BODY>
</HTML>

EOM
	}


sub PrintMainPage {
	local $_;
	$cur_hits = 0;
	if (open(LOG, "<$LogFile")) {
		binmode(LOG);
		while (defined($_ = <LOG>)) {
			$cur_hits++;
			}
		close(LOG);
		}
	$html_filter = &html_encode( $PREF{'Filter'} );

print <<"EOM";

<BLOCKQUOTE><FONT SIZE=-1>

 Currently have <B>$cur_hits</B> hits to work with.

<FORM METHOD=$Request_Method ACTION="$This_Script_Address" NAME="graphs" OnSubmit="return CheckGraphs()">

<CENTER>
<INPUT TYPE="TEXT" NAME="maximum" SIZE="4" VALUE="$PREF{'maximum'}">
<SELECT NAME="format">
EOM

# This is a Perl loop - you don't need to edit it:
foreach $Option (sort @DatabaseOptions) {
	$Option = html_encode($Option);
	if ($PREF{'format'} eq $Option) {
		print "<OPTION VALUE=\"$Option\" SELECTED>$Option\n";
		}
	else {
		print "<OPTION VALUE=\"$Option\">$Option\n";
		}
	} # end "foreach $Option".

print <<"EOM";
</SELECT>
<INPUT TYPE="SUBMIT" NAME="show_data" VALUE="Database Format">
</CENTER>

<P><FONT SIZE=-1>Enter the number of recent hits you'd like to view, or leave blank for all. Enter "L" to view hits since your last visit on $PREF{'last_string'}.</P>

<P><B>Create Graphs Based On:</B></P>

<CENTER>
<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">
<TR>
<TD VALIGN="top">
EOM

# This is a Perl loop - you don't need to edit it:
foreach $OptionCode (sort keys %GraphOptions) {
	print <<"EOM";
<INPUT TYPE=checkbox NAME="$OptionCode"><SPAN ONCLICK="javascript:TC(document.graphs.$OptionCode)" CLASS="textlink">$GraphOptions{$OptionCode}</SPAN><BR>
EOM
	} # end "foreach $OptionCode".

print <<"EOM";
</TD>

<TD WIDTH="40"><BR></TD>

<TD ALIGN="center" VALIGN="middle">
	<input type="checkbox" name="cvs_out" value="1"> Output in CVS Format<br />


<INPUT TYPE="reset" VALUE="Clear"><INPUT TYPE="button" VALUE="defaults" NAME="defaults" ONCLICK="setdefs()"><BR>
<INPUT TYPE="submit" VALUE="View in Graphical Format" NAME="MakeGraphs" ONCLICK="JavaMakeGraphs()"><BR>
	<BR><BR><IMG SRC="$PREF{'images_folder'}bluedeadforumlogobig2.gif" ALT="[deadbicycle.com]" HEIGHT="154" WIDTH="271">
</TD>
</TR>
</TABLE>
</CENTER>

<P><B>Graphing Filters:</B></P>

<BLOCKQUOTE>
	

	<P>
	&nbsp; &nbsp;
	<A HREF="javascript:FormatTimesSinceLast('$PREF{'last_string'}')" STYLE="cursor: text; text-decoration: none">
	<FONT COLOR="#000000">
	<INPUT TYPE="checkbox" $PREF{'since_last'} NAME="since_last">
		Graph only hits since my last visit on $PREF{'last_string'}
	</FONT>
	</A><BR>

	&nbsp; &nbsp;
	<A HREF="javascript:FormatTimesRecent();" STYLE="cursor: text; text-decoration: none">
	<FONT COLOR="#000000">
	<INPUT TYPE="checkbox" $PREF{'recent'} NAME="recent">
		Graph only hits from yesterday and today</FONT></A>, or specify:
	</P>

	<P>
	<INPUT TYPE="text" NAME="start_date" SIZE="10" VALUE="$PREF{'start_date'}" ONBLUR="FormatStartTime(document.graphs.start_date.value)">
		Start Date <I>(<FONT ID="StartTime">mm-dd-year</FONT>)</I><BR>

	<INPUT TYPE="text" NAME="end_date" SIZE="10" VALUE="$PREF{'end_date'}" ONBLUR="FormatEndTime(document.graphs.end_date.value)">
		End Date <I>(<FONT ID="EndTime">mm-dd-year</FONT>)</I><BR>

	<INPUT TYPE="text" NAME="Filter" SIZE="24" VALUE="$html_filter">
		Filter String</P>

	<P>The filter string may contain a file name, server name, or browser type </P>
</BLOCKQUOTE>
</FORM>




<BR>
</BLOCKQUOTE>
EOM
}
# ________________________________________________________________________


sub PrintJavaMainPage {
print <<"EOM";
<SCRIPT LANGUAGE="Javascript">
<!-- // Hide the Java...
function setdefs() {
	var1 = 'true';
	var2 = 'false';
EOM
foreach $OptionCode (keys %GraphOptions) {
	print "document.graphs.$OptionCode.checked = ";
	(($PREF{$OptionCode}) && ($PREF{$OptionCode} eq 'CHECKED')) ? print 'true' : print 'false';
	print ";\n";
	}
print <<"EOM";
	}
// End Java Hiding -->
</SCRIPT>
EOM
}
# ________________________________________________________________________


sub PrintCustomizePage {

	my $graph_options = '';

	foreach $OptionCode (sort keys %GraphOptions) {
		$graph_options .= <<"EOM";

	<INPUT TYPE="checkbox" NAME="$OptionCode" VALUE="CHECKED"><SPAN CLASS="hand" ONCLICK="TC(document.graphs.$OptionCode);">$GraphOptions{$OptionCode}</SPAN><BR>

EOM
		}

	my $webmaster_logging = '';

	if (($ENV{'HTTP_COOKIE'}) and ($ENV{'HTTP_COOKIE'} =~ m!axs_no_log=1!i)) {

$webmaster_logging = <<"EOM";

	<P><FONT SIZE=-2>Currently, your visits <B>ARE NOT</B> being logged.<BR><B>[<A HREF="$This_Script_Address?Target=Preferences&SetCookie=1&CookieValue=0" class="forumnormal">Log My Visits</A>]</B>.</P></FONT>


EOM

		}
	else {

$webmaster_logging = <<"EOM";

	<P><FONT SIZE=-2>Currently, your visits <B>are</B> being logged. <BR><B>[<A HREF="$This_Script_Address?Target=Preferences&SetCookie=1&CookieValue=1" class="forumnormal">Do Not Log My Visits</A>]</FONT></B>.</P>


EOM
		}





print &SetDefaults(<<"EOM", \%PREF);

<BLOCKQUOTE>

<FORM METHOD="$Request_Method" ACTION="$This_Script_Address" NAME="graphs">
<INPUT TYPE="hidden" NAME="Target" VALUE="Preferences">



<BLOCKQUOTE>
<INPUT NAME="maximum" SIZE=4>
<SELECT NAME="format">
	<OPTION VALUE="Sort All by Time">Sort All by Time
	<OPTION VALUE="Sort All by Visitor">Sort All by Visitor
	<OPTION VALUE="Visitor Flow Only">Visitor Flow Only
</SELECT>
</BLOCKQUOTE>

<P>The text box holds the number of recent hits you're interested in. You can enter a letter to view recent hits through the day of your last visit.</P>

<P><B>Most Common Graphs:</B></P>

<BLOCKQUOTE>$graph_options</BLOCKQUOTE>

<P><B>Graphing Filters:</B></P>

<BLOCKQUOTE>



	<P>
	&nbsp; &nbsp;
	<A HREF="javascript:FormatTimesSinceLast('$PREF{'last_string'}')" STYLE="cursor: text; text-decoration: none">
	<FONT COLOR="#000000">
	<INPUT TYPE="checkbox" NAME="since_last" VALUE="CHECKED">
		Graph only hits since my last visit on $PREF{'last_string'}
	</FONT>
	</A><BR>

	&nbsp; &nbsp;
	<A HREF="javascript:FormatTimesRecent();" STYLE="cursor: text; text-decoration: none">
	<FONT COLOR="#000000">
	<INPUT TYPE="checkbox" NAME="recent" VALUE="CHECKED">
		Graph only hits from yesterday and today</FONT></A>, or specify:
	</P>

	<P>
	<INPUT NAME="start_date" SIZE="10" OnBlur="FormatStartTime(document.graphs.start_date.value)">
		Start Date <I>(<FONT ID="StartTime">mm-dd-year</FONT>)</I><BR>

	<INPUT NAME="end_date" SIZE="10" OnBlur="FormatEndTime(document.graphs.end_date.value)">
		End Date <I>(<FONT ID="EndTime">mm-dd-year</FONT>)</I><BR>

	<INPUT NAME="Filter" SIZE="24">
		Filter String</P>

	
</BLOCKQUOTE>

<P><B>Graphics Output:</B><P>

<BLOCKQUOTE>

<DL>

<DT><A HREF="javascript:TC(document.graphs.NumSort)" STYLE="cursor: text; text-decoration: none">
<INPUT TYPE="checkbox" NAME="NumSort" VALUE="CHECKED">
<FONT COLOR="#000000">
	Sort data numerically, with most hits on top
</FONT>
</A></DT><DD><I>By default, graphs are alphabetically sorted by key</I></DD>

<DT><A HREF="javascript:TC(document.graphs.NewWindow)" STYLE="cursor: text; text-decoration: none">
<INPUT TYPE="checkbox" NAME="NewWindow" VALUE="CHECKED">
<FONT COLOR="#000000">
	Follow links by opening a separate window
</FONT>
</A></DT><DD></DD>

<DT><A HREF="javascript:TC(document.graphs.Highlight)" STYLE="cursor: text; text-decoration: none">
<INPUT TYPE="checkbox" NAME="Highlight" VALUE="CHECKED">
<FONT COLOR="#000000">
	Highlight the percentage column in graphs
</FONT>
</A></DT><DD></DD>

<DT><INPUT TYPE="checkbox" NAME="HidePoundSigns" VALUE="CHECKED"><SPAN CLASS="hand" ONCLICK="return TC(document.graphs.HidePoundSigns)"> Compress web addresses that include pound signs</SPAN></DT>
<DD>http://www.deadbicycle.com/links.html#localsites<I>
becomes</I><BR>http://www.deadbicycle.com/links.html<BR></DD>


<DT><INPUT TYPE="checkbox" NAME="HideQueryStrings" VALUE="CHECKED"><SPAN CLASS="hand" ONCLICK="return TC(document.graphs.HideQueryStrings)"> Compress web addresses that include query strings</SPAN></DT>
<DD>http://www.deadbicycle.com/links.cgi?foo=bar<I>
becomes</I><BR>http://www.deadbicycle.com/links.cgi<BR></DD>




<DT><A HREF="javascript:TC(document.graphs.HideDefaultDoc)" STYLE="cursor: text; text-decoration: none">
<INPUT TYPE="checkbox" NAME="HideDefaultDoc" VALUE="CHECKED">
<FONT COLOR="#000000">
	Compress web addresses that include the default document,
	<TT>$DefaultDoc</TT>
</FONT>
</A></DT>
<DD>http://www.deadbicycle.com/$DefaultDoc<I>
becomes</I><BR>http://www.deadbicycle.com/</DD>

<DT><A HREF="javascript:TC(document.graphs.UseMilTime)" STYLE="cursor: text; text-decoration: none">
<INPUT TYPE="checkbox" NAME="UseMilTime" VALUE="CHECKED">
<FONT COLOR="#000000">
	Use military time
</FONT>
</A></DT>
<DD>3:45 PM <I>becomes</I> 15:45<BR></DD>

</DL>

</BLOCKQUOTE>

<P>Set the maximum width of graphs to <INPUT NAME="MaxWidth" SIZE="3" STYLE="text-align:right"> pixels.</P>

<P>Set the maximum displayed characters in data strings to <INPUT NAME="MaxChars" SIZE="3" STYLE="text-align:right">.</P>

<P>Image Directory: <INPUT NAME="images_folder" SIZE=40><BR>


<P>Local web pages will be any web pages which contain this substring in their URL: <INPUT NAME="My_Web_Address"></P>

<BLOCKQUOTE>
	<INPUT TYPE="hidden" NAME="incoming" VALUE="true">
	<P><INPUT TYPE="submit" VALUE="Commit Changes"></P>
</BLOCKQUOTE>

</FORM>

<BR>
<HR NOSHADE SIZE="1" WIDTH="50%">

<P><B>Webmaster Logging</B></P>

<BLOCKQUOTE>

	$webmaster_logging

	

</BLOCKQUOTE>

<BR>
<HR NOSHADE SIZE="1" WIDTH="50%">


<FORM METHOD=$Request_Method ACTION="$This_Script_Address" NAME="Deletion" OnSubmit="return ConfirmDelete()">
<INPUT TYPE=HIDDEN NAME="terminate" VALUE="On">

<P><B>Log Management:</B></P>

<BLOCKQUOTE>
	<P><INPUT TYPE="SUBMIT" VALUE="Delete Access Log"></P>
</BLOCKQUOTE>

<P>By default, all entries will be deleted. You may choose to delete <I>only</I> hits <I>older</I> than a certain date:&nbsp; <INPUT TYPE="text" NAME="start_date" SIZE="10" OnBlur="FormatDeleteTime(document.Deletion.start_date.value)"> <I>(<FONT ID="DeleteTime">mm-dd-year</FONT>)</I></P>

<P>The access log will grow by about a kilobyte for every six hits, eventually becoming too large for processing (it's currently at $LogSizeKiloBytes kb - $Advice). We recommend deleting the log every so often. Before doing so, you'll want to generate your favorite graphs and save them to your system as HTML files, as a record of how your site traffic evolves over time.</P>

</FORM>
</BLOCKQUOTE>
<BR><BR>

EOM
	}





sub Authenticate {
$Target = ($FORM{'Target'} eq 'Preferences') ? 'Preferences' : '';
return <<"END_OF_HTML";

<CENTER>
<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="10">
<TR>
<TD WIDTH="20" BGCOLOR="#ffffff"><BR></TD>
<TD WIDTH="550" ALIGN="left" VALIGN="bottom">
<BR><BR>
<BLOCKQUOTE>


<CENTER><IMG SRC="$PREF{'images_folder'}bluedeadforumlogobig2.gif" ALT="[deadbicycle.com]" HEIGHT="154" WIDTH="271"><BR><BR>
<FORM ACTION="$This_Script_Address" METHOD="$Request_Method" NAME="authentication">

<TABLE BORDER="0">
<TR>
	<TD ALIGN="right" VALIGN="bottom">
	<B>Username: </B><INPUT TYPE="text" NAME="username" value="db" SIZE="8"><BR>
	<B>Password: </B><INPUT TYPE="password" NAME="password" SIZE="8"></TD>

	<TD ALIGN="center" VALIGN="bottom">

	<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="1" BGCOLOR="#ffffff">
	<TR><TD><INPUT TYPE="submit" VALUE="Authenticate"></TD></TR>
	</TABLE></TD>
</TR>
</TABLE>
<INPUT TYPE="hidden" NAME="Target" VALUE="$Target">
</FORM>

<SCRIPT LANGUAGE="JavaScript">
<!--
document.authentication.username.focus();
// -->
</SCRIPT>
</CENTER>



</BLOCKQUOTE></TD>
</TR>
</TABLE>
</CENTER>

END_OF_HTML
}
# ________________________________________________________________________


sub DatabaseFlowDescription {
return <<"END_OF_HTML";

<BLOCKQUOTE>
	<P>Below is a flow chart of your visitors.  Visits are shown with newer hits at the top, and older hits towards the bottom, with timestamps taken from the time of first visit.  Successive visits by the same user are grouped together, so that you can view the path taken through your site.</P>

	<P>The time interval between hits is given in Hour:Minute:Second format, followed by the number of days, if any.</P>

	<P>Note that in most cases, the same individual will have different IP addresses with each network logon.  Alternately, the same IP address may represent different visitors over time.  Sampling a smaller number of hits over a shorter time period reduces the probability of these errors occuring.</P>

</BLOCKQUOTE>

END_OF_HTML
}
# ________________________________________________________________________


sub DatabaseTimeDescription {
return <<"END_OF_HTML";

<BLOCKQUOTE>
	<P>Each hit below is listed in the order it was counted, with the most recent hits listed first.</P>
</BLOCKQUOTE>

END_OF_HTML
}
# ________________________________________________________________________




=item GraphSummary

Usage:
	print &GraphSummary();

Dependencies:
	$const{'truncated_keys'}

=cut

sub GraphSummary {


$relevant_hits = &AddCommas($relevant_hits);
$NumGraphLines = &AddCommas($NumGraphLines);
$SummaryText = "<P><B>Summary:</B></P><BLOCKQUOTE><P>There were $total_hits total hits analyzed";

if ($total_corrupt_rows) {
	$SummaryText .= " ($total_corrupt_rows data points were corrupt)";
	}

$SummaryText .= ".  Of these, $relevant_hits were ";

if ($NumGraphLines) {
	$SummaryText .= "relevant, and they resulted in $NumGraphLines lines in the table. "
	}
else {
	$SummaryText .= 'relevant. ';
	}

if (!$FilterString) {
	$SummaryText .= "No string matching was done against the access log.  ";
	}
elsif ($FilterString =~ m!^host:(.*)$!i) {
	$SummaryText .= "Searched only hits whose hostname matched \"" . html_encode($1) . "\".  ";
	}
elsif ($FilterString =~ m!^ip:(.*)$!i) {
	$SummaryText .= "Searched only hits whose IP address matched \"" . html_encode($1) . "\".  ";
	}
elsif ($FilterString =~ m!^from:(.*)$!i) {
	$SummaryText .= "Searched only hits whose referers matched \"" . html_encode($1) . "\".  ";
	}
elsif ($FilterString =~ m!^to:(.*)$!i) {
	$SummaryText .= "Searched only hits in which the document hit matched \"" . html_encode($1) . "\".  ";
	}
elsif ($FilterString =~ m!^browser:(.*)$!i) {
	$SummaryText .= "Searched only hits in which the browser name matched \"" . html_encode($1) . "\".  ";
	}
else {
	$SummaryText .= "Searched only records whose text matched \"" . html_encode($FilterString) . "\".  ";
	}

if (($StartString) && ($EndString)) {
	$SummaryText .= "Restricted to hits occurring between $StartString, and $EndString.</P>";
	}
elsif ($StartString) {
	$SummaryText .= "Restricted to hits occurring on or after $StartString.</P>";
	}
elsif ($EndString) {
	$SummaryText .= "Restricted to hits occurring on or before $EndString.</P>";
	}
else {
	$SummaryText .= "The log was not filtered by date.</P>";
	}


	if ($const{'truncated_keys'}) {
		$SummaryText .= "<P>$const{'truncated_keys'} of the text keys were longer than $PREF{'MaxChars'} characters, and were truncated in the display. This behavior can be controlled with the \"maximum displayed characters\" setting on the Customize page.</P>\n";
		}

#0013 - added descriptive sentence about how local web pages are defined
$SummaryText .= <<"END_OF_HTML";

	<P>Local web pages are those whose URL contains the substring "$PREF{'My_Web_Address'}".  All other documents are considered remote web pages.</P>

</BLOCKQUOTE>

END_OF_HTML
#0013 - end changes

return $SummaryText;
} #-----------------------------------------------------------------------


sub JavaLib {
return <<'END_OF_HTML';
<SCRIPT LANGUAGE="JavaScript">
<!-- Hide from non-Java browsers
window.onerror = null;
var version = parseInt(navigator.appVersion);
var isIE = navigator.appVersion.indexOf("MSIE")>0;
var isNav = navigator.appVersion.indexOf("Nav")>0;
var isIE4 = isIE && version>=4;
var isNav4 = isNav && version>=4;

function TC(checkbox) {
	checkbox . checked = ! checkbox . checked;
	}

function StripWhiteSpace (DS) {
while (DS.length && (DS.charAt(0) == ' ')) {
	DS = DS.substring(1,DS.length);
	}
return DS;
}

function AddLeadingZero (Number) {
	/*  kick int properties:  */
	Number++; Number--;
	if (Number < 10) {
		Number = " 0" + Number;
		Number = Number.substr(1,3);
		}
	return Number;
	}

function DateFromString(DS) {
	MonthNames = new Array("January","February","March","April",'May','June','July','August','September','October','November','December');
	CompMonthNames = new Array('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC');
	WeekDays = new Array('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
	CompWeekDays = new Array('SUN','MON','TUE','WED','THU','FRI','SAT');
	DateSuffix = new Array('th','st','nd','rd','th','th','th','th','th','th','th','th','th','th','th','th','th','th','th','th');
	var AllInt = '0123456789';
	AllCaps = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	AllLows = 'abcdefghijklmnopqrstuvwxyz';

DS = StripWhiteSpace(DS);

/* test for numeric status of first non-whitespace: */
var N1 = -1;
var MonthFirst = 1;
var TempAlphaString = '';

if ((DS.length) && (AllInt.indexOf(DS.charAt(0)) < 0)) {

	/* non-numeric: */
	/* capture all non-numerics up til first numeric, non-inclusive: */
	var TempAlphaString = '';
	while (DS.length && ((AllInt.indexOf(DS.charAt(0)) < 0) || (DS.charAt(0) == ' '))) {
		OffSet = AllLows.indexOf(DS.charAt(0));
		if (OffSet > -1) {
			TempAlphaString += AllCaps.substring(OffSet,OffSet+1);
			}
		else {
			TempAlphaString += DS.charAt(0);
			}
		DS = DS.substring(1,DS.length);
		}
	for (var i=0;i<12;i++) {
		if (TempAlphaString.indexOf(CompMonthNames[i]) >= 0) {
			N1 = i + 1;
			i = 12;
			}
		}
	}

if ((DS.length) && (N1 == -1)) {
	/* numeric first character.  Capture first 1 or 2 numerics */
	/* 1 if 2nd is non-numeric */
	N1 = parseInt(DS.charAt(0),10);
	DS = DS.substring(1,DS.length);
	if (DS.length && !(AllInt.indexOf(DS.charAt(0)) < 0) && (DS.charAt(0) != ' ')) {
		N1 *= 10;
		N1 += parseInt(DS.charAt(0));
		DS = DS.substring(1,DS.length);
		}
	}

DS = StripWhiteSpace(DS);

/* test for numeric status of first non-whitespace: */
var N2 = -1;
if ((DS.length) && (AllInt.indexOf(DS.charAt(0)) < 0)) {

	/* non-numeric: */
	/* capture all non-numerics up til first numeric, non-inclusive: */
	var TempAlphaString = '';
	while (DS.length && ((AllInt.indexOf(DS.charAt(0)) < 0) || (DS.charAt(0) == ' '))) {
		OffSet = AllLows.indexOf(DS.charAt(0));
		if (OffSet > -1) {
			TempAlphaString += AllCaps.substring(OffSet,OffSet+1);
			}
		else {
			TempAlphaString += DS.charAt(0);
			}
		DS = DS.substring(1,DS.length);
		}
	for (var i=0;i<12;i++) {
		if (TempAlphaString.indexOf(CompMonthNames[i]) >= 0) {
			N2 = i + 1;
			i = 12;
			MonthFirst = 0;
			}
		}
	}

/* continue with num search if text search was aborted or didn't turn */
/* anything up... */
if ((DS.length) && (N2 == -1)) {
	/* numeric first character.  Capture first 1 or 2 numerics */
	/* 1 if 2nd is non-numeric */
	N2 = parseInt(DS.charAt(0),10);
	DS = DS.substring(1,DS.length);
	if (DS.length && (!(AllInt.indexOf(DS.charAt(0)) < 0) && (DS.charAt(0) != ' '))) {
		N2 *= 10;
		N2 += parseInt(DS.charAt(0));
		DS = DS.substring(1,DS.length);
		}
	}

DS = StripWhiteSpace(DS);

/* test for numeric status of first non-whitespace: */
if (DS.length && (AllInt.indexOf(DS.charAt(0)) < 0)) {

	/* non-numeric: */
	/* strip all non-numerics up til first numeric, non-inclusive: */
	var TempAlphaString = '';
	while (DS.length && ((AllInt.indexOf(DS.charAt(0)) < 0) || (DS.charAt(0) == ' '))) {
		TempAlphaString += DS.charAt(0);
		DS = DS.substring(1,DS.length);
		}
	}

var YearNumber = 0;
while (DS.length && !(AllInt.indexOf(DS.charAt(0)) < 0) && (DS.charAt(0) != ' ')) {
	YearNumber = (YearNumber * 10) + parseInt(DS.charAt(0),10);
	DS = DS.substring(1,DS.length);
	}
YearNumber++; YearNumber--;

ThisDay = new Date();
ThisDayNumber = ThisDay.getDay();
NumDays1970 = (ThisDay.getTime()/(24*3600000));


/* if both N1,N2 fail, see if the guy typed in a weekday: */
if ((N1 == -1) && (N2 == -1)) {
	for (i=0; i<7; i++) {
		if (TempAlphaString.length && (TempAlphaString.indexOf(CompWeekDays[i]) >= 0)) {
			NumDaysPast = ((ThisDayNumber - i + 7) % 7);
			NewNumDays1970 = NumDays1970 - NumDaysPast;
			ThisDay.setTime(24*3600000*NewNumDays1970);
			N1 = ThisDay.getMonth() + 1;
			N2 = ThisDay.getDate();
			Year = ThisDay.getYear() + 1900;
			i = 7;
			}
		}
	}
if ((N1 == -1) && (N2 == -1)) {
	if ((TempAlphaString.length) && (TempAlphaString.indexOf("YEST") >= 0)) {
		NewNumDays1970 = NumDays1970 - 1;
		ThisDay.setTime(24*3600000*NewNumDays1970);
		N1 = ThisDay.getMonth() + 1;
		N2 = ThisDay.getDate();
		Year = ThisDay.getYear() + 1900;
		}
	else if ((TempAlphaString.length) && (TempAlphaString.indexOf("TOD") >= 0)) {
		N1 = ThisDay.getMonth() + 1;
		N2 = ThisDay.getDate();
		Year = ThisDay.getYear() + 1900;
		}
	else if (TempAlphaString.length && (TempAlphaString.indexOf("TOM") >= 0)) {
		NewNumDays1970 = NumDays1970 + 1;
		ThisDay.setTime(24*3600000*NewNumDays1970);
		N1 = ThisDay.getMonth() + 1;
		N2 = ThisDay.getDate();
		Year = ThisDay.getYear() + 1900;
		}
	}
if (YearNumber == 0) {
	YearNumber = ThisDay.getYear();
	}
if (YearNumber < 1000) {
	if (YearNumber < 50) {
		YearNumber += 2000;
		}
	else {
		YearNumber += 1900;
		}
	}
/* Date Pattern match not found: */
if ((N1 == -1) || (N2 == -1)) {
	return '';
	}
if (MonthFirst) {
	ThisMonthNum = (N1 - 1);
	ThisDay = N2;
	}
else {
	ThisMonthNum = (N2 - 1);
	ThisDay = N1;
	}
/* return 0 for bad configs: */
if (ThisDay < 1) {
	return 0;
	}
if ((ThisMonthNum < 0) || (ThisMonthNum > 11)) {
	return 0;
	}
DaysInMonth = new Array (31,28,31,30,31,30,31,31,30,31,30,31);
DaysInThisMonth = DaysInMonth[ThisMonthNum];
if (ThisDay > DaysInThisMonth) {
	if (!((ThisMonthNum == 1) && ((YearNumber % 4) == 0) && (ThisDay == 29))) {
		return 0;
		}
	}
/* Date is now set in stone (else we've already aborted).  Now format */
/* as needed for this application. */
MyDate = new Date();
MyDate.setYear(YearNumber);
MyDate.setMonth(ThisMonthNum);
MyDate.setDate(ThisDay);
ThisWeekDay = WeekDays[MyDate.getDay()];
ThisMonthName = MonthNames[ThisMonthNum];
return ThisWeekDay + ", the " + ThisDay + DateSuffix[ThisDay%20] + " of "  + ThisMonthName + ", " + YearNumber;
}
function FormatStartTime(DateString) {
DateString = DateFromString(DateString);
if (DateString != "") {
	window.status = DateString;
	if (isIE4) {
		document.all.StartTime.innerHTML = DateString;
		}
	}
return true;
}
function FormatEndTime(DateString) {
DateString = DateFromString(DateString);
if (DateString != "") {
	window.status = DateString;
	if (isIE4) {
		document.all.EndTime.innerHTML = DateString;
		}
	}
return true;
}
function FormatTimesSinceLast(DateString) {
	document.graphs.since_last.checked = !document.graphs.since_last.checked;
	FormatStartTime(DateString);
	FormatEndTime("Today");
	}
function FormatTimesRecent() {
	document.graphs.recent.checked = !document.graphs.recent.checked;
	FormatStartTime("Yesterday");
	FormatEndTime("Today");
	}
var DeleteTime = '';
function FormatDeleteTime(DateString) {
	DateString = DateFromString(DateString);
	if (DateString != "") {
		window.status = DateString;
		if (isIE4) {
			document.all.DeleteTime.innerHTML = DateString;
			}
		DeleteTime = DateString;
		}
	else {
		DeleteTime = '';
		}
	return true;
	}
function ConfirmDelete() {
	var Confirmation;
	if (DeleteTime != '') {
		Confirmation = "Are you sure you want to delete all log entries before " + DeleteTime + "?\nThere is no undo feature, you know.";
		}
	else {
		Confirmation = "Are you sure you want to delete the entire access log?\nThere is no undo feature, you know.";
		}
	if (confirm(Confirmation)) {
		return true;
		}
	else {
		return false;
		}
	}
var GetGraphs = 0;
function JavaMakeGraphs() {
	GetGraphs = 1;
	return true;
	}
function CheckGraphs() {
	if (GetGraphs == 0) {
		return true;
		}
	else if (document.graphs.s01.checked ||
				document.graphs.s02.checked ||
				document.graphs.s02a.checked ||
				document.graphs.s03.checked ||
				document.graphs.s04.checked ||
				document.graphs.s05.checked ||
				document.graphs.s06.checked ||
				document.graphs.s07.checked ||
				document.graphs.s08.checked ||
				document.graphs.s09.checked ||
				document.graphs.s10.checked ||
				document.graphs.s11.checked ||
				document.graphs.s12.checked ||
				document.graphs.s13.checked ||
				document.graphs.s14.checked ||
				document.graphs.s15.checked) {
		return true;
		}
	else {
		Confirmation  = "You must choose something to graph.\n\nYour options are listed on the ";
		Confirmation += "left (from type of \"Web Browser\" through \"Hits by Hour of Day\").";
		Confirmation += "  You can select them by clicking your mouse on the checkbox next to each ";
		Confirmation += "item.\n\nWould you like me to choose a graph for you?";

		if (confirm(Confirmation)) {
			document.graphs.s02.checked = true;
			document.graphs.MakeGraphs.value = 'Click me now!';
			}
		return false;
		}
	}
// End Java Hiding. -->
</SCRIPT>

END_OF_HTML
} #-----------------------------------------------------------------------


%FORM = ();
&WebFormL( \%FORM );

my $b_is_login = 0;
$err = '';
Err: {

	if ($FORM{'SetCookie'}) {
		$hostname = $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'};
		$hostname = lc($2) if ($hostname =~ m!^([^\.]+)(.*)$!);
		print "Set-Cookie: axs_no_log=$FORM{'CookieValue'}; expires=Thu, 24-Sep-2020 20:58:18 GMT; domain=$hostname; path=/\015\012";
		print "Content-Type: text/html\015\012\015\012";
		print "<HTML><HEAD><META HTTP-EQUIV=\"refresh\" CONTENT=\"0; URL=$This_Script_Address?Target=Preferences\"></HEAD></HTML>";
		last Err;
		}

	print "Pragma: no-cache\015\012";
	print "Content-Type: text/html\015\012\015\012";

	if (($0 =~ m!^(.*)(\\|/)!) and ($0 !~ m!safeperl\d*$!i)) {
		unless (chdir($1)) {
			$err = "unable to chdir to local script folder '$1' - $!";
			next Err;
			}
		print "<!-- Success: chdir to '$1' -->\015\012";
		}
	$const{'is_demo'} = (-e 'is_demo') ? 1 : 0;

	# Build generic timestamp for all functions:
	@MyT = localtime(time);

	# The following guesses the script address when $ENV is undefined, which
	# happens during command-line mode:
	unless ($This_Script_Address) {
		$This_Script_Address = '';
		$This_Script_Address = $1 if ($0 =~ m!([^\\|\/]+)$!);
		}

	print &Header;

	if (($AllowDebug) && (&query_env('QUERY_STRING') =~ m!^debugme$!i)) {
		&PrintDebugInfo(1);
		last Err;
		}

	$FilterString = $FORM{'Filter'} || '';

	my $reg_err = &check_regex($FilterString);
	if ($reg_err) {
		$FilterString = '';
		print "<P><B>Error:</B> $reg_err.</P>\n";
		}

	($err, $b_is_login, %PREF) = &AuthPref($prefs);
	next Err if ($err);
	last Err unless ($b_is_login);

	if ($FORM{'Target'} && ($FORM{'Target'} eq 'LogOut')) {
		print &Authenticate;
		$b_is_login = 0;
		last Err;
		}

	my $reg_err = &check_regex($PREF{'My_Web_Address'});
	if ($reg_err) {
		$PREF{'My_Web_Address'} = '';
		print "<P><B>Error:</B> $reg_err.</P>\n";
		}


	# Next, we open the log file and import all the records.  This is *only*
	# done if we're going to make graphs this time:

	if ($FORM{'show_data'} || $FORM{'MakeGraphs'} || $FORM{'terminate'}) {

		print "<!-- choosing to open the log file -->\r\n";

	# Allows the "L" flag to date-filter database results (for reverse
	# compatibility):
	if ($FORM{'show_data'} && ($FORM{'maximum'} !~ m!^\d*$!)) {
		$FORM{'since_last'} = 'on';
		}
	# If date filtering is enabled, the dates are converted into a format
	# that makes sense to AXS:
	($StartNumber,$StartString,$EndNumber,$EndString) = &FormatDates($FORM{'start_date'}, $FORM{'end_date'}, $FORM{'recent'}, $FORM{'since_last'}, $PREF{'last_number'});
	# Open the log file and store all of the hits in the
	# @LINES array.  Run whichever filters are necessary, for date/time
	# or by-file filtering.  This preps @LINES and also $total_hits.
	unless (open(LOGFILE,"<$LogFile")) {
		&PrintDebugInfo(0);
		last Err;
		}
	binmode(LOGFILE);
	if ($FilterString eq '') {
		$FILTER = '(\|[^\|]*){10,10}\|(\d*)\|\d*\|(\d*)';
		}
	elsif ($FilterString =~ m!^host:(.*)$!i) {
		$FILTER = '\|[^\|]*'.$1.'[^\|]*(\|[^\|]*){9,9}\|(\d*)\|\d*\|(\d*)';
		}
	elsif ($FilterString =~ m!^ip:(.*)$!i) {
		$FILTER = '\|[^\|]*\|[^\|]*'.$1.'[^\|]*(\|[^\|]*){8,8}\|(\d*)\|\d*\|(\d*)';
		}
	elsif ($FilterString =~ m!^from:(.*)$!i) {
		$FILTER = '\|[^\|]*\|[^\|]*\|[^\|]*'.$1.'[^\|]*(\|[^\|]*){7,7}\|(\d*)\|\d*\|(\d*)';
		}
	elsif ($FilterString =~ m!^to:(.*)$!i) {
		$FILTER = '\|[^\|]*\|[^\|]*\|[^\|]*\|[^\|]*'.$1.'[^\|]*(\|[^\|]*){6,6}\|(\d*)\|\d*\|(\d*)';
		}
	elsif ($FilterString =~ m!^browser:(.*)$!i) {
		$FILTER = '\|[^\|]*\|[^\|]*\|[^\|]*\|[^\|]*\|[^\|]*'.$1.'[^\|]*(\|[^\|]*){5,5}\|(\d*)\|\d*\|(\d*)';
		}
	elsif ($FilterString) {
		$FILTER = '.*'.$FilterString.'(.*)\|(\d*)\|\d*\|(\d*)\|(export\|)?\r?$';
		}
	else {
		$FILTER = '(\|[^\|]*){10,10}\|(\d*)\|\d*\|(\d*)';
		}

		#print "<!-- starting loop... -->\r\n";

	$total_hits = 0;
	if ($StartNumber || $EndNumber || $FilterString) {
		$EndSearchNow = 0;
		while (defined($_ = <LOGFILE>)) {
			# make sure each row is strictly valid:
			unless (m!^\|([^\|]*)\|([^\|]+)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|(export\|)?\r?$!) {
				$total_corrupt_rows++;
				next;
				}
			$total_hits++;

			next unless (($EndSearchNow) || (m!^$FILTER!));
			$ThisYDAY = $2 * 1000 + $3 + 1900000;
			next if (($StartNumber) && ($StartNumber > $ThisYDAY));
			if ($EndNumber && ($EndNumber < $ThisYDAY)) {
				$EndSearchNow = 'true';
				next;
				}
			push(@LINES,$_);
			}
		}
	else {

		while (defined($_ = <LOGFILE>)) {
			# make sure each row is strictly valid:
			unless (m!^\|([^\|]*)\|([^\|]+)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|(export\|)?\r?$!) {
				$total_corrupt_rows++;
				next;
				}
			$total_hits++;
			push(@LINES, $_);
			}
		}
	close(LOGFILE);
	$total_hits = &AddCommas($total_hits);

		#print "<!-- done with log file -->\r\n";

		} # End importing data.

	# Now we print HTML banner which goes at the top of every page:
	print &HTML_Header;

	# Finished printing HTML header. Now determine which subprocedure(s) to
	# invoke based on the input:

	if ($FORM{'show_data'}) {
		if ($FORM{'format'} eq 'Sort All by Time') {
			&show_data;
			}
		else {
			&show_data_flow;
			}
		last Err;
		}
	&make_stats(5,'Web Browser Full Name',0) if ($FORM{'s01'});

	&make_stats(5,'Web Browser Type and Version','short') if ($FORM{'s02'});

	&make_stats(5,'Web Browser Type','med') if ($FORM{'s02a'});

	&make_stats(5,'Operating System','os') if ($FORM{'s03'});

	if ($FORM{'s04'}) {
		if (open(FILE,"<data/tld.txt")) {
			binmode(FILE);
			while (<FILE>) {
				next unless (m!^(.*?):(.*?)\015?\012?$!);
				$tldx{$1} = $2;
				}
			close(FILE);
			}
		if (open(FILE,"<data/sld.txt")) {
			binmode(FILE);
			while (<FILE>) {
				next unless (m!^(.*?):(.*?)\015?\012?$!);
				$sldx{$1} = $2;
				}
			close(FILE);
			}
		if (open(FILE,"<data/states.txt")) {
			binmode(FILE);
			while (<FILE>) {
				next unless (m!^(.*?):(.*?)\015?\012?$!);
				$statesx{$1} = $2;
				}
			close(FILE);
			}
		&make_stats(1,'Top-Level Domain','tld');
		}
	&make_stats(1,'Domain','abbr') if ($FORM{'s05'});
	&make_stats(1,'Remote Server','full') if ($FORM{'s06'});
	&make_stats(2,'IP Address',0) if ($FORM{'s07'});
	&make_stats(3,'Referring URL','') if ($FORM{'s08'});
	&make_stats(3,'Referring URL','domain') if ($FORM{'s09'});
	&make_stats(4,'Links Followed','remote') if ($FORM{'s10'});
	&make_stats(4,'Document Hit','local') if ($FORM{'s11'});
	&avg_docs if ($FORM{'s12'});
	&make_stats_year(13,'Day of the Year',0) if ($FORM{'s13'});
	&make_stats_week(12,'Day of the Week',0) if ($FORM{'s14'});
	&make_stats_hour(8,'Hour of the Day',0) if ($FORM{'s15'});
	&kill_it if ($FORM{'terminate'});
	last Err if ($graph_made);

	# If no graphs were made, then show the intro page, or allow
	# the user to set his preferences.  Each of these pages will use the
	# massive Java library:
	print &JavaLib;

	if (($FORM{'Target'}) && ($FORM{'Target'} eq 'Preferences')) {
		# show preferences:
		$LogSizeKiloBytes = int((-s $LogFile) / 1000);
		if ($LogSizeKiloBytes < 500) {
			$Advice = 'that is not too bad';
			}
		elsif ($LogSizeKiloBytes < 1000) {
			$Advice = 'it is starting to get up there';
			}
		else {
			$Advice = 'you may want to delete it';
			}
		$LogSizeKiloBytes = &AddCommas($LogSizeKiloBytes);
		&PrintCustomizePage;
		}
	else {
		# show main page:
		&PrintJavaMainPage;
		&PrintMainPage;
		}

	last Err;
	}
continue {
	print "<P><B>Error:</B> $err.</P>\n";
	}
&Footer($b_is_login);




# This is the end - everything below is a sub-procedure called above.
# ________________________________________________________________________


# Prints a line of the graph:
#
#	Format is &print_line(Name,Value) where Name is something
#	like 'Netscape 3' and Value is the number of hits.
#	<TR><TD> name </TD><TD> percent </TD><TD> number </TD><TD> picture </TD></TR>
sub print_line {
($N,$V) = @_;
print "<TR><TD NOWRAP><TT>$N</TT>";
print '</TD><TD '.$BGCOLOR.' ALIGN="right"><TT>';
print sprintf("%.2f",($V * $RH100));
print '%</TT></TD><TD ALIGN=RIGHT><TT>';
print "$V</TT></TD>";

# traps minimum width at 1, since width=0 is ignored by browser:
$width = int($multiplier * $V) || 1;

print "<TD ALIGN=LEFT><IMG SRC=\"$PREF{'images_folder'}red.gif\" BORDER=\"1\" ALT=\"";
print 'X' x int($width*(30/$PREF{'MaxWidth'}));
print "\" HEIGHT=10 WIDTH=$width>";

# print '<TD><TABLE BGCOLOR="#000000" BORDER="0" CELLSPACING="2" CELLPADDING="0" WIDTH="'.$width.'" HEIGHT="5"><TR><TD BGCOLOR="#cf0000"><FONT SIZE="1"><BR></FONT></TD></TR></TABLE>';

print '</TD></TR>', "\n";
} # End Print Line.



sub print_line2 {
	my ($N,$N2,$V) = @_;
	print "<TR><TD NOWRAP><TT>$N</TT></TD><TD><TT>$N2<BR></TT></TD>";
	print '<TD '.$BGCOLOR.' ALIGN="right"><TT>';
	print sprintf("%.2f",($V * $RH100));
	print '%</TT></TD><TD ALIGN=RIGHT><TT>';
	print "$V</TT></TD>";
	# traps minimum width at 1, since width=0 is ignored by browser:
	$width = int($multiplier * $V) || 1;
	print "<TD ALIGN=LEFT><IMG SRC=\"$PREF{'images_folder'}red.gif\" BORDER=\"1\" ALT=\"";
	print 'X' x int($width*(30/$PREF{'MaxWidth'}));
	print "\" HEIGHT=10 WIDTH=$width>";
	# print '<TD><TABLE BGCOLOR="#000000" BORDER="0" CELLSPACING="2" CELLPADDING="0" WIDTH="'.$width.'" HEIGHT="5"><TR><TD BGCOLOR="#cf0000"><FONT SIZE="1"><BR></FONT></TD></TR></TABLE>';
	print '</TD></TR>', "\n";
	} # End Print Line.




# Prints a line of the graph.  Allows Value = 0.
#
#	Format is &print_line_allow0(Name,Value) where Name is something
#	like 'Tuesday' and Value is the number of hits.
#	<TR><TD> name </TD><TD> percent </TD><TD> number </TD><TD> picture </TD></TR>
sub print_line_allow0 {
($N,$V) = @_;
$N .= '&nbsp;' x (12 - length($N));
print "<TR><TD NOWRAP><TT>$N</TT>";
print '</TD><TD '.$BGCOLOR.' ALIGN="right"><TT>';
print sprintf("%.2f",($V * $RH100));
print '%</TT></TD><TD ALIGN="right"><TT>';
if ($V) {
	print $V;
	print '</TT></TD>';
	# traps minimum width at 1, since width=0 is ignored by browser:
	$width = int($multiplier * $V) || 1;
	print "<TD ALIGN=\"left\"><IMG SRC=\"$PREF{'images_folder'}red.gif\" BORDER=2 ALT=\"";
	print 'X' x int($width*(30/$PREF{'MaxWidth'}));
	print "\" HEIGHT=10 WIDTH=$width>";
# Above comments out image-using graphs:
#	print '<TD><TABLE BGCOLOR="#cc0000" WIDTH="'.$width.'"><TR><TD><BR></TD></TR></TABLE>';

	}
else {
	print '0</TT></TD><TD><BR>';
	}
print '</TD></TR>', "\n";
} # End Print Line/Allow 0


# Begin Main Graphing Procedure:
sub make_stats {
	($q, $graph_name, $detail) = @_;
	print '<BR><BR><HR SIZE="1" WIDTH="80%"><BR><BR><BR>' if $graph_made;





	if ($FORM{'cvs_out'}) {
		print "<hr /><pre><xmp>\n\n";
		}
	else {
		print '<TABLE BORDER="0" CELLPADDING="6" CELLSPACING="0">';

		if ($detail eq 'tld') {
			print '<TH COLSPAN=2 ALIGN="left">';
			}
		else {
			print '<TH ALIGN="left">';
			}

		print &html_encode($graph_name) . ':</TH><TH COLSPAN="2" ALIGN="center"> Hits: </TH><TH ALIGN="left">Graph:</TH></TR>';

		}

	$relevant_hits = 0;
	$max_var = 0;
	undef(%ASTA);

	my $qmbd2 = quotemeta($FORM{'bd2'} || '');


	foreach $RECORD (@LINES) {
		@xSQL = split(/\|/,$RECORD);
		$xSQL[1] = $xSQL[1] || $xSQL[2];

	# Special case of referring URLs - the script makes sure first
	# that there is a non-zero entry in field 3, and then discards
	# those which appear to be local to the web site.  If the query
	# is being made for domain name only, the script runs a pattern
	# match on (somthing)//(something)/(whatever) and saves the first
	# two fields.  Local file links are discarded for domain-only
	# queries.

	if ($q == 3) {
		next unless ($xSQL[3]);

	# To protect against those with blank $PREF{'My_Web_Address'} variables, this
	# code will show *all* referrers if $PREF{'My_Web_Address'} is blank.  I feel
	# that this is a better solution that showing *no* referers.
	#
	# code was:
	# next if ($xSQL[3] =~ /$PREF{'My_Web_Address'}/i);

		next if (($PREF{'My_Web_Address'}) && ($xSQL[3] =~ /$PREF{'My_Web_Address'}/i));


		if (($detail eq 'domain') && ($xSQL[3] =~ m!^([^\/]+)\/\/([^\/]*)!)) {
			$xSQL[3] = $1.'//'.$2;
			next if ($1 =~ m!file!i);
			}
		# strip "#" signs from URL's:
		if (($PREF{'HidePoundSigns'}) and ($xSQL[3] =~ m!^(.*)\#!)) {
			$xSQL[3] = $1;
			}
		if (($PREF{'HideQueryStrings'}) and ($xSQL[3] =~ m!^(.*)\?!)) {
			$xSQL[3] = $1;
			}
		}


	# $q = 1 indicates a query on the server name.  this code
	# abbreviates the server names to either TLD, host.TLD, or
	# ' IP Address Only' in the case of non-alpha hosts.

	elsif ($q == 1) {
		if ($xSQL[1] =~ m!([^\.]+)\.([^\.]+)\.([^\.|\d]+)$!) {
			my ($p1, $p2, $p3) = ($1, $2, $3);
			# check for foo.co.uk format
			if ((length($p3) == 2) and ($p2 =~ m!^(\w\w|com|net|edu|gov)$!i)) {
				if ($detail eq 'tld') {
					$xSQL[1] = "$p2.$p3";
					}
				elsif ($detail eq 'abbr') {
					$xSQL[1] = "$p1.$p2.$p3";
					next if (($FORM{'bd1'}) and ("$p2.$p3" ne $FORM{'bd1'}));
					}
				}
			else {
				if ($detail eq 'tld') {
					$xSQL[1] = $p3;
					}
				elsif ($detail eq 'abbr') {
					$xSQL[1] = $p2.'.'.$p3;
					next if (($FORM{'bd1'}) and ($p3 ne $FORM{'bd1'}));
					}
				}
			}
		elsif ($xSQL[1] =~ m!([^\.]+)\.([^\.|\d]+)$!) {
			if ($detail eq 'tld') {
				$xSQL[1] = $2;
				}
			elsif ($detail eq 'abbr') {
				$xSQL[1] = $1.'.'.$2;
				next if (($FORM{'bd1'}) and ($2 ne $FORM{'bd1'}));
				}
			}
		else {
			next if ($FORM{'bd1'});
			$xSQL[1] = ' IP addr';
			}
		if (($detail eq 'full') and ($FORM{'bd2'})) {
			next unless ($xSQL[1] =~ m!(^|\.)$qmbd2$!i);
			}
		}


	# Exit Points & Local Documents:

	elsif ($q == 4) {
		if ($detail eq 'remote') {
			next if ($xSQL[14] ne 'export');

			# Again, only limit to local web pages if the $PREF{'My_Web_Address'} variable
			# is populated:
			next if (($PREF{'My_Web_Address'}) and ($xSQL[4] =~ m!$PREF{'My_Web_Address'}!i));

			}
		elsif ($detail eq 'local') {

			# Again, only limit to local web pages if the $PREF{'My_Web_Address'} variable
			# is populated:

			next unless ($xSQL[4] =~ m!$PREF{'My_Web_Address'}!i);

			}

		# strip # signs from URL's:
		if (($PREF{'HidePoundSigns'}) && ($xSQL[4] =~ m!^(.*?)\#!)) {
			$xSQL[4] = $1;
			}
		if (($PREF{'HideQueryStrings'}) && ($xSQL[4] =~ m!^(.*?)\?!)) {
			$xSQL[4] = $1;
			}

		if ($xSQL[4] =~ m|([^\/]+)//([^\/]+):80\/(.*)|) {
			$xSQL[4] = "$1//$2/$3";
			}
		if (($PREF{'HideDefaultDoc'}) && ($xSQL[4] =~ m!(.*)/$DefaultDoc$!i)) {
			$xSQL[4] = "$1/";
			}

		}


	# Operating System and Short Web Browser Name:

	elsif ($q == 5) {

		if ($FORM{'bd1'}) { # browser detail 1
			my $browser_type = &get_browser_name($xSQL[5]);
			next unless ($browser_type eq $FORM{'bd1'});
			$xSQL[5] = &get_browser_ver($xSQL[5]);
			}
		elsif ($FORM{'bd2'}) { # browser detail 2
			my $browser_type = &get_browser_ver($xSQL[5]);
			next unless ($browser_type eq $FORM{'bd2'});
			}
		elsif ($FORM{'bd3'}) { # browser/os detal 3
			my $os_type = &get_os_type($xSQL[5]);
			next unless ($os_type eq $FORM{'bd3'});
			}
		else {
			$xSQL[5] = &get_os_type($xSQL[5]) if ($detail eq 'os');
			$xSQL[5] = &get_browser_name($xSQL[5]) if ($detail eq 'med');
			$xSQL[5] = &get_browser_ver($xSQL[5]) if ($detail eq 'short');
			}
		}


	$ASTA{$xSQL[$q]}++;
	$relevant_hits++;
	$max_var++ unless ($max_var >= $ASTA{$xSQL[$q]});
	}
# Finish loop through each hit in log file.


	$const{'truncated_keys'} = 0;

	$multiplier = ($PREF{'MaxWidth'} / $max_var) if ($max_var);

	$RH100 = 100 / $relevant_hits if ($relevant_hits);
	if ($relevant_hits < 1) {
		print '<TR><TD><B>No matches found for your search. Sorry.</B></TD></TR>';
		}
	elsif (($q == 3) || ($q == 4)) {
		# q3/4 => hits to local, hits from remote, etc. URL's.
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {
			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				}
			else {
				&print_line(&url_format($_),$ASTA{$_});
				}
			}
		}
	elsif (($q == 1) && ($detail eq 'abbr')) {
		# q1 => server names.

		my ($val, $dislay_val) = ('', '');

		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {
			$val = $display_val = $_;
			if (($PREF{'MaxChars'}) and (length($val) > $PREF{'MaxChars'})) {
				$const{'truncated_keys'}++;
				$display_val = substr($val, 0, $PREF{'MaxChars'});
				}

			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				next;
				}



			if (m! IP addr!) {
				&print_line('<I>IP addr</I>',$ASTA{$_});
				}
			else {
				&print_line("[<A HREF=\"$whois" . &html_encode($val) . "\"$TARGET>who</A>] <A HREF=\"$ENV{'SCRIPT_NAME'}?s06=on&MakeGraphs=1&bd2=" . &url_encode($_) . "\">" . &html_encode($display_val) . "</A>",$ASTA{$_});
				}
			}
		}
	elsif (($q == 1) and ($detail eq 'tld')) {
		# mil/com/ca etc
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {

			my $main = '';
			my $tld = $tldx{$_} || '';


			if ($_ eq ' IP addr') {
				$main = $_;
				$tld = '';
				}
			else {
				if (m!^(\w+)\.(\w+)$!) {
					if ($2 eq 'us') {
						$tld = "$statesx{$1} - $tldx{$2}";
						}
					else {
						$tld = "$sldx{$1} - $tldx{$2}";
						}
					}
				$main = "<A HREF=\"$ENV{'SCRIPT_NAME'}?s05=on&MakeGraphs=1&bd1=" . &url_encode($_) . "\">" . &html_encode($_) ."</A>";
				}

			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				$tld =~ s!\,!!g;
				print "$_,$tld,$ASTA{$_},\n";
				next;
				}

			&print_line2( $main, $tld, $ASTA{$_} );
			}
		}



	elsif ($q == 2) {
		# q2 => IP addresses.
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {

			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				next;
				}


			$htmlsafe = &html_encode($_);
			&print_line("<A HREF=\"$nslookup?$htmlsafe\"$TARGET>$htmlsafe</A>",$ASTA{$_});
			}
		}
	elsif (($q == 5) and ($detail eq 'med')) {
		my ($val, $dislay_val) = ('', '');





		# q* => other.  q5 = browser type, os type, etc.
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {
			$val = $display_val = $_;
			if (($PREF{'MaxChars'}) and (length($val) > $PREF{'MaxChars'})) {
				$const{'truncated_keys'}++;
				$display_val = substr($val, 0, $PREF{'MaxChars'});
				}


			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				next;
				}

			&print_line( "<A HREF=\"$ENV{'SCRIPT_NAME'}?s02=on&MakeGraphs=1&bd1=" . &url_encode($display_val) . "\">" . &html_encode($display_val) ."</A>", $ASTA{$_} );
			}
		}

	elsif (($q == 5) and ($detail eq 'short')) {
		my ($val, $dislay_val) = ('', '');





		# q* => other.  q5 = browser type, os type, etc.
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {
			$val = $display_val = $_;
			if (($PREF{'MaxChars'}) and (length($val) > $PREF{'MaxChars'})) {
				$const{'truncated_keys'}++;
				$display_val = substr($val, 0, $PREF{'MaxChars'});
				}

			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				next;
				}

			&print_line( "<A HREF=\"$ENV{'SCRIPT_NAME'}?s01=on&MakeGraphs=1&bd2=" . &url_encode($display_val) . "\">" . &html_encode($display_val) ."</A>", $ASTA{$_} );
			}
		}

	elsif (($q == 5) and ($detail eq 'os')) {
		my ($val, $dislay_val) = ('', '');





		# q* => other.  q5 = browser type, os type, etc.
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {
			$val = $display_val = $_;
			if (($PREF{'MaxChars'}) and (length($val) > $PREF{'MaxChars'})) {
				$const{'truncated_keys'}++;
				$display_val = substr($val, 0, $PREF{'MaxChars'});
				}

			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				next;
				}

			&print_line( "<A HREF=\"$ENV{'SCRIPT_NAME'}?s01=on&MakeGraphs=1&bd3=" . &url_encode($display_val) . "\">" . &html_encode($display_val) ."</A>", $ASTA{$_} );
			}
		}
	else {
		my ($val, $dislay_val) = ('', '');





		# q* => other.  q5 = browser type, os type, etc.
		foreach ($NUMS ? (sort {$ASTA{$b} <=> $ASTA{$a} || $a cmp $b} keys %ASTA) : (sort keys %ASTA)) {
			$val = $display_val = $_;
			if (($PREF{'MaxChars'}) and (length($val) > $PREF{'MaxChars'})) {
				$const{'truncated_keys'}++;
				$display_val = substr($val, 0, $PREF{'MaxChars'});
				}

			if ($FORM{'cvs_out'}) {
				s!\,!!g;
				print "$_,$ASTA{$_},\n";
				next;
				}

			&print_line( &html_encode($display_val), $ASTA{$_} );
			}
		}
	$NumGraphLines = scalar (keys %ASTA);



	if ($FORM{'cvs_out'}) {
		print "\n\n</xmp></pre><hr />\n";
		}
	else {
		print "</TABLE>\n";
		}

	print &GraphSummary;
	$graph_made++;
	}


# Begin Main Graphing Procedure for Day of Year:

sub make_stats_year {
	@DayCount = ();

	# Do we have a leap year, or a non-leap year?
	# leap years are divisible by 4.  However, every 100 years
	# is an exception (non-leap), and every 400 years is an
	# exception to that (leap).

	$this_year = (localtime(time))[5] + 1900;

	# Assume normal year:
	@mon_array = (0,31,59,90,120,151,181,212,243,273,304,334);
	$total_days_year = 365;

	if (($this_year % 4) == 0) {
		# year is divisible by 4, is leap, probably

		if ((($this_year % 100) == 0) && (($this_year % 400) != 0)) {
			# is divisible by 100, and not divisible by 400;
			# standard exception, leave this as a non-leap year
			}
		else {
			# ok world we have a leap year:

			@mon_array = (0,31,60,91,121,152,182,213,244,274,305,335);
			$total_days_year = 366;

			}
		}

	print '<BR><BR><HR SIZE=1 WIDTH=80%><BR><BR><BR>' if $graph_made;


	if ($FORM{'cvs_out'}) {
		print "<hr /><pre><xmp>\n\n";
		}
	else {
		print '<TABLE BORDER="0" CELLPADDING="6" CELLSPACING="0">';
		print '<TR><TH ALIGN="left">Day of Year:</TH><TH COLSPAN="2" ALIGN="center"> Hits:</TH><TH ALIGN="left">Graph:</TH></TR>';
		}



	undef($max_var);
	undef(%ASTA);
	$relevant_hits = scalar @LINES;

	my $min_day = 366;
	my $max_day = -1;

	foreach (@LINES) {
		$ThisDay = (split(/\|/,$_))[13];

		$max_day = $ThisDay if ($ThisDay > $max_day);
		$min_day = $ThisDay if ($ThisDay < $min_day);


		$DayCount[$ThisDay]++;
		$max_var++ unless ($max_var >= $DayCount[$ThisDay]);
		}
	$multiplier = ($PREF{'MaxWidth'} / $max_var) if ($max_var);
	if ($relevant_hits) {
		$RH100 = 100 / $relevant_hits;
		}
	$month_count = 0;

	# error correct
	$min_day = 0 if ($min_day == 366);
	$max_day = $total_days_year if ($max_day == -1);

	for (0..($total_days_year - 1)) {
		$month_count++ if ($_ == $mon_array[$month_count + 1]);
		$mday = (($_ - $mon_array[$month_count]) + 1);
		$day = "$LongMonths[$month_count] $mday";
		next if ($_ < $min_day);
		last if ($_ > $max_day);
		$NumGraphLines++;


		if ($FORM{'cvs_out'}) {
			s!\,!!g;
			my $human_month = $month_count + 1;
			print "$day,$human_month,$mday,$DayCount[$_],\n";
			next;
			}

		&print_line_allow0($day, $DayCount[$_]);
		}

	if ($FORM{'cvs_out'}) {
		print "\n\n</xmp></pre><hr />\n";
		}
	else {
		print "</TABLE>\n";
		}

	print &GraphSummary;
	$graph_made++;
	} # End Graph for Day of Year.


# Begin Main Graphing Procedure for Day of Week
sub make_stats_week {
	@DayCount = ();

print '<BR><BR><HR SIZE=1 WIDTH=80%><BR><BR><BR>' if $graph_made;



	if ($FORM{'cvs_out'}) {
		print "<hr /><pre><xmp>\n\n";
		}
	else {
		print '<TABLE BORDER="0" CELLPADDING="6" CELLSPACING="0">';
		print '<TR><TH ALIGN="left">Day of Week:</TH><TH COLSPAN="2" ALIGN="center"> Hits:</TH><TH ALIGN="left">Graph:</TH></TR>';
		}



undef($max_var);
undef(%ASTA);
$relevant_hits = scalar @LINES;
foreach (@LINES) {
	$ThisDay = (split(/\|/,$_))[12];
	$DayCount[$ThisDay]++;
	$max_var++ unless ($max_var >= $DayCount[$ThisDay]);
	}
$multiplier = ($PREF{'MaxWidth'} / $max_var) if ($max_var);
if ($relevant_hits) {
	$RH100 = 100 / $relevant_hits;
	}
# q12 => LongWeekDays
for (0..6) {
		if ($FORM{'cvs_out'}) {
			s!\,!!g;
			my $human_month = $month_count + 1;
			print "$LongWeekDays[$_],$_,$DayCount[$_],\n";
			next;
			}

	&print_line_allow0($LongWeekDays[$_],$DayCount[$_]);
	}
$NumGraphLines = 7;

	if ($FORM{'cvs_out'}) {
		print "\n\n</xmp></pre><hr />\n";
		}
	else {
		print "</TABLE>\n";
		}

print &GraphSummary;
$graph_made++;
} # End Graph for Day of Week



# Begin Main Graphing Procedure for Hour of Day:
sub make_stats_hour {
print '<BR><BR><HR SIZE=1 WIDTH=80%><BR><BR><BR>' if $graph_made;



	if ($FORM{'cvs_out'}) {
		print "<hr /><pre><xmp>\n\n";
		}
	else {
		print '<TABLE BORDER="0" CELLPADDING="6" CELLSPACING="0">';
		print '<TR><TH ALIGN="left">Hour of Day:</TH><TH COLSPAN="2" ALIGN="center"> Hits:</TH><TH ALIGN="left">Graph:</TH></TR>';
		}






undef($max_var);
undef(%ASTA);

$relevant_hits = scalar @LINES;
foreach (@LINES) {
	$ThisHour = (split(/\|/,$_))[8];
	$HourCount[$ThisHour]++;
	$max_var++ unless ($max_var >= $HourCount[$ThisHour]);
	}
$multiplier = ($PREF{'MaxWidth'} / $max_var) if ($max_var);
if ($relevant_hits) {
	$RH100 = 100 / $relevant_hits;
	}
for (0..23) {



		if ($FORM{'cvs_out'}) {
			s!\,!!g;
			print "$_,$HourCount[$_],\n";
			next;
			}


	print '<TR><TD ALIGN="right"><TT>';
	if ($PREF{'UseMilTime'}) {
		print "$_:00";
		}
	else {
		if ($_ == 0) {
			print 'Midnight';
			}
		elsif ($_ < 12) {
			print $_.' AM';
			}
		elsif ($_ == 12) {
			print 'High noon';
			}
		else {
			print $_ - 12;
			print ' PM';
			}
		}
	print '&nbsp;</TT></TD><TD '.$BGCOLOR.' ALIGN="right"><TT>';
	$V = $HourCount[$_];
	print sprintf("%.2f",($V * $RH100));
	print '%</TT></TD><TD ALIGN=RIGHT><TT>';
	if ($V) {
		print "$V</TT></TD>";
		# traps minimum width at 1, since width=0 is ignored by browser:
		$width = int($multiplier * $V) || 1;
		print "<TD ALIGN=LEFT><IMG SRC=\"$PREF{'images_folder'}red.gif\" BORDER=2 ALT=\"";
		print 'X' x int($width*(30/$PREF{'MaxWidth'}));
		print "\" HEIGHT=10 WIDTH=$width>";
		}
	else {
		print '0</TT></TD><TD><BR>';
		}
	print '</TD></TR>', "\n";
	}
$NumGraphLines = 24;

	if ($FORM{'cvs_out'}) {
		print "\n\n</xmp></pre><hr />\n";
		}
	else {
		print "</TABLE>\n";
		}
print &GraphSummary;
$graph_made++;
} # End make_stats_hour.





sub avg_docs {
	$internal_hits = 0;
	$unique_ip_count = 0;
	foreach (@LINES) {
		@terms = split(/\|/,$_);
		$unique_ip_count++ unless ($IP{$terms[2]});
		$IP{$terms[2]}++;
		$internal_hits++ if ($terms[4] =~ /$PREF{'My_Web_Address'}/i);
		}
	if ($unique_ip_count) {
		$avg_docs_per_visitor = $internal_hits / $unique_ip_count;
		}
	else {
		$avg_docs_per_visitor = 0;
		}
	$avg_docs_per_visitor = sprintf("%.3f",$avg_docs_per_visitor);

	$relevant_hits = $internal_hits;

	my $ac_internal_hits = &AddCommas($internal_hits);
	$unique_ip_count = &AddCommas($unique_ip_count);

print '<BR><BR><HR SIZE=1 WIDTH=80%><BR><BR><BR>' if $graph_made;
print <<EOM;
<B>Average Number of Hits Per Visitor</B>
<BLOCKQUOTE>
The average number of documents viewed per visitor is
<B>$avg_docs_per_visitor</B>.<BR>
There have been a total of $ac_internal_hits on local documents from
$unique_ip_count unique IP addresses.
</BLOCKQUOTE>
EOM
	print &GraphSummary;
	$graph_made++;
	}


sub PrettyTime {
	($Hour,$Minutes,$Seconds) = @_;

	#changed 0013 - fixed problems with date rendering
	$Minutes = reverse(substr(reverse("00$Minutes"), 0, 2));
	$Seconds = reverse(substr(reverse("00$Seconds"), 0, 2));

	if ($PREF{'UseMilTime'}) {
		$Hour = reverse(substr(reverse("  $Hour"), 0, 2));
		return "$Hour:$Minutes:$Seconds";
		}
	elsif ($Hour < 12) {
		$Hour = reverse(substr(reverse("  $Hour"), 0, 2));
		return "$Hour:$Minutes:$Seconds AM";
		}
	else {
		$Hour -= 12;
		$Hour = reverse(substr(reverse("  $Hour"), 0, 2));
		return "$Hour:$Minutes:$Seconds PM";
		}
	#end changes
	}

# Begin Show Database Procedure:
sub show_data {
	if ($FORM{'maximum'} =~ /\d+/) {
		$array_size = scalar @LINES;
		if ($FORM{'maximum'} < $array_size) {
			splice(@LINES,0,$array_size - $FORM{'maximum'});
			}
		}

	print &DatabaseTimeDescription;
	print '<PRE>';

	($relevant_hits,$NumGraphLines) = (0,0);
	foreach (reverse @LINES) {
		$relevant_hits++;
		($VisitHost,$IPAddress,$T3,$T4,$Browser,$SS,$MM,$HH,$Day,$T10,$Year,$T12,$Redirect) = (split(/\|/,$_))[1..12,14];
		$VisitHost = $VisitHost || $IPAddress;

		$Referer = $T3 ? &url_format($T3) : '';
		$WebPage = &url_format($T4);
		$HourMinSec = &PrettyTime($HH,$MM,$SS);
		$WeekDay = $LongWeekDays[$T12];
		$Month = $LongMonths[$T10];
		$Year += 1900;
		$Redirect = ($Redirect eq 'export') ? 1 : 0;

		#changed 0015 - security fix
		foreach ($VisitHost, $IPAddress, $Browser) {
			$_ = html_encode($_); #changed 0015 - security fix
			}


		print "A visitor from <B>$VisitHost</B> ($IPAddress)\n";
		if (($Redirect) && ($Referer ne $WebPage)) {
			print "was redirected to $WebPage\n";
			print "from $Referer\n";
			}
		elsif ($Redirect) {
			print "visited $WebPage\n";
			}
		else {
			if ($Referer) {
				print "arrived from $Referer,\n";
				}
			else {
				print "arrived without a refering URL,\n";
				}
			print "and visited $WebPage\n";
			}
		print "at $HourMinSec on $WeekDay, $Month $Day, $Year.\n";
		print "This visitor used $Browser.\n";
		print "\n";
		}
	print '</PRE>';
	print &GraphSummary;
	$graph_made++;
	} # End Show Database Procedure.


# Begin Show Database-Sytle Visitor Flow:
sub show_data_flow {
if ($FORM{'maximum'} =~ /\d+/) {
	$array_size = @LINES;
	if ($FORM{'maximum'} < $array_size) {
		splice(@LINES,0,$array_size - $FORM{'maximum'});
		}
	}
($total_ips,$multiple_hit_ips) = (0,0);
$delimiter = 'Flow_Chart_Delimiter';
foreach (@LINES) {
	next unless (m!^\|([^\|]*)\|([^\|]+)!);
	if ($IPFLOW{$2}) {
		$IPFLOW{$2} .= $delimiter.$_;
		}
	else {
		push(@IPS,$2);
		$IPFLOW{$2} = $_;
		$total_ips++;
		}
	}

print &DatabaseFlowDescription;
print '<PRE>';

foreach $key (reverse @IPS) {
	@LINES = split(m!$delimiter!,$IPFLOW{$key});

	$num_hits = scalar @LINES;
	if (($num_hits > 1) || ($FORM{'format'} eq 'Sort All by Visitor')) {

		# Multiple documents visited; generate flow chart:

		$multiple_hit_ips++ if ($num_hits > 1);
		@terms = split(/\|/,$LINES[0]);
		$terms[1] = $terms[1] || $terms[2];

		$HourMinSec = &PrettyTime($terms[8],$terms[7],$terms[6]);

		if ($num_hits > 2) {
			$NumTimes = "$num_hits times";
			}
		elsif ($num_hits == 1) {
			$NumTimes = 'once';
			}
		else {
			$NumTimes = 'twice';
			}

		#changed 0015 - security fix
		foreach ($terms[1], $terms[2], $terms[3], $terms[4], $terms[5]) {
			$_ = &html_encode($_); #changed 0015 - security fix
			}


$FullYear = 1900 + $terms[11];

print <<"EOM";
<HR SIZE="1" WIDTH="80%">

A visitor from <B>$terms[1]</B> ($terms[2]) was logged $NumTimes,
starting at $HourMinSec on $LongWeekDays[$terms[12]], $LongMonths[$terms[10]] $terms[9], $FullYear.
The initial browser was $terms[5].

EOM

print '  This visitor first ';
$first = 'true';
foreach (@LINES) {
	@terms = split(/\|/,$_);
	$terms[1] = $terms[1] || $terms[2];

		if ($first ne 'true') {

			$ThisTime = ((((($terms[13] * 24) + $terms[8]) * 60) + $terms[7]) * 60) + $terms[6];

			# $INT is the time interval in seconds:

			$INT = ($ThisTime - $PrevTime);

			#changed 0013 - fixed date rendering problem

			$seconds = int($INT % 60);
			$minutes = int(($INT % 3600) / 60);
			$hours = int(($INT % 86400) / 3600);

			$minutes = reverse(substr(reverse("00$minutes"), 0, 2));
			$seconds = reverse(substr(reverse("00$seconds"), 0, 2));
			$hours = reverse(substr(reverse("00$hours"), 0, 2));

			#end changes

			print "  $hours:$minutes:$seconds";
			if ($days = int($INT/86400)) {
				print " and $days day";
				print 's' if ($days > 1);
				}
			print " later, ";
			}

		if (($terms[14] eq 'export') && ($terms[3] ne $terms[4])) {
			print "was redirected to " . &url_format($terms[4]) . "\n";
			print "      from " . &url_format($terms[3]) . "\n\n";
			}
		elsif ($terms[14] eq 'export') { # Image redirect
			print "dropped by " . &url_format($terms[3]) . "\n\n";
			}
		else {
			if ($terms[3]) {
				print "arrived from " . &url_format($terms[3]) . "\n";
				}
			else {
				print "arrived without a refering URL,\n";
				}
			print "    and visited " . &url_format($terms[4]) . "\n";
			print "\n";
			}
		$first = 'false';

		$PrevTime = ((((($terms[13] * 24) + $terms[8]) * 60) + $terms[7]) * 60) + $terms[6];

		} # End foreach hit per IP.
	} # End test of more than one hit per IP.
} # End foreach loop through all IP's.

print <<"EOM";

<HR SIZE="1" WIDTH="80%">

</PRE>

<P><B>Summary:</B></P>

<P>There were visits from $total_ips distinct IP addresses.
However, only $multiple_hit_ips of these visited more than one
document.</P>
EOM

$graph_made++;
} # End Show Database-Style Visitor Flow.



# Begin Export/Delete Log Procedure:
sub kill_it {
	my $err = '';
	Err: {
		$graph_made++;

		if ($const{'is_demo'}) {
			$err = "the deletion of the access log is not allowed in the online demo";
			next Err;
			}

		unless (open(NEWLOG,">$LogFile")) {
			$err = "unable to open log file '$LogFile' for writing - $!";
			next Err;
			}
		binmode(NEWLOG);
		if ($StartNumber) {
			$NumLogEntries = scalar @LINES;
			foreach (@LINES) {
				print NEWLOG;
				}
			}
		close(NEWLOG);
		$NewLogSize = -s $LogFile;
print <<"EOM";

<P><B>Access Log Deleted:</B></P>
<BLOCKQUOTE>
	<P>The log file has been successfully deleted.</P>

EOM

print <<"EOM" if ($StartNumber);

<P>Hits since $StartString were retained. There are now $NumLogEntries entries in the access log. The new log size is $NewLogSize bytes.</P>

EOM

print <<"EOM";

</BLOCKQUOTE>

EOM
		last Err;
		}
	continue {
		print "<P><B>Error:</B> $err.</P>\n";
		}
	}





# This is the routine to support the new "Browser Wars" report.
# The routine for the "Abbreviated Browser" report has been renamed get_browser_ver

sub get_browser_name {
	local $_ = defined($_[0]) ? lc($_[0]) : '';
	return 'Unknown/Other' unless ($_);

# I reformatted the code below to make it appear more tabular and easier to read.
# You may have to clean up the tabs on some lines.
# I found that my email and text editors don't match.

if (m!opera.(\d)!o)					{ return 'Opera'; }
elsif (m!mozilla/(\d)!o) {
	if (m!compatible!o) {
		if    (m!webtv!o)				{ return 'WebTV'; }
		elsif (m!aol!o)				{ return 'AOL\'s Browser'; }
		elsif (m!msie!o)				{ return 'Internet Explorer'; }
		elsif (m!icab!o)				{ return 'iCab'; }
		elsif (m!mozilla/3.01.\(compatible;?\)!o) { return 'Cache/Proxy server'; }
		elsif (m!powermarks!o)			{ return 'Powermarks bookmark thing'; }
		elsif (m!fdse.robot!o)			{ return 'Spider/Crawler'; }
		elsif (m!netmind-minder!o)		{ return 'Spider/Crawler'; }
		elsif (m!bordermanager!o)		{ return 'Cache/Proxy server'; }
		else						{ return 'Unknown/Other'; }
		}
	else							{ return 'Netscape'; }
	}
elsif (m!(microsoft internet explorer)|(msie)!o)	{ return 'Internet Explorer'; }
elsif (m!msproxy!o)					{ return 'Cache/Proxy server'; }
elsif (m!(crawler)|(spider)|(scooter)|(bot)!o)	{ return 'Spider/Crawler'; }
elsif (m!(iweng)|(aolbrowser)!o)			{ return 'AOL\'s Browser'; }
elsif (m!lynx!o)						{ return 'Lynx'; }
elsif (m!webexplorer!o)					{ return 'IBM WebExplorer'; }
elsif (m!quarterdeck!o)					{ return 'QuarterDeck Mosaic'; }
elsif (m!spry!o)						{ return 'Compuserve\'s SPRY Mosaic'; }
elsif (m!enhanced_mosaic!o)				{ return 'NCSA Mosaic (Enhanced)'; }
elsif (m!mosaic!o)					{ return 'NCSA Mosaic'; }
elsif (m!prodigy!o)					{ return 'Prodigy\'s Browser'; }
else								{ return 'Unknown/Other'; }
} # end sub get_browser_name


# This is the routine to support the old "Abbreviated Browser" report.
# It has been renamed from get_browser_name
sub get_browser_ver {
	local $_ = defined($_[0]) ? lc($_[0]) : '';
	return 'Unknown/Other' unless ($_);

if (m!opera.(\d)!o)					{ return "Opera v$1.x"; }
elsif (m!mozilla/(\d)!o) {
	if (m!compatible!o) {
		if    (m!webtv!o)				{ return 'WebTV'; }
		elsif (m!aol (\d).(\d)!o)		{ return "AOL's Browser v$1.$2"; }
		elsif (m!aol-iweng (\d)!o)		{ return "AOL's Browser v$1.x"; }
		elsif (m!msie.?(\d).(\d)!o)		{ return "Internet Explorer v$1.$2"; }
		elsif (m!icab (\d).(\d)!o)		{ return "iCab v$1.$2"; }
		elsif (m!konqueror!o)			{ return 'Konqueror'; }
		elsif (m!powermarks!o)			{ return 'Powermarks bookmark thing'; }

		elsif (m!mozilla/3.01.\(compatible;?\)!o) { return 'Cache/Proxy server (Unknown/Other)'; }
		elsif (m!bordermanager!o)		{ return 'Cache/Proxy server (Border Manager)'; }
		elsif (m!fdse.robot!o)			{ return 'Spider/Crawler (FDSE)'; }
		elsif (m!netmind-minder!o)		{ return 'Spider/Crawler (NetMind)'; }
		elsif (m!openfind!o)			{ return 'Spider/Crawler (Openfind)'; }
		elsif (m!webwasher!o)			{ return 'Spider/Crawler (WebWasher)'; }
		elsif (m!wisenutbot!o)			{ return 'Spider/Crawler (WISEnut)'; }
		elsif (m!webwasher!o)			{ return 'Spider/Crawler (WebWasher)'; }
		else						{ return 'Unknown/Other'; }
		}
	elsif (m!mozilla/(\d).(\d)!o) {
		my $nsver = $1;
		if ($nsver >= 5) { $nsver++; }	  return "Netscape v$nsver.$2"; }
	else							{ return "Netscape v$1.x"; }
	}
elsif (m!microsoft internet explorer/(\d)!o)	{ return "Internet Explorer v$1.x"; }
elsif (m!msie/(\d)!o)					{ return "Internet Explorer v$1.x"; }
elsif (m!msproxy!o)					{ return 'Cache/Proxy server (MSProxy)'; }
elsif (m!fast-webcrawler!o)				{ return 'Spider/Crawler (AllTheWeb)'; }
elsif (m!scooter!o)					{ return 'Spider/Crawler (Altavista)'; }
elsif (m!ask jeeves!o)					{ return 'Spider/Crawler (Ask Jeeves)'; }
elsif (m!googlebot!o)					{ return 'Spider/Crawler (Google)'; }
elsif (m!(crawler)|(spider)|(bot)!o)		{ return 'Spider/Crawler (Unknown/Other)'; }
elsif (m!teleport pro!o)				{ return 'Teleport Pro Offline Browser'; }
elsif (m!iweng/(\d)!o)					{ return "AOL's Browser v$1.x"; }
elsif (m!aolbrowser/(\d)!o)				{ return "AOL's Browser v$1.x"; }
elsif (m!lynx!o)						{ return 'Lynx'; }
elsif (m!webexplorer!o)					{ return 'IBM WebExplorer'; }
elsif (m!quarterdeck!o)					{ return 'QuarterDeck Mosaic'; }
elsif (m!spry!o)						{ return 'Compuserve\'s SPRY Mosaic'; }
elsif (m!enhanced_mosaic!o)				{ return 'NCSA Mosaic (Enhanced)'; }
elsif (m!mosaic!o)					{ return 'NCSA Mosaic'; }
elsif (m!prodigy!o)					{ return 'Prodigy\'s Browser'; }
else								{ return 'Unknown/Other'; }
} # end sub get_browser_ver


sub get_os_type {
	local $_ = defined($_[0]) ? lc($_[0]) : '';
	return 'Unknown Platform' unless $_;

	if (m!(win95)|(windows 95)!o) {
		return 'Windows 95';
		}
	elsif (m!(win 9x 4.9|windows millennium)!o) {
		return 'Windows ME';
		}
	elsif (m!(win98)|(windows 98)!o) {
		return 'Windows 98';
		}
	elsif (m!windows (nt 5\.1|xp)!i) {
		return 'Windows XP';
		}
	elsif (m!windows nt 5!i) {
		return 'Windows 2000';
		}
	elsif (m!(windows nt)|(winnt)!o) {
		return 'Windows NT';
		}
	elsif (m!win16!o) {
		return 'Windows 16-bit';
		}
	elsif (m!win32!o) {
		return 'Windows 32-bit';
		}
	elsif (m!windows 3.1!o) {
		return 'Windows 3.1';
		}
	elsif (m!windows!o) {
		if (m!32bit!o) {
			return 'Windows 32-bit';
			}
		else {
			return 'Windows 16-bit';
			}
		}
	elsif (m!window!o) {
		return 'X Windows';
		}
	elsif (m!mac!o) {
		if (m!(ppc)|(powerpc)!o) {
			return 'Macintosh (PowerPC)';
			}
		else {
			return 'Macintosh (68K)';
			}
		}
	elsif (m!freebsd!o) {
		return 'UNIX (FreeBSD)';
		}
	elsif (m!hp-ux!o) {
		return 'UNIX (HP-UX)';
		}
	elsif (m!linux!o) {
		return 'UNIX (Linux)';
		}
	elsif (m!sunos!o) {
		return 'UNIX (SunOS)';
		}
	elsif (m!(x11)|(lynx)!o) {
		return 'UNIX (Unknown/Other)';
		}
	elsif (m!amiga!o) {
		return 'Amiga';
		}
	elsif (m!os/2!o) {
		return 'OS/2';
		}
	elsif (m!iweng!o) {
		return 'Windows 16-bit';
		}
	elsif (m!webtv!o) {
		return 'WebTV';
		}
	else {
		return 'Unknown Platform';
		}
	}



sub quickparse {
	my ($str) = @_;
	my %hash = ();
	my $pair = '';
	foreach $pair (split(m!\&!s, $str)) {
		next unless ($pair =~ m!^(.*?)=(.*)$!s);
		$hash{$1} = &url_decode($2);
		}
	return %hash;
	}


sub url_format {

	# URL Format takes a URL and turns it into a hyperlink with an
	# abbreviated (no "http://") viewable output.  Links from Altavista
	# and other search engines are formatted logically:

	local $_ = $_[0] || '';
	if ((m!$PREF{'My_Web_Address'}!i) and (m!^http://(.*)!i)) {
		# Use %LocalAddressTitlePairs if it exists:
		if ($UseLocalAddressTitlePairs == 1) {
			foreach $Address (keys %LocalAddressTitlePairs) {
				return "<A HREF=\"$_\"$TARGET>$LocalAddressTitlePairs{$_}</A>" if (m!^$Address$!i);
				}
			}
		my $stub = $1;
		if (($PREF{'MaxChars'}) and (length($stub) > $PREF{'MaxChars'})) {
			$stub = substr($stub, 0, $PREF{'MaxChars'});
			$const{'truncated_keys'}++;
			}
		return $stub;
		}

	my %hash = ();

	my ($linktext, $trailtext) = ($_, '');

	if (($_ !~ /\?/) && (m!http://(.*)!i)) {
		$linktext = $1;
		}
	elsif ($_ !~ m!\?!) {
		#def
		}

	elsif (m!://([^/]+)\.google\.([^/]+)/\w+\?(.*)$!i) {
		($host, $tld, $data) = ($1, $2, $3);
		%hash = &quickparse( $data );
		$start = $hash{'start'} || 0;
		$terms = $hash{'q'} || $hash{'as_q'} || 'unknown';
		if ($hash{'num'}) {
			$end = $start + $hash{'num'};
			}
		else {
			$end = $start + 10;
			}
		$start++;
		($linktext, $trailtext) = ( "$host.google.$tld", "$terms $start-$end" );
		}
	elsif (/\:\/\/([^\/]*)altavista\.([^\/|\?]*)(.*)\?.*q\=([^\&]+).*stq\=(\d+)/i) {
		($Host,$Domain,$Terms,$Rank) = ($1,$2,&url_decode($4),$5);
		($linktext, $trailtext) = ("$Host.altavista.$Domain", "$Terms ".($Rank+1).'-'.($Rank+10) );
		}
	elsif (/\:\/\/([^\/]*)altavista\.([^\/|\?]*)(.*)\?.*q=([^\&]+).*navig(\d+)?/i) {
		($Host,$Domain,$Terms,$Rank) = ($1,$2,&url_decode($4),($5?$5:0));
		($linktext, $trailtext) = ("$Host.altavista.$Domain", "$Terms ".($Rank+1).'-'.($Rank+10) );
		}
	elsif (/\:\/\/([^\/]*)altavista\.([^\/|\?]*)(.*)\?.*q\=([^\&]+)/i) {
		($Host,$Domain,$Terms) = ($1,$2,&url_decode($4));
		($linktext, $trailtext) = ("$Host.altavista.$Domain", "$Terms 1-10" );
		}
	elsif (/\:\/\/([^\/]*)webcrawler\.([^\/]+)(.*)\?(s|search|searchText)\=([^\&]+).*\&start\=(\d+).*perPage\=(\d+)/i) {
		($Host,$Domain,$Terms,$Rank,$Increment) = ($1,$2,&url_decode($5),$6,$7);
		($linktext, $trailtext) = ( "$Host.webcrawler.$Domain" , "$Terms ".($Rank+1)."-".($Rank+$Increment) );
		}
	elsif (/\:\/\/([^\/]*)webcrawler\.([^\/]+).*(s|search|searchText)\=([^\&]+)/i) {
		($Host,$Domain,$Terms) = ($1,$2,&url_decode($4));
		($linktext, $trailtext) = ( "$Host.webcrawler.$Domain", "$Terms 1-25" );
		}
	elsif (/\:\/\/([^\/]*)metacrawler\.([^\/]+).*general\=([^\&]+).*start\=(\d+).*rpp\=(\d+)/i) {
		($Host,$Domain,$Terms,$Rank,$Increment) = ($1,$2,&url_decode($3),$4,$5);
		($linktext, $trailtext) = ( "$Host.metacrawler.$Domain", "$Terms ".($Rank+1)."-".($Rank+$Increment) );
		}
	elsif (/\:\/\/([^\/]*)metacrawler\.([^\/]+).*general\=([^\&]+)/i) {
		($Host,$Domain,$Terms) = ($1,$2,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.metacrawler.$Domain", "$Terms 1-25" );
		}
	elsif (/\:\/\/([^\/]*)netfind.aol\.([^\/]+).*start=(\d+).*&search=([^\&]+).*start=(\d+).*perPage=(\d+)/i) {
		($Host,$Domain,$Terms,$Rank,$Increment) = ($1,$2,&url_decode($5),$4,$6);
		($linktext, $trailtext) = ( "$Host.netfind.aol.$Domain", "$Terms ".($Rank+1)."-".($Rank+$Increment) );
		}
	elsif (/\:\/\/([^\/]*)netfind\.aol\.([^\/]+).*search=([^\&]+)/i) {
		($Host,$Domain,$Terms) = ($1,$2,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.netfind.aol.$Domain", "$Terms 1-25" );
		}
	elsif (/\:\/\/([^\.]*)\.infoseek\.com(.*)\?.*qt=([^\&]+).*st=(\d+)?/i) {
		($Host,$Rank,$Terms) = ($1,$5,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.infoseek.com", "$Terms ".($Rank+1).'-'.($Rank+10) );
		}
	elsif (/\:\/\/([^\.]*)\.infoseek\.com(.*)\?.*qt=([^\&]+)/i) {
		($Host,$Terms) = ($1,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.infoseek.com", "$Terms 1-10" );
		}
	elsif (/\:\/\/([^\.]*)\.infoseek\.com(.*)\?.*oq=([^\&]+).*(st=)?(\d+)?/i) {
		($Host,$Rank,$Terms) = ($1,$5,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.infoseek.com", "$Terms ".($Rank+1).'-'.($Rank+10) );
		}
	elsif (/\:\/\/([^\.]*)\.infoseek\.com(.*)\?.*oq=([^\&]+).*(st=)?(\d+)?/i) {
		($Host,$Terms) = ($1,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.infoseek.com", "$Terms 1-10" );
		}
	elsif (/\:\/\/([^\.]*)\.excite\.com(.*)\?(.*)/i) {
		($Host,$rank,$Increment) = ($1,0,10);
		@parts = split(/\&/,$3);
		foreach $part (@parts) {
			if ($part =~ /^search=(.*)/) {
				$terms = $1;
				$terms =~ tr/+/ /;
				$terms =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C',hex($1))/eg;
				}
			if ($part =~ /^perPage=(.*)/) {
				$Increment = $1;
				}
			if ($part =~ /^start=(.*)/) {
				$rank = ($1 + $Increment);
				}
			}
		($linktext, $trailtext) = ( "$Host.excite.com", "$terms " . ($rank + 1) . "-" . ($rank + $Increment) );
		}
	elsif (m!://([^\/]*)\.yahoo\.([^\/]*).*\?.*p=([^\&]+).*b=(\d+)!i) {
		($Host,$Domain,$Terms,$Rank) = ($1,$2,&url_decode($3),$4);
		($linktext, $trailtext) = ( "$Host.yahoo.$Domain", "$Terms ".$Rank.'-'.($Rank + 19) );
		}
	elsif (m!://([^\/]*)\.yahoo\.([^\/]*).*\?.*p=([^\&]+)!i) {
		($Host,$Domain,$Terms) = ($1,$2,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.yahoo.$Domain", "$Terms 1-20" );
		}
	elsif (/\:\/\/([^\/]*)\.hotbot\.([^\/]*).*\?.*MT=([^\&]+).*base=(\d+)/i) {
		($Host,$Domain,$Terms,$Rank,$NextRank) = ($1,$2,&url_decode($3),($4+11),($4+20));
		($linktext, $trailtext) = ( "$Host.hotbot.$Domain", "$Terms $Rank-$NextRank" );
		}
	elsif (/\:\/\/([^\/]*)\.hotbot\.([^\/]*).*\?.*MT=([^\&]+)/i) {
		($Host,$Domain,$Terms) = ($1,$2,&url_decode($3));
		($linktext, $trailtext) = ( "$Host.hotbot.$Domain", "$Terms 1-10" );
		}
	elsif (/http\:\/\/(.*)/i) {
		$linktext = $1;
		}

	if (($PREF{'MaxChars'}) and (length($linktext) > $PREF{'MaxChars'})) {
		$linktext = substr( $linktext, 0, $PREF{'MaxChars'} );
		$const{'truncated_keys'}++;
		}

	if ($trailtext) {

		if (($PREF{'MaxChars'}) and (length($trailtext) > $PREF{'MaxChars'})) {
			$trailtext = substr( $trailtext, 0, $PREF{'MaxChars'} );
			$const{'truncated_keys'}++;
			}


		return '<A HREF="' . $_ . '"' . $TARGET . '>' . $linktext . '</A> <I>' . $trailtext . '</I>';
		}
	else {
		return '<A HREF="' . $_ . '"' . $TARGET . '>' . $linktext . '</A>';
		}

	} # End url_format procedure.



=item AuthPref

Usage:
	($err, $b_is_login, %PREF) = &AuthPref( $prefs_file );

=cut

sub AuthPref {
	my ($PrefsFile) = @_;
	my $b_is_login = 0;
	my $err = '';
	Err: {
		local $_;

		# Try to open the prefs file:
		unless (open(PREF, "<$PrefsFile")) {
			$err = "unable to open file '$PrefsFile' for reading - $!";
			next Err;
			}
		binmode(PREF);

		# Initialize $PREF{'format'} and {'maximum'}
		%PREF = (
			'format', '',
			'maximum', '',
			'end_date', '',
			'start_date', '',
			'since_last', '',
			'last_number', '',
			'last_number_temp', '',
			'AuthIP', '',
			'last_string', '',
			'MaxWidth', 400,
			'MaxChars', 128,

			'My_Web_Address' => &query_env('HTTP_HOST'),

			'images_folder' => 'http://www.xav.com/images/',
			'Filter', '',
			'recent', '',
			'NumSort', 'CHECKED',
			'NewWindow', 'CHECKED',
			'Highlight', 'CHECKED',
			'HideDefaultDoc', 'CHECKED',
			'HidePoundSigns','CHECKED',
			'HideQueryStrings','',
			'UseMilTime', '',
			);


		while (defined($_ = <PREF>)) {
			next unless (m!^([^\|]+)\|([^\|]*)!);
			$PREF{&url_decode($1)} = &url_decode($2);
			}
		close(PREF);

		# Now authenticate this user:
		AUTH: {
			if (($AllowAnonymousForGraphs == 1) && ($FORM{'Target'} ne 'Preferences') && (!$FORM{'terminate'})) {
				$b_is_login = 1;
				last AUTH;
				}
			if ($ENV{'REMOTE_ADDR'} && ($ENV{'REMOTE_ADDR'} eq $PREF{'AuthIP'})) {
				$b_is_login = 1;
				last AUTH;
				}
			if (($Password eq $FORM{'password'}) && ($Username eq $FORM{'username'})) {
				$PREF{'AuthIP'} = $ENV{'REMOTE_ADDR'};
				$b_is_login = 1;
				last AUTH;
				}
			if (($FORM{'password'}) || ($FORM{'username'})) {
				# check to see if crypt is in effect:
				if (($FORM{'username'} eq $Username) and ($Password eq crypt($FORM{'password'},substr(0,2,$FORM{'password'})))) {
					$b_is_login = 1;
					last AUTH;
					}
				print "<P>Invalid username or password!</P>\n";
				print "<A HREF=\"$This_Script_Address\">feel free to try again...</A>\n";
				}
			else {
				print &Authenticate;
				}
			last Err;
			}

		# User authenticated, continue parsing the preferences.  Save them if
		# necessary:
		$ThisDayNum = ($MyT[5] * 1000) + $MyT[7] + 1900000;
		if (($PREF{'last_number_temp'} < $ThisDayNum) || (!$PREF{'last_number'})) {
			$PREF{'last_number'} = $PREF{'last_number_temp'};
			$PREF{'last_string'} = $PREF{'last_string_temp'};
			}
		$PREF{'last_number_temp'} = $ThisDayNum;
		$PREF{'last_string_temp'} = (&DateByNum((@MyT)[4,3],$MyT[5]+1900))[0];
		if ($FORM{'incoming'}) {
			if ($const{'is_demo'}) {
				$err = "the saving of preferences has been disabled in the on-line demo";
				next Err;
				}
			$FORM{'images_folder'} = &Trim($FORM{'images_folder'});
			$FORM{'images_folder'} .= '/' unless ($FORM{'images_folder'} =~ m!/$!); #changed 0025
			for ('maximum','MaxWidth','MaxChars','My_Web_Address','start_date','end_date','Filter','format', 'images_folder') {
				$PREF{$_} = $FORM{$_};
				delete $FORM{$_};
				}
			for (keys %GraphOptions,'since_last','recent','NumSort','NewWindow','Highlight','HideDefaultDoc','HidePoundSigns','HideQueryStrings', 'UseMilTime') {
				$PREF{$_} = $FORM{$_} ? 'CHECKED' : '';
				delete $FORM{$_};
				}
			}
		$PREF{'MaxWidth'} = 400 unless ($PREF{'MaxWidth'});
		# abbreviated flag for numerical sorting:
		$NUMS = $PREF{'NumSort'} eq 'CHECKED' ? 1 : 0;
		# abbreviate bgcolor attribute:
		if ($PREF{'Highlight'} eq 'CHECKED') {
			$BGCOLOR = 'BGCOLOR="#dddddd"';
			}
		else {
			$BGCOLOR = '';
			}
		if ($PREF{'NewWindow'}) {
			$TARGET = ' TARGET="_blank"';
			}
		else {
			$TARGET = '';
			}
		if (($ENV{'REMOTE_ADDR'}) and ($ENV{'REMOTE_ADDR'} eq $PREF{'AuthIP'})) {
			# only write out preferences for authenticated users:
			unless (open(PREF, ">$prefs")) {
				$err = "unable to open file '$prefs' for writing - $!";
				next Err;
				}
			binmode(PREF);
			foreach $key (sort keys %PREF) {
				next if (($key eq 'AuthIP') and ($FORM{'Target'}) and ($FORM{'Target'} eq 'LogOut'));
				print PREF &url_encode($key) . '|';
				print PREF &url_encode($PREF{$key}) if ($PREF{$key});
				print PREF "|\n";
				}
			close(PREF);
			}
		last Err;
		}
	return ($err, $b_is_login, %PREF);
	}


sub DateIsValid {
	($MM,$DD,$YYYY) = @_;
	for ($MM,$DD,$YYYY) {
		return 0 unless m!^\d*$!;
		}
	return 0 if (($MM < 1) || ($MM > 12) || ($DD < 1));
	if ($YYYY % 4) {
		return 0 if ($DD > (31,29,31,30,31,30,31,31,30,31,30,31)[$MM-1]);
		}
	else {
		return 0 if ($DD > (31,28,31,30,31,30,31,31,30,31,30,31)[$MM-1]);
		}
	return 1;
	}

sub GetYDAY {
	($MM,$DD,$YYYY) = @_;
	if (($YYYY % 4) == 0) {
		return ((0,31,60,91,121,152,182,213,244,274,305,335)[$MM] + $DD - 1);
		}
	else {
		return ((0,31,59,90,120,151,181,212,243,273,304,334)[$MM] + $DD - 1);
		}
	}

sub DateByNum {
# this is failing for YDAY sometimes.

	# accepts computer date, returns text string, yday.
	($MM, $DD, $YYYY) = @_;

	# test:
	# print "<!-- DateByNum $MM $DD $YYYY -->\n";

	$DD--;$DD++;
	if ($YYYY < 1000) {
		if ($YYYY < 50) {
			$YYYY += 2000;
			}
		else {
			$YYYY += 1900;
			}
		}
	$YDAY = &GetYDAY($MM,$DD,$YYYY);
	$DaysSince1970 = int(($YYYY-1970)*365.25) + $YDAY + 1;
	$WeekDay = $LongWeekDays[(localtime($DaysSince1970 * 86400))[6]];

	# test:
	# print "<!-- resolves to $WeekDay with YDAY as $YDAY -->\n";

	return ("$LongMonths[$MM] $DD, $YYYY", $YDAY);
	}

sub FormatDates {
($StartInput, $EndInput, $Recent, $SinceLast, $LastNumber) = @_;
($StartNumber, $StartString, $EndNumber, $EndString) = (0,'',0,'');
($MM,$DD,$YYYY) = (0,0,0);
MMDDYY: for ($StartInput) {
if ($_) {
	if (m!^\s*(\d{2,2})\D*(\d{2,2})\D*(\d{2,4})?!) {
		($MM,$DD,$YYYY) = ($1,$2,($3 ? $3 : $MyT[5]));
		last MMDDYY if &DateIsValid($MM,$DD,$YYYY);
		}
	if (m!^\s*(\d{1,2})\D+(\d{1,2})\D*(\d{2,4})?!) {
		($MM,$DD,$YYYY) = ($1,$2,($3?$3:$MyT[5]));
		last MMDDYY if &DateIsValid($MM,$DD,$YYYY);
		}
	LITERAL_MONTH: {
		if (m!^\s*(\D+)(\d{1,2})\D*(\d{2,4})?!) {
			($MonthString,$DD,$YYYY) = ($1,$2,($3?$3:$MyT[5]));
			}
		elsif (m!^\s*(\d{1,2})(\D*)(\d{2,4})?!) {
			($MonthString,$DD,$YYYY) = ($2,$1,($3?$3:$MyT[5]));
			}
		else {
			last LITERAL_MONTH;
			}
		for ($MM=1;$MM<=12;$MM++) {
			if ($MonthString =~ m!$ShortMonths[$MM-1]!i) {
				last MMDDYY if &DateIsValid($MM,$DD,$YYYY);
				last LITERAL_MONTH;
				}
			}
		}
	for $X (0..6) {
		if (m!$ShortWeekDays[$X]!i) {
			($MM,$DD,$YYYY) = (localtime(time-((7+$MyT[6]-$X)%7)*86400))[4,3,5];
			$MM++;
			last MMDDYY;
			}
		}
	for $X (0..2) {
		if (m!$ShortDayNames[$X]!i) {
			($MM,$DD,$YYYY) = (localtime(time+($X-1)*86400))[4,3,5];
			$MM++;
			last MMDDYY;
			}
		}
	}
if ($Recent) {
	($MM,$DD,$YYYY) = (localtime((time-86400)))[4,3,5];
	$MM++;
	last MMDDYY;
	}
} # End MMDDYY.

if ($MM && $DD && defined($YYYY)) {
	# kick INT mode, and correct for human->computer month indexing:
	$MM--;

	if ($YYYY < 1000) {
		# User is entering an abbreviated date.  Is it 01 for 2001, or 99 for 1999?
		if ($YYYY < 50) {
			$YYYY += 2000;
			}
		else {
			$YYYY += 1900;
			}
		}

	($StartString,$YDAY) = &DateByNum($MM,$DD,$YYYY);
	$StartNumber = ($YYYY * 1000) + $YDAY;
	}
elsif ($SinceLast) {
# or "if $StartInput existed maybe but didn't successfully match anything, and $Recent was not defined,
# but $SinceLast is...
	$StartNumber = $LastNumber;
	$YYYY = int($LastNumber/1000);
	$YDAY = $LastNumber % 1000;
	$DaysSince1970 = int(($YYYY-1970)*365.25) + $YDAY + 1;
	($DD,$MM,$YYYY,$WeekDay) = (localtime($DaysSince1970 * 86400))[3..6];
	$YYYY += 1900;
	$WeekDay = $LongWeekDays[$WeekDay];
	$StartString = "$WeekDay, $LongMonths[$MM] $DD, $YYYY";
	}

# Zero out:
($MM,$DD,$YYYY) = (0,0,0);
MMDDYY: for ($EndInput) {
if ($_) {
	if (m!^\s*(\d{2,2})\D*(\d{2,2})\D*(\d{2,4})?!) {
		($MM,$DD,$YYYY) = ($1,$2,($3?$3:$MyT[5]));
		last MMDDYY if &DateIsValid($MM,$DD,$YYYY);
		}
	if (m!^\s*(\d{1,2})\D+(\d{1,2})\D*(\d{2,4})?!) {
		($MM,$DD,$YYYY) = ($1,$2,($3?$3:$MyT[5]));
		last MMDDYY if &DateIsValid($MM,$DD,$YYYY);
		}
	LITERAL_MONTH: {
		if (m!^\s*(\D+)(\d{1,2})\D*(\d{2,4})?!) {
			($MonthString,$DD,$YYYY) = ($1,$2,($3?$3:$MyT[5]));
			}
		elsif (m!^\s*(\d{1,2})(\D*)(\d{2,4})?!) {
			($MonthString,$DD,$YYYY) = ($2,$1,($3?$3:$MyT[5]));
			}
		else {
			last LITERAL_MONTH;
			}
		for ($MM=1;$MM<=12;$MM++) {
			if ($MonthString =~ m!$ShortMonths[$MM-1]!i) {
				last MMDDYY if &DateIsValid($MM,$DD,$YYYY);
				last LITERAL_MONTH;
				}
			}
		}
	for $X (0..6) {
		if (m!$ShortWeekDays[$X]!i) {
			($MM,$DD,$YYYY) = (localtime(time-((7+$MyT[6]-$X)%7)*86400))[4,3,5];
			$MM++;
			last MMDDYY;
			}
		}
	for $X (0..2) {
		if (m!$ShortDayNames[$X]!i) {
			($MM,$DD,$YYYY) = (localtime(time+($X-1)*86400))[4,3,5];
			$MM++;
			last MMDDYY;
			}
		}
	}

if ($Recent || $SinceLast) {
	($MM,$DD,$YYYY) = (localtime(time))[4,3,5];
	$MM++;
	last MMDDYY;
	}
} # End MMDDYY.

if ($MM && $DD && defined($YYYY)) {
	# kick INT mode, and correct for human->computer month indexing:
	$MM--;

	if ($YYYY < 1000) {
		# User is entering an abbreviated date.  Is it 01 for 2001, or 99 for 1999?
		if ($YYYY < 50) {
			$YYYY += 2000;
			}
		else {
			$YYYY += 1900;
			}
		}

	($EndString,$YDAY) = &DateByNum($MM,$DD,$YYYY);
	unless ($Recent || $SinceLast) {
		$EndNumber = ($YYYY * 1000) + $YDAY;
		}
	}
return ($StartNumber, $StartString, $EndNumber, $EndString);
}


=item PrintDebugInfo()

This runs a filesystem test against $LogFile and dumps a ton of (hopefully) useful information to the screen.

=cut

sub PrintDebugInfo {
	my ($verbose) = @_;
	my $err = '';
	Err: {
		print "<P>Testing log file '$LogFile'...</P>\n";

		if (-e $LogFile) {
			print "<P>File exists.</P>\n";
			}
		else {
			print "<P>Warning: file does not exist.</P>\n";
			}

		if (open(FILE,">>$LogFile")) {
			binmode(FILE);
			close(FILE);
			print "<P><B>Success:</B> log file is writable.</P>\n";
			}
		else {
			print "<P><B>Error:</B> unable to write to the log file - $! - $^E.</P>\n";
			print "<P>Resolve this error by creating an empty file named '$LogFile' (if one doesn't already exist) and making it writable.</P>\n";
			}

		print "<P>Testing preferences file '$prefs'...</P>\n";

		if (-e $prefs) {
			print "<P>File exists.</P>\n";
			}
		else {
			print "<P>Warning: file does not exist.</P>\n";
			}

		if (open(FILE,">>$prefs")) {
			binmode(FILE);
			close(FILE);
			print "<P><B>Success:</B> prefs file is writable.</P>\n";
			}
		else {
			print "<P><B>Error:</B> unable to write to the prefs file - $! - $^E.</P>\n";
			print "<P>Resolve this error by creating an empty file named '$prefs' (if one doesn't already exist) and making it writable.</P>\n";
			}

		unless ($verbose) {
			print "<P>Vist the <A HREF=\"$ENV{'SCRIPT_NAME'}?debugme\">debug page</A> for more detailed information.</P>\n";
			last Err;
			}

print <<"EOM";

<P><B>AXS Debug Screen</B></P>

<P>This is one tool, of many, to help you out. Read the <A HREF="http://www.xav.com/scripts/axs/" TARGET="_blank">trouble-shooting guide</A> if you need more detailed assistance.</P>

<P><B>Standard Debugging Information:</B></P>

<TABLE BORDER=1>
<TR>
	<TD ALIGN=right><B>Script Version:</B></TD>
	<TD>$VERSION</TD>
</TR>
<TR>
	<TD ALIGN=right><B>Script file:</B></TD>
	<TD>$0</TD>
</TR>
<TR>
	<TD ALIGN=right><B>Perl version:</B></TD>
	<TD>$]</TD>
</TR>
<TR>
	<TD ALIGN=right><B>Operating system:</B></TD>
	<TD>$^O</TD>
</TR>
</TABLE>

<P><B>Environment Variables:</B></P>

<TABLE BORDER=1>
EOM

foreach (sort keys %ENV) {
	print "<TR><TD ALIGN=right><B>" . &html_encode($_) . ":</B></TD><TD>" . &html_encode(substr($ENV{$_},0,60)) . "</TD></TR>\n";
	}

print <<"EOM";
</TABLE>

<HR WIDTH="50%" SIZE=1>

<H5 ALIGN="center">Visit <A HREF="http://www.xav.com/scripts/axs/" TARGET="_blank">the AXS help page</A> for more information.  AXS is copyright 1997-2001 by Fluid Dynamics.</H5>

EOM
		last Err;
		}
	}



sub AddCommas {
	$_ = reverse shift;
	s!(\d{3,3})!$1,!g;
	$_ = reverse $_;
	s!^,!!o;
	return $_;
	}

=item check_regex

Usage:
	$err = &check_regex($pattern);

Checks against ?{} code-executing expressions.

Uses an eval wrapper to confirm that the expression is valid.

updated 2001-09-28

=cut

sub check_regex {
	my ($pattern) = @_;
	my $err = '';
	Err: {
		if ($pattern =~ m!\?\{!) {
			$err = 'query pattern "' . &html_encode($pattern) . '" contains illegal ?{} code-executing regular expression';
			next Err;
			}
		eval '"foo" =~ m!$pattern!;';
		if ($@) {
			$err = 'unable to evaluate pattern "' . &html_encode($pattern) . '" - ' . &html_encode($@);
			undef($@);
			next Err;
			}
		}
	return $err;
	}





=item WebFormL

Usage:
	&WebFormL( \%FORM );

Returns a by-reference hash of all name-value pairs submitted to the CGI script.

updated: 8/21/2001

Dependencies:
	&url_decode
	&query_env

=cut

sub WebFormL {
	my ($p_hash) = @_;
	my @Pairs = ();
	if ('POST' eq &query_env('REQUEST_METHOD')) {
		my $buffer = '';
		my $len = &query_env('CONTENT_LENGTH',0);
		read(STDIN, $buffer, $len);
		@Pairs = split(m!\&!, $buffer);
		}
	elsif (&query_env('QUERY_STRING')) {
		@Pairs = split(m!\&!, &query_env('QUERY_STRING'));
		}
	else {
		@Pairs = @ARGV;
		}
	local $_;
	foreach (@Pairs) {
		next unless (m!^(.*?)=(.*)$!s);
		my ($name, $value) = (&url_decode($1), &url_decode($2));
		if ($$p_hash{$name}) {
			$$p_hash{$name} .= ",$value";
			}
		else {
			$$p_hash{$name} = $value;
			}
		}
	}

sub url_decode {
	local $_ = defined($_[0]) ? $_[0] : '';
	tr!+! !;
	s!\%([a-fA-F0-9][a-fA-F0-9])!pack('C', hex($1))!eg;
	return $_;
	}



=item query_env

Usage:
	my $remote_host = &query_env('REMOTE_HOST');

Abstraction layer for the %ENV hash.  Why abstract?  Here's why:
 1. adds safety for -T taint checks
 2. always returns '' if undef; prevent -w warnings

=cut

sub query_env {
	my ($name,$default) = @_;
	if (($ENV{$name}) and ($ENV{$name} =~ m!^(.*)$!s)) {
		return $1;
		}
	elsif (defined($default)) {
		return $default;
		}
	else {
		return '';
		}
	}


=item Trim

Usage:

	my $word = &Trim("  word  \t\n");

Strips whitespace and line breaks from the beginning and end of the argument.

=cut

sub Trim {
	local $_ = defined($_[0]) ? $_[0] : '';
	s!^[\r\n\s]+!!o;
	s![\r\n\s]+$!!o;
	return $_;
	}





sub Assert {
	return if ($_[0]);
	my ($package, $file, $line) = caller();
	print "Content-Type: text/html\015\012\015\012";
	print "<HR><H1><PRE>Assertion Error:<BR>	Package: $package<BR>	File: $file<BR>	Line: $line</PRE></H1><HR>";
	}




=item SetDefaults

Usage:
	my $text = &SetDefaults( $html, \%params );

Takes $html, which is an HTML fragment including FORM elements, and sets all default attributes to match %params.

Requires strict format:

	<INPUT TYPE=radio NAME="name" VALUE="value">
	<INPUT TYPE=checkbox NAME="name" VALUE="value">
	<INPUT NAME="foo">
	<SELECT NAME="name".*?><OPTION VALUE="value"><OPTION VALUE="value"></SELECT>
	<INPUT TYPE=hidden NAME="name">
	<TEXTAREA NAME="foo">value</TEXTAREA>

Generally will accept double-quoted attributes, and unquoted attributes which don't contain any embedded space.

In the case of replacing "hidden"-type fields, will only insert new values for hidden form elements that do not already have a value.

This code will insert CHECKED and SELECTED attributes for the appropriate form elements, but will not overwrite existing CHECKED and SELECTED attributes.  The recommended way to formulate your input forms is to not use these explicit defaults.

The code will overwrite default VALUE="x" values for INPUT TEXT and INPUT PASSWORD and TEXTAREA.

Dependencies:
	&html_encode

=cut

sub SetDefaults {
	my ($text, $p_params) = @_;

	&Assert('HASH' eq ref($p_params));

	my @array = split(m!<(INPUT|SELECT|TEXTAREA)([^\>]+?)\>!is, $text);

	my $finaltext = $array[0];

	my $x = 1;
	for ($x = 1; $x < $#array; $x += 3) {

		my ($tag, $attribs, $trail) = (uc($array[$x]), $array[$x+1], $array[$x+2]);


		Tweak: {

			my $tag_name = '';
			if ($attribs =~ m! NAME\s*=\s*\"([^\"]+?)\"!is) {
				$tag_name = $1;
				}
			elsif ($attribs =~ m! NAME\s*=\s*(\S+)!is) {
				$tag_name = $1;
				}
			else {

				# we cannot modify what we do not understand:
				last Tweak;
				}

			# does the user have an over-ride value defined for this?
			last Tweak unless (defined($$p_params{$tag_name}));

			my $setval = &html_encode($$p_params{$tag_name});


			if ($tag eq 'INPUT') {

				# discover VALUE and TYPE
				my $type = 'TEXT';
				if ($attribs =~ m! TYPE\s*=\s*\"([^\"]+?)\"!is) {
					$type = uc($1);
					}
				elsif ($attribs =~ m! TYPE\s*=\s*(\S+)!is) {
					$type = uc($1);
					}

				# discover VALUE and TYPE
				my $value = '';
				if ($attribs =~ m! VALUE\s*=\s*\"([^\"]+?)\"!is) {
					$value = $1;
					}
				elsif ($attribs =~ m! VALUE\s*=\s*(\S+)!is) {
					$value = $1;
					}

				# we can only set values for known types:

				if (($type eq 'RADIO') or ($type eq 'CHECKBOX')) {

# this code does not overwriting existing explicit CHECKED attributes in INPUT tags
# we avoid this because it would be expensive to distinguish between CHECKED as an attribute and the literal CHECKED inside a VALUE="" or other attribute; we *could* do it, but it would be expensive, and since SetDefaults is only called on pre-formatted forms, we choose long-term efficiency

					# should this be checked?

					if ($setval eq $value) {
						$attribs = " CHECKED$attribs";
						}
					}
				elsif (($type eq 'TEXT') or ($type eq 'PASSWORD') or ($type eq 'HIDDEN')) {

					# but only hidden fields if value is null:

					last Tweak if (($type eq 'HIDDEN') and ($value ne ''));


					# replace any existing VALUE tag:
					my $qm_value = quotemeta($value);
					$attribs =~ s! VALUE\s*=\s*\"$qm_value\"! VALUE="$setval"!iso;
					$attribs =~ s! VALUE\s*=\s*$qm_value! VALUE="$setval"!iso;

					# add the tag if it's not present (i.e. if no VALUE was present in original tag)
					my $qm_setval = quotemeta($setval);
					unless ($attribs =~ m! VALUE="$qm_setval"!s) {
						$attribs = " VALUE=\"$setval\"$attribs";
						}

					}
				}
			elsif ($tag eq 'SELECT') {
# this code does not overwriting existing explicit SELECTED attributes in OPTION tags
# does not support <OPTION>value syntax, only <OPTION VALUE="value">value

				my $lc_set_value = lc($setval);

				my @frags = ();
				foreach (split(m!<OPTION !is, $trail)) {
					if (m!VALUE\s*=\s*\"(.*?)\"!is) {
						if ($lc_set_value eq lc($1)) {
							$_ = 'SELECTED ' . $_;
							}
						}
					elsif (m!VALUE\s*=\s*(\S+)!is) {
						if ($lc_set_value eq lc($1)) {
							$_ = 'SELECTED ' . $_;
							}
						}
					push(@frags, $_);
					}
				$trail = join('<OPTION ', @frags);
				}
			elsif ($tag eq 'TEXTAREA') {
				$trail =~ s!^.*?</TEXTAREA>!$setval</TEXTAREA>!osi;
				}
			last Tweak;
			}

		$finaltext .= "<$tag$attribs>$trail";
		}
	return $finaltext;
	}



=item url_encode

Usage:
	my $str_url = &url_encode($str);

Formats strings consistent with RFC 1945 by rewriting metacharacters in their
%HH format.

=cut

sub url_encode {
	local $_ = defined($_[0]) ? $_[0] : '';
	s!([^a-zA-Z0-9_.-])!uc(sprintf("%%%02x", ord($1)))!eg;
	return $_;
	}


END_OF_CODE

sub html_encode {
	local $_ = $_[0] || '';
	s!\&!\&amp;!g;
	s!\>!\&gt;!g;
	s!\<!\&lt;!g;
	s!\"!\&quot;!g;
	return $_;
	}


undef($@);
eval $all_code;
my $err = &html_encode($@); #typecast to str
if ($err) {
	print "Content-Type: text/html\015\012\015\012";
	print "<HR><P><B>Perl Execution Error</B> in $0:</P><BLOCKQUOTE><TT>$err</TT></BLOCKQUOTE>";
print <<"EOM";

<FORM METHOD="post" ACTION="http://www.xav.com/bug.pl">
<INPUT TYPE=hidden NAME="product" VALUE="axs">
<INPUT TYPE=hidden NAME="version" VALUE="$VERSION">
<INPUT TYPE=hidden NAME="Perl Version" VALUE="$]">
<INPUT TYPE=hidden NAME="Script Path" VALUE="$0">
<INPUT TYPE=hidden NAME="Perl Error" VALUE="$err">
EOM

my ($name, $value) = ();
while (($name, $value) = each %FORM) {
	print "<INPUT TYPE=hidden NAME=\"Form: $name\" VALUE=\"$value\">\n";
	}
print <<"EOM";

<P>Please report this error to the script author:</P>
<BLOCKQUOTE><INPUT TYPE="submit" VALUE="Report Error"></BLOCKQUOTE>
</FORM><HR>

EOM

	}
1;

