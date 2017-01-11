# Copyright (C) 2017 Bohdan Khomtchouk and Kasra A. Vand
# This file is part of Matchmaker.

# -------------------------------------------------------------------------------------------

from distutils.core import setup
from Cython.Build import cythonize

setup(name='general functions',
      ext_modules=cythonize("similarity.pyx"),
      )
