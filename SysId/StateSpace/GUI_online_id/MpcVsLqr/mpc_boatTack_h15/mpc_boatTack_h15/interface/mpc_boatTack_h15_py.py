#mpc_boatTack_h15 : A fast customized optimization solver.
#
#Copyright (C) 2013-2015 EMBOTECH GMBH [info@embotech.com]. All rights reserved.
#
#
#This software is intended for simulation and testing purposes only. 
#Use of this software for any commercial purpose is prohibited.
#
#This program is distributed in the hope that it will be useful.
#EMBOTECH makes NO WARRANTIES with respect to the use of the software 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
#PARTICULAR PURPOSE. 
#
#EMBOTECH shall not have any liability for any damage arising from the use
#of the software.
#
#This Agreement shall exclusively be governed by and interpreted in 
#accordance with the laws of Switzerland, excluding its principles
#of conflict of laws. The Courts of Zurich-City shall have exclusive 
#jurisdiction in case of any dispute.
#
#def __init__():
'''
a Python wrapper for a fast solver generated by FORCES Pro

   OUTPUT = mpc_boatTack_h15_py.mpc_boatTack_h15_solve(PARAMS) solves a multistage problem
   subject to the parameters supplied in the following dictionary:
       PARAMS['minusAExt_times_x0'] - column vector of length 3
       PARAMS['Hessians'] - column vector of length 4
       PARAMS['HessiansFinal'] - matrix of size [4 x 4]
       PARAMS['lowerBound'] - column vector of length 2
       PARAMS['upperBound'] - column vector of length 2
       PARAMS['C'] - matrix of size [3 x 4]
       PARAMS['D'] - matrix of size [3 x 4]

   OUTPUT returns the values of the last iteration of the solver where
       OUTPUT['u0'] - column vector of size 1

   [OUTPUT, EXITFLAG] = mpc_boatTack_h15_py.mpc_boatTack_h15_solve(PARAMS) returns additionally
   the integer EXITFLAG indicating the state of the solution with 
       1 - Optimal solution has been found (subject to desired accuracy)
       0 - Maximum number of interior point iterations reached
      -7 - Line search could not progress

   [OUTPUT, EXITFLAG, INFO] = mpc_boatTack_h15_py.mpc_boatTack_h15_solve(PARAMS) returns 
   additional information about the last iterate:
       INFO.it        - number of iterations that lead to this result
       INFO.res_eq    - max. equality constraint residual
       INFO.res_ineq  - max. inequality constraint residual
       INFO.pobj      - primal objective
       INFO.dobj      - dual objective
       INFO.dgap      - duality gap := pobj - dobj
       INFO.rdgap     - relative duality gap := |dgap / pobj|
       INFO.mu        - duality measure
       INFO.sigma     - centering parameter
       INFO.lsit_aff  - iterations of affine line search
       INFO.lsit_cc   - iterations of line search (combined direction)
       INFO.step_aff  - step size (affine direction)
       INFO.step_cc   - step size (centering direction)
       INFO.solvetime - Time needed for solve (wall clock time)

 See also COPYING

'''

import ctypes
import os
import numpy as np
import numpy.ctypeslib as npct

_lib = ctypes.CDLL(os.path.join(os.getcwd(),'mpc_boatTack_h15/lib/mpc_boatTack_h15.dll')) 
csolver = getattr(_lib,'mpc_boatTack_h15_solve')

class mpc_boatTack_h15_params_ctypes(ctypes.Structure):
#	@classmethod
#	def from_param(self):
#		return self
	_fields_ = [('minusAExt_times_x0', ctypes.c_float * 3),
('Hessians', ctypes.c_float * 16),
('HessiansFinal', ctypes.c_float * 16),
('lowerBound', ctypes.c_float * 2),
('upperBound', ctypes.c_float * 2),
('C', ctypes.c_float * 12),
('D', ctypes.c_float * 12),
]

mpc_boatTack_h15_params = {'minusAExt_times_x0' : np.array([]),
'Hessians' : np.array([]),
'HessiansFinal' : np.array([]),
'lowerBound' : np.array([]),
'upperBound' : np.array([]),
'C' : np.array([]),
'D' : np.array([]),
}


class mpc_boatTack_h15_outputs_ctypes(ctypes.Structure):
#	@classmethod
#	def from_param(self):
#		return self
	_fields_ = [('u0', ctypes.c_float * 1),
]

