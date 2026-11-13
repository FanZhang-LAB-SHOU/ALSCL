#ifndef ACL_MODEL_MATH_HPP
#define ACL_MODEL_MATH_HPP
// Integral of exp(-z*t) from 0 to 1. The sixth-order expansion avoids
// cancellation in 1-exp(-z) near zero and has truncation error below 3e-33
// for 0 <= z < 1e-4. A safe inactive denominator also supports z == 0.
// CondExp keeps the expression differentiable by CppAD and TMBad.
template<class Type>
Type survival_integral(Type z) {
  Type small = Type(1) + z * (Type(-0.5) + z * (Type(1.0/6.0) +
    z * (Type(-1.0/24.0) + z * (Type(1.0/120.0) +
    z * (Type(-1.0/720.0) + z * Type(1.0/5040.0))))));
  Type denominator = CppAD::CondExpLt(z, Type(1e-4), Type(1), z);
  Type ordinary = (Type(1) - exp(-z)) / denominator;
  return CppAD::CondExpLt(z, Type(1e-4), small, ordinary);
}
// TMB's normal CDF has analytic AD derivatives. Evaluate right tails via
// symmetry to avoid subtracting two probabilities rounded to one.
template<class Type>
Type normal_interval(Type upper, Type lower) {
  Type left = pnorm(upper) - pnorm(lower);
  Type right = pnorm(-lower) - pnorm(-upper);
  Type probability = CppAD::CondExpGt(lower, Type(0), right, left);
  return CppAD::CondExpLt(probability, Type(0), Type(0), probability);
}
template<class Type>
Type positive_probability(Type p) {
  return CppAD::CondExpLt(p, Type(1e-300), Type(1e-300), p);
}
template<class Type>
matrix<Type> length_age_key(vector<Type> borders, vector<Type> ages,
                           Type Linf, Type vbk, Type t0, Type cv) {
  int L = borders.size() + 1, A = ages.size();
  matrix<Type> pla(L, A);
  for (int a = 0; a < A; ++a) {
    Type mean = Linf * (Type(1) - exp(-vbk * (ages(a) - t0)));
    Type sd = mean * cv;
    vector<Type> z = (borders - mean) / sd;
    pla(0,a) = positive_probability(pnorm(z(0)));
    for (int l = 1; l < L-1; ++l)
      pla(l,a) = positive_probability(normal_interval(z(l), z(l-1)));
    pla(L-1,a) = positive_probability(pnorm(-z(L-2)));
    Type total = pla.col(a).sum();
    pla.col(a) /= total;
  }
  return pla;
}
// Optional integer setting in the data list. An absent entry returns 0, which
// keeps the published model structure, so data lists built for earlier
// versions remain valid.
inline int optional_setting(SEXP data, const char* name) {
  SEXP value = getListElement(data, name);
  if (Rf_isNull(value) || Rf_length(value) < 1) return 0;
  return (int) Rf_asReal(value);
}
// Optional numeric setting in the data list; an absent entry returns 0.
inline double optional_value(SEXP data, const char* name) {
  SEXP value = getListElement(data, name);
  if (Rf_isNull(value) || Rf_length(value) < 1) return 0.0;
  return Rf_asReal(value);
}
// AR(1) correlation from its optimizer-scale parameter.
// range 0: logistic, between 0 and 1 (published structure).
// range 1: 2 * logistic - 1, between -1 and 1.
template<class Type>
Type ar1_correlation(Type x, int range) {
  if (range == 1) return Type(2) * invlogit(x) - Type(1);
  return invlogit(x);
}
// Expected growth increment over one time step for a fish of length x.
// increment 0: decreasing logistic curve of Zhang and Cadigan (2022), scaled
//   linearly by the time step.
// increment 1: von Bertalanffy, (Linf - x) * (1 - exp(-vbk * growth_step))
//   below Linf, declining smoothly to zero above Linf (smoothing scale
//   0.01 * Linf) so that the increment stays positive and differentiable.
template<class Type>
Type growth_increment_mean(Type x, Type Linf, Type vbk, Type growth_step, int increment) {
  if (increment == 1) {
    Type scale = Type(0.01) * Linf;
    Type u = (Linf - x) / scale;
    Type capped = CppAD::CondExpGt(u, Type(30), Type(30), u);
    Type smooth = scale * log(Type(1) + exp(capped));
    Type remaining = CppAD::CondExpGt(u, Type(30), Linf - x, smooth);
    return (Type(1) - exp(-vbk * growth_step)) * remaining;
  }
  Type max_inc = (Type(1) - exp(-vbk)) * Linf;
  Type l50 = Type(.5) * Linf;
  Type l95 = Type(.05) * Linf;
  return growth_step * max_inc / (Type(1) + exp(-log(Type(19)) * (x - l50) / (l95 - l50)));
}
// Mean of the standard normal CDF over the interval between u_hi and u_lo:
// (H(u_lo) - H(u_hi)) / (u_lo - u_hi) with H(u) = u * pnorm(u) + dnorm(u), the
// antiderivative of pnorm. For a very short interval it is pnorm at the middle.
template<class Type>
Type mean_pnorm(Type u_lo, Type u_hi) {
  Type du = u_lo - u_hi;
  Type tiny = CppAD::CondExpLt(CppAD::abs(du), Type(1e-8), Type(1), Type(0));
  Type safe = CppAD::CondExpLt(CppAD::abs(du), Type(1e-8), Type(1), du);
  Type H_lo = u_lo * pnorm(u_lo) + dnorm(u_lo, Type(0), Type(1), false);
  Type H_hi = u_hi * pnorm(u_hi) + dnorm(u_hi, Type(0), Type(1), false);
  Type ratio = (H_lo - H_hi) / safe;
  Type middle = pnorm(Type(.5) * (u_lo + u_hi));
  return tiny * middle + (Type(1) - tiny) * ratio;
}
// Growth transition matrix G(i,j): probability of moving from length bin j to
// bin i in one time step. Fish cannot shrink out of their bin, and the last
// bin absorbs the right tail. The increment is normal with mean
// growth_increment_mean() and SD cv_grow times that mean.
// transition 0: every fish starts at the midpoint of its bin.
// transition 1: starting lengths are uniform within the bin. The bin is cut
//   into eight pieces; within a piece the expected end length is taken as
//   linear in the starting length and the increment SD as constant, which
//   gives the probability of ending below a border in closed form
//   (mean_pnorm). The result is smooth in the growth parameters and does not
//   stall when the increment is much smaller than the bin width. The first
//   bin is taken as symmetric about its midpoint.
template<class Type>
matrix<Type> growth_matrix(vector<Type> len_mid, vector<Type> len_border, Type Linf,
                           Type vbk, Type cv_grow, Type growth_step,
                           int increment, int transition) {
  int L = len_mid.size();
  int K = 8;
  Type sd_floor = Type(1e-12) * Linf;
  matrix<Type> G(L, L);
  G.setZero();
  for (int j = 0; j < L; ++j) {
    if (j == L-1) { G(j,j) = Type(1); continue; }
    if (transition != 1) {
      Type x = len_mid(j);
      Type mean_inc = growth_increment_mean(x, Linf, vbk, growth_step, increment);
      Type sd_inc = mean_inc * cv_grow + sd_floor;
      for (int i = j; i < L; ++i) {
        if (i == L-1) G(i,j) = pnorm(-(len_border(L-2) - x - mean_inc) / sd_inc);
        else if (i == j) G(i,j) = pnorm((len_border(i) - x - mean_inc) / sd_inc);
        else G(i,j) = normal_interval((len_border(i) - x - mean_inc) / sd_inc,
                                      (len_border(i-1) - x - mean_inc) / sd_inc);
      }
    } else {
      Type lower = j == 0 ? Type(2) * len_mid(0) - len_border(0) : len_border(j-1);
      Type upper = len_border(j);
      // Probability of ending at or below (below) and above (above) each
      // border from bin j upwards, averaged over the pieces of the bin.
      vector<Type> below(L-1), above(L-1);
      below.setZero(); above.setZero();
      for (int k = 0; k < K; ++k) {
        Type a = lower + (upper - lower) * Type(k) / Type(K);
        Type b = lower + (upper - lower) * Type(k + 1) / Type(K);
        Type end_a = a + growth_increment_mean(a, Linf, vbk, growth_step, increment);
        Type end_b = b + growth_increment_mean(b, Linf, vbk, growth_step, increment);
        Type sd_inc = cv_grow * growth_increment_mean(Type(.5) * (a + b), Linf, vbk,
                                                      growth_step, increment) + sd_floor;
        for (int i = j; i < L-1; ++i) {
          Type u_a = (len_border(i) - end_a) / sd_inc;
          Type u_b = (len_border(i) - end_b) / sd_inc;
          below(i) += mean_pnorm(u_a, u_b) / Type(K);
          above(i) += mean_pnorm(-u_b, -u_a) / Type(K);
        }
      }
      for (int i = j; i < L; ++i) {
        Type p;
        if (i == L-1) p = above(L-2);
        else if (i == j) p = below(i);
        else p = CppAD::CondExpGt(below(i-1), Type(.5), above(i-1) - above(i),
                                  below(i) - below(i-1));
        G(i,j) = CppAD::CondExpLt(p, Type(0), Type(0), p);
      }
    }
    Type total = G.col(j).sum();
    G.col(j) /= total;
  }
  return G;
}
#endif
