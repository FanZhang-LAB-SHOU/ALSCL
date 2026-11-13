test_that("age-length probabilities match the normal distribution throughout the CV range", {
 for(model in c("ACL","ALSCL")) for(cv in c(.01,.2,1)) {
  x<-cpp_fixture(model,cv);r<-x$obj$report(x$obj$par);d<-x$data;p<-x$parameters
  means<-exp(p$log_Linf)*(1-exp(-exp(p$log_vbk)*(d$age-if(model=="ACL")p$t0 else exp(p$log_t0))))
  expected<-vapply(means,function(mu) diff(pnorm(c(-Inf,d$len_border,Inf),mu,mu*cv)),numeric(d$L))
  expect_equal(r$pla,expected,tolerance=1e-12)
  expect_equal(colSums(r$pla),rep(1,d$A),tolerance=1e-12)
  expect_true(all(is.finite(x$obj$gr(x$obj$par))))
 }
})
test_that("ACL plus group retains the previous oldest fish", {
 x<-cpp_fixture("ACL");r<-x$obj$report(x$obj$par);A<-x$data$A;Y<-x$data$Y
 expected<-r[["NA"]][A-1,1:(Y-1)]*exp(-r$Z[A-1,1:(Y-1)])+r[["NA"]][A,1:(Y-1)]*exp(-r$Z[A,1:(Y-1)])
 expect_equal(r[["NA"]][A,2:Y],expected,tolerance=1e-12)
})
test_that("ALSCL conserves survivors and recovers constant F including the plus group entry", {
 x<-cpp_fixture();r<-x$obj$report(x$obj$par);L<-x$data$L;A<-x$data$A;Y<-x$data$Y
 expect_equal(colSums(r$G),rep(1,L),tolerance=1e-12)
 expect_equal(r$G[upper.tri(r$G)],rep(0,sum(upper.tri(r$G))))
 expect_equal(r$NL,apply(r$NLA,c(1,3),sum),tolerance=1e-12)
 expect_equal(r$B,apply(r$BLA,3,sum),tolerance=1e-12)
 expect_equal(r$CNL,apply(r$CNLA,c(1,3),sum),tolerance=1e-12)
 expect_equal(r$FA,matrix(.2,A,Y),tolerance=1e-10)
 # Constant F gives F at age 0.2 for any cohort and any indexing. Let F vary
 # by length bin and time step, so that F at age depends on each cohort's own
 # length composition, and compare with the independent R dynamics.
 p<-x$parameters;p$dev_log_F<-array(.6*sin(seq_len(L*Y)),c(L,Y))
 o<-TMB::MakeADFun(x$data,p,DLL=x$info$dll_name,silent=TRUE);v<-o$report(o$par)
 ref<-ref_alscl_dynamics(x$data,p);M<-x$data$M
 expected<-matrix(0,A,Y)
 for(a in seq_len(A)) for(y in seq_len(Y))
  expected[a,y]<- -log(sum(ref$NLA[,a,y]*exp(-ref$ZL[,y]))/sum(ref$NLA[,a,y]))-M
 expect_equal(v$FA,expected,tolerance=1e-10)
 expect_equal(v$ZA,v$FA+M,tolerance=1e-12)
 expect_gt(min(apply(v$FA,1,function(z) diff(range(z)))),.01)
 expect_gt(min(apply(v$FA,2,function(z) diff(range(z)))),.01)
 # Growth moves survivors between length bins without loss, so total mortality
 # at age links numbers at age in consecutive time steps.
 expect_equal(v[["NA"]][2:(A-1),2:Y],v[["NA"]][1:(A-2),1:(Y-1)]*exp(-v$ZA[1:(A-2),1:(Y-1)]),tolerance=1e-10)
 for(y in 2:Y) expect_equal(sum(r$NLA[,,y]),r$Rec[y]+sum(r$NLA[,,y-1]*exp(-r$ZL[,y-1])),tolerance=1e-10)
 # Compare AD with finite differences at ordinary, non-tail parameters.
 idx<-which(names(x$obj$par)%in%c("log_vbk","log_Linf","log_cv_len","log_cv_grow"))
 g<-x$obj$gr(x$obj$par)
 for(j in idx) {
  a<-b<-x$obj$par;a[j]<-a[j]+1e-5;b[j]<-b[j]-1e-5
  fd<-(x$obj$fn(a)-x$obj$fn(b))/2e-5
  expect_equal(as.numeric(g[j]),as.numeric(fd),tolerance=2e-5)
 }
})
test_that("double evaluation never depends on uninitialized Eigen storage", {
 x<-cpp_fixture();folder<-tempfile();dir.create(folder)
 src<-readLines(system.file("extdata","ALSCL.cpp",package="ALSCL"))
 writeLines(c("#define EIGEN_INITIALIZE_MATRICES_BY_NAN",src),file.path(folder,"ALSCL_nan.cpp"))
 file.copy(system.file("extdata","model_math.hpp",package="ALSCL"),folder)
 compile_nan <- function() {
   previous_dir <- setwd(folder); on.exit(setwd(previous_dir))
   # Unoptimized Eigen templates exceed the standard Windows COFF section limit.
   flags <- if (.Platform$OS.type == "windows") "-O0 -Wa,-mbig-obj" else "-O0"
   TMB::compile("ALSCL_nan.cpp",flags=flags,openmp=FALSE)
 }
 compile_nan()
 dyn.load(TMB::dynlib(file.path(folder,"ALSCL_nan")))
 o<-TMB::MakeADFun(x$data,x$parameters,DLL="ALSCL_nan",type="Fun",silent=TRUE)
 r<-o$report(unlist(x$parameters))
 for(n in c("NLA","NL","BL","SBL","CNL","CBL")) expect_true(all(is.finite(r[[n]])))
})
