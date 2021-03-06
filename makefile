# minimalist makefile
.SUFFIXES:
.PHONY: all clean
#
.SUFFIXES: .cpp .o .c .h
CFLAGS= -fPIC -std=c99 -Wall -Wextra -Wshadow
ifeq ($(DEBUG),1)
CFLAGS += -ggdb -fsanitize=undefined  -fno-omit-frame-pointer -fsanitize=address
else
CFLAGS += -O3
endif # debug

CFLAGS_ICC=
CFLAGS_GCC=

ifeq ($(SSE),1)
CFLAGS += -msse -march=native
else
ifeq ($(AVX512),1)
CFLAGS += -DHAVE_AVX2_INSTRUCTIONS -DHAVE_AVX512_INSTRUCTIONS
CFLAGS_GCC += -mavx512vbmi -march=native
CFLAGS_ICC += -xCORE-AVX512
else
ifeq ($(AVX512F),1)
CFLAGS += -DHAVE_AVX2_INSTRUCTIONS -DHAVE_AVX512F_INSTRUCTIONS
CFLAGS_GCC += -mavx512f -march=native
CFLAGS_ICC += -xCOMMON-AVX512
else # AVX2
CFLAGS += -march=native -DHAVE_AVX2_INSTRUCTIONS
CFLAGS_GCC += -mavx2
CFLAGS_ICC += -march=core-avx2
endif # AVX512F
endif # AVX512
endif # SSE

ifneq ($(NOPOPCNT),1)
CFLAGS += -DHAVE_POPCNT_INSTRUCTION
endif

ifeq ($(CC),icc)
CFLAGS += $(CFLAGS_ICC)
else
CFLAGS += $(CFLAGS_GCC)
endif

all: unit basic_benchmark jaccard_benchmark bitset_benchmark


HEADERS=./include/avx_hamming_weight.h \
        ./include/hamming_weight.h \
        ./include/popcnt_hamming_weight.h \
        ./include/scalar_hamming_weight.h \
        ./include/tabulated_hamming_weight.h \
        ./include/avx_harley_seal_hamming_weight.h \
        ./include/config.h \
        ./include/avx512_hamming_weight.h \
        ./include/avx512f_hamming_weight.h \
        ./include/sse_hamming_weight.h \
        ./include/sse_jaccard_index.h \
        ./include/jaccard_index.h \
        ./include/sse_jaccard_index.h \
        ./include/sse_harley_seal_hamming_weight.h

OBJECTS= avx_hamming_weight.o popcnt_hamming_weight.o scalar_hamming_weight.o \
		tabulated_hamming_weight.o avx_harley_seal_hamming_weight.o \
		avx512_hamming_weight.o \
		avx512f_hamming_weight.o \
		sse_hamming_weight.o  sse_harley_seal_hamming_weight.o 

BITSET_OBJ = avx_bitset.o popcnt_bitset.o scalar_bitset.o
		

JACCARD_OBJ=sse_jaccard_index.o \
		popcnt_jaccard_index.o \
		scalar_jaccard_index.o \
        avx_jaccard_index.o

%.o: ./src/%.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -Iinclude


basic_benchmark: ./benchmarks/basic_benchmark.c  ./benchmarks/benchmark.h  $(HEADERS) $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ ./benchmarks/basic_benchmark.c -Iinclude  $(OBJECTS)

jaccard_benchmark: ./benchmarks/jaccard_benchmark.c  ./benchmarks/benchmark.h  $(HEADERS) $(JACCARD_OBJ)
	$(CC) $(CFLAGS) -o $@ ./benchmarks/jaccard_benchmark.c -Iinclude  $(JACCARD_OBJ)

bitset_benchmark: ./benchmarks/bitset_benchmark.c  ./benchmarks/benchmark.h  $(HEADERS) $(BITSET_OBJ)
	$(CC) $(CFLAGS) -o $@ ./benchmarks/bitset_benchmark.c -Iinclude  $(BITSET_OBJ)

unit: ./tests/unit.c  $(HEADERS) $(OBJECTS)
	$(CC) $(CFLAGS) -o unit ./tests/unit.c -Iinclude  $(OBJECTS)


avx512: basic_benchmark
	sde -cnl -- ./basic_benchmark

clean:
	rm -f unit jaccard_benchmark basic_benchmark *.o
