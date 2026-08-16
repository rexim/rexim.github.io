// Generate a new RSS event

TITLE :: "Patreon Added to \"My social media links\"";
LINK :: "https://rexim.github.io/#socials";
DESCRIPTION :: #string END
<p><a href="https://patreon.com/tsoding" target="_blank">patreon.com/tsoding</a></p>
<p>Please note that I don't get any money from it due to sanctions imposed on the country I live in. It is used purely to limit access to our <a href="https://discord.gg/KehewYS" target="_blank">Discord</a> for moderation purposes.</p>
END

BASE_URL :: "https://rexim.github.io/";

#run {
    set_build_options_dc(.{ do_output = false });
    pub_date_in_rfc822 := get_current_date_rfc822();
    huid               := new_huid();
    event_file_path    := tprint("event/%.json", huid);
    guid               := tprint("%%", BASE_URL, event_file_path);
    if !write_entire_file(event_file_path, json_event(TITLE, LINK, DESCRIPTION, pub_date_in_rfc822)) {
        exit(69);
    }
    print("Generated event file %\n", event_file_path);
    print("Copy-paste this to rss.xml:\n\n");
    print("%\n", rss_event(TITLE, LINK, DESCRIPTION, pub_date_in_rfc822, guid));
}

rss_event :: (title: string, link: string, description: string, pub_date_in_rfc822: string, guid: string) -> string {
    sb: String_Builder;
    print_to_builder(*sb, "    <item>\n");
    print_to_builder(*sb, "      <title>%</title>\n", quote_xml_string(title));
    print_to_builder(*sb, "      <link>%</link>\n", quote_xml_string(link));
    print_to_builder(*sb, "      <description>%</description>\n", cdata(description));
    print_to_builder(*sb, "      <pubDate>%</pubDate>\n", quote_xml_string(pub_date_in_rfc822));
    print_to_builder(*sb, "      <guid>%</guid>\n", quote_xml_string(guid));
    print_to_builder(*sb, "    </item>\n");
    return builder_to_string(*sb);
}

json_event :: (title: string, link: string, description: string, pub_date_in_rfc822: string) -> string {
    sb: String_Builder;
    print_to_builder(*sb, "{\n");
    print_to_builder(*sb, "    \"title\": \"%\",\n",       quote_json_string(title));
    print_to_builder(*sb, "    \"link\": \"%\",\n",        quote_json_string(link));
    print_to_builder(*sb, "    \"description\": \"%\",\n", quote_json_string(description));
    print_to_builder(*sb, "    \"pubDate\": \"%\",\n",     quote_json_string(pub_date_in_rfc822));
    print_to_builder(*sb, "}\n");
    return builder_to_string(*sb);
}

get_current_date_rfc822 :: () -> string {
    WEEKDAYS :: string.[
        "Mon", "Tue", "Wed",
        "Thu", "Fri", "Sat",
        "Sun",
    ];

    MONTHS :: string.[
        "Jan", "Feb", "Mar",
        "Apr", "May", "Jun",
        "Jul", "Aug", "Sep",
        "Oct", "Nov", "Dec",
    ];

    rawtime: time_t;
    time(*rawtime);
    timeinfo := localtime(*rawtime);

    sb: String_Builder;
    print_to_builder(*sb, "%, ", WEEKDAYS[timeinfo.tm_wday - 1]);
    print_to_builder(*sb, "% ",  formatInt(timeinfo.tm_mday, minimum_digits = 2));
    print_to_builder(*sb, "% ",  MONTHS[timeinfo.tm_mon]);
    print_to_builder(*sb, "% ",  timeinfo.tm_year+1900,);
    print_to_builder(*sb, "%:",  formatInt(timeinfo.tm_hour, minimum_digits = 2));
    print_to_builder(*sb, "%:",  formatInt(timeinfo.tm_min, minimum_digits = 2));
    print_to_builder(*sb, "% ",  formatInt(timeinfo.tm_sec, minimum_digits = 2));
    zone := to_string(timeinfo.tm_zone);
    assert(zone.count == 3);
    print_to_builder(*sb, "%",   zone);
    print_to_builder(*sb, "00");
    return builder_to_string(*sb);
}

new_huid :: () -> string {
    rawtime: time_t;
    time(*rawtime);
    timeinfo := gmtime(*rawtime);
    return tprint("%%%-%%%",
        formatInt(timeinfo.tm_year+1900, minimum_digits = 4),
        formatInt(timeinfo.tm_mon+1,     minimum_digits = 2),
        formatInt(timeinfo.tm_mday,      minimum_digits = 2),
        formatInt(timeinfo.tm_hour,      minimum_digits = 2),
        formatInt(timeinfo.tm_min,       minimum_digits = 2),
        formatInt(timeinfo.tm_sec,       minimum_digits = 2));
}

quote_json_string :: (s: string) -> string {
    sb: String_Builder;
    for x: s {
        if x == {
        case "\""; print_to_builder(*sb, "\\\"");
        case "\n"; print_to_builder(*sb, "\\n");
        case;      append(*sb, x);
        }
    }
    return builder_to_string(*sb);
}

cdata :: (s: string) -> string {
    assert(!contains(s, "]]>"), "TODO: escape stuff inside of CDATA properly");
    return sprint("<![CDATA[%]]>", s);
}

quote_xml_string :: (s: string) -> string {
    sb: String_Builder;
    for x: s {
        // https://stackoverflow.com/a/1091955
        if x == {
        case "\""; print_to_builder(*sb, "&quot;");
        case "&";  print_to_builder(*sb, "&amp;");
        case "'";  print_to_builder(*sb, "&apos;");
        case "<";  print_to_builder(*sb, "&lt;");
        case ">";  print_to_builder(*sb, "&gt;");
        case;      append(*sb, x);
        }
    }
    return builder_to_string(*sb);
}

#import "Basic";
#import "Compiler";
#import "File";
#import "String";
// TODO: make this cross-platform using Apollo_Time module or what not
#import "POSIX";
