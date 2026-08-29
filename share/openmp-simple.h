/**
All setters EXCEPT the LOCK routines,
  as defined at https://gcc.gnu.org/onlinedocs/libgomp/Runtime-Library-Routines.html

   Status                              GCC*     Description
+-------------------------------------------------------------------------------------------+
 - DONE   omp_set_num_threads          8.3.0  – Set upper team size limit
 - DONE   omp_set_schedule             8.3.0  – Set the runtime scheduling method
 - DONE   omp_set_dynamic              8.3.0  – Enable/disable dynamic teams
 - DONE   omp_set_nested               8.3.0  – Enable/disable nested parallel regions
 - DONE   omp_set_max_active_levels    8.3.0  – Limits the number of active parallel regions
 - DONE   omp_set_default_device       8.3.0  – Set the default device for target regions
 - DONE   omp_set_num_teams           12.3.0  – Set upper teams limit for teams construct
 - DONE   omp_set_teams_thread_limit  12.3.0  – Set upper thread limit for teams construct
+-------------------------------------------------------------------------------------------+
**/

/* %ENV Update Macros                                      */

#define PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE             \
    char *num1 = getenv("OMP_DEFAULT_DEVICE");              \
    if (num1 != NULL) {                                     \
      omp_set_default_device(atoi(num1));                   \
    }

#define PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT         \
    char *num2 = getenv("OMP_TEAMS_THREAD_LIMIT");          \
    if (num2 != NULL) {                                     \
      omp_set_teams_thread_limit(atoi(num2));               \
    }

#define PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS                  \
    char *num3 = getenv("OMP_NUM_TEAMS");                   \
    if (num3 != NULL) {                                     \
      omp_set_num_teams(atoi(num3));                        \
    }

#define PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS          \
    char *num4 = getenv("OMP_MAX_ACTIVE_LEVELS");           \
    if (num4 != NULL) {                                     \
      omp_set_max_active_levels(atoi(num4));                \
    }

#define PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                \
    char *num5 = getenv("OMP_NUM_THREADS");                 \
    if (num5 != NULL) {                                     \
      omp_set_num_threads(atoi(num5));                      \
    }

#define PerlOMP_UPDATE_WITH_ENV__DYNAMIC                    \
    {                                                       \
      const char *PerlOMP_dynamic = getenv("OMP_DYNAMIC"); \
      if (PerlOMP_dynamic == NULL) {                        \
        omp_set_dynamic(0);                                 \
      }                                                     \
      else if (strcmp(PerlOMP_dynamic,"TRUE") == 0 ||      \
               strcmp(PerlOMP_dynamic,"true") == 0 ||      \
               strcmp(PerlOMP_dynamic,"1") == 0) {         \
        omp_set_dynamic(1);                                 \
      }                                                     \
      else {                                                \
        omp_set_dynamic(0);                                 \
      }                                                     \
    }

#define PerlOMP_UPDATE_WITH_ENV__NESTED                     \
    {                                                       \
      const char *PerlOMP_nested = getenv("OMP_NESTED");   \
      if (PerlOMP_nested == NULL) {                         \
        omp_set_nested(0);                                  \
      }                                                     \
      else if (strcmp(PerlOMP_nested,"TRUE") == 0 ||       \
               strcmp(PerlOMP_nested,"true") == 0 ||       \
               strcmp(PerlOMP_nested,"1") == 0) {          \
        omp_set_nested(1);                                  \
      }                                                     \
      else {                                                \
        omp_set_nested(0);                                  \
      }                                                     \
    }

