# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'RPi::GPIO' ); }

my $object = RPi::GPIO->new ();
isa_ok ($object, 'RPi::GPIO');


