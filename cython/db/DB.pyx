import cython
cimport cython
from libcpp.pair cimport pair
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map
from libcpp.string cimport string
import numpy as np
cimport numpy as np
cimport cpython
import os
import imp
from cpython.ref cimport PyObject
from cpython.cobject cimport PyCObject_FromVoidPtr

cdef class DB:
  """ 
  Maintains the map from (relation names -> (len,data)
  """
  cdef:
    cdef unordered_map[string,void*]* _dbmap
    cdef string _folder

  def query(self,libname):
    os.system("cd $EMPTYHEADED_HOME/cython/query && ./build.sh && cd -")

    imp.acquire_lock()
    fname = os.path.expandvars("$EMPTYHEADED_HOME/cython/query/Query")+".so"
    mod = imp.load_dynamic("Query",fname)
    imp.release_lock()

    voidptr = PyCObject_FromVoidPtr(self._dbmap,NULL) #FIXME add destructor
    return mod.c_query(voidptr)

  def load(self,libname):
    os.system("cd $EMPTYHEADED_HOME/cython/load && ./build.sh && cd -")

    imp.acquire_lock()
    fname = os.path.expandvars("$EMPTYHEADED_HOME/cython/load/PTrie")+".so"
    mod = imp.load_dynamic("PTrie",fname)
    imp.release_lock()

    voidptr = PyCObject_FromVoidPtr(self._dbmap,NULL) #FIXME add destructor
    return mod.PTrie(voidptr)

  def create(self,relations,dbhash):
    imp.acquire_lock()
    fname = self._folder+"/libs/createDB/DFMap_"+dbhash+".so"
    mod = imp.load_dynamic("DFMap_"+dbhash,fname)
    imp.release_lock()
    return eval("mod.DFMap_"+dbhash+"(relations)")

  def __cinit__(DB self):
  # Initialize the "this pointer" to NULL so __dealloc__
  # knows if there is something to deallocate. Do not 
  # call new TestClass() here.
    self._dbmap = NULL

  def __init__(DB self,string folder):
    self._dbmap = new unordered_map[string,void*]()
    self._folder = folder

  def __dealloc__(DB self):
    # Only call del if the C++ object is alive, 
    # or we will get a segfault.
    if self._dbmap != NULL:
      del self._dbmap

  cdef int _check_alive(DB self) except -1:
    # Beacuse of the context manager protocol, the C++ object
    # might die before DB self is reclaimed.
    # We therefore need a small utility to check for the
    # availability of self._dbmap
    if self._dbmap == NULL:
      raise RuntimeError("Wrapped C++ object is deleted")
    else:
      return 0    


  # The context manager protocol allows us to precisely
  # control the liftetime of the wrapped C++ object. del
  # is called deterministically and independently of 
  # the Python garbage collection.

  def __enter__(DB self):
    self._check_alive()
    return self

  def __exit__(DB self, exc_tp, exc_val, exc_tb):
    if self._dbmap != NULL:
      del self._dbmap
    self._dbmap = NULL # inform __dealloc__
    return False # propagate exceptions