#define PerlOMP_UPDATE_WITH_ENV__SCHEDULE                   \
    {                                                       \
      const char *PerlOMP_schedule = getenv("OMP_SCHEDULE"); \
      if (PerlOMP_schedule != NULL) {                       \
        omp_sched_t PerlOMP_schedule_kind = omp_sched_static; \
        const char *PerlOMP_chunk_text = NULL;              \
        int PerlOMP_chunk = 1;                              \
        int PerlOMP_schedule_valid = 1;                     \
        if (strncmp(PerlOMP_schedule,"static",6) == 0 &&   \
            (PerlOMP_schedule[6] == '\0' || PerlOMP_schedule[6] == ',')) { \
          PerlOMP_schedule_kind = omp_sched_static;         \
          PerlOMP_chunk_text = PerlOMP_schedule[6] == ',' ? PerlOMP_schedule + 7 : NULL; \
        }                                                   \
        else if (strncmp(PerlOMP_schedule,"dynamic",7) == 0 && \
                 (PerlOMP_schedule[7] == '\0' || PerlOMP_schedule[7] == ',')) { \
          PerlOMP_schedule_kind = omp_sched_dynamic;        \
          PerlOMP_chunk_text = PerlOMP_schedule[7] == ',' ? PerlOMP_schedule + 8 : NULL; \
        }                                                   \
        else if (strncmp(PerlOMP_schedule,"guided",6) == 0 && \
                 (PerlOMP_schedule[6] == '\0' || PerlOMP_schedule[6] == ',')) { \
          PerlOMP_schedule_kind = omp_sched_guided;         \
          PerlOMP_chunk_text = PerlOMP_schedule[6] == ',' ? PerlOMP_schedule + 7 : NULL; \
        }                                                   \
        else if (strncmp(PerlOMP_schedule,"auto",4) == 0 && \
                 (PerlOMP_schedule[4] == '\0' || PerlOMP_schedule[4] == ',')) { \
          PerlOMP_schedule_kind = omp_sched_auto;           \
          PerlOMP_chunk_text = PerlOMP_schedule[4] == ',' ? PerlOMP_schedule + 5 : NULL; \
        }                                                   \
        else {                                              \
          PerlOMP_schedule_valid = 0;                       \
        }                                                   \
        if (PerlOMP_chunk_text != NULL && *PerlOMP_chunk_text != '\0') { \
          PerlOMP_chunk = atoi(PerlOMP_chunk_text);         \
        }                                                   \
        if (PerlOMP_schedule_valid) {                       \
          omp_set_schedule(PerlOMP_schedule_kind, PerlOMP_chunk); \
        }                                                   \
      }                                                     \
    }

/* bundled Macros */
#define PerlOMP_GETENV_BASIC                                \
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                    \
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

// ... add all of them from OpenMP::Environment, add unit tests

/* Output Init Macros (needed?) */
#define PerlOMP_RET_ARRAY_REF_ret AV* ret = newAV();sv_2mortal((SV*)ret);

/* Datatype Converters (doxygen style comments) */

/**
 * Converts a 1D Perl Array Reference (AV*) into a 1D C array of floats; allocates retArray[numElements] by reference
 * @param[in] *Aref, int numElements, float retArray[numElements]
 * @param[out] void
 */

void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(SV *AVref, int numElements, float retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvNV(*element);
  }
}

/* threaded version */
void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY_r(SV *AVref, int numElements, float retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  PerlOMP_GETENV_BASIC
  #pragma omp parallel for
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvNV(*element);
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

void PerlOMP_1D_Array_TO_1D_INT_ARRAY(SV *AVref, int numElements, int retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvIV(*element);
  }
}

/* threaded version */
void PerlOMP_1D_Array_TO_1D_INT_ARRAY_r(SV *AVref, int numElements, int retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  PerlOMP_GETENV_BASIC
  #pragma omp parallel for
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvIV(*element);
  }
}

/* 1D Array reference to 1D C string array ...
 * Converts a Perl array of strings, e.g.,
 *
 *   my $Aref = [ "hello", "world", "foo", "bar" ];
 *
 * into a C array of strings (char*), so it can be used in OpenMP or C code.
 */

void PerlOMP_1D_Array_TO_1D_STRING_ARRAY(SV *AVref, int numElements, char *retArray[numElements]) {
  AV *array = (AV*)SvRV(AVref);
  SV **element;

  for (int i = 0; i < numElements; i++) {
    STRLEN length;
    const char *source;

    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element)) {
      for (int j = 0; j < i; j++)
        free(retArray[j]);
      croak("Expected value at array[%d]", i);
    }

    source = SvPV(*element, length);
    retArray[i] = (char *)malloc((size_t)length + 1);
    if (!retArray[i]) {
      for (int j = 0; j < i; j++)
        free(retArray[j]);
      croak("Memory allocation failed for array[%d]", i);
    }

    memcpy(retArray[i], source, (size_t)length);
    retArray[i][length] = '\0';
  }
}

