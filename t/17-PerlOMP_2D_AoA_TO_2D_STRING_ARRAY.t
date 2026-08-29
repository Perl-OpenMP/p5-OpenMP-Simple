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

  my $aref_new      = omp_get_renew_aref($aref_orig);
  my $seen_elements = shift @$aref_new;
  my $seen_threads  = shift @$aref_new;

  is $seen_elements, scalar(@$aref_orig) * scalar(@{$aref_orig->[0]}),
    q{2D array element count is correct};
  is $seen_threads, $thread_count,
    qq{OMP_NUM_THREADS=$thread_count is respected inside the omp parallel section};

  if ($has_test_deep) {
    cmp_deeply $aref_new, $aref_orig,
      q{2D array passed by reference matches the array returned};
  }
  else {
    SKIP: {
      skip q{Skipping cmp_deeply because Perl is below 5.12 or Test::Deep is unavailable}, 1;
    }
  }
}

done_testing;

__DATA__
__C__

AV* omp_get_renew_aref(SV *AoA) {
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_RET_ARRAY_REF_ret

  int numRows = PerlOMP_2D_AoA_NUM_ROWS(AoA);
  int rowSize = PerlOMP_2D_AoA_NUM_COLS(AoA);
  av_push(ret, newSViv(numRows * rowSize));

  char *raw_array[numRows][rowSize];
  PerlOMP_2D_AoA_TO_2D_STRING_ARRAY(AoA, numRows, rowSize, raw_array);

  size_t processed_length[numRows][rowSize];
  int seen_threads = 1;

  #pragma omp parallel shared(raw_array, numRows, rowSize, processed_length, seen_threads)
  {
    #pragma omp master
      seen_threads = omp_get_num_threads();

    #pragma omp for collapse(2)
    for (int i = 0; i < numRows; i++) {
      for (int j = 0; j < rowSize; j++) {
        processed_length[i][j] = strlen(raw_array[i][j]);
      }
    }
  }

  av_push(ret, newSViv(seen_threads));

  for (int i = 0; i < numRows; i++) {
    AV *row = newAV();
    for (int j = 0; j < rowSize; j++) {
      av_push(row, newSVpvn(raw_array[i][j], (STRLEN)processed_length[i][j]));
      free(raw_array[i][j]);
    }
    av_push(ret, newRV_noinc((SV*)row));
  }

  return ret;
}
