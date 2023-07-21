package OpenMP::Simple;

use strict;
use warnings;
use Alien::OpenMP;

sub Inline {
  my ($self, $lang) = @_;
  my $config = Alien::OpenMP->Inline($lang);
  $config->{AUTO_INCLUDE} .=q{

// NOTE: it is possible (and likely desirable) for this to become a .h file at some point //

/* %ENV Update Macros (doxygen style comments) */
#define PerlOMP_ENV_UPDATE_NUM_THREADS char *num = getenv("OMP_NUM_THREADS"); omp_set_num_threads(atoi(num)); ///< read and update $ENV{OMP_NUM_THREADS}
#define PerlOMP_ENV_UPDATE_SCHEDULE char *str = getenv("OMP_SCHEDULE"); omp_set_schedule(str);                ///< read and update $ENV{OMP_SCHEDULE}

// ... add all of them from OpenMP::Environment, add unit tests

/* Output Init Macros (needed?) */
#define PerlOMP_RET_ARRAY_REF_ret AV* ret = newAV();sv_2mortal((SV*)ret);

/* Datatype Converters (doxygen style comments) */

/**
 * Converts a 1D Perl Array Reference (AV*) into a 1D C array of floats; allocates retArray[numElements] by reference
 * @param[in] *Aref, int numElements, float retArray[numElements] 
 * @param[out] void 
 */ 

void PerlOMP_1D_Array_TO_FLOAT_ARRAY_1D(SV *Aref, int numElements, float retArray[numElements]) {
  for (int i=0; i<numElements; i++) {
    SV **element = av_fetch((AV*)SvRV(Aref), i, 0);
    retArray[i] = SvNV(*element);
  }
}

/* 2D AoA to 2D float C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of floating point values, e.g.,
 *
 *   my $AoA = [ [qw/1.01 2.02 3.03/], [qw/3.145 2.123 0.892/], [qw/19.17 60.651 20.17/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/
 
void PerlOMP_2D_AoA_TO_FLOAT_ARRAY_2D(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]) {
  SV **AVref;
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* 1D Array reference to 1D int C array ...
 * Convert a regular M-element Perl array consisting of inting point values, e.g.,
 *
 *   my $Aref = [ 10, 314, 527, 911, 538 ];
 *
 * into a C array of the same dimensions so that it can be used as exepcted with an OpenMP
 * "#pragma omp for" work sharing construct
*/

void PerlOMP_1D_Array_TO_INT_ARRAY_1D(SV *Aref, int numElements, int retArray[numElements]) {
  for (int i=0; i<numElements; i++) {
    SV **element = av_fetch((AV*)SvRV(Aref), i, 0);
    retArray[i] = SvIV(*element);
  }
}

/* 2D AoA to 2D int C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of inting point values, e.g.,
 *
 *   my $AoA = [ [qw/101 202 303/], [qw/3145 2123 892/], [qw/1917 60.651 2017/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/
 
void PerlOMP_2D_AoA_TO_INT_ARRAY_2D(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]) {
  SV **AVref;
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      retArray[i][j] = SvIV(*element);
    }
  }
}

/* TODO:
  * add unit tests for conversion functions
  * add some basic matrix operations (transpose for 2D, reverse for 1D)
  * experiment with simple hash ref to C struct
 * ...
*/

};
  return $config;
}

1;

__END__

=head1 NAME OpenMP::Simple

=head1 SYNOPSIS

    use OpenMP::Simple;
    use OpenMP::Environment;
    
    use Inline (
        C                 => 'DATA',
        with              => qw/OpenMP::Simple/,
    );
    
=head1 DESCRIPTION

This module attempts to ease the transition for those more familiar with programming C with OpenMP
than they are with Perl or using C<Inline::C> within their Perl programs. It build upon the configuration
information that is provided for by C<Alien::OpenMP>, and appends to the C<AUTO_INCLUDE> literal
lines of C code that defines useful macros and data conversion functions (Perl to C, C to Perl).

In addition to helping to deal with getting data structures that are very common in the computational
domains into and out of these C<Inline::C>'d routines that leverage I<OpenMP>, this module provides
macros that are designed to provide behavior that is assumed to work when executing a binary that has
been compiled with OpenMP support, such as the awareness of the current state of the C<OMP_NUM_THREADS>
environmental variable.

=head1 PROVIDED MACROS

=over 4

=item C<PerlOMP_ENV_UPDATE_NUM_THREADS>

When used, the value of C<OMP_NUM_THREADS> will be read and be used to update with the runtime the
number of threads via OpenMP standard runtime function, C<omp_set_num_threads> (as implemented by
GCC's GOMP).

=item C<PerlOMP_RET_ARRAY_REF_ret>

(may not be needed) - creates a new C<AV*> and sets it I<mortal> (doesn't survive outside of the
current scope). Used when wanting to return an array reference that's been populated via C<av_push>.

=back

=head1 PROVIDED PERL TO C CONVERSION FUNCTIONS

=over 4

=item C<PerlOMP_2D_AoA_TO_FLOAT_ARRAY_2D(AoA, num_nodes, dims, nodes)>

Used to extract the contents of a 2D rectangular Perl array reference that has been used to
represent a 2D matrix.

    float nodes[num_nodes][dims];
    PerlOMP_2D_AoA_TO_FLOAT_ARRAY_2D(AoA, num_nodes, dims, nodes);

=back

=head1 COPYRIGHT

Same as Perl.
