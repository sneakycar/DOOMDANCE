#!/usr/local/bin/perl
#
&readparse;
print "Content-type: text/html\n\n";
#
#********* BEGIN BODY******************** 

open(LOGFILE, "<jeffrey.log"); 
@entries = <LOGFILE>; 
close LOGFILE; 


print "<HTML><HEAD><link rel=\"stylesheet\" href=\"/global.css\"> </HEAD><TITLE>dead deaddeaddead dead</TITLE><BODY background=/img/404bg.gif bgcolor=white>\n"; 
print "<CENTER><TABLE WIDTH=55%\n";
foreach $line (@entries) { 
        @fields = split(/::/,$line); 

        print "$fields[0]<BR>$fields[1]\n";
	

}; 

print "</TABLE></BODY></HTML>\n";

#******** END BODY************************ 
#
# EACH VALUE IN THE HTML FORM WILL BE CONTAINED IN
# THE THE @VALUE ARRAY.
sub readparse {
read(STDIN,$user_string,$ENV{'CONTENT_LENGTH'});
if (length($ENV{'QUERY_STRING'})>0) {$user_string=$ENV{'QUERY_STRING'}};
$user_string =~ s/\+/ /g;
@name_value_pairs = split(/&/,$user_string);
foreach $name_value_pair (@name_value_pairs) {
        ($keyword,$value) = split(/=/,$name_value_pair);
        $value =~ s/%([a-fA-F0-1][a-fA-F0-1])/pack("C",hex($1))/ge;
        push(@value, "$value");
	  $user_data{$keyword} = $value;
	  if ($value=~/<!--\#exec/) {
		print "Content-type: text/html\n\nNo SSI permitted";
		exit;
	  };
};
};



#E-MAIL SUBROUTINE  
#ADD "&email(to,from,subject,text)" TO YOUR SCRIPT 
#REMEMBER TO BACKSLASH THE @ WHEN YOU ARE NOT USING IT IN AN ARRAY
#FOR EXAMPLE:
# $to='robyoung\@mediaone.net';  
# $from='foo\@company.com';
# $subject='Thank you for your inquiry';
# $text='Dear reader\n\nThank you for your recent inquiry.';
# &email($to,$from,$subject,$text);

sub email {
local($to,$from,$sub,$letter) = @_;
$to=~s/@/\@/;
$from=~s/@/\@/;
open(MAIL, "|/usr/lib/sendmail -t") || die
"Content-type: text/text\n\nCan't open /usr/lib/sendmail!";
print MAIL "To: $to\n";
print MAIL "From: $from\n";
print MAIL "Subject: $sub\n";
print MAIL "$letter\n";
return close(MAIL);
}