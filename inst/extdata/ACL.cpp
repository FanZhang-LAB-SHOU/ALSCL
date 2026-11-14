// Age-structured statistical catch-at-length model (ACL) for survey catch at length
// Based on: Zhang & Cadigan (2022) Fish and Fisheries, 23(5), 1121-1135
//
// - Numbers at age follow a cohort model with a plus group.
// - Numbers at length are numbers at age times the length-at-age
//   probability matrix pla (von Bertalanffy mean, constant CV, normal).
// - Survey catchability at length is supplied (log_q), not estimated.
// - Recruitment deviations follow an AR(1) process; log-F deviations follow a
//   separable AR(1) process over ages and time steps, or one AR(1) series
//   shared by all ages when dev_log_F has a single row.
// - Initial numbers at age (ages after the first) have iid normal deviations.
// - Optional data entry initial_plus_group = 1 makes the first-period plus
//   group the equilibrium sum of all older cohorts at init_Z.
// - Optional data entry correlation_range = 1 lets the AR(1) correlations
//   take values between -1 and 1.
// - Optional data entry M_AY (A x Y) is the natural mortality rate by age and
//   time step; it replaces the single rate M.
// - Optional data entry q_age (A) is a survey catchability multiplier by age:
//   the expected index at length is q(length) times the sum over ages of
//   q_age(age) * pla(length, age) * NA(age, time step).
// - Optional data entry log_q_LY (L x Y) is the log survey catchability by
//   length and time step; it replaces log_q, for example after a change of
//   gear.
//   The code for these three entries sits in branches that a fit without
//   them does not enter, so such a fit is computed exactly as before.

#include <TMB.hpp>
#include <iostream>

#include "model_math.hpp"

