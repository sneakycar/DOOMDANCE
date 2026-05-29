<?php

  function format_body($body){
    global $ForumAllowHTML, $plugins, $lQuote;

    // get rid of moderator HTML tags
    $body = str_replace("<HTML>", "", $body);
    $body = str_replace("</HTML>", "", $body);

    // replace all tag starts and ends
    $body=str_replace("<", "&lt;", $body);
    $body=str_replace(">", "&gt;", $body);

    if(function_exists("preg_replace")){
        // handle old legacy <> links by converting them into BB tags
        $body=preg_replace("/&lt;((http|https|ftp):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)&gt;/i", "<a href=\"$1\" target=\"_blank\">$1</a>", $body);
        $body=preg_replace("/&lt;mailto:([a-z0-9\-_\.\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+?)&gt;/i", "<a href=\"mailto:$1\">$1</a>", $body);
    }

    if(function_exists("preg_replace")){

        if($ForumAllowHTML==1){
            // replace url/link items
            $body=preg_replace("/\[img\]((http|https|ftp):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\[\/img\]/i", "<img src=\"$1\" />", $body);
            $body=preg_replace("/\[url\]((http|https|ftp|mailto):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\[\/url\]/i", "<a href=\"$1\" target=\"_blank\">$1</a>", $body);
            $body=preg_replace("/\[url=((http|https|ftp|mailto):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\](.+?)\[\/url\]/i", "<a href=\"$1\" target=\"_blank\">$3</a>", $body);
            $body=preg_replace("/\[email\]([a-z0-9\-_\.\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+?)\[\/email\]/i", "<a href=\"mailto:$1\">$1</a>", $body);



            // replace simple tag replacements
            $search=array(
                          "/\[(b)\]/",
                          "/\[\/(b)\]/",
                          "/\[(u)\]/",
                          "/\[\/(u)\]/",
                          "/\[(i)\]/",
                          "/\[\/(i)\]/",
                          "/\[(center)\]/",
                          "/\[\/(center)\]/",
                          "/\[(quote)\]/",
                          "/\[\/(quote)\]/"
                      );

            $replace=array(
                        "<strong>",
                        "</strong>",
                        "<u>",
                        "</u>",
                        "<i>",
                        "</i>",
                        "<center>",
                        "</center>",
                        "<blockquote>$lQuote:<br />\n",
                        "</blockquote>"
                     );

            $body=preg_replace($search, $replace, $body);
        }



        // clean up badly formed tags or if not allowed

        $body=preg_replace("/\[url=.*?\]/", "", $body);


        $search_clean=array(
                        "/\[url\]/",
                        "/\[\/url\]/",
                        "/\[img\]/",
                        "/\[\/img\]/",
                        "/\[email\]/",
                        "/\[email\]/",
                        "/\[\/email\]/"
                      );

        $body=preg_replace($search_clean, "", $body);

    }
    // exec all read plugins
    @reset($plugins["read_body"]);
    while(list($key,$val) = each($plugins["read_body"])) {
      $body = $val($body);
    }

    $body=nl2br($body);

    return $body;

  }

  function format_artist($artist){
    global $ForumAllowHTML, $plugins, $lQuote;

    // get rid of moderator HTML tags
    $artist = str_replace("<HTML>", "", $artist);
    $artist = str_replace("</HTML>", "", $artist);

    // replace all tag starts and ends
    $artist=str_replace("<", "&lt;", $artist);
    $artist=str_replace(">", "&gt;", $artist);

    if(function_exists("preg_replace")){
        // handle old legacy <> links by converting them into BB tags
        $artist=preg_replace("/&lt;((http|https|ftp):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)&gt;/i", "<a href=\"$1\" target=\"_blank\">$1</a>", $artist);
        $artist=preg_replace("/&lt;mailto:([a-z0-9\-_\.\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+?)&gt;/i", "<a href=\"mailto:$1\">$1</a>", $artist);
    }

    if(function_exists("preg_replace")){

        if($ForumAllowHTML==1){
            // replace url/link items
            $artist=preg_replace("/\[img\]((http|https|ftp):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\[\/img\]/i", "<img src=\"$1\" />", $artist);
            $artist=preg_replace("/\[url\]((http|https|ftp|mailto):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\[\/url\]/i", "<a href=\"$1\" target=\"_blank\">$1</a>", $artist);
            $artist=preg_replace("/\[url=((http|https|ftp|mailto):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\](.+?)\[\/url\]/i", "<a href=\"$1\" target=\"_blank\">$3</a>", $artist);
            $artist=preg_replace("/\[email\]([a-z0-9\-_\.\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+?)\[\/email\]/i", "<a href=\"mailto:$1\">$1</a>", $artist);



            // replace simple tag replacements
            $search=array(
                          "/\[(b)\]/",
                          "/\[\/(b)\]/",
                          "/\[(u)\]/",
                          "/\[\/(u)\]/",
                          "/\[(i)\]/",
                          "/\[\/(i)\]/",
                          "/\[(center)\]/",
                          "/\[\/(center)\]/",
                          "/\[(quote)\]/",
                          "/\[\/(quote)\]/"
                      );

            $replace=array(
                        "<strong>",
                        "</strong>",
                        "<u>",
                        "</u>",
                        "<i>",
                        "</i>",
                        "<center>",
                        "</center>",
                        "<blockquote>$lQuote:<br />\n",
                        "</blockquote>"
                     );

            $artist=preg_replace($search, $replace, $artist);
        }



        // clean up badly formed tags or if not allowed

        $artist=preg_replace("/\[url=.*?\]/", "", $artist);


        $search_clean=array(
                        "/\[url\]/",
                        "/\[\/url\]/",
                        "/\[img\]/",
                        "/\[\/img\]/",
                        "/\[email\]/",
                        "/\[email\]/",
                        "/\[\/email\]/"
                      );

        $artist=preg_replace($search_clean, "", $artist);

    }
    // exec all read plugins
    @reset($plugins["read_artist"]);
    while(list($key,$val) = each($plugins["read_artist"])) {
      $artist = $val($artist);
    }

    $artist=nl2br($artist);

    return $artist;

  }

  function format_rating($rating){
    global $ForumAllowHTML, $plugins, $lQuote;

    // get rid of moderator HTML tags
    $rating = str_replace("<HTML>", "", $rating);
    $rating = str_replace("</HTML>", "", $rating);

    // replace all tag starts and ends
    $rating=str_replace("<", "&lt;", $rating);
    $rating=str_replace(">", "&gt;", $rating);

    if(function_exists("preg_replace")){
        // handle old legacy <> links by converting them into BB tags
        $rating=preg_replace("/&lt;((http|https|ftp):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)&gt;/i", "<a href=\"$1\" target=\"_blank\">$1</a>", $rating);
        $rating=preg_replace("/&lt;mailto:([a-z0-9\-_\.\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+?)&gt;/i", "<a href=\"mailto:$1\">$1</a>", $rating);
    }

    if(function_exists("preg_replace")){

        if($ForumAllowHTML==1){
            // replace url/link items
            $rating=preg_replace("/\[img\]((http|https|ftp):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\[\/img\]/i", "<img src=\"$1\" />", $rating);
            $rating=preg_replace("/\[url\]((http|https|ftp|mailto):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\[\/url\]/i", "<a href=\"$1\" target=\"_blank\">$1</a>", $rating);
            $rating=preg_replace("/\[url=((http|https|ftp|mailto):\/\/[a-z0-9;\/\?:@=\&\$\-_\.\+!*'\(\),~]+?)\](.+?)\[\/url\]/i", "<a href=\"$1\" target=\"_blank\">$3</a>", $rating);
            $rating=preg_replace("/\[email\]([a-z0-9\-_\.\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+?)\[\/email\]/i", "<a href=\"mailto:$1\">$1</a>", $rating);



            // replace simple tag replacements
            $search=array(
                          "/\[(b)\]/",
                          "/\[\/(b)\]/",
                          "/\[(u)\]/",
                          "/\[\/(u)\]/",
                          "/\[(i)\]/",
                          "/\[\/(i)\]/",
                          "/\[(center)\]/",
                          "/\[\/(center)\]/",
                          "/\[(quote)\]/",
                          "/\[\/(quote)\]/"
                      );

            $replace=array(
                        "<strong>",
                        "</strong>",
                        "<u>",
                        "</u>",
                        "<i>",
                        "</i>",
                        "<center>",
                        "</center>",
                        "<blockquote>$lQuote:<br />\n",
                        "</blockquote>"
                     );

            $rating=preg_replace($search, $replace, $rating);
        }



        // clean up badly formed tags or if not allowed

        $rating=preg_replace("/\[url=.*?\]/", "", $rating);


        $search_clean=array(
                        "/\[url\]/",
                        "/\[\/url\]/",
                        "/\[img\]/",
                        "/\[\/img\]/",
                        "/\[email\]/",
                        "/\[email\]/",
                        "/\[\/email\]/"
                      );

        $rating=preg_replace($search_clean, "", $rating);

    }
    // exec all read plugins
    @reset($plugins["read_rating"]);
    while(list($key,$val) = each($plugins["read_rating"])) {
      $rating = $val($rating);
    }

    $rating=nl2br($rating);

    return $rating;

  }


?>