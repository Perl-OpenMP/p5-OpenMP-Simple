use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Test::More tests => 8;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__NUM_THREADS'};
for my $num_threads ( 1 .. 8 ) {
    my $current_value = $env->omp_num_threads($num_threads);
    is _test_num_threads(), $num_threads, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_NUM_THREADS, as expected}, $num_threads;
}

__DATA__
__C__
int _test_num_threads() {
  PerlOMP_GETENV_OMP_Basic
  int ret = 0;
  // See https://stackoverflow.com/questions/11071116/i-got-omp-get-num-threads-always-return-1-in-gcc-works-in-icc
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_num_threads();
  }
  return ret;
}

__END__
