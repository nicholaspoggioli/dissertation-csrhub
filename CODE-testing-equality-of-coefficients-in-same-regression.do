*** Coefficients x1 and x2 are unequal, x3 and x4 are equal
clear all
set obs 1000

gen x1 = rnormal(2)
gen x2 = rnormal(5,3)
gen x3 = rnormal()
gen x4 = rnormal(3,2)
gen e = rnormal()
gen y = 1 + .3*x1 + .5*x2 + .4*x3 + .4*x4 + e

* regress
reg y x1 x2 x3 x4

* x1 and x2 are different: test should reject the null
testparm x1 x2, equal

* x3 and x4 are equal: test should not reject the null
testparm x3 x4, equal
