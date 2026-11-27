// SPDX-License-Identifier: MIT
#if !(defined(GO) && defined(GOM) && defined(GO2) && defined(DATA))
#error meh!
#endif

// Complex numbers are passed in as an address in the stack

GOW(acos, dEd)
GOW(acosf, fEf)
GOM(__acosf_finite, fEf) //%noE
GOM(__acos_finite, dEd)  //%noE
GOW(acosh, dEd)
GOW(acoshf, fEf)
GOM(__acoshf_finite, fEf) //%noE
GOM(__acosh_finite, dEd)  //%noE
#ifdef HAVE_LD80BITS
GOW(acoshl, DED)
#else
GOW2(acoshl, KEK, acosh)
#endif
#ifdef HAVE_LD80BITS
GOW(acosl, DED)
#else
GOW2(acosl, KEK, acos)
#endif
GOW(asin, dEd)
GOW(asinf, fEf)
GOM(__asinf_finite, fEf) //%noE
GOM(__asin_finite, dEd)  //%noE
GOW(asinh, dEd)
GOW(asinhf, fEf)
#ifdef HAVE_LD80BITS
GOW(asinhl, DED)
#else
GOW2(asinhl, KEK, asinh)
#endif
#ifdef HAVE_LD80BITS
GOW(asinl, DED)
#else
GOW2(asinl, KEK, asin)
#endif
GO(atan, dEd)
#ifdef HAVE_LD80BITS
GO(atanl, DED)
#else
GO2(atanl, KEK, atan)
#endif
GOW(atan2, dEdd)
#ifdef HAVE_LD80BITS
GOW(atan2l, DEDD)
#else
GOW2(atan2l, KEKK, atan2)
#endif
GOW(atan2f, fEff)
GOM(__atan2f_finite, fEff) //%noE
GOM(__atan2_finite, dEdd)  //%noE
// atan2l   // Weak
GOW(atanf, fEf)
GOW(atanh, dEd)
GOW(atanhf, fEf)
// __atanhf_finite
// __atanh_finite
#ifdef HAVE_LD80BITS
GOW(atanhl, DED)
#else
GOW2(atanhl, KEK, atanh)
#endif
// atanl    // Weak
GOW(cabs, dEdd)     // only 1 arg, but is a double complex
GOW(cabsf, fEff)    // only 1 arg, but is a float complex
// cabsl    // Weak
//GOWS(cacos, pEps)   //%% complex
GOWM(cacosf, UEs)   //%noE
//GOWS(cacosh, pEps)  //%% complex
GOWM(cacoshf, UEs)  //%noE
// cacoshl  // Weak
// cacosl   // Weak
//GOW(carg, dEdd)     // 1arg, double complex
GOW(cargf, fEff)    // 1arg, float complex
// cargl    // Weak
//GOWS(casin, pEps)   //%%  complex
GOWM(casinf, UEs)   //%noE
//GOWS(casinh, pEps)  //%%  complex
GOWM(casinhf, UEs)  //%noE
// casinhl  // Weak
// casinl   // Weak
//GOWS(catan, pEps)   //%%   complex
GOWM(catanf, UEs)   //%noE
//GOWS(catanh, pEps)  //%%   complex
GOWM(catanhf, UEs)  //%noE
// catanhl  // Weak
// catanl   // Weak
GOW(cbrt, dEd)
GOW(cbrtf, fEf)
#ifdef HAVE_LD80BITS
GOW(cbrtl, DED)
#else
GOW2(cbrtl, KEK, cbrt)
#endif
//GOWS(ccos, pEps)    //%%   return complex
GOWM(ccosf, UEs)    //%noE return complex
//GOWS(ccosh, pEps)   //%%   return complex
GOWM(ccoshf, UEs)   //%noE return complex
// ccoshl   // Weak
// ccosl    // Weak
GOW(ceil, dEd)
#ifdef HAVE_LD80BITS
GOW(ceill, DED)
#else
GOW2(ceill, KEK, ceil)
#endif
GOW(ceilf, fEf)
// ceill    // Weak
//GOWS(cexp, pEps)     //%%   return complex
GOWM(cexpf, UEs)     //%noE return complex
// cexpl    // Weak
// cimag    // Weak
// cimagf   // Weak
// cimagl   // Weak
//GOS(clog, pEps)   //%% return a double complex, so ret 4
// clog10   // Weak
// __clog10
// clog10f  // Weak
// __clog10f
// clog10l  // Weak
// __clog10l
GOM(clogf, UEs)    //%noE float complex doesn't trigger the ret 4, but returns an u64!
// clogl    // Weak
// conj // Weak
// conjf    // Weak
// conjl    // Weak
GOW(copysign, dEdd)
#ifdef HAVE_LD80BITS
GOW(copysignl, DEDD)
#else
GOW2(copysignl, KEKK, copysign)
#endif
GOW(copysignf, fEff)
// copysignl    // Weak
GOW(cos, dEd)
#ifdef HAVE_LD80BITS
GOW(cosl, DED)
#else
GOW2(cosl, KEK, cos)
#endif
GOW(cosf, fEf)
GOW(cosh, dEd)
#ifdef HAVE_LD80BITS
GOW(coshl, DED)
#else
GOW2(coshl, KEK, cosh)
#endif
GOW(coshf, fEf)
GOM(__coshf_finite, fEf) //%noE
GOM(__cosh_finite, dEd)  //%noE
// coshl    // Weak
// cosl // Weak
//GOWS(cpow, pEpsvvvvs) //%% return complex
GOWM(cpowf, UEsvvs)   //%noE
// cpowl    // Weak
//GOS(cproj, pEps)    //%%   double complex
GOM(cprojf, UEs)    //%noE
// cprojl   // Weak
// creal    // Weak
// crealf   // Weak
// creall   // Weak
//GOWS(csin, pEps)    //%%   return complex
GOWM(csinf, UEs)    //%noE return complex
//GOWS(csinh, pEps)   //%%   return complex
GOWM(csinhf, UEs)   //%noE return complex
// csinhl   // Weak
// csinl    // Weak
//GOWS(csqrt, pEps)   //%%
GOWM(csqrtf, UEs)   //%noE
// csqrtl   // Weak
//GOWS(ctan, pEps)    //%%   return complex
GOWM(ctanf, UEs)    //%noE return complex
//GOWS(ctanh, pEps)   //%%   return complex
GOWM(ctanhf, UEs)   //%noE return complex
// ctanhl   // Weak
// ctanl    // Weak
// __cxa_finalize  // Weak
GOW(drem, dEdd)
GOW(dremf, fEff)
// dreml    // Weak
GOW(erf, dEd)
GOW(erfc, dEd)
GOW(erfcf, fEf)
#ifdef HAVE_LD80BITS
GOW(erfcl, DED)
#else
GOW2(erfcl, KEK, erfc)
#endif
GOW(erff, fEf)
#ifdef HAVE_LD80BITS
GOW(erfl, DED)
#else
GOW2(erfl, KEK, erf)
#endif
GOW(exp, dEd)
#ifdef HAVE_LD80BITS
GOW(expl, DED)
#else
GOW2(expl, KEK, exp)
#endif
GOW(exp10, dEd)
#ifdef HAVE_LD80BITS
GOW(exp10l, DED)
#else
GOW2(exp10l, KEK, exp10)
#endif
GOW(exp10f, fEf)
// __exp10f_finite
// __exp10_finite
// exp10l   // Weak
GOW(exp2, dEd)
#ifdef HAVE_LD80BITS
GOW(exp2l, DED)
#else
GOW2(exp2l, KEK, exp2)
#endif
GOW(exp2f, fEf)
GOM(__exp2f_finite, fEf) //%noE
GOM(__exp2_finite, dEd)  //%noE
// exp2l    // Weak
GOW(expf, fEf)
GOM(__expf_finite, fEf) //%noE
GOM(__exp_finite, dEd)  //%noE
// expl // Weak
GOW(expm1, dEd)
#ifdef HAVE_LD80BITS
GOW(expm1l, DED)
#else
GOW2(expm1l, KEK, expm1)
#endif
GOW(expm1f, fEf)
// expm1l   // Weak
GOW(fabs, dEd)
#ifdef HAVE_LD80BITS
GOW(fabsl, DED)
#else
GOW2(fabsl, KEK, fabs)
#endif
GOW(fabsf, fEf)
// fabsl    // Weak
GOW(fdim, dEdd)
#ifdef HAVE_LD80BITS
GOW(fdiml, DEDD)
#else
GOW2(fdiml, KEKK, fdim)
#endif
GOW(fdimf, fEff)
// fdiml    // Weak
GO2(feclearexcept, iEEi, my_feclearexcept)
GO(fedisableexcept, iEi)
GO(feenableexcept, iEi)
GO(fegetenv, iEp)
GO(fegetexcept, iEv)
GO2(fegetexceptflag, iEEpi, my_fegetexceptflag)
GO2(fegetround, iEEv, my_fegetround)
GO(feholdexcept, iEp)
GO2(feraiseexcept, iEEi, my_feraiseexcept)
GOM(fesetenv, iEEp)
GO2(fesetexceptflag, iEEpi, my_fesetexceptflag)
GO2(fesetround, iEEi, my_fesetround)
GO2(fetestexcept, iEEi, my_fetestexcept)
GOM(feupdateenv, iEEp)
GOW(finite, iEd)
// __finite
GOW(finitef, iEf)
GO(__finitef, iEf)
// finitel  // Weak
// __finitel
GOW(floor, dEd)
#ifdef HAVE_LD80BITS
GOW(floorl, DED)
#else
GOW2(floorl, KEK, floor)
#endif
GOW(floorf, fEf)
// floorl   // Weak
GOW(fma, dEddd)
#ifdef HAVE_LD80BITS
GOW(fmal, DEDDD)
#else
GOW2(fmal, KEKKK, fma)
#endif
GOW(fmaf, fEfff)
// fmal // Weak
GOW(fmax, dEdd)
#ifdef HAVE_LD80BITS
GOW(fmaxl, DEDD)
#else
GOW2(fmaxl, KEKK, fmax)
#endif
GOW(fmaxf, fEff)
// fmaxl    // Weak
GOW(fmin, dEdd)
#ifdef HAVE_LD80BITS
GOW(fminl, DEDD)
#else
GOW2(fminl, KEKK, fmin)
#endif
GOW(fminf, fEff)
// fminl    // Weak
GOW(fmod, dEdd)
GOW(fmodf, fEff)
// __fmodf_finite
// __fmod_finite
#ifdef HAVE_LD80BITS
GOW(fmodl, DEDD)
#else
GOW2(fmodl, KEKK, fmod)
#endif
GO(__fpclassify, iEd)
GO(__fpclassifyf, iEf)
GOW(frexp, dEdp)
GOW(frexpf, fEfp)
#ifdef HAVE_LD80BITS
GOW(frexpl, DEDp)
#else
GOW2(frexpl, KEKp, frexp)
#endif
GOW(gamma, dEd)
GOW(gammaf, fEf)
// __gammaf_r_finite
// gammal   // Weak
// __gamma_r_finite
// __gmon_start__  // Weak
GOW(hypot, dEdd)
#ifdef HAVE_LD80BITS
GOW(hypotl, DEDD)
#else
GOW2(hypotl, KEKK, hypot)
#endif
GOW(hypotf, fEff)
GOM(__hypotf_finite, fEff) //%noE
GOM(__hypot_finite, dEdd)  //%noE
// hypotl   // Weak
GOW(ilogb, iEd)
#ifdef HAVE_LD80BITS
GOW(ilogbl, iED)
#else
GOW2(ilogbl, iEK, ilogb)
#endif
GOW(ilogbf, iEf)
// ilogbl   // Weak
// __issignaling
// __issignalingf
// _ITM_deregisterTMCloneTable // Weak
// _ITM_registerTMCloneTable   // Weak
GO(j0, dEd)
GO(j0f, fEf)
// __j0f_finite
// __j0_finite
// j0l
GO(j1, dEd)
GO(j1f, fEf)
// __j1f_finite
// __j1_finite
// j1l
GO(jn, dEid)
GO(jnf, fEif)
// __jnf_finite
// __jn_finite
// jnl
GOW(ldexp, dEdi)
GOW(ldexpf, fEfi)
#ifdef HAVE_LD80BITS
GOW(ldexpl, DEDi)
#else
GOW2(ldexpl, KEKi, ldexp)
#endif
GOW(lgamma, dEd)
GOW(lgammaf, fEf)
GOW(lgammaf_r, fEfp)
// __lgammaf_r_finite
#ifdef HAVE_LD80BITS
GOW(lgammal, DED)
#else
GOW2(lgammal, KEK, lgamma)
#endif
#ifdef HAVE_LD80BITS
GOW(lgammal_r, DEDp)
#else
GOW2(lgammal_r, KEKp, lgamma_r)
#endif
GOW(lgamma_r, dEdp)
// __lgamma_r_finite
DATAV(_LIB_VERSION, 4)
GOW(llrint, IEd)
#ifdef HAVE_LD80BITS
GOW(llrintl, IED)
#else
GOW2(llrintl, IEK, llrint)
#endif
GOW(llrintf, IEf)
// llrintl  // Weak
GOW(llround, IEd)
#ifdef HAVE_LD80BITS
GOW(llroundl, IED)
#else
GOW2(llroundl, IEK, llround)
#endif
GOW(llroundf, IEf)
// llroundl // Weak
GOW(log, dEd)
GOW(log10, dEd)
#ifdef HAVE_LD80BITS
GOW(log10l, DED)
#else
GOW2(log10l, KEK, log10)
#endif
GOW(log10f, fEf)
GOM(__log10f_finite, fEf) //%noE
GOM(__log10_finite, dEd)  //%noE
// log10l   // Weak
GOW(log1p, dEd)
#ifdef HAVE_LD80BITS
GOW(log1pl, DED)
#else
GOW2(log1pl, KEK, log1p)
#endif
GOW(log1pf, fEf)
// log1pl   // Weak
GOW(log2, dEd)
#ifdef HAVE_LD80BITS
GOW(log2l, DED)
#else
GOW2(log2l, KEK, log2)
#endif
GOW(log2f, fEf)
GOM(__log2f_finite, fEf) //%noE
GOM(__log2_finite, dEd)  //%noE
// log2l    // Weak
GOW(logb, dEd)
#ifdef HAVE_LD80BITS
GOW(logbl, DED)
#else
GOW2(logbl, KEK, logb)
#endif
GOW(logbf, fEf)
// logbl    // Weak
GOW(logf, fEf)
GOM(__logf_finite, fEf) //%noE
GOM(__log_finite, dEd)  //%noE
#ifdef HAVE_LD80BITS
GOW(logl, DED)
#else
GOW2(logl, KEK, log)
#endif
GOW(lrint, iEd)
#ifdef HAVE_LD80BITS
GOW(lrintl, iED)
#else
GOW2(lrintl, iEK, lrint)
#endif
GOW(lrintf, iEf)
// lrintl   // Weak
GOW(lround, iEd)
#ifdef HAVE_LD80BITS
GOW(lroundl, iED)
#else
GOW2(lroundl, iEK, lround)
#endif
GOW(lroundf, iEf)
// lroundl  // Weak
// matherr  // Weak
GOW(modf, dEdp)
GOW(modff, fEfp)
// modfl    // Weak
GOW(nan, dEp)
GOW(nanf, fEp)
// nanl // Weak
GOW(nearbyint, dEd)
#ifdef HAVE_LD80BITS
GOW(nearbyintl, DED)
#else
GOW2(nearbyintl, KEK, nearbyint)
#endif
GOW(nearbyintf, fEf)
// nearbyintl   // Weak
GOW(nextafter, dEdd)
#ifdef HAVE_LD80BITS
GOW(nextafterl, DEDD)
#else
GOW2(nextafterl, KEKK, nextafter)
#endif
GOW(nextafterf, fEff)
// nextafterl   // Weak
GOW(nexttoward, dEdD)
#ifdef HAVE_LD80BITS
GOW(nexttowardl, DEDD)
#else
GOW2(nexttowardl, KEKK, nextafter)
#endif
GOW(nexttowardf, fEfD)
// nexttowardl  // Weak
GOW(pow, dEdd)
GOW(pow10, dEd)
GOW(pow10f, fEf)
#ifdef HAVE_LD80BITS
GOWM(pow10l, DED)   //%noE
#else
GOWM(pow10l, KEK)   //%noE
#endif
GOW(powf, fEff)
GOM(__powf_finite, fEff) //%noE
GOM(__pow_finite, dEdd)  //%noE
#ifdef HAVE_LD80BITS
GOW(powl, DEDD)
#else
GOW2(powl, KEKK, pow)
#endif
GOW(remainder, dEdd)
#ifdef HAVE_LD80BITS
GOW(remainderl, DEDD)
#else
GOW2(remainderl, KEKK, remainder)
#endif
GOW(remainderf, fEff)
// __remainderf_finite
// __remainder_finite
// remainderl   // Weak
GOW(remquo, dEddp)
#ifdef HAVE_LD80BITS
GOW(remquol, DEDDp)
#else
GOW2(remquol, KEKKp, remquo)
#endif
GOW(remquof, fEffp)
// remquol  // Weak
GOW(rint, dEd)
#ifdef HAVE_LD80BITS
GOW(rintl, DED)
#else
GOW2(rintl, KEK, rint)
#endif
GOW(rintf, fEf)
// rintl    // Weak
GOW(round, dEd)
#ifdef HAVE_LD80BITS
GOW(roundl, DED)
#else
GOW2(roundl, KEK, round)
#endif
GOW(roundf, fEf)
// roundl   // Weak
GOW(scalb, dEdd)
GOW(scalbf, fEff)
// __scalbf_finite
// __scalb_finite
// scalbl   // Weak
GOW(scalbln, dEdi)
#ifdef HAVE_LD80BITS
GOW(scalblnl, DEDi)
#else
GOW2(scalblnl, KEKi, scalbln)
#endif
GOW(scalblnf, fEfi)
// scalblnl // Weak
GOW(scalbn, dEdi)
GOW(scalbnf, fEfi)
#ifdef HAVE_LD80BITS
GOW(scalbnl, DEDi)
#else
GOW2(scalbnl, KEKi, scalbn)
#endif
// __signbit
// __signbitf
DATAB(signgam, 4)
GOW(significand, dEd)
GOW(significandf, fEf)
// significandl // Weak
GOW(sin, dEd)
#ifdef HAVE_LD80BITS
GOW(sinl, DED)
#else
GOW2(sinl, KEK, sin)
#endif
GOW(sincos, vEdpp)
GOW(sincosf, vEfpp)
// sincosl  // Weak
GOW(sinf, fEf)
GOW(sinh, dEd)
#ifdef HAVE_LD80BITS
GOW(sinhl, DED)
#else
GOW2(sinhl, KEK, sinh)
#endif
GOW(sinhf, fEf)
GOM(__sinhf_finite, fEf) //%noE
GOM(__sinh_finite, dEd)  //%noE
// sinhl    // Weak
// sinl // Weak
GOW(sqrt, dEd)
#ifdef HAVE_LD80BITS
GOW(sqrtl, DED)
#else
GOW2(sqrtl, KEK, sqrt)
#endif
GOW(sqrtf, fEf)
GOM(__sqrtf_finite, fEf) //%noE
GOM(__sqrt_finite, dEd)  //%noE
// sqrtl    // Weak
GO(tan, dEd)
#ifdef HAVE_LD80BITS
GO(tanl, DED)
#else
GO2(tanl, KEK, tan)
#endif
GOW(tanf, fEf)
GOW(tanh, dEd)
#ifdef HAVE_LD80BITS
GOW(tanhl, DED)
#else
GOW2(tanhl, KEK, tanh)
#endif
GOW(tanhf, fEf)
// tanhl    // Weak
// tanl // Weak
GOW(tgamma, dEd)
GOW(tgammaf, fEf)
#ifdef HAVE_LD80BITS
GOW(tgammal, DED)
#else
GOW2(tgammal, KEK, tgamma)
#endif
GOW(trunc, dEd)
#ifdef HAVE_LD80BITS
GOW(truncl, DED)
#else
GOW2(truncl, KEK, trunc)
#endif
GOW(truncf, fEf)
// truncl   // Weak
GO(y0, dEd)
GO(y0f, fEf)
// __y0f_finite
// __y0_finite
// y0l
GO(y1, dEd)
GO(y1f, fEf)
// __y1f_finite
// __y1_finite
// y1l
GO(yn, dEid)
GO(ynf, fEif)
// __ynf_finite
// __yn_finite
// ynl
