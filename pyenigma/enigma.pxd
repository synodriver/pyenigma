# cython: language_level=3
from libc.stdint cimport uint8_t


cdef extern from "enigma.h" nogil:
    """
uint8_t reflect(void *ud, uint8_t c)
{
    if (c % 2 == 0) // 0, 2, 254
    {
        return c + 1;
    }
    else
    {
        return c - 1;
    }
}

uint8_t replace(void *ud, uint8_t c)
{
    return c;
}
    """
    ctypedef int bool
    ctypedef struct enigma_machine_t:
        size_t encode_count
        size_t rollers
        uint8_t *offset # roller offset len=rollers
        uint8_t *forward_maps # rollers*256
        uint8_t *reverse_maps # rollers*256
        uint8_t (*reflect_func)(void *, uint8_t)

        # f(f(x))==x f(x)!=x
        void *reflect_ud

        uint8_t (*replace_func)(void *, uint8_t)

        # f(f(x))==x
        void *replace_ud

    enigma_machine_t * enigma_machine_new(const uint8_t *maps, size_t mapsize,
                       uint8_t (*reflect_func)(void *, uint8_t),
                       void *reflect_ud,
                       uint8_t (*replace_func)(void *, uint8_t),
                       void *replace_ud)

    void enigma_machine_del(enigma_machine_t *self)

    void enigma_machine_roll(enigma_machine_t *self, size_t idx, int count)

    void enigma_machine_encode_into(enigma_machine_t *self, const uint8_t *data, size_t len_, uint8_t *out)

    void enigma_machine_encode_inplace(enigma_machine_t *self, uint8_t *data, size_t len_)

    enigma_machine_t * enigma_machine_dup(enigma_machine_t *self)

    bool enigma_machine_test_replace(enigma_machine_t *self)

    bool enigma_machine_test_reflect(enigma_machine_t *self)

    void enigma_machine_dump_replace_table(enigma_machine_t *self, uint8_t *out)

    void enigma_machine_dump_reflect_table(enigma_machine_t *self, uint8_t *out)