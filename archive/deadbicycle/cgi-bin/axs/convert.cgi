#!/usr/bin/perl -w
use strict;
my $VERSION = '2.3.0.0025';
my $usage = <<"EOM";

Usage:
	perl convert.pl axs-to-ncsa < infile > outfile

Will convert an AXS log on standard input (infile) into an NCSA Extended log in standard output (to outfile).

Usage:
	perl convert.pl -s:www.xav.com ncsa-to-axs < infile > outfile

Will convert an NCSA Extended log on standard input (infile) to an AXS log in standard output (to outfile).

Note that you have to use the "perl convert.pl" syntax instead of "convert.pl" on Windows in order for io redirection to work properly.

Errors will be written to STDERR.

Flags:

	-s:servername
	The hostname of the web server that generated the inputted NCSA log.  Defaults to www.xav.com

	-v	verbose output (line counts, etc., to STDOUT)
	-d	perform DNS lookups on unresolved addresses

Bugs:

Doesn't handle time zones well.
Any quotes in the raw AXS data will be stripped when writing to the NCSA format (like a quote in a URL)

Copyright 2001 by Zoltan Milosevic

EOM

my $TimeOffsetInHours = 0;

my @mon = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

my $servername = 'www.xav.com';

my %timecache = ();

local $_;