mpc_boatTack_h15_outputs = {'u0' : np.array([]),
}


class mpc_boatTack_h15_info(ctypes.Structure):
#	@classmethod
#	def from_param(self):
#		return self
	_fields_ = [('it', ctypes.c_int),
('res_eq', ctypes.c_float),
('res_ineq', ctypes.c_float),
('pobj',ctypes.c_float),
('dobj',ctypes.c_float),
('dgap',ctypes.c_float),
('rdgap',ctypes.c_float),
('mu',ctypes.c_float),
('mu_aff',ctypes.c_float),
('sigma',ctypes.c_float),
('lsit_aff', ctypes.c_int),
('lsit_cc', ctypes.c_int),
('step_aff',ctypes.c_float),
('step_cc',ctypes.c_float),
('solvetime',ctypes.c_float)
]


# determine data types for solver function prototype 
csolver.argtypes = ( ctypes.POINTER(mpc_boatTack_h15_params_ctypes), ctypes.POINTER(mpc_boatTack_h15_outputs_ctypes), ctypes.POINTER(mpc_boatTack_h15_info) )
csolver.restype = ctypes.c_int

def mpc_boatTack_h15_solve(params):
	'''
a Python wrapper for a fast solver generated by FORCES Pro

   OUTPUT = mpc_boatTack_h15_py.mpc_boatTack_h15_solve(PARAMS) solves a multistage problem
   subject to the parameters supplied in the following dictionary:
       PARAMS['minusAExt_times_x0'] - column vector of length 3
       PARAMS['Hessians'] - column vector of length 4
       PARAMS['HessiansFinal'] - matrix of size [4 x 4]
       PARAMS['lowerBound'] - column vector of length 2
       PARAMS['upperBound'] - column vector of length 2
       PARAMS['C'] - matrix of size [3 x 4]
       PARAMS['D'] - matrix of size [3 x 4]

   OUTPUT returns the values of the last iteration of the solver where
       OUTPUT['u0'] - column vector of size 1

   [OUTPUT, EXITFLAG] = mpc_boatTack_h15_py.mpc_boatTack_h15_solve(PARAMS) returns additionally
   the integer EXITFLAG indicating the state of the solution with 
       1 - Optimal solution has been found (subject to desired accuracy)
       0 - Maximum number of interior point iterations reached
      -7 - Line search could not progress

   [OUTPUT, EXITFLAG, INFO] = mpc_boatTack_h15_py.mpc_boatTack_h15_solve(PARAMS) returns 
   additional information about the last iterate:
       INFO.it        - number of iterations that lead to this result
       INFO.res_eq    - max. equality constraint residual
       INFO.res_ineq  - max. inequality constraint residual
       INFO.pobj      - primal objective
       INFO.dobj      - dual objective
       INFO.dgap      - duality gap := pobj - dobj
       INFO.rdgap     - relative duality gap := |dgap / pobj|
       INFO.mu        - duality measure
       INFO.sigma     - centering parameter
       INFO.lsit_aff  - iterations of affine line search
       INFO.lsit_cc   - iterations of line search (combined direction)
       INFO.step_aff  - step size (affine direction)
       INFO.step_cc   - step size (centering direction)
       INFO.solvetime - Time needed for solve (wall clock time)

 See also COPYING

	'''
	global _lib

	# convert parameters
	params_py = mpc_boatTack_h15_params_ctypes()
	for par in params:
		try:
			setattr(params_py, par, npct.as_ctypes(np.reshape(params[par],np.size(params[par]),order='F')))
		except:
			raise ValueError('Parameter' + par + 'does not have the appropriate dimensions or data type. Please use numpy arrays for parameters.')
    
	outputs_py = mpc_boatTack_h15_outputs_ctypes()
	info_py = mpc_boatTack_h15_info()
	try:
		exitflag = _lib.mpc_boatTack_h15_solve( params_py, ctypes.byref(outputs_py), ctypes.byref(info_py) )
	except:
		#print 'Problem with solver'
		raise

	# convert outputs
	for out in mpc_boatTack_h15_outputs:
		mpc_boatTack_h15_outputs[out] = npct.as_array(getattr(outputs_py,out))

	return mpc_boatTack_h15_outputs,int(exitflag),info_py




