#!/usr/bin/perl --
use strict;

=item overview

AXS Script Set, Logging Module
Copyright 1997-2001 by Fluid Dynamics

Please adhere to the copyright notice and conditions of use as described at the URL below.  For latest version and help files, visit:
	http://www.xav.com/scripts/axs/

=cut

my $VERSION = '2.3.0.0025';

# Enter the location of your log file relative to this script.  This is path
# and file name, not a web address.  Leave as-is for a default install.

my $LogFile = 'log.txt';

# Logging can be disabled after the log exceeds a certain size.  To use this
# feature, enter a non-zero number for the maximum byte size for your log
# file.  Leave it at zero to always log, without size restriction.

my $MaxLogSize = 0;

# This script will not log visits from users with hostnames or IP addresses
# listed below.  Use all lowercase names.  Empty the array to log everyone:

my @IgnoreHosts = ();

# Example:
#
# @IgnoreHosts = ('.foobar.org', 'host.example.co.uk', '250.245.240.');

# This maps hostnames to a consistent format; for example, if your site can
# be addressed as http://xav.com/ and http://www.xav.com/ then this set of
# mappings can convert all URL's to a consistent format.
#
# Format is:
#	Original-String, Final-String,
#
# The To and From web addresses will have a find-and-replace operation done
# on them with each name-value pair in the %Maps hash.  The operation will be
# done as a case insensitive substring match.

my %Maps = (
	'http://xav.com/'     => 'http://www.xav.com/',
	'http://ftp.xav.com/' => 'http://www.xav.com/',
	);

# Once the script is working to your satisfaction, set the $AllowDebug
# variable to zero:

my $AllowDebug = 1;


# When this is set to 1, ax.pl will perform DNS lookups on unresolved
# visitors (i.e., "140.140.58.1" becomes "anaconda.brooks.af.mil").  DNS
# resolution is a sometimes slow and time-consuming process, and you can
# improve speed by setting this to 0.

my $resolve_dns_names = 1;

# __________________________________________________________________
#
# The following shouldn't need to be changed:

my $domain = 'http://' . &query_env('SERVER_NAME','localhost');

# If your webserver doesn't support SERVER_NAME, then set this variable
# as the top-level URL to your server without a trailing slash, e.g.:
#
#	my $domain = 'http://www.xav.com';
#

my $header = "Content-type: text/html\015\012\015\012";

# This should be deleted if the content-type header is being echoed out
# to your SSI output, otherwise leave as is.


# The above variable allows you to correct for a different time zone if
# your ISP is somewhere else.  This is an integer of +/- a certain number
# of hours.  i.e., ISP is in Pennsylvania and owner is in Seattle:
#	$TimeOffsetInHours = -3;
# ISP in Australia, owner in London:
#	$TimeOffsetInHours = +12;

my $TimeOffsetInHours = 0;

# If you use image redirects and the image appears broken, you may enter the
# path to a real 1x1 pixel transparent GIF image in the $TransURL variable.
# This real image will be used by ax.pl instead of a synthetic one if this
# variable is set (meaning you will have to remove the # comment in front of
# it as well):
#
####	my $TransURL = 'http://www.deadbicycle.com/img/tm.gif';
my $TransURL = '';


# If every visitor is being logged twice, try setting the following variable
# to 1:

my $NoLogHead = 0;

# ___________________________________________________________________________


my $IIS = (&query_env('SERVER_SOFTWARE') =~ m!iis!i) ? 1 : 0;

my %FORM = ();
&WebFormL(\%FORM);

my $Export = 0;

