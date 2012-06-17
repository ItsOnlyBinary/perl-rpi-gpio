

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'RPi::GPIO',
    VERSION_FROM => 'lib/RPi/GPIO.pm', # finds \$VERSION
    AUTHOR       => 'NucWin (nucwin@gmail.com)',
    ABSTRACT     => 'GPIO Access for Raspberry Pi',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
