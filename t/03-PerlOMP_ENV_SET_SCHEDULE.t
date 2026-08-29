use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Util::H2O::More qw/h2o/;
use Test::More;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__SCHEDULE'};

# generate schedule value look up
my $schedules = {};
foreach my $sched (qw/static dynamic guided auto/) {
  $schedules->{$sched} = _omp_sched_t_to_int($sched);
}
h2o $schedules;

foreach my $sched (qw/static dynamic guided auto/) {
  foreach my $chunk (qw/1 10 100 1000 10000/) {
    my $current_value = $env->omp_schedule(qq{$sched,$chunk});
    my $environment_value = $ENV{OMP_SCHEDULE};
    note $current_value;
    _set_schedule_with_macro();
    my $set_schedule = _get_schedule();
    is $set_schedule, $schedules->$sched, sprintf qq{Schedule '%s' set in the OpenMP runtime, as expected.}, $sched;
    my $set_chunk = _get_chunk();
    if ($sched ne 'auto') {
      is $chunk, $set_chunk, sprintf qq{Chunk size '% 5d' set in the OpenMP runtime, as expected.}, $set_chunk;
    }
    is $ENV{OMP_SCHEDULE}, $environment_value, 'Schedule update does not modify OMP_SCHEDULE';
  }
}

done_testing;

__DATA__
__C__
void _set_schedule_with_macro() {
  PerlOMP_UPDATE_WITH_ENV__SCHEDULE
}

int _get_schedule() {
  omp_sched_t sched;
  int chunk;
  omp_get_schedule(&sched, &chunk);
  return (int)sched;
}

int _get_chunk() {
  omp_sched_t sched;
  int chunk;
  omp_get_schedule(&sched, &chunk);
  return chunk;
}

int _omp_sched_t_to_int(char *schedule) {
  if (strcmp(schedule,"static") == 0) {
    return (int)omp_sched_static;
  }
  if (strcmp(schedule,"dynamic") == 0) {
    return (int)omp_sched_dynamic;
  }
  if (strcmp(schedule,"guided") == 0) {
    return (int)omp_sched_guided;
  }
  if (strcmp(schedule,"auto") == 0) {
    return (int)omp_sched_auto;
  }
  return -1;
}

__END__
