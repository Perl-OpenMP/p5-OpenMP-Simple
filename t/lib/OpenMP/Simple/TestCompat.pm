package OpenMP::Simple::TestCompat;

use strict;
use warnings;

use Exporter qw/import/;

our @EXPORT_OK = qw/
  cancellation_true_skip_reason
  default_device_values
/;

# Keep compiler/runtime-specific test accommodations here.  The public
# OpenMP::Simple header should stay implementation-neutral unless a runtime
# difference truly requires a library-level workaround.

sub cancellation_true_skip_reason {
    my ($runtime_value) = @_;

    # Observed with Strawberry Perl + GCC/libgomp in GitHub Actions: the
    # environment contains OMP_CANCELLATION=TRUE before libgomp is loaded,
    # but omp_get_cancellation() still reports disabled.  Keep the assertion
    # active everywhere else so this does not hide regressions on other
    # implementations.  If Windows starts reporting true, no skip occurs.
    if ($^O eq q{MSWin32} and not $runtime_value) {
        return q{Windows OpenMP runtime does not enable OMP_CANCELLATION=TRUE};
    }

    return;
}

sub default_device_values {
    my ($num_devices, $max_tests) = @_;
    $max_tests = 8 if not defined $max_tests;

    die qq{Invalid omp_get_num_devices() value: $num_devices\n}
      if not defined $num_devices or $num_devices < 0;

    # omp_get_num_devices() is the number of non-host devices.  The host
    # device number is that same value, so 0 is a valid host device on a
    # host-only runtime such as the usual macOS libomp installation.
    my $last = $num_devices;
    $last = $max_tests - 1 if $last >= $max_tests;

    return (0 .. $last);
}

1;
