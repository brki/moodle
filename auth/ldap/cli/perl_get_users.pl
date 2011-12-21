#
# This script will read usernames from the LDAP server
# and output them in the form:
#   ldapattr :: username-1
#   ldapattr :: username-2
#   ...
#   ldapattr :: username-n

#
# This script is based on the one posted by Olumuyiwa Taiwo to http://moodle.org/mod/forum/discuss.php?d=49336
# It was updated by Brian King (brian of liip ch) in December 2011
#   * use strict mode for the perl script
#   * adjusted to work with Moodle 2.1 and 2.2.
#   * adjusted to pass parameters to the perl script via a file instead of in the exec call (moderately more secure)

use strict;
use Net::LDAP;
use Net::LDAP::Control::Paged;
use Net::LDAP::Constant qw( LDAP_CONTROL_PAGED );

my $paramFile = $ARGV[0];

if (not -f $paramFile) {
    exit 4; # Let PHP deal with the exit status
}

# find out where and what to get from ldap
my %var = ();
open FILE,'<', $paramFile or die 'died: '.$!;
my @lines = <FILE>;
chomp(@lines);
foreach my $line (@lines) {
  my ($key, $value) = split(' :: ',$line, 2);
  $var{$key} = $value;
}
close FILE;

my @ldap_server;

my @variables = (
    'ldap_server',
    'ad_ldap_dn',
    'ad_ldap_password',
    'ad_ldap_version',
    'size_limit',
    'base',
    'scope',
    'filter',
    'attrs',
);

foreach my $variable (@variables) {
    if ( not defined $var{$variable} ) {
        exit 5; # Let PHP deal with the exit status
    }
}

my $ad_ldap = Net::LDAP->new( $var{'ldap_server'}, version => $var{'ad_ldap_version'} ) or exit 2; # Let PHP deal with the exit status

my $bind = $ad_ldap->bind($var{'ad_ldap_dn'}, password => $var{'ad_ldap_password'}) or exit 3; # Let PHP deal with the exit status

my $page = Net::LDAP::Control::Paged->new( size => $var{'size_limit'} );

my $cookie;

my @args = (
'base'     => $var{'base'},
'scope'    => $var{'scope'},
'filter'   => $var{'filter'},
'attrs'    => [ $var{'attrs'} ],
'control'  => [ $page ],
);

my $count = 0;

while(1) {
    # Perform search
    my $result = $ad_ldap->search( @args );

    my $href = $result->as_struct;

    # get an array of the DN names
    my @arrayOfDNs  = keys %$href;        # use DN hashes

    # process each DN using it as a key
    foreach ( @arrayOfDNs ) {
        my $valref = $$href{$_};
        # get an array of the attribute names
        # passed for this one DN.
        my @arrayOfAttrs = sort keys %$valref; #use Attr hashes
        my $attrName;
        foreach $attrName (@arrayOfAttrs) {

            # skip any binary data: yuck!
            next if ( $attrName =~ /;binary$/ );

            # get the attribute value (pointer) using the
            # attribute name as the hash
            my $attrVal =  @$valref{$attrName};
            print "ldapattr :: @$attrVal\n";
        }
        # End of that DN
        $count++;
    }

    # Only continue on LDAP_SUCCESS
    $result->code and last;

    # Get cookie from paged control
    my($resp)  = $result->control( LDAP_CONTROL_PAGED ) or last;
    $cookie    = $resp->cookie or last;

    # Set cookie in paged control
    $page->cookie($cookie);
}

if ($cookie) {
    # We had an abnormal exit, so let the server know we do not want any more
    $page->cookie($cookie);
    $page->size(0);
    my $result = $ad_ldap->search( @args );
}
$ad_ldap->unbind;
