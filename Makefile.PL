

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DateTime::Parser',
    VERSION_FROM => 'lib/DateTime/Parser.pm', # finds \$VERSION
    AUTHOR       => 'Maroš Kollár (maros [at] k-1.com)',
    ABSTRACT     => 'Locale aware Parser for DateTime',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
