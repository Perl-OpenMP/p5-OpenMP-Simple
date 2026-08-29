package OpenMP::Simple;

use strict;
use warnings;
use Alien::OpenMP;

our $VERSION = q{0.2.7};

# This module is a wrapper around a ".h" file that is injected into Alien::OpenMP
# via Inline:C's AUTO_INCLUDE feature. This header file constains C macros for reading
# OpenMP relavent environmental variables via %ENV (set by OpenMP::Environment perhaps)
# and using the standard OpenMP runtime functions to set them.

use File::ShareDir 'dist_dir';

my $share_dir = dist_dir('OpenMP-Simple');

sub Inline {
  my ($self, $lang) = @_;
  my $config = Alien::OpenMP->Inline($lang);
  $config->{INC} = qq{-I$share_dir};
  $config->{AUTO_INCLUDE} .= qq{\n#include "$share_dir/ppport.h"\n#include "$share_dir/openmp-simple.h"\n};
  return $config;
}

1;

__END__
=head1 NAME

OpenMP::Simple - Inline::C support for using OpenMP from Perl

=head1 SYNOPSIS

=head2 Using OpenMP::Environment

  use strict;
  use warnings;

  use OpenMP::Simple;
  use OpenMP::Environment;

  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );

  my $env = OpenMP::Environment->new;
  $env->omp_num_threads(4);
  $env->omp_schedule('dynamic,4');

  # Optional: validate the OpenMP environment before entering C.
  $env->assert_omp_environment;

  print "threads = ", _openmp_threads(), "\n";

  __DATA__
  __C__

  int _openmp_threads() {
    PerlOMP_GETENV_BASIC

    int threads = 0;
    #pragma omp parallel
    {
      #pragma omp single
      threads = omp_get_num_threads();
    }

    return threads;
  }

=head2 Using C<%ENV> directly

L<OpenMP::Environment> is convenient, but it is not required in order to use
C<OpenMP::Simple>. The macros read the normal OpenMP environment variables
from C<%ENV>.

  use strict;
  use warnings;

  BEGIN {
      $ENV{OMP_NUM_THREADS} = 4;
      $ENV{OMP_SCHEDULE}    = 'guided,8';
  }

  use OpenMP::Simple;

  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );

  print "threads = ", _openmp_threads(), "\n";

  __DATA__
  __C__

  int _openmp_threads() {
    PerlOMP_GETENV_BASIC

    int threads = 0;
    #pragma omp parallel
    {
      #pragma omp single
      threads = omp_get_num_threads();
    }

    return threads;
  }

=head2 Using OpenMP without the environment macros

C<OpenMP::Simple> can also be used simply to obtain the OpenMP build and link
configuration through L<Alien::OpenMP>. There is no requirement that a
C<PerlOMP_*> environment macro be used.

  use strict;
  use warnings;

  use OpenMP::Simple;

  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );

  print "maximum threads = ", _openmp_max_threads(), "\n";

  __DATA__
  __C__

  int _openmp_max_threads() {
    return omp_get_max_threads();
  }

=head1 DESCRIPTION

C<OpenMP::Simple> is a small L<Inline::C> configuration wrapper around
L<Alien::OpenMP>. It supplies the compiler and linker configuration discovered
by C<Alien::OpenMP> and automatically includes the C<openmp-simple.h> header
shipped with this distribution.

The header provides convenience macros and helper functions for common
Perl/OpenMP tasks. The most commonly used macros read standard OpenMP
variables from C<%ENV> and apply those values to the current OpenMP runtime by
calling the corresponding OpenMP runtime functions.

L<OpenMP::Environment> is the recommended interface for managing OpenMP
environment variables from Perl because it provides a consistent API and can
validate values. It is not, however, required by C<OpenMP::Simple>. Setting
C<%ENV> directly is supported, and C<OpenMP::Simple> may also be used without
any environment-update macros at all.

=head2 Runtime environment and process startup

Not every OpenMP environment variable has a corresponding runtime setter.
Variables such as C<OMP_NUM_THREADS> and C<OMP_SCHEDULE> can be read by
C<OpenMP::Simple> and applied with OpenMP runtime functions. Other variables,
such as C<OMP_CANCELLATION>, may be consumed by the OpenMP runtime when the
runtime is initialized and therefore may need to be present in the environment
before the Inline::C shared library is loaded.

When an OpenMP setting must exist before runtime initialization, set it in a
C<BEGIN> block or otherwise arrange for it to be present in the process
environment before OpenMP code is loaded.

=head2 Experimental data conversion helpers

