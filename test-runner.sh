#!/usr/bin/env bash

mkdir -p blib/lib/auto/share/dist/OpenMP-Simple/ > /dev/null 2>&1
cp -f share/openmp-simple.h blib/lib/auto/share/dist/OpenMP-Simple/openmp-simple.h
cp -f share/ppport.h blib/lib/auto/share/dist/OpenMP-Simple/ppport.h
PERL_DL_NONLAZY=1 perl -Ilib -MExtUtils::Command::MM -MTest::Harness -e "undef *Test::Harness::Switches; test_harness(1, 'blib/lib', 'blib/arch')" t/*.t | grep '\.\.\.\.'
