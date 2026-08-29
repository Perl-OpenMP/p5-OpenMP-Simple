#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);

my @tests = @ARGV;
@tests = sort glob('t/*.t') unless @tests;
@tests = map { m{^t[\\/]} ? $_ : "t/$_" } @tests;

die "No tests found\n" unless @tests;

remove_tree('blib');
make_path('blib/lib/auto/share/dist/OpenMP-Simple');

for my $file (qw(openmp-simple.h ppport.h)) {
    copy("share/$file", "blib/lib/auto/share/dist/OpenMP-Simple/$file")
        or die "Unable to copy share/$file: $!\n";
}

my $harness = q{undef *Test::Harness::Switches; test_harness(1, 'blib/lib', 'blib/arch')};
my $failed = 0;

for my $test (@tests) {
    local $ENV{PERL_DL_NONLAZY} = 1;
    my $status = system(
        $^X,
        '-Ilib',
        '-MExtUtils::Command::MM',
        '-MTest::Harness',
        '-e',
        $harness,
        $test,
    );
    ++$failed if $status != 0;
}

exit($failed > 255 ? 255 : $failed);
