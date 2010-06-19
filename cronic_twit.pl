use strict;
use Net::OAuth::Simple;
use Net::Twitter::Lite;

##################### cronic_twit ###########################
# cronic_twit is a script for updating twitter from a config file,
# based on the your local hour, 0-23. Requires two arguments, the path to your
# config file and the number of hours between tweets. 
#
# Format for your tweets in the config file should be
# phrase 7 My phrase goes here.
# or
# PHRASE 12 this is a tweet of some sort
# or even
# PhraSE     4          another thing to tweet
# 
# On first running, you will be prompted to go to a url and copy a pin
# to paste back into cronic_twit.  Afterwards your tokens will be written
# to the config file, and further runnings should not require user input
# 
# Be aware: this runs as a loop, so choosing an number which 24 is divisible by
# ( or an number which is 24 + a number that 24 is divisible by )
# will result in the script not calling 24 different phrases.
# 
# Examples:
#   perl cronic_twit.pl time_cube 6
#       Will run one of 4 different phrase entries from the file time_cube 
#           every 6 hours
#   perl cronic_twit.pl sisyphus 25
#       Will run one of 24 different phrase entries from the file sisyphus 
#           every day and an hour
#   perl cronic_twit.pl trolololo 1
#       Will run through all 24 phrases in a day and make anyone who follows
#           or is mentioned by the account hate you
#
# You'll have to get your own consumer key/secret pair, and put it in the script,
# cause I'm not okay sharing that w/ gethub. just toss it in at lines 49 and 50
# written by Ben Breedlove
#############################################################

my $config_file = $ARGV[0];
my $hours    = $ARGV[1];
die "No configuration file specified.\n" unless defined ( $config_file );
die "Must provide the number of hours between tweets as the second argument" unless (($hours * 1) eq $hours);

my $interval = $hours * 60 * 60; #perl's sleep is in seconds

# Super secret app tokens
my $consumer_key    = 'yes, you\'ll have to get your own damn app key';
my $consumer_secret = 'and secret.  Suck it up. it\'s easy';

open CONFIG, "<", $config_file or die $!;
my @config = <CONFIG>;
my ($access_token) = grep { /^access_token\b/i } @config;
$access_token =~ s/^access_token\s+//i;
chomp $access_token;
my ($access_token_secret) = grep { /^access_token_secret\b/i } @config;
$access_token_secret =~ s/^access_token_secret\s+//i;
chomp $access_token_secret;
close CONFIG or die $!;

my $net_twitter = Net::Twitter::Lite->new(
    consumer_key    => $consumer_key,
    consumer_secret => $consumer_secret,
);

if ( defined($access_token) and defined($access_token_secret) ) {
    $net_twitter->access_token($access_token);
    $net_twitter->access_token_secret($access_token_secret);
}

unless ($net_twitter->authorized) {
    print 'Please authorize at ' . $net_twitter->get_authorization_url 
        . " and enter the pin.\n";
    my $pin = <STDIN>;
    chomp $pin;

    my($access_token, $access_token_secret, $user_id, $screen_name) =
        $net_twitter->request_access_token(verifier => $pin); 

        open CONFIG, ">>", $config_file or die $!;
        print CONFIG 'ACCESS_TOKEN ' . $access_token . "\n";
        print CONFIG 'ACCESS_TOKEN_SECRET ' . $access_token_secret . "\n";
        close CONFIG;
}

my $previous = 25; #sure to not be an hour value
while (1) {

    my @time = localtime(time);
    my $hour = $time[2];

    unless ($hour == $previous) { #don't double update.  That's bad form
        $previous = $hour;

        my $phrase = get_phrase($hour);
        if ($phrase) { $net_twitter->update( $phrase ) };
    }

    sleep $interval;
}

sub get_phrase {
    my ($hour) = @_;
    open CONFIG, "<", $config_file or die $!;

    my ($phrase) = grep { /^phrase\s+$hour\b/i } <CONFIG>;
    $phrase =~ s/^phrase\s+$hour\s+//i;
    chomp $phrase;

    close CONFIG or die $!;

    return $phrase;

}
#note that while i do have an exit here, the current implementation will never see it
exit 0;
