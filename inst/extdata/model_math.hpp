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
#endif
