use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Test::More;
use lib 't/lib';
use OpenMP::Simple::TestCompat qw/default_device_values/;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;
my @devices = default_device_values(_get_num_devices(), 8);

plan tests => scalar @devices;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE'};
for my $default_device (@devices) {
    my $current_value = $env->omp_default_device($default_device);
    is _get_default_device(), $default_device,
      sprintf qq{Default device (%0d) is reflected by the OpenMP runtime, as expected},
        $default_device;
}

__DATA__
__C__
int _get_num_devices() {
  return omp_get_num_devices();
}

int _get_default_device() {
  /* default-device-var is bound to the generating task. */
  PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE
  return omp_get_default_device();
}

__END__