my $err = '';
Err: {

	if ($ENV{'SERVER_SOFTWARE'}) {
		print "Content-Type: text/html\n\n";
		print "This script can only be called from the command line, not the web.";
		last Err;
		}

	my %dns_cache = (); # ip => hostname

	my $b_verbose = 0;
	my $b_dns = 0;
	my $direction = 0;
	foreach (@ARGV) {
		if (m!^-v$!) { $b_verbose = 1 }
		if (m!^-d$!) { $b_dns = 1 }
		if (m!^axs-to-ncsa$!) { $direction = 1 }
		if (m!^ncsa-to-axs$!) { $direction = 2 }
		if (m!^-s:(.*)$!) { $servername = $1 }
		}

	if ($b_verbose) {
		print STDERR "Using verbose output\n";
		}
	if ($b_dns) {
		print STDERR "Performing DNS lookups\n";
		}
	unless ($direction) {
		print STDERR $usage;
		last Err;
		}

	if ($direction == 2) {

		# NCSA log converted to AXS format


		my $linenum = 0;
		while (defined($_ = <STDIN>)) {
			$linenum++;

			if ((0 == ($linenum % 100)) and ($b_verbose)) {
				print STDERR "Handled $linenum entries.\n";
				}


			unless (m!^([^\s]+) - \S+ \[(.*?)\] "(.*?)" (\d+) (-|\d+) "(.*?)" "(.*?)"\r?$!) {
				print STDERR "Input line $linenum '" . substr(&Trim($_), 0, 40) . "' does not pattern match to NCSA Extended format.\n";
				next;
				}


			my ($ip, $strDateTime, $rq_str, $status_code, $bandwidth, $ref, $browser) = ($1, $2, $3, $4, $5, $6, $7);

			my ($verb, $uri) = ('', '');
			if ($rq_str =~ m!^(\S+) (\S+)!) {
				($verb, $uri) = ($1, $2);
				}


			$bandwidth = 0 if ($bandwidth eq '-');


			my $hostname = $ip;
			if ($b_dns) {
				# Resolve the hostname:

				if ($dns_cache{$ip}) {
					$hostname = $dns_cache{$ip};
					}
				elsif ($ip =~ m!^(\d+)\.(\d+)\.(\d+)\.(\d+)$!) {
					my $key = pack('C4', $1, $2, $3, $4);
					$hostname = (gethostbyaddr($key,2))[0];
					unless ($hostname) {
						$hostname = $ip;
						}
					$dns_cache{$ip} = $hostname; # cache both pos and neg responses
					}
				}

			# convert time:

			my $time = 0;
			if ($strDateTime =~ m!^(\d+)/(\w+)/(\d+):(\d+)\:(\d+)\:(\d+) -\d\d\d\d$!) {
				my ($mon_str, $mday, $yyyy, $hh, $mm, $ss) = (lc($2), $1, $3, $4, $5, $6);
				$time = &timelocal($ss,$mm, $hh, $mday, $mon_str, $yyyy, \%timecache);
				}
			unless ($time) {
				$err = "unable to parse time string '$strDateTime'";
				next Err;
				}



			#152.163.189.131 - - [02/Feb/2000:00:01:36 -0500] "GET /tori/patrickb.html HTTP/1.0" 200 697


			my $local = 'http://' . $servername . $uri;
			$ref = $local if ($ref eq '-');


			print "|$hostname|$ip|$ref|$local|$browser|";


			foreach ((localtime($time + (3600 * $TimeOffsetInHours)))[0..7]) {
				print $_.'|';
				}
			print "\n";
			}

		# 152.163.189.131 - - [02/Feb/2000:00:01:36 -0500] "GET /tori/patrickb.html HTTP/1.0" 200 697
		# |d8-34.dyn.telerama.com|205.201.40.98|http://cgi.resourceindex.com/Programs_and_Scripts/Perl/Logging_Accesses_a
		#nd_Statistics/|http://www.xav.com/scripts/axs/index.html|
		#Mozilla/4.0 (compatible; MSIE 4.01; MSN 2.5; Windows 98)
		##|9|31|15|21|0|100|5|20|


		}
	else {


		# AXS log converted to NCSA format


		my $linenum = 0;
		while (defined($_ = <STDIN>)) {
			$linenum++;

			if ((0 == ($linenum % 100)) and ($b_verbose)) {
				print STDERR "Handled $linenum entries.\n";
				}


			my @Fields = split(m!\|!, $_);

			unless ($#Fields > 8) {
				print STDERR "Input line $linenum '" . substr(&Trim($_), 0, 40) . "' does not pattern match to the AXS log format.\n";
				next;
				}

			my $x = 0;
			for $x (6..11) {
				if (not defined($Fields[$x])) {
					$err = "field $x not defined";
					next Err;
					}
				}

			my $time = &timelocal($Fields[6], $Fields[7], $Fields[8], $Fields[9], $Fields[10], $Fields[11] + 1900, \%timecache);
			unless ($time) {
				$err = "unable to parse time string";
				next Err;
				}

			for (6,7,8,9) {
				$Fields[$_] = '0' . $Fields[$_] if (1 == length($Fields[$_]));
				}
			$Fields[11] += 1900;
			my $datetime = "$Fields[9]/$mon[$Fields[10]]/$Fields[11]:$Fields[8]:$Fields[7]:$Fields[6] +0000";

			my $uri = '/';
			if ($Fields[4] =~ m!://([^/]+)/(.*)$!) {
				$uri = "/$2";
				}
			else {
				print STDERR "Unable to parse AXS log line $linenum\n";
				next;
				}


			$uri =~ s!\"!!sg;
			$Fields[3] =~ s!\"!!sg;
			$Fields[4] =~ s!\"!!sg;

			print "$Fields[2] - - [$datetime] \"GET $uri HTTP/1.1\" 200 911 \"$Fields[3]\" \"$Fields[5]\"\015\012";

			}



		}

	last Err;
	}
continue {
	print STDERR "Error: $err.\n";
	}




=item timegm

Usage:
	my %timecache = ();
	$time = &timelocal($sec,$min,$hours,$mday,$mon,$year,\%timecache);
	$time = &timegm($sec,$min,$hours,$mday,$mon,$year,\%timecache);

Arguments:
	$mday is human time, i.e. 1..31
	$mon is computer time, i.e. 0..11
	$mon can be a text string like "JUN" or "JUL"
	$year should be 4-digit; if less than 999, some sort of algorithm will force a 4-digit year.

These routines were taken from the Time::Local module.

They have been extracted into small functions so that they can be safely called from platforms that due not have the Time::Local modules install. Also, the error handling has been changed so that it never croaks (what were they smoking when they designed it that way?). Caching has been cleaned up and made optional.

Error Handling:
	Will return 0 if unable to handle the input values.
	Will return 0 if out-of-band year (less than 1970 or more than 2037)
	All other range checking has been removed.

Dependencies:

	Called by: process_text
	Called by: timelocal
	Called by: webrequest

	Global: none

	Dependency: basetime - 1

	Required library: ../../searchmods/common_parse_page.pl

