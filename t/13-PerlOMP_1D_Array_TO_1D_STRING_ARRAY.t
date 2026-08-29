#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $has_test_deep = 1;
BEGIN {
  if ($] < 5.012) {
    $has_test_deep = 0;
  }
  else {
    eval { require Test::Deep; Test::Deep->import(); 1 }
      or $has_test_deep = 0;
  }
  if (not $has_test_deep) {
    no warnings qw/redefine/;
    *cmp_deeply = sub { 1 };
  }
}

use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

my $aref_orig = [
  [ qw/apple banana cherry date elder fig grape honey iris jack/ ],
  [ qw/kite lemon mango nectar olive pear quince rose straw tulip/ ],
  [ qw/umbrella violet water xenon yellow zebra apple banana cherry date/ ],
  [ qw/elder fig grape honey iris jack kite lemon mango nectar/ ],
  [ qw/olive pear quince rose straw tulip umbrella violet water xenon/ ],
  [ qw/yellow zebra apple banana cherry date elder fig grape honey/ ],
];

foreach my $thread_count (qw/1 4 8/) {
  $env->omp_num_threads($thread_count);

  foreach my $row_orig (@$aref_orig) {
    my $aref_new      = omp_get_renew_aref($row_orig);
    my $seen_elements = shift @$aref_new;
    my $seen_threads  = shift @$aref_new;

    is $seen_elements, scalar @$row_orig,
      q{PerlOMP_1D_Array_NUM_ELEMENTS works on original ARRAY reference};
    is $seen_threads, $thread_count,
      qq{OMP_NUM_THREADS=$thread_count is respected inside the omp parallel section};

    if ($has_test_deep) {
      cmp_deeply $aref_new, $row_orig,
        q{Row passed by reference matches the row constructed and returned by reference};
    }
    else {
      SKIP: {
        skip q{Skipping cmp_deeply because Perl is below 5.12 or Test::Deep is unavailable}, 1;
      }
    }
  }
}

done_testing;

__DATA__
__C__

AV* omp_get_renew_aref(SV *ARRAY) {
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_RET_ARRAY_REF_ret

  int num_elements = PerlOMP_1D_Array_NUM_ELEMENTS(ARRAY);
  av_push(ret, newSViv(num_elements));

  char *raw_array[num_elements];
  PerlOMP_1D_Array_TO_1D_STRING_ARRAY(ARRAY, num_elements, raw_array);

  /*
   * Exercise the native strings in parallel without touching the Perl API
   * or allocating/freeing memory from OpenMP worker threads.
   */
  size_t processed_length[num_elements];
  int seen_threads = 1;

  #pragma omp parallel shared(raw_array, num_elements, processed_length, seen_threads)
  {
    #pragma omp master
      seen_threads = omp_get_num_threads();

    #pragma omp for
    for (int i = 0; i < num_elements; i++) {
      processed_length[i] = strlen(raw_array[i]);
    }
  }

  av_push(ret, newSViv(seen_threads));

  for (int i = 0; i < num_elements; i++) {
    av_push(ret, newSVpvn(raw_array[i], (STRLEN)processed_length[i]));
    free(raw_array[i]);
  }

  return ret;
}