# $mode is one of:
#
#	ssi => server-side include call; no output
#	redir => redirect visitor to the URL given in nexturl
#	img => return a 1x1 pixel transparent gif
#	debug => returns debug print

	my $mode = $FORM{'mode'} || '';


	# $ref is the full URL of the referring file.  If not given, will query HTTP_REFERER

	my $ref = $FORM{'ref'} || $ENV{'HTTP_REFERER'} || '';


	# $to is the full URL of the file being visited.  If not given, will be pulled from various environment variables

	my $to = $FORM{'to'} || '';
	if ($mode eq 'img') {
		$to = &query_env('HTTP_REFERER');
		}


	my $nexturl = $FORM{'nexturl'} || '';


	my $qs = &query_env('QUERY_STRING');


	if (($mode ne 'img') and ($mode ne 'redir')) {

		# rev-compat code for auto-detecting mode. also used by modern mode=ssi for auto-detecting $to


		# SSI call:

		if ($ENV{'DOCUMENT_URI'}) {
			$mode = 'ssi' unless ($mode);
			$to = $domain . $ENV{'DOCUMENT_URI'} unless ($to);
			}

		# Alternate SSI call (via REQUEST_URI not DOCUMENT_URI)

		elsif ($ENV{'REQUEST_URI'} and ($qs eq '')) {
			$mode = 'ssi' unless ($mode);
			$to = $domain . $ENV{'REQUEST_URI'} unless ($to);
			}

		# Alt SSI call on Windows/IIS

		elsif (($IIS) and ($ENV{'PATH_INFO'} ne $ENV{'SCRIPT_NAME'})) {
			$mode = 'ssi' unless ($mode);
			$to = $domain . $ENV{'SCRIPT_NAME'} unless ($to);
			}


		# trans image logging:

		elsif ($qs =~ m!^(\w+)\.gif(\&ref=)?(.*)$!i) {
			$mode = 'img' unless ($mode);
			$ref = $3 if ($3);
			$to = &query_env('HTTP_REFERER');
			}


		# redirect

		elsif (($qs) and ($qs ne 'debugme')) {
			$mode = 'redir' unless ($mode);
			$nexturl = $qs unless ($nexturl);
			$Export = 1;
			}
		elsif (($AllowDebug) and (lc($qs) eq 'debugme')) {
			$mode = 'debug';
			}
		}

	if ($mode eq 'redir') {
		$to = $nexturl;
		}


	# provide output the user first, independent of logging action:

	if ($mode eq 'ssi') {
		print "$header\n \n";
		}
	elsif ($mode eq 'img') {
		&Print_Image;
		}
	elsif ($mode eq 'redir') {
		print "HTTP/1.0 302 Moved\015\012" if ($IIS);
		print "Location: $nexturl\015\012\015\012";
		}
	elsif ($mode eq 'debug') {
		&SpawnDebugger;
		}
	else {
		# we should never get here, this is just a valid HTTP response
		# in case of mis-configuration or whatever:
		print "HTTP/1.0 200 OK\015\012" if ($IIS);
		print $header;
		print "<P>$0 - working okay - no logging command received - use ?debugme query string for more info.</P>";
		}







	# decide whether or not to log this visit:

	my $err = '';
	Err: {

		last Err if ($mode eq 'debug');

		last Err if (&query_env('HTTP_COOKIE') =~ m!axs_no_log=1!);

		last Err if (($NoLogHead) and (&query_env('REQUEST_METHOD') eq 'HEAD'));

		my ($vhost, $vaddr) = &resolve_host($resolve_dns_names);
		my $ighost = '';
		foreach $ighost (@IgnoreHosts) {
			$ighost = quotemeta($ighost);
			next unless ($ighost);
			last Err if ($vhost =~ m!$ighost!);
			last Err if ($vaddr =~ m!$ighost!);
			}

		# Note: you can filter on other things as well.  If you want to ignore people
		# arriving from a certain site, like Yahoo, you can write the following (note
		# that HTTP_REFERER is used instead of REMOTE_HOST):
		#
		#	@ignore = ('yahoo.com', 'av.yahoo.com');
		#	foreach (@ignore) {
		#		exit if ($ENV{'HTTP_REFERER'} =~ m!$_!);
		#		}



		if (($0 =~ m!^(.*)(\\|/)!) and ($0 !~ m!safeperl\d*!i)) {
			last Err unless (chdir($1));
			}



		# don't fill up the file system:

		my $LogSize = -s $LogFile || 0;
		last Err if (($MaxLogSize) and ($MaxLogSize < $LogSize));



		# cleanse the data:

		my ($clean_url, $host, $port, $path, $is_valid) = &parse_url($ref);
		if ($is_valid) {
			$ref = $clean_url;
			}

		($clean_url, $host, $port, $path, $is_valid) = &parse_url($to);
		if ($is_valid) {
			$to = $clean_url;
			}

		# Apply the mappings:
		foreach (keys %Maps) {
			$to =~ s!$_!$Maps{$_}!ig;
			$ref =~ s!$_!$Maps{$_}!ig;
			}

		&log_visit($vhost,$vaddr,$ref,$to);

		last Err;
		}





























sub Print_Image {
	print "HTTP/1.0 200 OK\015\012" if ($IIS);
	print "Pragma: no-cache\015\012";
	print "Expires: Saturday, February 15, 1997 10:10:10 GMT\015\012";
	if ($TransURL) {
		print "Location: $TransURL\015\012\015\012";
		}
	else {
		print "Content-Type: image/gif\015\012\015\012";
		binmode(STDOUT);
		foreach (71,73,70,56,57,97,1,0,1,0,128,255,0,192,192,192,0,0,0,33,249,4,1,0,0,0,0,44,0,0,0,0,1,0,1,0,0,1,1,50,0,59) {
			print pack('C',$_);
			}
		}
	}

