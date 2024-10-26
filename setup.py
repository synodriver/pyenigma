# -*- coding: utf-8 -*-
import os
import re
import sys
from collections import defaultdict

from Cython.Build import cythonize
from Cython.Compiler.Version import version as cython_version
from packaging.version import Version
from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext

BUILD_ARGS = defaultdict(lambda: ["-O3", "-g0"])

for compiler, args in [
    ("msvc", ["/EHsc", "/DHUNSPELL_STATIC", "/Oi", "/O2", "/Ot"]),
    ("gcc", ["-O3", "-g0"]),
]:
    BUILD_ARGS[compiler] = args


class build_ext_compiler_check(build_ext):
    def build_extensions(self):
        compiler = self.compiler.compiler_type
        args = BUILD_ARGS[compiler]
        for ext in self.extensions:
            ext.extra_compile_args.extend(args)
        super().build_extensions()


define_macros = [
    ("ENIGMA_MALLOC0", "PyMem_RawMalloc"),
    ("ENIGMA_FREE", "PyMem_RawFree"),
    ("ENIGMA_EXTRA_HEADER", '"Python.h"'),
]

if (
    sys.version_info > (3, 13, 0)
    and hasattr(sys, "_is_gil_enabled")
    and not sys._is_gil_enabled()
):
    print("build nogil")
    define_macros.append(
        ("Py_GIL_DISABLED", "1"),
    )  # ("CYTHON_METH_FASTCALL", "1"), ("CYTHON_VECTORCALL",  1)]

extensions = [
    Extension(
        "pyenigma._enigma",
        ["pyenigma/_enigma.pyx", "./dep/src/enigma.c"],
        include_dirs=[f"./dep/src"],
        library_dirs=[f"./dep/src"],
        define_macros=define_macros,
    ),
]


def get_dis():
    with open("README.markdown", "r", encoding="utf-8") as f:
        return f.read()


def get_version() -> str:
    path = os.path.join(
        os.path.abspath(os.path.dirname(__file__)), "pyenigma", "__init__.py"
    )
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    result = re.findall(r"(?<=__version__ = \")\S+(?=\")", data)
    return result[0]


packages = find_packages(exclude=("test", "tests.*", "test*"))


compiler_directives = {
    "cdivision": True,
    "embedsignature": True,
    "boundscheck": False,
    "wraparound": False,
}


if Version(cython_version) >= Version("3.1.0a0"):
    compiler_directives["freethreading_compatible"] = True


def main():
    version: str = get_version()
    dis = get_dis()
    setup(
        name="pyenigma",
        version=version,
        url="https://github.com/synodriver/pyenigma",
        packages=packages,
        keywords=["enigma"],
        description="enigma encrypt and decrypt",
        long_description_content_type="text/markdown",
        long_description=dis,
        author="synodriver",
        author_email="diguohuangjiajinweijun@gmail.com",
        python_requires=">=3.6",
        install_requires=["cython"],
        license="BSD",
        classifiers=[
            "Development Status :: 4 - Beta",
            "Operating System :: OS Independent",
            "License :: OSI Approved :: BSD License",
            "Programming Language :: C",
            "Programming Language :: Cython",
            "Programming Language :: Python",
            "Programming Language :: Python :: 3.8",
            "Programming Language :: Python :: 3.9",
            "Programming Language :: Python :: 3.10",
            "Programming Language :: Python :: 3.11",
            "Programming Language :: Python :: 3.12",
            "Programming Language :: Python :: 3.13",
            "Programming Language :: Python :: Implementation :: CPython",
        ],
        include_package_data=True,
        zip_safe=False,
        cmdclass={"build_ext": build_ext_compiler_check},
        ext_modules=cythonize(
            extensions,
            compiler_directives=compiler_directives,
        ),
    )


if __name__ == "__main__":
    main()