/*
 * Threaded version.
 *
 * Perl API access and allocation stay on the calling Perl thread. OpenMP
 * workers only copy bytes between native buffers. This avoids crossing Perl
 * allocator/interpreter ownership boundaries on runtimes such as Strawberry
 * Perl while keeping the caller-facing API unchanged.
 */
void PerlOMP_1D_Array_TO_1D_STRING_ARRAY_r(SV *AVref, int numElements, char *retArray[numElements]) {
  AV *array = (AV*)SvRV(AVref);
  const char **source = NULL;
  STRLEN *length = NULL;

  PerlOMP_GETENV_BASIC

  if (numElements > 0) {
    source = (const char **)malloc((size_t)numElements * sizeof(*source));
    length = (STRLEN *)malloc((size_t)numElements * sizeof(*length));
    if (!source || !length) {
      free(source);
      free(length);
      croak("Memory allocation failed while staging string array");
    }
  }

  for (int i = 0; i < numElements; i++) {
    SV **element = av_fetch(array, i, 0);

    if (!element || !*element || !SvOK(*element)) {
      for (int j = 0; j < i; j++)
        free(retArray[j]);
      free(source);
      free(length);
      croak("Expected value at array[%d]", i);
    }

    source[i] = SvPV(*element, length[i]);
    retArray[i] = (char *)malloc((size_t)length[i] + 1);
    if (!retArray[i]) {
      for (int j = 0; j < i; j++)
        free(retArray[j]);
      free(source);
      free(length);
      croak("Memory allocation failed for array[%d]", i);
    }
  }

  #pragma omp parallel for
  for (int i = 0; i < numElements; i++) {
    memcpy(retArray[i], source[i], (size_t)length[i]);
    retArray[i][length[i]] = '\0';
  }

  free(source);
  free(length);
}

/* 2D AoA to 2D float C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of floating point values, e.g.,
 *
 *   my $AoA = [ [qw/1.01 2.02 3.03/], [qw/3.145 2.123 0.892/], [qw/19.17 60.651 20.17/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/

// contribued by CPAN's NERDVANA - thank you!
void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* threaded version */
void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY_r(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");

  PerlOMP_GETENV_BASIC
  #pragma omp parallel for private(AVref)
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
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

void PerlOMP_2D_AoA_TO_2D_INT_ARRAY(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* threaded version */
void PerlOMP_2D_AoA_TO_2D_INT_ARRAY_r(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");

  PerlOMP_GETENV_BASIC
  #pragma omp parallel for private(AVref)
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* 2D AoA to 2D C String array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of string values, e.g.,
 *
 *   my $AoA = [ [qw/hello world/], [qw/foo bar/], [qw/baz qux/] ];
 *
 * into a C array of strings (char*[][]) so it can be used with OpenMP
 * "#pragma omp for" work-sharing construct.
 */

void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY(SV *AoA, int numRows, int rowSize, char *retArray[numRows][rowSize]) {
  SV **AVref;

  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");

  for (int i = 0; i < numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV) {
      for (size_t k = 0; k < (size_t)i * (size_t)rowSize; k++)
        free(retArray[k / (size_t)rowSize][k % (size_t)rowSize]);
      croak("Expected arrayref at array[%d]", i);
    }

    for (int j = 0; j < rowSize; j++) {
      size_t index = (size_t)i * (size_t)rowSize + (size_t)j;
      STRLEN length;
      const char *source;
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);

      if (!element || !*element || !SvOK(*element)) {
        for (size_t k = 0; k < index; k++)
          free(retArray[k / (size_t)rowSize][k % (size_t)rowSize]);
        croak("Expected value at array[%d][%d]", i, j);
      }

      source = SvPV(*element, length);
      retArray[i][j] = (char *)malloc((size_t)length + 1);
      if (!retArray[i][j]) {
        for (size_t k = 0; k < index; k++)
          free(retArray[k / (size_t)rowSize][k % (size_t)rowSize]);
        croak("Memory allocation failed for array[%d][%d]", i, j);
      }

      memcpy(retArray[i][j], source, (size_t)length);
      retArray[i][j][length] = '\0';
    }
  }
}

/*
 * Threaded version using OpenMP.
 *
 * As with the 1D variant, Perl API access and allocation happen only on the
 * calling Perl thread. Worker threads operate exclusively on native buffers.
 */
void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY_r(SV *AoA, int numRows, int rowSize, char *retArray[numRows][rowSize]) {
  size_t count;
  const char **source = NULL;
  STRLEN *length = NULL;

  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");

  PerlOMP_GETENV_BASIC

  count = (size_t)numRows * (size_t)rowSize;
  if (count > 0) {
    source = (const char **)malloc(count * sizeof(*source));
    length = (STRLEN *)malloc(count * sizeof(*length));
    if (!source || !length) {
      free(source);
      free(length);
      croak("Memory allocation failed while staging 2D string array");
    }
  }

  for (int i = 0; i < numRows; i++) {
    SV **AVref = av_fetch((AV*)SvRV(AoA), i, 0);

    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV) {
      size_t allocated = (size_t)i * (size_t)rowSize;
      for (size_t k = 0; k < allocated; k++)
        free(retArray[k / (size_t)rowSize][k % (size_t)rowSize]);
      free(source);
      free(length);
      croak("Expected arrayref at array[%d]", i);
    }

    for (int j = 0; j < rowSize; j++) {
      size_t index = (size_t)i * (size_t)rowSize + (size_t)j;
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);

      if (!element || !*element || !SvOK(*element)) {
        for (size_t k = 0; k < index; k++)
          free(retArray[k / (size_t)rowSize][k % (size_t)rowSize]);
        free(source);
        free(length);
        croak("Expected value at array[%d][%d]", i, j);
      }

      source[index] = SvPV(*element, length[index]);
      retArray[i][j] = (char *)malloc((size_t)length[index] + 1);
      if (!retArray[i][j]) {
        for (size_t k = 0; k < index; k++)
          free(retArray[k / (size_t)rowSize][k % (size_t)rowSize]);
        free(source);
        free(length);
        croak("Memory allocation failed for array[%d][%d]", i, j);
      }
    }
  }

  #pragma omp parallel for collapse(2)
  for (int i = 0; i < numRows; i++) {
    for (int j = 0; j < rowSize; j++) {
      size_t index = (size_t)i * (size_t)rowSize + (size_t)j;
      memcpy(retArray[i][j], source[index], (size_t)length[index]);
      retArray[i][j][length[index]] = '\0';
    }
  }

  free(source);
  free(length);
}