The array conversion and verification helpers are intended to make common
Perl-to-C data handling less repetitive. They remain more experimental than
the environment-update macros.

Perl API access from arbitrary OpenMP worker threads should not be assumed to
be safe. Where practical, stage Perl data on the Perl/caller thread and do only
native C work inside OpenMP worker threads. The string conversion helpers have
been hardened in this direction. The C<_r> numeric conversion helpers should
still be regarded as experimental when portability across Perl builds and
threading models is important.

=head1 OpenMP::Environment

L<OpenMP::Environment> and C<OpenMP::Simple> are designed to work together,
but they have separate responsibilities.

C<OpenMP::Environment> manages and validates the Perl process environment.
C<OpenMP::Simple> makes those environment values useful inside Inline::C code
by applying them to the active OpenMP runtime.

For example:

  my $env = OpenMP::Environment->new;

  $env->omp_num_threads(8);
  $env->omp_dynamic('FALSE');
  $env->omp_schedule('static,16');

  $env->assert_omp_environment;

and then in C:

  void apply_openmp_environment() {
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
    PerlOMP_UPDATE_WITH_ENV__DYNAMIC
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE
  }

The equivalent can be done without C<OpenMP::Environment>:

  $ENV{OMP_NUM_THREADS} = 8;
  $ENV{OMP_DYNAMIC}     = 'FALSE';
  $ENV{OMP_SCHEDULE}    = 'static,16';

The C code is unchanged because the macros read the process environment, not
the Perl object that was used to create it.

=head1 PORTABILITY AND TESTED PLATFORMS

=head2 Tested configurations

The continuous-integration matrix documents configurations that are actively
tested. It is not intended to define the complete set of platforms on which
C<OpenMP::Simple> can run.

Current testing includes:

=over 4

=item *

Perl 5.10 through Perl 5.44 on Ubuntu 22.04 and Ubuntu 24.04.

=item *

Perl 5.44.0 built specifically with GCC 12.5.0, 13.4.0, 14.4.0, 15.3.0,
and 16.2.0.

=item *

macOS with Perl 5.42.2, Apple Clang 21.0.0, and libomp 22.1.8.

=item *

Windows with Strawberry Perl 5.42.2.1 and GCC 13.2.0.

=back

The dedicated GCC matrix builds Perl with each compiler being tested so that
the compiler recorded in Perl's C<Config> is the same compiler used by
L<Alien::OpenMP> and C<OpenMP::Simple>.

=head2 Portability beyond the tested matrix

C<OpenMP::Simple> itself contains very little platform-specific code. It relies
on L<Alien::OpenMP> to provide the compiler and OpenMP runtime configuration
required by L<Inline::C>. As a result, systems outside the tested matrix should
generally work when the Perl installation, C compiler, and OpenMP runtime form
a compatible toolchain.

Older Linux distributions are expected to remain usable provided their Perl,
compiler, C library, and OpenMP runtime satisfy the requirements of
L<Alien::OpenMP> and the particular OpenMP runtime functions being used. The
tested Ubuntu 22.04 and Ubuntu 24.04 systems should therefore be regarded as
reference platforms rather than minimum supported operating-system versions.

Likewise, GCC versions older than those in the dedicated GCC matrix may work.
Most basic C<OpenMP::Simple> functionality uses long-established OpenMP
runtime interfaces such as C<omp_set_num_threads>, C<omp_set_schedule>,
C<omp_set_dynamic>, C<omp_set_nested>, C<omp_set_max_active_levels>, and
C<omp_set_default_device>.

Individual newer features may require a newer OpenMP implementation. In
particular, C<omp_set_num_teams> and C<omp_set_teams_thread_limit> require the
corresponding runtime support and should not be assumed to exist on older
OpenMP runtimes.

Other Unix-like systems, other Clang/libomp combinations, and other compatible
OpenMP implementations may also work but are not currently part of the
continuous-integration matrix. A platform should not be considered unsupported
merely because its exact operating-system or compiler version does not appear
in CI.

The important portability constraint is the toolchain as a whole: the compiler
and OpenMP runtime used by C<OpenMP::Simple> should be compatible with the
compiler configuration of the Perl being used. L<Alien::OpenMP> is responsible
for discovering and supplying that configuration.

Accordingly:

=over 4

=item *

Configurations in the CI matrix are actively tested.

=item *

Older operating systems are supported where the Perl, compiler, and OpenMP
toolchain remains compatible.

=item *

Older compiler and OpenMP combinations may support the core API even when
newer optional OpenMP runtime functions are unavailable.

