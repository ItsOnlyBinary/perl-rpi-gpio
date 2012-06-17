# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'RPi::GPIO' ); }

my $object = RPi::GPIO->new(
	MODE => 'PIN', 
	PIN  => [undef, undef, undef, 0, undef, 1, undef, 4, 14, undef, 15, 17, 18, 21, undef, 22, 23, undef, 24, 10, undef, 9, 25, 11, 8, undef, 7],
	BCM  => [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25],
);
isa_ok ($object, 'RPi::GPIO');


