// Age- and Length-Structured Statistical Catch-at-Length Model (ALSCL)
// Based on: Zhang & Cadigan (2022) Fish and Fisheries, 23(5), 1121-1135
//
// Key features vs ACL:
// - 3D population dynamics: NLA(length, age, year)
// - F at length level with 2D AR1 variation (year x length)
// - Growth transition matrix G applied each time step
// - Decreasing logistic function for growth increment (published structure);
//   optional von Bertalanffy increment and integration over the source bin
// - FA (F-at-age) derived as emergent property from NLA -> NA
// - Supports both annual and sub-annual (quarterly) time steps
//
// Optional data entries select alternative structures. When an entry is absent
// or 0 the published structure is used:
//   growth_increment   1 = von Bertalanffy increment over the time step
//   growth_transition  1 = starting lengths uniform within the source bin
//   initial_length     1 = first-period lengths at age follow from growth
//   initial_plus_group 1 = first-period plus group is the equilibrium sum of
//                          all older cohorts at init_Z
//   correlation_range  1 = AR(1) correlations between -1 and 1
//   t0_lower           lower limit of t0: t0 = t0_lower + exp(log_t0)
//   M_LAY              natural mortality rate by length, age and time step
//                      (L x A x Y). It replaces the single rate M in survival,
//                      in the catch equation and in Z and F at age. FA is then
//                      ZA minus the mean of M over lengths weighted by numbers
//                      at length of that age, and ZL is FL plus the mean of M
//                      over ages weighted by numbers at age of that length.
//   q_age              survey catchability multiplier by age (A): the expected
//                      index at length is q(length) times the sum over ages of
//                      q_age(age) * NLA(length, age, time step).
//   log_q_LY           log survey catchability by length and time step (L x Y);
//                      it replaces log_q, for example after a change of gear.
// The code for these three entries sits in branches that a fit without them
// does not enter, so such a fit is computed exactly as before.

#include <TMB.hpp>
#include <iostream>

#include "model_math.hpp"