/* Datastructure Introspection Functions*/

/**
 * Returns the number of elements in a 1D array from Perl
 */

int PerlOMP_1D_Array_NUM_ELEMENTS (SV *AVref) {
  return av_count((AV*)SvRV(AVref));
}

/* Datastructure Introspection Functions*/

/**
 * Returns the number of rows in a 2D array from Perl
 */

int PerlOMP_2D_AoA_NUM_ROWS(SV *AoAref) {
    if (!SvROK(AoAref)) {
        croak("Expected an array reference");
        return -1;
    }

    AV *av = (AV *)SvRV(AoAref);
    if (SvTYPE(av) != SVt_PVAV) {
        croak("Expected an array reference, but got a different reference type");
        return -1;
    }

    return av_count(av);
}

int PerlOMP_2D_AoA_NUM_COLS(SV *AoAref) {
    if (!SvROK(AoAref)) {
        croak("Expected an array reference");
        return -1;
    }

    AV *av = (AV *)SvRV(AoAref);
    if (SvTYPE(av) != SVt_PVAV) {
        croak("Expected an array reference, but got a different reference type");
        return -1;
    }

    // Get the first row (another array reference)
    SV **first_row_sv = av_fetch(av, 0, 0);
    if (!first_row_sv || !SvROK(*first_row_sv)) {
        croak("First element is not a valid array reference");
        return -1;
    }

    AV *first_row = (AV *)SvRV(*first_row_sv);
    if (SvTYPE(first_row) != SVt_PVAV) {
        croak("First row is not an array reference");
        return -1;
    }

    return av_count(first_row);
}

/**
  * Verification and Testing Functions
  * ChatGPT Generated
*/

/* Helper function to check if an SV is an array reference */
bool is_array_ref(SV *sv) {
    return SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV;
}

/* Verify if a Perl variable is a valid 1D array reference */
void PerlOMP_VERIFY_1D_Array(SV *array) {
    if (!is_array_ref(array)) {
        croak("Expected a 1D array reference");
    }
}

