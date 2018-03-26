#!/usr/bin/perl -w
 
##############################################################
#
# Centreon push notification plugin            
#
# Works with superVize App. Find it on Play Store   
#
#
# Use Onesignal (https://onesignal.com) push service
#
###############################################################

#use strict;
use warnings;
use Getopt::Long;
&Getopt::Long::config('bundling');
use Net::Curl::Easy qw(/^CURLOPT_.*/);;
use WWW::Curl;
use JSON;
use Data::Dumper;

my $opt_h;
my $rest_api_key;
my $app_id;
my $type;
my $notification_id;
my $notification_type;
my $host_alias;
my $service_desc;
my $state;

my $status = GetOptions(
	"h|help"        => \$opt_h,
	"r|rest_api_key=s"  => \$rest_api_key,	
	"a|app_id=s" => \$app_id,
	"T|type=s" => \$type,	# host or service	
	"i|notification_id=s" => \$notification_id,	#	$HOSTNOTIFICATIONID$ or $SERVICENOTIFICATIONID$
	"t|notif_type=s" => \$notification_type,	#	$NOTIFICATIONTYPE$
	"H|host_alias=s" => \$host_alias,	#	$HOSTALIAS$
	"S|service_desc=s" => \$service_desc,	#	$SERVICEDESC$
	"s|state=s" => \$state	#	$HOSTSTATE$ or $SERVICESTATE$
);

if ($opt_h) {
    print_usage();
    exit;
}

if (!$rest_api_key) {
    print "-r incorrect value. REST API KEY is empty. Check it on your Onesignal (https://onesignal.com) admin panel \n";
    exit;
}

if (!$app_id) {
    print "-a incorrect value. APP ID is empty. Check it on your Onesignal (https://onesignal.com) admin panel \n";
    exit;
}

if (  $type ne ( "host" or "service" ) ){
	print "incorrect value provided for -T \n";
	exit;
}

sub SendNotification
{
    my ($url , $authorisation , $app_id , $contents) = @_;
    my $curl = Net::Curl::Easy->new;
    my $json = JSON->new();
    my $response_body;
 
    my $json_string = $json->encode({ app_id => $app_id ,
                                      included_segments => ["All"] ,
                                      data => { "key1" => "Value 1" } ,
                                      ios_badgeType => "Increase" ,
                                      ios_badgeCount => 1 ,
									  headings => { en => "$type $state"},
                                      contents => { en => $contents}
                                    });
 
    $curl->setopt( CURLOPT_URL, $url);
    $curl->setopt( CURLOPT_SSL_VERIFYHOST , 0);
    $curl->setopt( CURLOPT_SSL_VERIFYPEER , 0);
 
    $curl->setopt( CURLOPT_HTTPHEADER, ['Content-Type: application/json; charset=utf-8' ,
                                        "Authorization: Basic $authorisation"]);
    $curl->setopt( CURLOPT_POST , 1);
    $curl->setopt( CURLOPT_POSTFIELDS , $json_string);
 
    $curl->setopt( CURLOPT_WRITEDATA , \$response_body);
 
    $curl->perform;
    print Dumper($response_body);
}

if($type  =~ /host/){
SendNotification("https://onesignal.com/api/v1/notifications" ,
                 "$rest_api_key" ,
                 "$app_id" ,
                 "Please check $host_alias");
}

if($type  =~ /service/){
SendNotification("https://onesignal.com/api/v1/notifications" ,
                 "$rest_api_key" ,
                 "$app_id" ,
                 "Please check $service_desc");
}

sub print_usage {
	print <<EOU;
	
	*******************************************************
	* Centreon/Nagios push notification plugin            * 
	*                                                     *
	* Originally written to work with superVize App       *
	*                                                     *
	* Use Onesignal (https://onesignal.com) push service  *
	*******************************************************
	
    Usage: ssend_supervize_notif_push.pl -r [ YOUR_ONESIGNAL_REST_API_KEY ] -a [ YOUR_ONESIGNAL_APP_ID ] -T [ host|service] -i [ \$HOSTNOTIFICATIONID\$|\$SERVICENOTIFICATIONID\$ ] -t [ \$NOTIFICATIONTYPE\$ ] [ -H \$HOSTALIAS\$ ] [ -S \$SERVICEDESC\$ ] -s [ \$HOSTSTATE\$|\$SERVICESTATE\$ ]

    Options:

    -h, --help
        Display this help.
    -r, --rest_api_key
        REST API key. Check it on your Onesignal control panel
    -a, --app_id STRING 
        Onesignal App ID. Check it on your Onesignal control panel
	-T, --type
        host or service
    -i, notification_id
       \$HOSTNOTIFICATIONID\$ or \$SERVICENOTIFICATIONID\$ depending if plugin is used for host or service notification
    -t, --notif_type
        must be \$NOTIFICATIONTYPE\$
    -H, --host_alias
       \$HOSTALIAS\$ !!!Only if -T is set to "host"
    -S, --service_desc
       \$SERVICEDESC\$ !!!Only if -T is set to "service"
    -s, --state
       \$HOSTSTATE\$ if -T is set to host, \$SERVICESTATE\$ if -T is set to service
	
EOU
}	
		 
exit(0);