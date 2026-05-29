#!/usr/bin/perl





#











########### YOU MUST CHANGE THE FOLLOWING ##########











$name_list = "dead";





	# THE NAME OF YOUR MAILING LIST











$your_email = "gerald\@deadbicyle.com";





	# YOUR EMAIL ADDRESS





	# don't forget the \ before @











$your_name = "dead gerald";





	# YOUR NAME 





	# Will show up in the from field 





	# of all emails sent





	





$name_url ="http://www.deadbicyle.com";





	#THE URL OF YOUR SITE











$name_home = "//DEAD.BICYCLE(S)";





	#YOUR COMPANY OR SITE NAME





	





$mail_prog = "/usr/sbin/sendmail";





     	# PATH TO MAILER PROGRAM:





     	# This has to point to your sendmail program. If your server does not





     	# have sendmail, you may need to modify the open(MAIL,"|$mailprog -t");





     	# lines in all of the scripts to support whatever format your server





     	# email system requires. If you are not sure, ask your server 





     	# administrator. If you have a virtual domain with your own root 





     	# directory, look in the /usr/sbin ,  /usr/lib, /usr/bin, and similar





     	# directories, for a program named sendmail. If it does not exist, 





     	# ask your server admin what is the correct calling method. This is a





     	# server dependent problem, and we at Solution Scripts cannot help you with 





     	# this. If you have other working scripts that send email, look at 





     	# them for clues.











$remove_link = 1;





	# This will put a link at the bottom of all emails sent out, where a user can click on





	# to automatically be removed from your mailing list. Set to 1 for on, 0 for off.

















###################################





## ADVANCED CONFIGURATION ##





###################################

















	## COLOR OPTIONS ##





	# The following five variables allow you to customize the look of Power List





	# by changing the colors of the table backgrounds and the text throughout the 





	# Script. Simply enter the color desired, either by name or its hex number





	# ie: "white" or "#FFFFFF"





	





$table_head_bg = "#ffcc00";





	# Background color of the small header row of the table





	





$table_head_text = "#666600";





	# Color of the text in the table header











$table_body_bg = "#ffcc00";





	# Background color of the main body of the table





	





$table_body_text = "#666600";





	# Color of the text in the body of the table











$body_tag = qq~





	<BODY BACKGROUND="/img/404bg.gif" BGCOLOR="ffffff" TEXT="ffffff" link="#669900" vlink="#669900" active="#669900">





~;





	# Body tag used throughout the program. Change the body tag to however





	# you like.

















$data_path = "";





	# (OPTIONAL)





	# Directory path to where you want the two data files stored.





	# EXAMPLE - $data_path = "/home/httpd/html/powerlist";





	





$address_file = "";





	# (OPTIONAL)





	# Name of file where email addresses are stored.





	# If left blank, address.txt is used.





	# EXAMPLE - $address_file = "emailsaddrs.txt";





























##############################################################################





# CHANGE NO MORE











$version = "1.5";











$thisurl = $ENV{'SCRIPT_NAME'};





$mail_url = $ENV{'SERVER_NAME'};











$address_file = "address.txt" unless $address_file;





$pwd_file = "lester.txt" unless $pwd_file;











$address_file = "$data_path/$address_file" if $data_path;





$pwd_file = "$data_path/$pwd_file" if $data_path;





 











read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});





@pairs = split(/&/, $buffer);





foreach $pair (@pairs) {





	($name, $value) = split(/=/, $pair);





	$value =~ tr/+/ /;





	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;





	if ($INPUT{$name}) { $INPUT{$name} = $INPUT{$name}.",".$value; }





	else { $INPUT{$name} = $value; }





}











unless ($INPUT{'email'}) { 





	print "Content-type: text/html \n\n";





	&Top;





}











$temp=0;





$temp=$ENV{'QUERY_STRING'};





if ($temp) {





	$INPUT{'address'} = $temp;





	&remove;





}











if ($INPUT{'email'}) { &email; }





elsif ($INPUT{'action'} eq "subscribe") { &subscribe; }





elsif ($INPUT{'action'} eq "remove") { &remove; }





elsif ($INPUT{'newpass'}) { &newpass; }