template<class Type>
Type objective_function<Type>::operator()()
{
	// ==================== DATA ====================
	DATA_MATRIX(logN_at_len);   // observed survey catch at length (L x Y), log scale
	DATA_MATRIX(na_matrix);     // indicator: 1 = observed, 0 = missing/zero (L x Y)
	DATA_VECTOR(log_q);         // survey catchability at length (L)
	DATA_VECTOR(len_mid);       // midpoints of length bins (L)
	DATA_VECTOR(len_border);    // borders between adjacent length bins (L-1)
	DATA_VECTOR(age);           // age vector (A)
	DATA_INTEGER(Y);            // number of years
	DATA_INTEGER(A);            // number of age groups
	DATA_INTEGER(L);            // number of length bins
	DATA_MATRIX(weight);        // weight at length (L x Y)
	DATA_MATRIX(mat);           // maturity at length (L x Y)
	DATA_SCALAR(M);             // natural mortality rate
	DATA_SCALAR(growth_step);   // growth time step (1 = annual, 0.25 = quarterly)

	// ==================== PARAMETERS ====================
	// Initial population
	PARAMETER(log_init_Z);          // initial total mortality for age structure
	PARAMETER(log_sigma_log_N0);    // SD of initial numbers-at-age deviations

	// Recruitment
	PARAMETER(mean_log_R);          // mean log-recruitment
	PARAMETER(log_sigma_log_R);     // SD of recruitment deviations
	PARAMETER(logit_log_R);         // AR1 correlation for recruitment

	// Fishing mortality (at LENGTH, not age)
	PARAMETER(mean_log_F);          // mean log-F
	PARAMETER(log_sigma_log_F);     // SD of F deviations
	PARAMETER(logit_log_F_y);       // AR1 correlation of F across years
	PARAMETER(logit_log_F_l);       // AR1 correlation of F across lengths

	// Growth
	PARAMETER(log_vbk);             // log Von Bertalanffy k
	PARAMETER(log_Linf);            // log asymptotic length
	PARAMETER(log_t0);              // log t0 (log-transformed, unlike ACL which uses raw t0)
	PARAMETER(log_cv_len);          // CV of length-at-age distribution
	PARAMETER(log_cv_grow);         // CV of growth increment (ALSCL-specific)

	// Observation error
	PARAMETER(log_sigma_index);     // SD of survey index measurement error

	// Random effects
	PARAMETER_VECTOR(dev_log_R);    // recruitment deviations (Y)
	PARAMETER_ARRAY(dev_log_F);     // F deviations at LENGTH (L x Y), not (A x Y) as in ACL
	PARAMETER_VECTOR(dev_log_N0);   // initial abundance deviations (A-1)

	// ==================== DERIVED QUANTITIES ====================
	Type one = 1.0;
	Type zero = 0.0;

	Type init_Z = exp(log_init_Z);
	Type sigma_log_N0 = exp(log_sigma_log_N0);

	// Optional settings (absent or 0 = published structure).
	int correlation_range = optional_setting(this->data, "correlation_range");
	double t0_lower = optional_value(this->data, "t0_lower");

	Type sigma_log_R = exp(log_sigma_log_R);
	Type phi_log_R = ar1_correlation(logit_log_R, correlation_range);

	Type sigma_log_F = exp(log_sigma_log_F);
	Type phi_log_F_y = ar1_correlation(logit_log_F_y, correlation_range);
	Type phi_log_F_l = ar1_correlation(logit_log_F_l, correlation_range);

	Type vbk = exp(log_vbk);
	Type Linf = exp(log_Linf);
	// t0 = t0_lower + exp(log_t0); t0_lower = 0 gives the published positive t0.
	Type t0 = exp(log_t0);
	if (t0_lower != 0.0) t0 = t0 + Type(t0_lower);
	Type cv_len = exp(log_cv_len);
	Type cv_grow = exp(log_cv_grow);
	Type sigma_index = exp(log_sigma_index);

	using namespace density;

	// Optional natural mortality rate by length, age and time step, and survey
	// catchability multiplier by age (absent = published structure).
	std::vector<double> M_values = optional_numbers(this->data, "M_LAY", (size_t) L * A * Y);
	std::vector<double> q_age = optional_numbers(this->data, "q_age", (size_t) A);
	std::vector<double> log_q_time = optional_numbers(this->data, "log_q_LY", (size_t) L * Y);
	bool M_varies = M_values.size() > 0;
	bool q_by_age = q_age.size() > 0;
	bool q_by_time = log_q_time.size() > 0;
	// M at length bin k, age class j and time step i (used only when M_varies).
	auto M_at = [&](int k, int j, int i) { return Type(M_values[k + L * (j + A * i)]); };

	// ==================== F AND Z AT LENGTH ====================
	matrix<Type> ZL(L,Y);
	matrix<Type> FL(L,Y);
	matrix<Type> log_FL(L,Y);
	for(int i=0; i<L; ++i){
		for(int j=0; j<Y; ++j){
			log_FL(i,j) = mean_log_F + dev_log_F(dev_log_F.dim[0] == 1 ? 0 : i,j);
			FL(i,j) = exp(log_FL(i,j));
			ZL(i,j) = FL(i,j) + M;
		}
	}

	// Optional structure settings (0 = published structure).
	int growth_increment = optional_setting(this->data, "growth_increment");
	int growth_transition = optional_setting(this->data, "growth_transition");
	int initial_length = optional_setting(this->data, "initial_length");
	int initial_plus_group = optional_setting(this->data, "initial_plus_group");

	// Growth conserves all survivors; the last bin absorbs the right tail.
	matrix<Type> G(L,L);
	G.setZero();
	if (growth_increment == 0 && growth_transition == 0) {
	for (int j=0; j<L; ++j) {
		Type max_inc = (one-exp(-vbk))*Linf;
		Type l50 = Type(.5)*Linf;
		Type l95 = Type(.05)*Linf;
		Type mean_inc = growth_step*max_inc/(one+exp(-log(Type(19))*(len_mid(j)-l50)/(l95-l50)));
		Type sd_inc = mean_inc*cv_grow;
		for (int i=j; i<L; ++i) {
			if (j==L-1) G(i,j)=one;
			else if (i==L-1) G(i,j)=pnorm(-(len_border(L-2)-len_mid(j)-mean_inc)/sd_inc);
			else if (i==j) G(i,j)=pnorm((len_border(i)-len_mid(j)-mean_inc)/sd_inc);
			else G(i,j)=normal_interval((len_border(i)-len_mid(j)-mean_inc)/sd_inc,
			                              (len_border(i-1)-len_mid(j)-mean_inc)/sd_inc);
		}
		Type total=G.col(j).sum();
		G.col(j)/=total;
	}
	} else {
		G = growth_matrix(len_mid, len_border, Linf, vbk, cv_grow, growth_step,
		                  growth_increment, growth_transition);
	}

	// ==================== RECRUITMENT ====================
	vector<Type> log_Rec = dev_log_R + mean_log_R;
	vector<Type> Rec = exp(log_Rec);

	// ==================== LENGTH-AT-AGE PROBABILITY MATRIX (pla) ====================
	matrix<Type> pla = length_age_key(len_border, age, Linf, vbk, t0, cv_len);

	// ==================== 3D POPULATION DYNAMICS: NLA(L, A, Y) ====================
	array<Type> NLA(L,A,Y);

	// Initializing recruitment and first year abundance
	vector<Type> log_N0(A);
	vector<Type> N0(A);
	log_N0(0) = log_Rec(0);
	N0(0) = Rec(0);

	for(int j = 1;j < A;++j){
		log_N0(j) = log_N0(j-1) - init_Z + dev_log_N0(j-1);
		N0(j) = exp(log_N0(j));
	}

	Type init_survival = exp(-init_Z);
	if (initial_length == 0) {
		// Published structure: every age has the length-at-age distribution pla.
		if (initial_plus_group == 1) N0(A-1) = N0(A-1) / (one - init_survival);
		for(int j=0; j<A; ++j){
			NLA.col(0).col(j) = pla.col(j) * N0(j);
		}
	} else {
		// Lengths at age follow from growth: each age is the previous age after
		// survival at init_Z and one growth step, so the first period is
		// consistent with the dynamics that follow.
		vector<Type> state = pla.col(0) * N0(0);
		NLA.col(0).col(0) = state;
		for(int j=1; j<A; ++j){
			vector<Type> grown = G * state;
			state = grown * exp(-init_Z + dev_log_N0(j-1));
			if (j == A-1 && initial_plus_group == 1) {
				// Sum over all older cohorts, sum_k (s G)^k state, by forward
				// substitution (G is lower triangular).
				vector<Type> total(L);
				for (int i=0; i<L; ++i) {
					Type acc = state(i);
					for (int k=0; k<i; ++k) acc += init_survival * G(i,k) * total(k);
					total(i) = acc / (one - init_survival * G(i,i));
				}
				state = total;
			}
			NLA.col(0).col(j) = state;
		}
	}

	// Core dynamics: years 2+
	for(int i = 1; i < Y;++i){
		// Recruitment: stationary length distribution
		NLA.col(i).col(0) = pla.col(0) * Rec(i);

		// Ages 2 to A-1: survive then grow through G
		for(int j = 1;j < (A-1);++j){
			vector<Type> previous = NLA.col(i-1).col(j-1);
			if (!M_varies) {
				vector<Type> survival = previous * exp(-ZL.col(i-1).array());
				NLA.col(i).col(j) = G * survival;
			} else {
				vector<Type> survival(L);
				for (int k=0; k<L; ++k)
					survival(k) = previous(k) * exp(-(FL(k,i-1) + M_at(k,j-1,i-1)));
				NLA.col(i).col(j) = G * survival;
			}
		}

		// Plus group: accumulate A-1 and A survivors
		vector<Type> previous_1 = NLA.col(i-1).col(A-2);
		vector<Type> previous_2 = NLA.col(i-1).col(A-1);
		if (!M_varies) {
			vector<Type> survival = (previous_1 + previous_2) * exp(-ZL.col(i-1).array());
			NLA.col(i).col(A-1) = G * survival;
		} else {
			// The two source ages have their own natural mortality rates.
			vector<Type> survival(L);
			for (int k=0; k<L; ++k)
				survival(k) = previous_1(k) * exp(-(FL(k,i-1) + M_at(k,A-2,i-1))) +
				              previous_2(k) * exp(-(FL(k,i-1) + M_at(k,A-1,i-1)));
			NLA.col(i).col(A-1) = G * survival;
		}
	}

	// With M by length, age and time step, total mortality at length is not a
	// single rate. ZL is then FL plus the mean of M over ages, weighted by
	// numbers at age of that length (the unweighted mean where numbers are 0).
	// M_LAY is reported so that R can complete F at age (.acl_F_at_age).
	if (M_varies) {
		array<Type> M_LAY(L,A,Y);
		for(int i=0; i<Y; ++i){
			for(int k=0; k<L; ++k){
				Type weighted = zero;
				Type total = zero;
				for(int j=0; j<A; ++j){
					M_LAY(k,j,i) = M_at(k,j,i);
					Type w = NLA(k,j,i) + Type(1e-300);
					weighted += w * M_at(k,j,i);
					total += w;
				}
				ZL(k,i) = FL(k,i) + weighted / total;
			}
		}
		REPORT(M_LAY);
	}

	// ==================== BIOMASS AND SSB (3D) ====================
	array<Type> BLA(L,A,Y);
	array<Type> SBLA(L,A,Y);
	for(int i=0; i<Y; ++i){
		for(int j=0; j<A; ++j){
			for(int k=0; k<L; ++k){
				BLA(k,j,i) = NLA(k,j,i)*weight(k,i);
				SBLA(k,j,i) = BLA(k,j,i)*mat(k,i);
			}
		}
	}

	// ==================== MARGINALS: AGGREGATE OVER AGE OR LENGTH ====================
	matrix<Type> NL(L,Y);
	NL.setZero();
	matrix<Type> NA(A,Y);
	matrix<Type> BL(L,Y);
	BL.setZero();
	matrix<Type> BA(A,Y);
	matrix<Type> SBL(L,Y);
	SBL.setZero();
	matrix<Type> SBA(A,Y);

	for(int i=0; i<Y; ++i){
		for(int j=0; j<A; ++j){
			for(int k=0; k<L; ++k){
				NL(k,i) += NLA(k,j,i);
				BL(k,i) += BLA(k,j,i);
				SBL(k,i) += SBLA(k,j,i);
			}
		}
	}
	for(int i=0; i<Y; ++i){
		for(int j=0; j<A; ++j){
			NA(j,i) = NLA.col(i).col(j).sum();
			BA(j,i) = BLA.col(i).col(j).sum();
			SBA(j,i) = SBLA.col(i).col(j).sum();
		}
	}

	// ==================== CATCH STATISTICS ====================
	array<Type> CNLA(L,A,Y);
	matrix<Type> CNL(L,Y);
	CNL.setZero();
	matrix<Type> CNA(A,Y);

	array<Type> CBLA(L,A,Y);
	matrix<Type> CBL(L,Y);
	CBL.setZero();
	matrix<Type> CBA(A,Y);

	for(int i=0; i<Y; ++i){
		for(int j=0; j<A; ++j){
			for(int k=0; k<L; ++k){
				if (!M_varies) CNLA(k,j,i) = NLA(k,j,i) * FL(k,i) * survival_integral(ZL(k,i));
				else CNLA(k,j,i) = NLA(k,j,i) * FL(k,i) * survival_integral(FL(k,i) + M_at(k,j,i));
				CBLA(k,j,i) = CNLA(k,j,i)*weight(k,i);
			}
		}
	}

	for(int i=0; i<Y; ++i){
		for(int j=0; j<A; ++j){
			for(int k=0; k<L; ++k){
				CNL(k,i) += CNLA(k,j,i);
				CBL(k,i) += CBLA(k,j,i);
			}
		}
	}

	for(int i=0; i<Y; ++i){
		for(int j=0; j<A; ++j){
			CNA(j,i) = CNLA.col(i).col(j).sum();
			CBA(j,i) = CBLA.col(i).col(j).sum();
		}
	}

	// ==================== EMERGENT F-AT-AGE ====================
	// Derived from population abundance at age, NOT a direct parameter
	// Ages before the plus group and periods before the last. The remaining
	// cells are computed in R from NLA and ZL (see .acl_F_at_age): computing
	// them here would add operations to the tape and structural entries to the
	// random-effect Hessian, which changes fitted values at rounding level.
	matrix<Type> ZA(A-1,Y-1);
	matrix<Type> FA(A-1,Y-1);
	for(int i=0; i<A-1; ++i){
		for(int j=0; j<Y-1; ++j){
			vector<Type> cohort = NLA.col(j).col(i);
			if (!M_varies) {
				vector<Type> survivors = cohort * exp(-ZL.col(j).array());
				ZA(i,j) = log(positive_probability(cohort.sum())) - log(positive_probability(survivors.sum()));
				FA(i,j) = ZA(i,j) - M;
			} else {
				// F at age is Z at age minus the mean of M over lengths, weighted
				// by numbers at length of this age (see also .acl_F_at_age in R).
				Type survivors = zero;
				Type weighted = zero;
				Type total = zero;
				for (int k=0; k<L; ++k) {
					survivors += cohort(k) * exp(-(FL(k,j) + M_at(k,i,j)));
					Type w = cohort(k) + Type(1e-300);
					weighted += w * M_at(k,i,j);
					total += w;
				}
				ZA(i,j) = log(positive_probability(cohort.sum())) - log(positive_probability(survivors));
				FA(i,j) = ZA(i,j) - weighted / total;
			}
		}
	}

	// ==================== TOTALS ====================
	vector<Type> N(Y);
	vector<Type> B(Y);
	vector<Type> SSB(Y);
	vector<Type> CN(Y);
	vector<Type> CB(Y);
	for(int i=0; i<Y; ++i){
		N(i) = NL.col(i).sum();
		B(i) = BL.col(i).sum();
		SSB(i) = SBL.col(i).sum();
		CN(i) = CNL.col(i).sum();
		CB(i) = CBL.col(i).sum();
	}

	// ==================== SURVEY INDEX ====================
	matrix<Type> Elog_index(L,Y);
	matrix<Type> resid_index(L,Y);
	for(int i = 0;i < L;++i){
		for(int j=0; j<Y; ++j){
			if (!q_by_age && !q_by_time) {
				Elog_index(i,j) = log_q(i) + log(positive_probability(NL(i,j)));
			} else {
				Type seen = NL(i,j);
				if (q_by_age) {
					seen = zero;
					for(int a=0; a<A; ++a) seen += Type(q_age[a]) * NLA(i,a,j);
				}
				Type log_q_now = q_by_time ? Type(log_q_time[i + L * j]) : Type(log_q(i));
				Elog_index(i,j) = log_q_now + log(positive_probability(seen));
			}
			resid_index(i,j) = zero;
		if (na_matrix(i,j)>0) resid_index(i,j) = (logN_at_len(i,j) - Elog_index(i,j))* na_matrix(i,j);
		}
	}

	// ==================== NEGATIVE LOG-LIKELIHOOD ====================
	parallel_accumulator<Type> nll(this);

	// Observation: survey index measurement error
	for(int i=0;i<L;++i){
		for(int j=0;j<Y;++j){
			if(na_matrix(i,j)>0){
				nll -= dnorm(resid_index(i,j),zero,sigma_index,true);
			}
		}
	}

	// Process: F deviations — 2D AR1 (year x length)
	// A single row is the optional shared F process: Y random effects and
  // one AR(1) normalization, not tied cells of the two-dimensional field.
  if (dev_log_F.dim[0] == 1) {
    vector<Type> yearly_F(Y);
    for (int y=0; y<Y; ++y) yearly_F(y) = dev_log_F(0,y);
    nll += SCALE(AR1(phi_log_F_y),sigma_log_F)(yearly_F);
  } else {
    nll += SCALE(SEPARABLE(AR1(phi_log_F_y),AR1(phi_log_F_l)),sigma_log_F)(dev_log_F);
  }

	// Process: Recruitment deviations — AR1
	nll += SCALE(AR1(phi_log_R),sigma_log_R)(dev_log_R);

	// Process: Initial abundance deviations — iid normal
	nll -= dnorm(dev_log_N0,zero,sigma_log_N0,true).sum();

	// ==================== REPORT ====================
	REPORT(pla);
	REPORT(G);

	REPORT(Rec);
	REPORT(N);
	REPORT(NLA);
	REPORT(NL);
	REPORT(NA);

	REPORT(B);
	REPORT(BLA);
	REPORT(BL);
	REPORT(BA);

	REPORT(SSB);
	REPORT(SBLA);
	REPORT(SBL);
	REPORT(SBA);

	REPORT(CN);
	REPORT(CNLA);
	REPORT(CNL);
	REPORT(CNA);
	REPORT(CB);
	REPORT(CBLA);
	REPORT(CBL);
	REPORT(CBA);

	REPORT(FL);
	REPORT(FA);
	REPORT(ZL);
	REPORT(ZA);

	REPORT(mean_log_F);
	REPORT(dev_log_F);
	REPORT(phi_log_F_y);
	REPORT(phi_log_F_l);
	REPORT(sigma_log_F);

	REPORT(mean_log_R);
	REPORT(dev_log_R);
	REPORT(sigma_log_R);
	REPORT(phi_log_R);

	REPORT(sigma_index);
	REPORT(Elog_index);
	REPORT(resid_index);

	REPORT(vbk);
	REPORT(Linf);
	REPORT(t0);
	REPORT(cv_len);
	REPORT(cv_grow);

	REPORT(init_Z);
	REPORT(sigma_log_N0);
		REPORT(dev_log_N0);

	// ==================== ADREPORT for sdreport ====================
	ADREPORT(Rec);
	ADREPORT(N);
	ADREPORT(NA);
	ADREPORT(NL);
	ADREPORT(B);
	ADREPORT(BA);
	ADREPORT(BL);
	ADREPORT(SSB);
	ADREPORT(SBA);
	ADREPORT(SBL);
	ADREPORT(FA);
	ADREPORT(FL);
	ADREPORT(CN);
	ADREPORT(CNA);
	ADREPORT(CNL);

	return nll;
}