=cut

sub timegm {
	my ($sec, $min, $hours, $mday, $month, $year, $p_timecache) = @_;

	if ($month =~ m!\D!) {
		my $n = 0;
		$month = lc($month);
		foreach ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec') {
			last if ($month eq $_);
			$n++;
			}
		$month = $n % 12;
		}

	if ($year < 100) {

		# Handle two-digit years:

		# since our effective range is only 1970 to 2037, necessity dictates the following:

		if ($year > 70) {
			$year += 1900;
			}
		else {
			$year += 2000;
			}

		}



	if (($year < 1970) or ($year > 2037)) {
		return 0;
		}

	# convert back to base-1900 to prevent overflows:
	$year -= 1900;

	my $base_time_at_mon_year = &basetime($month, $year, $p_timecache);


	if ($base_time_at_mon_year == -1) {
		return 0;
		}

	return ($base_time_at_mon_year) + ($sec) + ($min * 60) + (3600 * $hours) + (86400 * ($mday - 1));
	}


=item timelocal



Dependencies:

	Called by: migrate_log

	Global: none

	Dependency: timegm - 1

	Required library: ../../searchmods/common_parse_page.pl

=cut

sub timelocal {
	my $gtime = &timegm(@_);
	return 0 unless ($gtime);

	# Calculate seconds offset between localtime and gmtime

	my $testtime = $gtime;

	# If we're anywhere near a year boundary, shift up by a day or two:
	my $yday = (gmtime($testtime))[7];
	if (($yday < 2) or ($yday > 360)) {
		$testtime += 86400 * 15;
		}
	my @lt = localtime($testtime);
	my @gt = gmtime($testtime);
	my $offset = ($lt[0] - $gt[0]) + 60 * ($lt[1] - $gt[1]) + 3600 * ($lt[2] - $gt[2]) + 86400 * ($lt[7] - $gt[7]);

	my $ltime = $gtime - $offset;

	# kludge kludge kludge... I hate this ... this is a +/- 1 search pattern in case our response doesn't agree with what they input. this corrects for some weird crazyness surrounding gmtime vs localtime while daylight savings time is propagating between them.
	if ((localtime($ltime))[2] != $_[2]) {
		$ltime -= 3600;
		}
	if ((localtime($ltime))[2] != $_[2]) {
		$ltime += 2 * 3600;
		}
	return $ltime;
	}


=item basetime



Dependencies:

	Called by: timegm

	Global: none

	Dependency: none

=cut

sub basetime {
	my ($month, $year, $p_timecache) = @_;

	my $time = -1;

	Err: {

		if (($p_timecache) and ('HASH' eq ref($p_timecache))) {
			my $key = pack('LC', $year, $month);
			last Err if ($time = $$p_timecache{$key});
			}

		my $guess_time = time();

		my ($guess_month, $guess_year) = (gmtime($guess_time))[4,5];

		my $yeardiff = $guess_year - $year;
		my $mondiff = $guess_month - $month;

		$guess_time -= (366 * 86400) * $yeardiff;
		$guess_time -= (31 * 86400) * (1 + $mondiff);
		$guess_time = 0 if ($guess_time < 0);

		# Okay, no $guess_time should lie sometime before the start of $month/$year. We took that extra month just in case.

		# Now step forward by 25-day increments until $guess_time returns a matching $month/year
		while (1) {
			($guess_month, $guess_year) = (gmtime($guess_time))[4,5];
			last Err unless (defined($guess_month));
			last Err unless (defined($guess_year));
			last if (($guess_month == $month) and ($guess_year == $year));
			$guess_time += 25 * 86400;
			last Err if ($guess_year > $year);
			}

		# Take $guess_time down to the time the month/year started:
		my ($sec, $min, $hour, $mday) = gmtime($guess_time);
		$guess_time -= ( $sec + 60 * $min + 3600 * $hour + 86400 * ($mday - 1) );

		if (($p_timecache) and ('HASH' eq ref($p_timecache))) {
			my $key = pack('LC', $year, $month);
			$$p_timecache{$key} = $guess_time;
			}
		$time = $guess_time;
		}
	return $time;
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