=item *

Untested platforms using compatible Perl, C compiler, and OpenMP runtime
combinations are expected to work, but should be regarded as unverified until
exercised by CI or CPAN Testers.

=back

=head1 PROVIDED C MACROS

=head2 Updating the OpenMP runtime from C<%ENV>

The C<PerlOMP_UPDATE_WITH_ENV__*> macros read standard OpenMP environment
variables and, where an OpenMP runtime setter exists, apply the value to the
current runtime.

The variables can be set through L<OpenMP::Environment> or directly through
C<%ENV>.

=head2 C<PerlOMP_GETENV_BASIC>

A convenience bundle equivalent to:

  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_UPDATE_WITH_ENV__SCHEDULE

This is useful when a routine should honor the two most common per-call
settings without spelling out both macros.

=head2 C<PerlOMP_UPDATE_WITH_ENV__NUM_THREADS>

Reads C<$ENV{OMP_NUM_THREADS}> and applies it with C<omp_set_num_threads>.

With L<OpenMP::Environment>:

  my $env = OpenMP::Environment->new;
  $env->omp_num_threads(8);

Without L<OpenMP::Environment>:

  $ENV{OMP_NUM_THREADS} = 8;

In either case:

  int threads_in_team() {
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

    int threads = 0;
    #pragma omp parallel
    {
      #pragma omp single
      threads = omp_get_num_threads();
    }
    return threads;
  }

=head2 C<PerlOMP_UPDATE_WITH_ENV__SCHEDULE>

Reads C<$ENV{OMP_SCHEDULE}> and applies it with C<omp_set_schedule>.

The current helper recognizes C<static>, C<dynamic>, C<guided>, and C<auto>,
with an optional comma-separated chunk size where meaningful, for example:

  $ENV{OMP_SCHEDULE} = 'dynamic,4';

or:

  my $env = OpenMP::Environment->new;
  $env->omp_schedule('dynamic,4');

A simple runtime check is:

  int current_schedule_chunk() {
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

    omp_sched_t kind;
    int chunk = 0;
    omp_get_schedule(&kind, &chunk);
    return chunk;
  }

The OpenMP runtime may normalize schedule details, especially for C<auto>, so
code should not assume that every implementation reports an identical chunk
value for every scheduling mode.

=head2 C<PerlOMP_UPDATE_WITH_ENV__DYNAMIC>

Reads C<$ENV{OMP_DYNAMIC}> and applies it with C<omp_set_dynamic>. True values
accepted by the helper include C<TRUE>, C<true>, and C<1>; other values disable
dynamic adjustment.

=head2 C<PerlOMP_UPDATE_WITH_ENV__NESTED>

Reads C<$ENV{OMP_NESTED}> and applies it with C<omp_set_nested>.

C<omp_set_nested> is retained for compatibility with the existing
C<OpenMP::Simple> API, although newer OpenMP specifications prefer controlling
nested parallelism with active-level settings such as
C<OMP_MAX_ACTIVE_LEVELS> and C<omp_set_max_active_levels>.

=head2 C<PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS>

Reads C<$ENV{OMP_MAX_ACTIVE_LEVELS}> and applies it with
C<omp_set_max_active_levels>.

=head2 C<PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE>

Reads C<$ENV{OMP_DEFAULT_DEVICE}> and applies it with
C<omp_set_default_device>.

Device numbers are runtime-dependent. A host-only OpenMP implementation may
report zero target devices, so portable code should query
C<omp_get_num_devices> before assuming that a particular target device number
is valid.

=head2 C<PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS>

Reads C<$ENV{OMP_NUM_TEAMS}> and applies it with C<omp_set_num_teams> when the
OpenMP runtime provides that function.

This is a newer OpenMP runtime interface than the core thread-management
functions. Availability therefore depends on the compiler and OpenMP runtime
being used.

=head2 C<PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT>

Reads C<$ENV{OMP_TEAMS_THREAD_LIMIT}> and applies it with
C<omp_set_teams_thread_limit> when the OpenMP runtime provides that function.

As with C<omp_set_num_teams>, availability depends on the OpenMP implementation
and version.

=head2 C<PerlOMP_RET_ARRAY_REF_ret>

Creates a mortal Perl C<AV *> named C<ret>. It is a convenience helper for
Inline::C routines that build and return an array reference.

For example:

  AV *values() {
    PerlOMP_RET_ARRAY_REF_ret

    av_push(ret, newSViv(10));
    av_push(ret, newSViv(20));
    av_push(ret, newSViv(30));

    return ret;
  }

