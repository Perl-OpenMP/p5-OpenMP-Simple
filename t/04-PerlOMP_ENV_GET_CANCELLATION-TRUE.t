use strict;
use warnings;

# OMP_CANCELLATION initializes cancel-var and has no runtime setter.  Set it
# before OpenMP::Simple/Inline::C can load the OpenMP runtime.
BEGIN {
  use OpenMP::Environment;
  my $env = OpenMP::Environment->new;
  my $current_value = $env->omp_cancellation(q{TRUE});
}

use Test::More;
use lib 't/lib';
use OpenMP::Simple::TestCompat qw/cancellation_true_skip_reason/;
use OpenMP::Simple;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;
my $runtime_cancellation = _get_cancellation();
my $skip_reason = cancellation_true_skip_reason($runtime_cancellation);

plan tests => 2;
note qq{Testing OMP_CANCELLATION is readable in an Inline::C'd subroutine.};

SKIP: {
  skip $skip_reason, 1 if defined $skip_reason;
  is $runtime_cancellation, 1,
    q{The cancellation policy reported by omp_get_cancellation() is 1 (ON), as expected};
}

is $env->omp_cancellation(), q{TRUE},
  q{OpenMP::Environment still reports OMP_CANCELLATION as TRUE};

__DATA__
__C__
int _get_cancellation() {
  return omp_get_cancellation();
}

__END__