# ___________________________________________________________________________

# This runs a filesystem test against $LogFile and dumps a ton of (hopefully)
# useful information to the screen:

sub SpawnDebugger {
	print "HTTP/1.0 200 OK\015\012" if ($IIS);
	print "Content-Type: text/html\015\012\015\012";

	unless ($AllowDebug) {
		print 'No debug output available because $AllowDebug = 0';
		return 0;
		}


print <<"EOM";

<HTML>
<HEAD>
	<TITLE></TITLE>
	<META NAME="robots" CONTENT="none">
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
</HEAD>
<BODY>

<DL>
<DT><B>Usage Instructions:</B></DT>
<DD>

	<P>These instructions apply <I>only</I> if your file system test passes (see below).</P>

	<OL>


		<LI>
			<P>Add the "AXS tracking code" to any HTML pages that you want to have tracked.</P>
			<PRE>\t&lt;SCRIPT LANGUAGE="JavaScript"&gt;
\t&lt;!--
\t\tdocument.write("&lt;IMG SRC=\\"$ENV{'SCRIPT_NAME'}?trans.gif&ref=");
\t\tdocument.write(document.referrer);
\t\tdocument.write("\\" HEIGHT=1 WIDTH=1&gt;");
\t// -->
\t&lt;/SCRIPT&gt;&lt;NOSCRIPT&gt;
\t\t&lt;IMG SRC="$ENV{'SCRIPT_NAME'}?trans.gif" HEIGHT="1" WIDTH="1"&gt;
\t&lt;/NOSCRIPT&gt;
</PRE>


			<P>If your web server supports server-side includes (SSI), then you can try this alternate syntax. You might have to name the pages with a <TT>.shtml</TT> or <TT>.stm</TT> extension in order for this to work. If this syntax doesn't work, just use the Javascript code above:</P>
			<PRE>\t&lt;!--#exec cgi="$ENV{'SCRIPT_NAME'}" --&gt;</PRE>

		<LI>
			<P>Code your <I>off-site</I> links like this (links to pages/files that don't already contain the AXS tracking code):</P>

			<PRE>\t&lt;A HREF="$ENV{'SCRIPT_NAME'}?http://yahoo.com/"&gt;http://yahoo.com/&lt;/A&gt;</PRE>

			<P>Here is an <A HREF="$ENV{'SCRIPT_NAME'}?http://www.yahoo.com/" TARGET=_blank>example link</A>.</P>

	</OL>

<DT><B>Standard Debugging Information:</B></DT>
<DD>
<P>This is AXS Logging Module version $VERSION in debug mode.<BR>
The file name of this script is <TT>$0</TT>.<BR>
This script is executing under Perl version $].<BR>
The critical file system variable is <TT>\$LogFile = "$LogFile";</TT>.
EOM
if ($MaxLogSize) {
	print "MaxLogSize has been initialized to $MaxLogSize bytes.";
	}
else {
	print 'MaxLogSize is not set.';
	}
print <<"EOM";
</P></DD>

<DT><B>Filesystem Test:</B></DT>
<DD>
EOM

TEST: {

if (-e $LogFile) {
	my ($LogSize,$LastModT) = (stat($LogFile))[7,9];
	$LastModT = scalar localtime($LastModT);
	print "<P>The log file, <TT>$LogFile</TT>, exists with size $LogSize bytes. It was last modified at $LastModT. ";
	if (open(FILE,">>$LogFile")) {
		binmode(FILE);
		close(FILE);
		print "The log file is writable. <FONT COLOR=\"#008811\"><B>The filesystem test passed!</B></FONT></P>";
		}
	else {
print <<"EOM";
However, the log file is not writable. The filesystem returned <TT>"$!"</TT>
when this script tried to write to it. You need to change the file
permissions to make it script writable. <FONT COLOR="#ff0000"><B>The filesystem test failed.</B></FONT></P>
EOM
		last TEST;
		}
	}
elsif (open(FILE,">>$LogFile")) {
	binmode(FILE);
	close(FILE);
print <<"EOM";
<P>The log file, <TT>$LogFile</TT>, did not exist when this script started.
However, this script attempted to create it for you, and the server
responded that this was successful. So everything <I>should</I> be fine now.
Reload this web page, and hopefully you'll see a message that the file system
test has passed. If it doesn't pass, and instead you get an error or you get
this message again, then you'll have to manually create the log file and
set it's permissions. <FONT COLOR="#ff0000"><B>The filesystem test needs to be run again.</B></FONT></P>
EOM
	last TEST;
	}
else {
print <<"EOM";
<P>The log file, <TT>$LogFile</TT>, doesn't exist. You need to create one and
give it writable permissions. Alternately, the log file may exist but the
<TT>\$LogFile</TT> variable might not point to the correct location, in which
case you will need to change your variable. <FONT COLOR="#ff0000"><B>The filesystem test
failed.</B></FONT></P>
EOM
	last TEST;
	}
print <<"EOM";
</DD>
EOM
	} # End of block TEST
print '</DD><DT><B>Environment Variables:</B></DT><DD><PRE>';
foreach (sort keys %ENV) {
	print "$_: $ENV{$_}\n";
	}
print <<"FOOT";

</PRE></DD></DL>

	<!--#echo banner=""-->

<CENTER>


</CENTER>

</BODY>
</HTML>


FOOT
} # End SpawnDebugger.



sub Trim {
	local $_ = $_[0] ? $_[0] : '';
	s!^[\r\n\s]+!!o;
	s![\r\n\s]+$!!o;
	return $_;
	}



sub clean_path {
	local $_ = $_[0] || '';

	# trim whitespace:
	$_ = Trim($_);

	# strip pound signs and all that follows (links internal to a page)
	s!\#.*$!!;

	# map "/./" to "/"
	s!/+\./+!/!g;

	# map trailing "/." to "/"
	s!/+\.$!/!g;

	# map "/folder/../" => "/"
	while (s!([^/]+)/+\.\./+!/!) {}

	# map /../foo => /foo
	while (s!^/+\.\./+!/!) {}

	s!^/+\.\.$!/!;

	# collapse back-to-back slashes:
	s!/+!/!g;

	return $_;
	}


sub parse_url {
	local $_ = $_[0] || '';
	my ($clean_url, $host, $port, $path, $is_valid) = ('', '', 80, '/', 0);

	# add trailing slash if none present
	$_ .= '/' if (m!^http://([^/]+)$!i);

	if (m!^http://([\w|\.|\-]+)\:?(\d*)/(.*)$!i) {
		($host, $port, $path, $is_valid) = (lc($1), $2, clean_path("/$3"), 1);
		$port = 80 unless $port;
		if ($port == 80) {
			$clean_url = "http://$host$path";
			}
		else {
			$clean_url = "http://$host:$port$path";
			}
		}
	return ($clean_url, $host, $port, $path, $is_valid);
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
	if (&query_env('QUERY_STRING')) {
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



=item resolve_host

Usage:
	my ($host,$addr) = &resolve_host($resolve_dns_names);

Returns either the FQDN and IP address of the visitor, based on the variables $ENV{'REMOTE_HOST'}, $ENV{'REMOTE_ADDR'}, and $resolve_dns_names.

=cut

sub resolve_host {
	my ($resolve_dns_names) = @_;

	# This code converts un-resolved hostnames to their text versions, then makes
	# the names lowercase, and then aborts logging if this hostname is forbidden:

	my ($host, $addr) = (&query_env('REMOTE_HOST'), &query_env('REMOTE_ADDR'));
	if (($host eq '') or ($host =~ m!^\d+\.\d+\.\d+\.\d+$!)) {
		if (($resolve_dns_names) and ($addr =~ m!^(\d+)\.(\d+)\.(\d+)\.(\d+)$!)) {
			$host = (gethostbyaddr(pack('C4',$1,$2,$3,$4),2))[0];
			}
		}
	$host = lc($host) || $addr;
	return ($host,$addr);
	}




sub log_visit {
	my ($host,$addr,$ref,$to) = @_;
	my $logline = '|';
	foreach ($host,$addr,$ref,$to,&query_env('HTTP_USER_AGENT')) {
		# strip delimiters:
		s!\||\015|\012!!sg;
		$logline .= $_.'|';
		}
	foreach ((localtime(time + (3600*$TimeOffsetInHours)))[0..7]) {
		$logline .= $_.'|';
		}
	$logline .= 'export|' if ($Export);
	$logline .= "\n";
	# Make sure the record is strictly valid before writing to the log:
	exit unless ($logline =~ m!^\|([^\|]+)\|([^\|]+)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|\d+\|(export\|)?$!);
	if (open(LOG,">>$LogFile")) {
		binmode(LOG);
		print LOG $logline;
		close(LOG);
		}
	}


1;

