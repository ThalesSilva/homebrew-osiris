class OsirisPic < Formula
  desc      "OSIRIS particle‑in‑cell plasma simulation framework"
  homepage  "https://osiris-code.github.io/"
  url       "https://github.com/osiris-code/osiris/archive/refs/tags/1.0.0.tar.gz"
  sha256    "693b80b250de086f0a33379998dc4abd5b6dbb73ae8bd7811267ea4f54959e0f"
  license   "AGPL-3.0-or-later"

  depends_on "gcc"       # gfortran 14.x
  depends_on "open-mpi"
  depends_on "hdf5-mpi"

  fails_with :clang      # no Fortran front‑end

  def install
    # ─────────────────────────────────────────────────────────────
    # 1. Write a *macOS‑specific* config file from scratch
    #    (<<~EOS dwarf‑heredoc keeps indentation tidy)
    # ─────────────────────────────────────────────────────────────
    (buildpath/"config/osiris_sys.darwin.gnu").write <<~EOS
      PRECISION = SINGLE
      F90 = mpif90
      F03 = $(F90)
      cc  = mpicc
      CC  = mpicc
      FPP = gcc -C -E -x assembler-with-cpp
      DISABLE_PARANOIA = YES
      UNDERSCORE       = FORTRANSINGLEUNDERSCORE
      F90FLAGS_all = -pipe -ffree-line-length-none -fno-range-check
      F90FLAGS_production = $(F90FLAGS_all) -O3
      F90FLAGS_debug      = $(F90FLAGS_all) -g -Og -fbacktrace -fbounds-check \
                            -Wall -fimplicit-none -pedantic \
                            -Wimplicit-interface -Wconversion -Wsurprising \
                            -Wunderflow -ffpe-trap=invalid,zero,overflow
      F90FLAGS_profile    = -g $(F90FLAGS_production)
      CFLAGS_production = -O3 -std=c99
      CFLAGS_debug      = -Og -g -Wall -pedantic -std=c99
      CFLAGS_profile    = -g $(CFLAGS_production)
      MPI_FCOMPILEFLAGS =
      MPI_FLINKFLAGS    =
      H5_ROOT          = #{Formula["hdf5-mpi"].opt_prefix}
      H5_FCOMPILEFLAGS = -I$(H5_ROOT)/include
      H5_FLINKFLAGS    = -L$(H5_ROOT)/lib -lhdf5_fortran -lhdf5 -lm
    EOS

    inreplace "source/Makefile.config-info","@python ", "@python3 "
    
    ENV.deparallelize
    system "./configure", "-d", "1", "-s", "darwin.gnu"
    system "make"
    system "./configure", "-d", "2", "-s", "darwin.gnu"
    system "make"
    system "./configure", "-d", "3", "-s", "darwin.gnu"
    system "make"    
    bin.install Dir["bin/*"]
    testdir = buildpath/"test"
    testdir = buildpath/"tests" unless testdir.exist?
    pkgshare.install testdir if testdir.exist?
  end

  # ───────────────────────────── tests ───────────────────────────
  test do
    assert_match "OSIRIS", shell_output("#{bin}/osiris-1D.e -v 2>&1")
  end

  # ───────────────────────── livecheck ───────────────────────────
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end
end

