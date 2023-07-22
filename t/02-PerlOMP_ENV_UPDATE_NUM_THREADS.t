use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Test::More tests => 8;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_UPDATE_NUM_THREADS'};
for my $num_threads (1 .. 8) {
  $env->omp_num_threads( $num_threads );
  is omp_test_num_threads(), $num_threads, sprintf qq{Got expected number of threads (%0d) spawned via OMP_NUM_THREADS}, $num_threads;
}

__DATA__
__C__
int omp_test_num_threads() {
  PerlOMP_ENV_UPDATE_NUM_THREADS
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_num_threads();
  }
  return ret;
}

__END__