=head1 PROVIDED C FUNCTIONS FOR COUNTING PERL ARRAYS

=head2 C<PerlOMP_1D_Array_NUM_ELEMENTS>

  int PerlOMP_1D_Array_NUM_ELEMENTS(SV *AVref);

Returns the number of elements in a one-dimensional Perl array reference.

=head2 C<PerlOMP_2D_AoA_NUM_ROWS>

  int PerlOMP_2D_AoA_NUM_ROWS(SV *AoAref);

Returns the number of rows in a two-dimensional Perl array-of-arrays.

=head2 C<PerlOMP_2D_AoA_NUM_COLS>

  int PerlOMP_2D_AoA_NUM_COLS(SV *AoAref);

Returns the number of elements in the first row of a two-dimensional Perl
array-of-arrays. It assumes that the caller intends the rows to have a common
shape; it does not verify every row length.

=head2 Example

These helpers do not require L<OpenMP::Environment>:

  use strict;
  use warnings;

  use OpenMP::Simple;

  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );

  my $matrix = [
      [ 1, 2, 3 ],
      [ 4, 5, 6 ],
  ];

  print rows($matrix), " x ", cols($matrix), "\n";

  __DATA__
  __C__

  int rows(SV *matrix) {
    return PerlOMP_2D_AoA_NUM_ROWS(matrix);
  }

  int cols(SV *matrix) {
    return PerlOMP_2D_AoA_NUM_COLS(matrix);
  }

=head1 PROVIDED C FUNCTIONS FOR CONVERTING 1D PERL ARRAYS TO C ARRAYS

=head2 C<PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY>

  void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(
      SV *AVref,
      int numElements,
      float retArray[numElements]
  );

Converts a one-dimensional Perl array reference to a C array of C<float>.

=head2 C<PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY_r>

  void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY_r(
      SV *AVref,
      int numElements,
      float retArray[numElements]
  );

OpenMP-parallelized variant of
C<PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY>. See L</Experimental data conversion
helpers> before relying on the C<_r> conversion helpers across different Perl
threading models.

=head2 C<PerlOMP_1D_Array_TO_1D_INT_ARRAY>

  void PerlOMP_1D_Array_TO_1D_INT_ARRAY(
      SV *AVref,
      int numElements,
      int retArray[numElements]
  );

Converts a one-dimensional Perl array reference to a C array of C<int>.

=head2 C<PerlOMP_1D_Array_TO_1D_INT_ARRAY_r>

  void PerlOMP_1D_Array_TO_1D_INT_ARRAY_r(
      SV *AVref,
      int numElements,
      int retArray[numElements]
  );

OpenMP-parallelized variant of C<PerlOMP_1D_Array_TO_1D_INT_ARRAY>. See
L</Experimental data conversion helpers> for the portability caveat applying
to C<_r> conversion helpers.

=head2 C<PerlOMP_1D_Array_TO_1D_STRING_ARRAY>

  void PerlOMP_1D_Array_TO_1D_STRING_ARRAY(
      SV *AVref,
      int numElements,
      char *retArray[numElements]
  );

Converts a one-dimensional Perl array reference to separately allocated native
C strings.

The caller owns the resulting C strings and should C<free> each element when it
is no longer needed.

=head2 C<PerlOMP_1D_Array_TO_1D_STRING_ARRAY_r>

  void PerlOMP_1D_Array_TO_1D_STRING_ARRAY_r(
      SV *AVref,
      int numElements,
      char *retArray[numElements]
  );

Parallelized string-copy variant. Perl scalar access and native-buffer setup
are staged on the caller thread; OpenMP workers copy native string data rather
than manipulating Perl scalar storage directly.

As with the non-C<_r> form, the caller owns the resulting C strings and should
C<free> them.

=head1 PROVIDED C FUNCTIONS FOR CONVERTING 2D PERL ARRAYS TO C ARRAYS

=head2 C<PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY>

  void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(
      SV *AoA,
      int numRows,
      int rowSize,
      float retArray[numRows][rowSize]
  );

Converts a two-dimensional Perl array-of-arrays to a two-dimensional C array of
C<float>.

=head2 C<PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY_r>

OpenMP-parallelized variant of C<PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY>. See
L</Experimental data conversion helpers> for the portability caveat applying
to C<_r> conversion helpers.

=head2 C<PerlOMP_2D_AoA_TO_2D_INT_ARRAY>

  void PerlOMP_2D_AoA_TO_2D_INT_ARRAY(
      SV *AoA,
      int numRows,
      int rowSize,
      int retArray[numRows][rowSize]
  );