elsif ($INPUT{'delete_select'}) { &delete_select; }





elsif ($INPUT{'delete_final'}) { &delete_final; }





elsif ($INPUT{'sendemail'}) { &sendemail; }





elsif ($INPUT{'address'}) { &subscribe; }





else { &admin; }





exit;











########### MAIN ADMIN SCREEN ##########





sub admin {











open (PASSWORD, "$pwd_file");





$password = <PASSWORD>;





close (PASSWORD);





chop ($password) if ($password =~ /\n$/);











if (!$password) {





	print qq~





	<table cellspacing=0 border=0 cellpadding =5 width=500>





	<TR bgcolor="$table_head_bg"><TD>





	<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Set Admin Password





	</B></FONT>





	</TD></TR>





	<TR bgcolor="$table_body_bg">





	<TD>





	<BR>





	<FONT SIZE="-1" FACE="Arial" color="$table_body_text">





	Make Password:





	</font>





	<FORM METHOD=POST ACTION=$thisurl>





	<CENTER>





	<INPUT TYPE=PASSWORD NAME=passad SIZE=10><BR>





	<INPUT TYPE=PASSWORD NAME=passad2 SIZE=10><BR>





	<INPUT TYPE=SUBMIT NAME=newpass VALUE="And Then!">





	</CENTER></FORM>





	</TD></TR></TABLE><BR>





	~;





	&Bottom;





	exit;





}





	





$numemail=0;





	





open(LIST,"$address_file");





@addresses=<LIST>;





close(LIST);





	





$numemail = push(@addresses);





	





print qq~





<STYLE TYPE="text/css">

<!--

body { scrollbar-arrow-color: #000000; scrollbar-3dlight-color: #c0c0c0; scrollbar-highlight-color: #ffffff; scrollbar-face-color: #ffffff; scrollbar-shadow-color: #000000; scrollbar-track-color: #ffffff; scrollbar-darkshadow-color: #000000}

-->

</style> 

		<table border="0" cellpadding="0" cellspacing="2" width="645">

			<tr>

				<td width="327"><A HREF="/index.html"><img src="/img/superbaby.gif" width="320" height="333" border="0"></A></td>

				<td width="304">

					<table border="0" cellpadding="3" cellspacing="3" width="327">

						<tr><form action="$thisurl" method=post>

							<td bgcolor="#ffcc00" width="287"><font color="#666600">Add/Remove

<br>

										<input type="text" name="address" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;" size="25" maxlength="50"></font>

									<p><font color="#666600"><input type="radio" value="subscribe" name="action" checked>Subscribe<br>

											<input type="radio" value="remove" name="action">Unsubscribe<br>

										</font><input type="submit" value="And Then!" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;"></FORM></p>

								</td>

						</tr>

						<tr height="30">

							<td width="287" height="30"></td>

						</tr>

						<tr><form action="$thisurl" method=post>

							<td bgcolor="#ffcc00" width="287"><font color="#666600">Password:<br>

									<input type="password" name="password" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;" size="25" maxlength="50"></font>

								<p><font color="#666600">Send Email (<b>$numemail</b> members)<br>

										<input type="submit" name="sendemail" value="And Then!" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;"><br>

										<br>

										

									Delete members<br>

									</font><input type="submit" name="delete_select" value="And Then!" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;"></p>

							</td>

						</tr>

					</FORM></table>

				</td>

			</tr>

		</table>







~;











&Bottom;





exit;











}











########## SET NEW PASSWORD ##########





sub newpass {





	





unless ($INPUT{'passad'} eq $INPUT{'passad2'}) {





	print qq~





	<table cellspacing=0 border=0 cellpadding =5 width=400>





	<TR bgcolor="$table_head_bg"><TD>





	<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Error!!





	</FONT>





	</TD></TR>





	<TR bgcolor="$table_body_bg">





	<TD><FONT SIZE="-1" FACE="Arial" color="$table_body_text">





	<BR>make it the same</TD></TR></TABLE>





	~;





	&Bottom;





	exit;





}











if ($INPUT{'passad'}) {





	$newpassword = crypt($INPUT{'passad'}, aa);





}





else {





	print qq~





	<table cellspacing=0 border=0 cellpadding =5 width=400>





	<TR bgcolor="$table_head_bg"><TD>





	<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Error!!





	</B></FONT>





	</TD></TR>





	<TR bgcolor="$table_body_bg">





	<TD>





	<BR><FONT SIZE="-1" FACE="Arial" color="$table_body_text">





	no password</FONT></TD></TR></TABLE>





	~;





	&Bottom;





	exit;





}











if (-e "$pwd_file") {





	print qq~





	<table cellspacing=0 border=0 cellpadding =5 width=400>





	<TR bgcolor="$table_head_bg"><TD>





	<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Error!!





	</B></FONT>





	</TD></TR>





	<TR bgcolor="$table_body_bg">





	<TD>





	<BR><FONT SIZE="-1" FACE="Arial" color="$table_body_text">





	Password already exists<BR><BR>





	To set a new password manually delete the 





	<BR>





	$pwd_file file </FONT>





	</TD></TR></TABLE>





	~;





	&Bottom;





	exit;





}











open (PASSWORD, ">$pwd_file") || &error(1);





print PASSWORD "$newpassword";





close (PASSWORD);











print qq~





<table cellspacing=0 border=0 cellpadding =5 width=400>





<TR bgcolor="$table_head_bg"><TD>





<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Password Set





</B></FONT>





</TD></TR>





<TR bgcolor="$table_body_bg">





<TD><FONT SIZE="-1" FACE="Arial" color="$table_body_text">





<BR>password has been set.</FONT></TD></TR></TABLE>





<BR>





~;





&admin;





exit;





}











########## SUBSCRIBE NEW EMAILS ##########





sub subscribe {











unless ($INPUT{'address'}=~/\@/)   { 





	&error_pretty("invalid email there, son.");





}











open(LIST,"$address_file");





@addresses=<LIST>;





close(LIST);











@add = grep{ /$INPUT{'address'}/i } @addresses;











if (@add) {





	&error_pretty("<B>$INPUT{'address'}</B> has already left for the winter.");





}

















open(LIST,">>$address_file") || &error(2);





print LIST "$INPUT{'address'}\n";





close(LIST);











print qq~





<CENTER>

			<table border="0" cellpadding="0" cellspacing="2" width="72">

				<tr>

					<td><a href="/headphones.html"><img src="/img/superbaby.gif" width="320" height="333" border="0"></a></td>

					<td>

						<table border="0" cellpadding="4" cellspacing="4" width="193" height="165">

							<tr>

								<td bgcolor="#ffcc33">

									<p><font color="#6a4e2b"><b>[$INPUT{'address'}]</B></FONT></P><p><font color="#6a4e2b"><b>Lester and Louise were the happiest couple in the world.<br>

											</b></font></p>

									<p><font color="#6a4e2b"><b>Until the water softener broke.<br>

												<br>

											</b></font></p>

									<p><font color="#6a4e2b"><b>They didn't speak much after that.</b></font>

									<p></p>

									<P><I><B><A HREF="earl.cgi">dead gerald's writings</A></B></I></P>
									<p><b><i><a href="/index.html">CUT&nbsp;YOUR&nbsp;HAIR</a></i></b></p>

								</td>

				</tr>

			</table>





~;











&Bottom;





exit;





}

















########## REMOVE ADDRESSES ##########





sub remove{











unless ($INPUT{'address'}) {





	&error_pretty("gerald will never be able to send you his cancer diagnosis without an email address!");





}











if (-e "$address_file") {





	&lock($address_file);





	





	open(LIST, "+<$address_file");





	@addresses = <LIST>;





	seek (LIST, 0, 0);





	truncate (LIST,0);





	





	foreach $add(@addresses) {





		chomp($add);





		unless ($add =~ /^$INPUT{'address'}$/i) {





			print LIST "$add\n";





		}





		else {





			$found=1;





		}





	}	





	close(LIST);





	&unlock($address_file);





}











print qq~





<table cellspacing=0 border=0 cellpadding =5 width=400>





<TR bgcolor="$table_head_bg"><TD>





<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>removed.bicycle(S)





</B></FONT>





</TD></TR>





<TR bgcolor="$table_body_bg">





<TD>





<BR><FONT SIZE="-1" FACE="Arial" color="$table_body_text">





<B>$INPUT{'address'}</B> removed.bicycle(S)





<BR><BR>





</td></TR>





<TR bgcolor="$table_head_bg">





<TD>





<FONT SIZE="-1" FACE="arial" color="$table_head_text">





Return to <a href=$name_url>$name_home</a> 





</FONT></TD></TR>





</TABLE>





~;











&Bottom;





exit;





}











########## SEND EMAILS ##########





sub email {











&checkpassword;











####





$pid = fork();





print "Content-type: text/html \n\n fork failed: $!" unless defined $pid;











if ($pid) {





	#parent





	print "Content-type: text/html \n\n";





	&Top;	





	print qq~



<CENTER>		


			<table border="0" cellpadding="0" cellspacing="2" width="72">

				<tr>

					<td><a href="/military/index.html"><img src="/img/superbaby.gif" width="320" height="333" border="0"></a></td>

					<td>

						<table border="0" cellpadding="4" cellspacing="4" width="193" height="165">

							<tr>

								<td bgcolor="#ffcc33">

									<P>
		
		
</P><p><font color="#6a4e2b">








<b>Lester and Louise were the happiest couple in the world.<br>

											</b></font></p>

									<p><font color="#6a4e2b"><b>Until the water softener broke.<br>

												<br>

											</b></font></p>

									<p><font color="#6a4e2b"><b>They didn't speak much after that.</b></font>

									<p></p>

									<p><b><i><a href="/index.html">CUT&nbsp;YOUR&nbsp;HAIR</a></i></b></p>

								</td>

				</tr>

			</table>





	



	~;





	&Bottom;





	exit(0);





}





else {





	#child











	close (STDOUT);





	open(LIST,"$address_file");





	@addresses=<LIST>;





	close(LIST);





	$num_email=0;





	





	foreach $line(@addresses) {





		chomp($line);











		open(MAIL, "|$mail_prog -t") || &error("error bicycles");





		print MAIL "To: $line \n";





		print MAIL "From: $your_name <$your_email>\n";





		print MAIL "Subject: $INPUT{'subject'} \n";





		print MAIL "$INPUT{'body'}";





		print MAIL "\n\n";





		if ($remove_link) {





			print MAIL "http://www.deaddeaddead.com\n";







		}





		print MAIL "\n\n";





		close (MAIL);





		$num_email++;


		
		



		


	}




	{

		open (LOGFILE, ">>jeffrey.log"); 

		$newline=join('::',@value); 

 		
		

		print LOGFILE "<TABLE WIDTH=55%><TR BGCOLOR=YELLOW><TD><B>$INPUT{'subject'}:: </B></TD></TR>\n";



		print LOGFILE "<TR BGCOLOR=white><TD>$INPUT{'body'}:: </TD></TR>\n";
		
	
		print LOGFILE "</TABLE><BR><BR>";
		close LOGFILE; 

	}






	open(MAIL, "|$mail_prog -t") || &error("error bicycle");





	print MAIL "To: $your_email \n";





	print MAIL "From: $your_name <$your_email>\n";





	print MAIL "Subject: $INPUT{'subject'} \n";





	print MAIL "$num_email were sent out with the following message \n\n";





	print MAIL"-----------------------------------------------------------------------------------------\n";





	print MAIL "$INPUT{'body'}";





	print MAIL "\n\n";





	print MAIL "\n\n";





	close (MAIL);





	exit(0);





}





	





	





}











########## DELETE SELECTED EMAILS ##########





sub delete_select {





	





&checkpassword;











open(LIST,"$address_file");





@addresses=<LIST>;





close(LIST);











@addresses = sort(@addresses);











print qq~



<STYLE TYPE="text/css">

<!--

body { scrollbar-arrow-color: #000000; scrollbar-3dlight-color: #c0c0c0; scrollbar-highlight-color: #ffffff; scrollbar-face-color: #ffffff; scrollbar-shadow-color: #000000; scrollbar-track-color: #ffffff; scrollbar-darkshadow-color: #000000}

-->

</style> 





<FORM METHOD=POST ACTION="$thisurl">









<table border="0" cellpadding="0" cellspacing="2" width="100%">

			<tr>

				<td width="320"><A HREF="/index.html"><img src="/img/superbaby.gif" width="320" height="333" border="0"></A></td>

				<td width="304">

					<table border="0" cellpadding="3" cellspacing="3" width="387">

						<tr>

							<td bgcolor="#ffcc00" width="387"><font color="#666600">

									</font>





<table cellspacing=0 border=0 cellpadding =5>





<TR bgcolor="$table_head_bg"><TD colspan=3>





<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Remove:





</B></FONT>





</TD></TR>





<TR bgcolor="$table_body_bg">



		

									

									



~;





	





$num_email=0;





foreach $line(@addresses) {





	chomp($line);





	if ($num_email == 2) { 





		print "</TR><TR bgcolor=\#ffcc00 align=left>"; 





		$num_email=0;





	}





	print "<TD><FONT SIZE=\"-2\" FACE=\"Arial\" color=\"$table_body_text\">";





	print "<INPUT TYPE=\"CHECKBOX\" NAME=\"delete\" VALUE=\"$line\"> -- $line</TD>";





	$num_email++;





}











print qq~



<TR><TD>

	<font color="#666600">Password:<br>

											<input type="password" name="password" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;" size="25" maxlength="50"></font><font color="#666600"><br>

										</font><input type="submit" name="delete_final" value="And Then!" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;"></p>

								

						

						

							

						

						

							

						

					</table>

				</td>

			</tr>

		</table></FORM>





~;





&Bottom;





exit;	





	





}	











########## DELETE MULTIPLE ##########





sub delete_final {





	





&checkpassword;











open(LIST,"$address_file");





@addresses=<LIST>;





close(LIST);











@deleting = split(/\,/,$INPUT{'delete'});











foreach $line(@deleting) {





	@addresses = grep{ !(/$line/i) } @addresses;





}











open(LIST,">$address_file") || &error(2);





print LIST @addresses;





close(LIST);











$INPUT{'delete'} =~ s/\,/<BR>\n/g;











print qq~





<table cellspacing=0 border=1 cellpadding =5 width=400>





<TR bgcolor="$table_head_bg"><TD>





<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>removed





</B></FONT>





</TD></TR>





<TR bgcolor="$table_body_bg">





<TD><FONT SIZE="-1" FACE="Arial" color="$table_body_text">deleted:<BR><BR>





<B>$INPUT{'delete'}</B><BR><BR>





</TD></TR></TABLE>





~;











&Bottom;





exit;











}











########## WRITE THE EMAIL ##########





sub sendemail {





	





&checkpassword;











print qq~





<FORM METHOD=POST ACTION=$thisurl>

<STYLE TYPE="text/css">

<!--

body { scrollbar-arrow-color: #000000; scrollbar-3dlight-color: #c0c0c0; scrollbar-highlight-color: #ffffff; scrollbar-face-color: #ffffff; scrollbar-shadow-color: #000000; scrollbar-track-color: #ffffff; scrollbar-darkshadow-color: #000000}

-->

</style> 



<CENTER>

			<table border="0" cellpadding="0" cellspacing="2" width="100%">

				<tr>

					<td><a href="/index.html"><img src="/img/superbaby.gif" width="320" height="333" border="0"></a></td>

					<td>

						<table border="0" cellpadding="4" cellspacing="4" width="351" height="349">

							<tr>

								<td bgcolor="#ffcc33">

									<p><b><font color="#666600">Subject:<br>

											</font></b><b><font color="#666600"><input type="text" name="subject" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;" size="40" maxlength="100"></font></b></p>

									<p><b><font color="#666600">Message:<br>

											</font></b><textarea name="body" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;" cols="40" rows="13"></textarea><br>

										<br>

										<font color="#666600"><b>Password:</b></font><br>

										<input type="password" name="password" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;" size="25" maxlength="50"><br><BR>

										<INPUT TYPE=SUBMIT NAME=email VALUE="and then!" style="background-color: #ffffff; font-family:Verdana, Geneva; font-size:8pt; color: #000000; border: 1 solid; border-color: #666600;"></p></FORM>

								</td>

				</tr>

			</table></FORM>





~;





&Bottom;





exit;





}











########## CHECK PASSWORD ##########





sub checkpassword {











open (PASSWORD, "$pwd_file");





$password = <PASSWORD>; 





close (PASSWORD);











if ($INPUT{'password'}) {





	$newpassword = crypt($INPUT{'password'}, aa);





	unless ($newpassword eq $password) {





		&error_pretty("Wrong Password");





	}





}





else {





	&error_pretty("You must enter a password");





}











}

















sub Top {











print qq~





<HTML><HEAD><TITLE>dead bicycle</TITLE></HEAD>





$body_tag



<BR>











~;





}





sub Top2 {







print qq~



<HTML><HEAD><META HTTP-EQUIV="Refresh" CONTENT="1; URL=/index.html"><TITLE>dead bicycle</TITLE></HEAD>



$body_tag



<CENTER>



<table cellspacing=0 border=0 cellpadding =5>



<TR bgcolor="$table_head_bg"><TD align=center>



<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>



&nbsp; &nbsp; &nbsp; &nbsp; 



$name_list



&nbsp; &nbsp; &nbsp; &nbsp; 



</FONT>



</TD></TR></TABLE>



<BR><BR>



~;



}







sub Bottom {





print qq~





</BODY></HTML>





~;





}











sub error{





$errors = $_[0] ;











if ($errors == 1) {





	$error_msg = "Unable to write to $pwd_file";





}





else {





	$error_msg = "Unable to write to $address_file";





}	





print qq~





<table cellspacing=0 border=0 cellpadding =5 width=400>





<TR bgcolor="$table_head_bg"><TD colspan=3>





<FONT SIZE="-1" FACE="Arial" color="$table_head_text"><B>Fatal Error!!





</B></FONT>





</TD></TR>





<TR bgcolor="$table_body_bg">





<TD>





<BR>





<FONT SIZE="-1" FACE="Arial" color="$table_body_text">





$error_msg -





<B>$!</B><BR><BR>





If the above error states "Permission Denied than either the dir this cgi file is in or the text file mentioned need 





to be chmoded to 777.<BR><BR>





Do not worry if you do not have the file mentioned, once the permissions are set correctly it will be created for you.





<BR><BR>





If you are having trouble with this script<BR>please post a message to the 





<A HREF="http://forum.solutionscripts.com"><B>CGI Forum</B></A><BR><BR></FONT></TD></TR></TABLE>





~;





&Bottom;





exit;





}











sub error_pretty { 





$errors = $_[0];





print qq~





<CENTER>

			<table border="0" cellpadding="0" cellspacing="2" width="72">

				<tr>

					<td><a href="/headphones.html"><img src="/img/superbaby.gif" width="320" height="333" border="0"></a></td>

					<td>

						<table border="0" cellpadding="4" cellspacing="4" width="193" height="165">

							<tr>

								<td bgcolor="#ffcc33">

									<p><font color="#6a4e2b"><b>[$errors]</B></FONT></P><p><font color="#6a4e2b"><b>Jane likes lemonade.<br>

											</b></font></p>

									<p><font color="#6a4e2b"><b>And one extremely hot summer day,<br>

												<br>

											</b></font></p>

									<p><font color="#6a4e2b"><b>Gertrude mowed the lawn.  And Jane drank a glass of lemonade.</b></font>

									<p></p>

									<p><b><i><a href="/index.html">CUT&nbsp;YOUR&nbsp;HAIR</a></i></b></p>

								</td>

				</tr>

			</table>



















~;





&Bottom;





exit;





}











########## FILE LOCKING SUB ##########





sub lock {











my $file = $_[0];





my $etime = time + 5;











if (-e "$file.lock") {





	open (LOCK,"$file.lock");





	my $temp = <LOCK>;





	close (LOCK);





	chomp ($temp);











    if ($temp < (time - 10)) {





         unlink ("$file.lock");





	}





}











while (-e "$file.lock" && time < $etime) {





	sleep(1);





}











if (-e "$file.lock") {





	print "file lock still here $file.lock";





	exit;





} 





else {





	open (LOCKFILE, ">$file.lock");





	print LOCKFILE time;





	close (LOCKFILE);	





}





}











############





sub unlock {





my $file = shift;





unlink ("$file.lock");





}











1;