template<class Type>
Type objective_function<Type>::operator() ()
{

  // input data;
  DATA_MATRIX(logN_at_len); // observed survey catch at length (L by Y)
  DATA_MATRIX(na_matrix); // indicating elements where N_at_len is NA.
  DATA_VECTOR(log_q); // catchability at length
  DATA_VECTOR(len_border); // breaking border between length bins
  DATA_VECTOR(age); // ages
  DATA_INTEGER(Y); // number of years
  DATA_INTEGER(A); // number of ages
  DATA_INTEGER(L); // number of length bins
  DATA_MATRIX(weight); // weight at length (L by Y)
  DATA_MATRIX(mat); // maturity at length (L by Y)
  DATA_SCALAR(M); // assumed constant natural mortality

  Type zero = 0.0;
  Type one = 1.0;

  //define parameters;

  // fixed effects
  PARAMETER(log_init_Z); // intital total mortality used to set initial age structure
  PARAMETER(log_std_log_N0); // variability of initial number at age

  PARAMETER(mean_log_R); // mean recruitment
  PARAMETER(log_std_log_R); // recruitment standard error
  PARAMETER(logit_log_R); // define the AR1 coefficient of recruitment variation

  PARAMETER(mean_log_F);
  PARAMETER(log_std_log_F);
  PARAMETER(logit_log_F_y);
  PARAMETER(logit_log_F_a);

  PARAMETER(log_vbk); // VB parameter
  PARAMETER(log_Linf); // VB parameter
  PARAMETER(t0); // VB parameter
  PARAMETER(log_cv_len); // cv of length-at-age

  PARAMETER(log_std_index); // measurement error of survey catch at legnth

  // random effects
  PARAMETER_VECTOR(dev_log_R); // recruitment deviation
  PARAMETER_ARRAY(dev_log_F); // deviation of fishing moratlity across years and ages
  PARAMETER_VECTOR(dev_log_N0); // deviation of initial number at age (except for the first age), so size = A-1

  // derived parameters
  Type init_Z = exp(log_init_Z);
  Type std_log_N0 = exp(log_std_log_N0);

  // Optional: AR(1) correlations between -1 and 1 (absent or 0 keeps 0 to 1).
  int correlation_range = optional_setting(this->data, "correlation_range");

  Type std_log_R = exp(log_std_log_R);
  Type phi_log_R = ar1_correlation(logit_log_R, correlation_range);

  Type std_log_F = exp(log_std_log_F);
  Type phi_log_F_y = ar1_correlation(logit_log_F_y, correlation_range);
  Type phi_log_F_a = ar1_correlation(logit_log_F_a, correlation_range);

  Type vbk = exp(log_vbk);
  Type Linf = exp(log_Linf);
  Type cv_len = exp(log_cv_len);

  Type std_index = exp(log_std_index);

  // Optional natural mortality rate by age and time step, and survey
  // catchability multiplier by age (absent = original structure).
  std::vector<double> M_AY = optional_numbers(this->data, "M_AY", (size_t) A * Y);
  std::vector<double> q_age = optional_numbers(this->data, "q_age", (size_t) A);
  std::vector<double> log_q_time = optional_numbers(this->data, "log_q_LY", (size_t) L * Y);
  bool M_varies = M_AY.size() > 0;
  bool q_by_age = q_age.size() > 0;
  bool q_by_time = log_q_time.size() > 0;

  vector<Type> N(Y);
  matrix<Type> NA(A,Y);
  matrix<Type> log_NA(A,Y);
  matrix<Type> NL(L,Y);
  matrix<Type> log_NL(L,Y);
  matrix<Type> Z(A,Y);
  matrix<Type> F(A,Y);
  matrix<Type> pla(L,A);

  using namespace density; // call functions in TMB density namespace

  pla = length_age_key(len_border, age, Linf, vbk, t0, cv_len);

  //compute Z,F and M
  for(int i = 0;i < A;++i){
    for(int j = 0;j < Y;++j){
        F(i,j) = exp(mean_log_F + dev_log_F(dev_log_F.dim[0] == 1 ? 0 : i,j));
        if (!M_varies) Z(i,j)=F(i,j)+M;
        else Z(i,j)=F(i,j)+Type(M_AY[i + A * j]);
     }
  }

  // get annual recruitment
  vector<Type> log_Rec = dev_log_R + mean_log_R; // may need to plug in SR model here
  vector<Type> Rec = exp(log_Rec); // - half * std_log_R * std_log_R); // bias correction

  // The cohort model;
  //initializing first year
  log_NA(0,0) = log_Rec(0);
  NA(0,0) = Rec(0);
  //Type cz=zero;
  for(int i = 1;i < A;++i){
    log_NA(i,0) = log_NA(i-1,0) -init_Z  + dev_log_N0(i-1);
	NA(i,0) = exp(log_NA(i,0));
  }
  // Optional: the first-period plus group is the equilibrium sum of all older
  // cohorts at init_Z (absent or 0 keeps the original single-cohort value).
  if (optional_setting(this->data, "initial_plus_group") == 1) {
    log_NA(A-1,0) -= log(one - exp(-init_Z));
    NA(A-1,0) = exp(log_NA(A-1,0));
  }
  //compute numbers at age
  for(int j = 1;j < Y;++j){
    log_NA(0,j) = log_Rec(j);
	NA(0,j) = Rec(j);
    for(int i = 1;i < (A-1);++i){
		log_NA(i,j) = log_NA(i-1,j-1) - Z(i-1,j-1);
		NA(i,j) = exp(log_NA(i,j));
	}
	NA(A-1,j) = NA(A-2,j-1)*exp(-Z(A-2,j-1)) + NA(A-1,j-1)*exp(-Z(A-1,j-1)); // plus group
	log_NA(A-1,j) = log(NA(A-1,j));
  }

  // compute number at length
  for(int i=0; i<Y; ++i){
	NL.col(i) = pla * NA.col(i);
	N(i)=NA.col(i).sum();
  }
  log_NL= log(NL.array() + Type(1e-300));

  // compute biomass at age and length
  vector<Type> B(Y);
  vector<Type> SSB(Y);
  matrix<Type> BL(L,Y);
  matrix<Type> SBL(L,Y);
  vector<Type> CN(Y); // annual catch in numbers
  matrix<Type> CNA(A,Y);

  for(int i=0; i<L; ++i){
	  for(int j=0; j<Y; ++j){
		BL(i,j)=NL(i,j)*weight(i,j);
		SBL(i,j)=BL(i,j)*mat(i,j);
	  }
  }

  for(int i=0; i<A; ++i){
	  for(int j=0; j<Y; ++j){
		CNA(i,j)=NA(i,j)*F(i,j)*survival_integral(Z(i,j));
	  }
  }

  for(int i=0; i<Y; ++i){
	  CN(i)=CNA.col(i).sum();
	  B(i)=BL.col(i).sum();
	  SSB(i)=SBL.col(i).sum();
  }

  //calculate index
  matrix<Type> Elog_index(L,Y);
  matrix<Type> resid_index(L,Y);
  for(int i = 0;i < L;++i){
	for(int j=0; j<Y; ++j){
  	if (!q_by_age && !q_by_time) {
  	  Elog_index(i,j) = log_q(i) + log_NL(i,j);
  	} else {
  	  Type log_seen = log_NL(i,j);
  	  if (q_by_age) {
  	    Type seen = zero;
  	    for(int a=0; a<A; ++a) seen += Type(q_age[a]) * pla(i,a) * NA(a,j);
  	    log_seen = log(seen + Type(1e-300));
  	  }
  	  Type log_q_now = q_by_time ? Type(log_q_time[i + L * j]) : Type(log_q(i));
  	  Elog_index(i,j) = log_q_now + log_seen;
  	}
		resid_index(i,j) = zero;
		if (na_matrix(i,j)>0) resid_index(i,j) = (logN_at_len(i,j) - Elog_index(i,j)) * na_matrix(i,j);
	}
  }

  //negative log-likelihoods
  // parallel_accumulator enables TMB::openmp() multi-thread gradient computation
  // When openmp(1), behaves identically to Type nll = 0
  parallel_accumulator<Type> nll(this);

  //index, the measurement error
  for(int i=0;i<L;++i){
	for(int j=0;j<Y;++j){
		if(na_matrix(i,j)>0){
			nll -= dnorm(resid_index(i,j),zero,std_index,true);
		}
	}
  }

  // logF
  // A single row is the optional shared F process: Y random effects and
  // one AR(1) normalization, not tied cells of the two-dimensional field.
  if (dev_log_F.dim[0] == 1) {
    vector<Type> yearly_F(Y);
    for (int y=0; y<Y; ++y) yearly_F(y) = dev_log_F(0,y);
    nll += SCALE(AR1(phi_log_F_y),std_log_F)(yearly_F);
  } else {
    nll += SCALE(SEPARABLE(AR1(phi_log_F_y),AR1(phi_log_F_a)),std_log_F)(dev_log_F);
  }

  //recruitment estimates
  nll += SCALE(AR1(phi_log_R),std_log_R)(dev_log_R); // AR1 evaluation to generate nll for logR

  // initial population size
  nll -= dnorm(dev_log_N0,zero,std_log_N0,true).sum(); // iid evaluation of the initial population size

 // report results
  REPORT(pla);
  REPORT(N)
  REPORT(NL);
  REPORT(NA);
  REPORT(dev_log_N0);
  REPORT(std_log_N0);
  REPORT(B);
  REPORT(BL);
  REPORT(SSB);
  REPORT(SBL);
  REPORT(Z);
  REPORT(F);
  REPORT(CN);
  REPORT(CNA);
  REPORT(mean_log_F);
  REPORT(dev_log_F);
  REPORT(phi_log_F_y);
  REPORT(phi_log_F_a);
  REPORT(Rec);
  REPORT(mean_log_R);
  REPORT(dev_log_R);
  REPORT(std_log_R);
  REPORT(phi_log_R);
  REPORT(Elog_index);
  REPORT(resid_index);
  REPORT(std_index);

  REPORT(vbk);
  REPORT(Linf);
  REPORT(t0);
  REPORT(cv_len);

  ADREPORT(Rec);
  ADREPORT(N);
  ADREPORT(NA);
  ADREPORT(NL);
  ADREPORT(B);
  ADREPORT(SSB);
  ADREPORT(F);
  ADREPORT(CN);

  return nll;
}