Converts a two-dimensional Perl array-of-arrays to a two-dimensional C array of
C<int>.

=head2 C<PerlOMP_2D_AoA_TO_2D_INT_ARRAY_r>

OpenMP-parallelized variant of C<PerlOMP_2D_AoA_TO_2D_INT_ARRAY>. See
L</Experimental data conversion helpers> for the portability caveat applying
to C<_r> conversion helpers.

=head2 C<PerlOMP_2D_AoA_TO_2D_STRING_ARRAY>

  void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY(
      SV *AoA,
      int numRows,
      int rowSize,
      char *retArray[numRows][rowSize]
  );

Converts a two-dimensional Perl array-of-arrays to separately allocated native
C strings.

The caller owns the resulting strings and should C<free> every element.

=head2 C<PerlOMP_2D_AoA_TO_2D_STRING_ARRAY_r>

  void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY_r(
      SV *AoA,
      int numRows,
      int rowSize,
      char *retArray[numRows][rowSize]
  );

Parallelized string-copy variant. Perl scalar access and native-buffer setup
are staged on the caller thread; OpenMP workers copy native string data rather
than manipulating Perl scalar storage directly.

The caller owns the resulting strings and should C<free> every element.

=head1 PROVIDED ARRAY VERIFICATION FUNCTIONS

=head2 C<PerlOMP_VERIFY_1D_Array>

  void PerlOMP_VERIFY_1D_Array(SV *array);

Verifies that the supplied Perl value is a one-dimensional array reference.

=head2 C<PerlOMP_VERIFY_1D_INT_ARRAY>

  void PerlOMP_VERIFY_1D_INT_ARRAY(SV *array);

Verifies that a one-dimensional Perl array contains integer values.

=head2 C<PerlOMP_VERIFY_1D_FLOAT_ARRAY>

  void PerlOMP_VERIFY_1D_FLOAT_ARRAY(SV *array);

Verifies that a one-dimensional Perl array contains floating-point values.

=head2 C<PerlOMP_VERIFY_1D_STRING_ARRAY>

  void PerlOMP_VERIFY_1D_STRING_ARRAY(SV *array);

Verifies that a one-dimensional Perl array contains string values.

=head2 C<PerlOMP_VERIFY_2D_AoA>

  void PerlOMP_VERIFY_2D_AoA(SV *array);

Verifies that the supplied Perl value is a two-dimensional array-of-arrays.

=head2 C<PerlOMP_VERIFY_2D_INT_ARRAY>

  void PerlOMP_VERIFY_2D_INT_ARRAY(SV *array);

Verifies that a two-dimensional Perl array contains integer values.

=head2 C<PerlOMP_VERIFY_2D_FLOAT_ARRAY>

  void PerlOMP_VERIFY_2D_FLOAT_ARRAY(SV *array);

Verifies that a two-dimensional Perl array contains floating-point values.

=head2 C<PerlOMP_VERIFY_2D_STRING_ARRAY>

  void PerlOMP_VERIFY_2D_STRING_ARRAY(SV *array);

Verifies that a two-dimensional Perl array contains string values.

=head1 TESTS AND EXAMPLES

The distribution's C<t> directory contains focused examples for the macros and
helper functions. The test suite is also used to exercise Perl, compiler,
OpenMP runtime, and operating-system combinations that are difficult to
represent accurately in a single documentation example.

Examples in the test suite may use L<Test::More> or other testing modules for
verification. Those testing modules are not required merely to use
C<OpenMP::Simple> in an application.

=head1 SEE ALSO

L<Alien::OpenMP> provides the OpenMP compiler and linker configuration used by
this module.

L<OpenMP::Environment> provides a Perl interface for managing and validating
OpenMP environment variables and is the recommended companion module when an
application needs runtime configuration through C<%ENV>.

The GNU libgomp documentation is useful when using GCC's OpenMP runtime:

L<https://gcc.gnu.org/onlinedocs/libgomp/>

The OpenMP specification and implementation documentation for the compiler and
runtime in use remain authoritative for implementation-specific behavior.

L<https://www.openmp.org/specifications/>

See also the RPerl project for related work involving Perl and compiled
parallel code:

L<https://www.rperl.org/>

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 AI GENERATED CODE DISCLAIMER

For transparency, portions of the conversion functions, verification
functions, their documentation, and associated tests were developed with
substantial assistance from generative AI tools. These portions are maintained
and tested as part of C<OpenMP::Simple> like the rest of the distribution.

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut
