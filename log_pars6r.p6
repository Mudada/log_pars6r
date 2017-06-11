use JSON::Tiny;

my $path = "/home/nada/SDC-VIRT/log_parser/src/";
my $conf_file = $path ~ "../log_parser.json";
my %conf = from-json(slurp $conf_file);

grammar NAGIOS {
	token TOP { \[<timestamp>\]<ws><type><ws>[<arg>+ % ';']*[<status>]?[<ws><error>]? }
	token timestamp { \d* }
	token type { [\w|\s]+\: }
	proto 	token arg {*}
		token arg:sym<email> { "notify-host-by-email" }	
		token arg:sym<else> { [\w|\-|\=]+ }	
	token status { [\w|\-]+ }
	token error { .+$ }
}

class NAGIOS-actions {
	method arg:sym<email> ($/) { make (:email) }
	method arg:sym<else> ($/) { make (:!email) }
}

for %conf<log_files>.IO.lines {
	my $res = NAGIOS.parse($_, actions => NAGIOS-actions);
	next unless $res && +$res<timestamp> > %conf<last_timestamp>;
	%conf<last_timestamp> = +$res<timestamp>;
	if any($res<arg>).made<email> {
		say "send mail";
	}
}