/* Verify if a Perl variable is a valid 2D array of arrays reference */
void PerlOMP_VERIFY_2D_AoA(SV *AoA) {
    if (!is_array_ref(AoA)) {
        croak("Expected a 2D array reference");
    }
    AV *outer = (AV *)SvRV(AoA);
    I32 len = av_len(outer) + 1;
    for (I32 i = 0; i < len; i++) {
        SV **inner_ref = av_fetch(outer, i, 0);
        if (!inner_ref || !is_array_ref(*inner_ref)) {
            croak("Expected a 2D array with valid inner array references at index %d", i);
        }
    }
}

/* Checks if an SV is an integer, allowing for stored floats that are whole numbers */
bool is_int(SV *sv) {
    return SvIOK(sv) || (SvNOK(sv) && SvIV(sv) == SvNV(sv));
}

/* Checks if an SV is a float, including cases where Perl stores it as an integer */
bool is_float(SV *sv) {
    return SvNOK(sv) || (SvIOK(sv) && SvIV(sv) != SvNV(sv));
}

/* Checks if an SV is a string, ensuring it's not just a numeric representation */
bool is_string(SV *sv) {
    return SvPOK(sv) || (!SvNOK(sv) && !SvIOK(sv));
}

void verify_1D_array_type(SV *array, bool (*type_check)(SV *), const char *type_name) {
    if (!is_array_ref(array)) {
        croak("Expected a 1D array reference");
    }
    AV *av = (AV *)SvRV(array);
    I32 len = av_len(av);
    if (len == -1) return;  // Handle empty arrays safely
    len++;  // Convert last index to total count

    for (I32 i = 0; i < len; i++) {
        SV **element = av_fetch(av, i, 0);
        if (!element || !*element || !type_check(*element)) {
            croak("Expected all elements to be %s at index %" IVdf, type_name, (IV)i);
        }
    }
}

/* Implement type-specific 1D array verifications */
void PerlOMP_VERIFY_1D_FLOAT_ARRAY(SV *array) { verify_1D_array_type(array, is_float, "float"); }
void PerlOMP_VERIFY_1D_INT_ARRAY(SV *array) { verify_1D_array_type(array, is_int, "integer"); }
void PerlOMP_VERIFY_1D_STRING_ARRAY(SV *array) { verify_1D_array_type(array, is_string, "string"); }

/* Generic function to verify a 2D array's element type */
void verify_2D_array_type(SV *AoA, bool (*type_check)(SV *), const char *type_name) {
    PerlOMP_VERIFY_2D_AoA(AoA);  // Assuming this macro validates AoA correctly

    if (!is_array_ref(AoA)) {
        croak("Expected a 2D array reference");
    }

    AV *outer = (AV *)SvRV(AoA);
    I32 rows = av_len(outer);
    if (rows == -1) return;  // Handle empty outer array safely
    rows++;  // Convert last index to total count

    for (I32 i = 0; i < rows; i++) {
        SV **inner_ref = av_fetch(outer, i, 0);
        if (!inner_ref || !*inner_ref || !is_array_ref(*inner_ref)) {
            croak("Expected an array reference at row %" IVdf, (IV)i);
        }

        AV *inner = (AV *)SvRV(*inner_ref);
        I32 cols = av_len(inner);
        if (cols == -1) continue;  // Handle empty inner arrays safely
        cols++;  // Convert last index to total count

        for (I32 j = 0; j < cols; j++) {
            SV **element = av_fetch(inner, j, 0);
            if (!element || !*element || !type_check(*element)) {
                croak("Expected all elements to be %s at [%" IVdf "][%" IVdf "]", type_name, (IV)i, (IV)j);
            }
        }
    }
}

/* Implement type-specific 2D array verifications */
void PerlOMP_VERIFY_2D_FLOAT_ARRAY(SV *AoA) { verify_2D_array_type(AoA, is_float, "float"); }
void PerlOMP_VERIFY_2D_INT_ARRAY(SV *AoA) { verify_2D_array_type(AoA, is_int, "integer"); }
void PerlOMP_VERIFY_2D_STRING_ARRAY(SV *AoA) { verify_2D_array_type(AoA, is_string, "string"); }
