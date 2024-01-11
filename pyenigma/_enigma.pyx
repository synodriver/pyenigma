# cython: language_level=3
cimport cython
from cpython.bytes cimport PyBytes_AS_STRING, PyBytes_FromStringAndSize
from libc.stdint cimport uint8_t

from pyenigma.enigma cimport (enigma_machine_del,
                              enigma_machine_dump_reflect_table,
                              enigma_machine_dump_replace_table,
                              enigma_machine_dup,
                              enigma_machine_encode_inplace,
                              enigma_machine_encode_into, enigma_machine_new,
                              enigma_machine_roll, enigma_machine_t,
                              enigma_machine_test_reflect,
                              enigma_machine_test_replace)


cdef uint8_t reflect_func_c(void* ud, uint8_t c) noexcept with gil:
    cdef object func = <object>ud
    return func(c)

@cython.no_gc
@cython.freelist(8)
@cython.final
cdef class EnigmaMachine:
    cdef:
        enigma_machine_t *m
        object reflect_func
        object replace_func

    def __init__(self, const uint8_t[::1] maps, object reflect_func, object replace_func):
        self.reflect_func = reflect_func
        self.replace_func = replace_func
        self.m = enigma_machine_new(&maps[0],
                                    <size_t>maps.shape[0],
                                    reflect_func_c, <void*>reflect_func,
                                    reflect_func_c, <void*>replace_func)
        if self.m == NULL:
            raise MemoryError

    def __dealloc__(self):
        if self.m:
            enigma_machine_del(self.m)
            self.m = NULL
    @property
    def encode_count(self):
        return self.m.encode_count

    @property
    def rollers(self):
        return self.m.rollers

    @property
    def current_position(self):
        cdef bytes data = PyBytes_FromStringAndSize(<char*>self.m.offset, <Py_ssize_t>self.m.rollers)
        return [d for d in data]

    cpdef inline roll(self, size_t idx, int count):
        with nogil:
            enigma_machine_roll(self.m, idx, count)

    cpdef inline encode_into(self, const uint8_t[::1] data, uint8_t[::1] dst):
        with nogil:
            enigma_machine_encode_into(self.m, &data[0], <size_t>data.shape[0], &dst[0])

    cpdef inline encode_inplace(self, uint8_t[::1] data):
        with nogil:
            enigma_machine_encode_inplace(self.m, &data[0], <size_t>data.shape[0])

    cpdef inline EnigmaMachine dup(self):
        cdef enigma_machine_t *obj
        with nogil:
            obj = enigma_machine_dup(self.m)
        cdef EnigmaMachine newmachine = EnigmaMachine.__new__(EnigmaMachine)
        newmachine.m = obj
        newmachine.reflect_func = self.reflect_func
        newmachine.replace_func = self.replace_func
        return newmachine

    cpdef inline bint test_replace(self):
        cdef bint ret
        with nogil:
            ret=enigma_machine_test_replace(self.m)
        if not ret:
            raise ValueError("check replace callback failed")
        return ret

    cpdef inline bint test_reflect(self):
        cdef bint ret
        with nogil:
            ret=enigma_machine_test_reflect(self.m)
        if not ret:
            raise ValueError("check reflect callback failed")
        return ret

    cpdef inline bytes dump_reflect_table(self):
        cdef bytes out = PyBytes_FromStringAndSize(NULL, 256)
        cdef uint8_t *ptr = <uint8_t *>PyBytes_AS_STRING(out)
        with nogil:
            enigma_machine_dump_reflect_table(self.m, ptr)
        return out

    cpdef inline bytes dump_replace_table(self):
        cdef bytes out = PyBytes_FromStringAndSize(NULL, 256)
        cdef uint8_t *ptr = <uint8_t *> PyBytes_AS_STRING(out)
        with nogil:
            enigma_machine_dump_replace_table(self.m, ptr)
        return out
