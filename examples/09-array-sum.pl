#!/usr/bin/env perl

use strict;
use warnings;
use Alien::OpenMP;
use OpenMP::Environment ();
use Getopt::Long qw/GetOptionsFromArray/;
use Util::H2O qw/h2o/;

=pod
THIS IS NON-FUNCTIONAL, BUT SHOWS A "MOCK UP"
OF WHAT A PERL/OPENMP SCRIPT MIGHT LOOK LIKE
WHEN USING Inline::C::OpenMP
=cut

# build and load subroutines via Inline::C::OpenMP
use Inline::C (
    OpenMP      => 'DATA',
    with        => qw/Alien::OpenMP/,
    BUILD_NOISY => 1,
);

# init options
my $o = { threads => q{1,2,4,8,16}, };

my $ret = GetOptionsFromArray( \@ARGV, $o, qw/threads=s/ );
h2o $o;

my $oenv = OpenMP::Environment->new;
my @arr  = ( 1 .. 1_000 );
for my $num_threads ( split / *, */, $o->threads ) {
    $oenv->omp_num_threads($num_threads);
    my $sum = sum( \@arr );
    print qq{$sum\n};
}

exit;

__DATA__

__C__
# include <stdlib.h>
# include <stdio.h>

/* Notes:
 * 1. the compiler appropriate "omp.h" file will be
 *    injected at the top via Alien::OpenMP
 *
 * 2. the other feature of Inline::C::OpenMP is that it
 *    automatically "includes" a header file that defines
 *    useful macros - e.g., one to read the current value
 *    of OMP_NUM_THREADS, which is the idiomatic way that
 *    OpenMP codes set the actual number of threads that are
 *    used when in a "#omp parallel" region
*/

SV *sum(SV *array) {
    int numelts, i;

    /* macro provided by Inline::C::OpenMP */
    __INLINE_C_OPENMP_ENV_SET_OMP_NUM_THREADS__

    if ((!SvROK(array))
        || (SvTYPE(SvRV(array)) != SVt_PVAV)
        || ((numelts = av_len((AV *)SvRV(array))) < 0)
    ) {
        return &PL_sv_undef;
    }

    int total = 0;
    #pragma omp parallel sections reduction(+:total)
    {
      for (i = 0; i <= numelts; i++) {
        total += SvIV(*av_fetch((AV *)SvRV(array), i, 0));
      }
    }
    total *= numthreads; 

    return newSViv(total);
}
