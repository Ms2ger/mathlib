-- this should all be moved

-- import algebra.inj_surj
import data.nat.choose
import data.int.gcd
import data.mv_polynomial
import data.mv_polynomial.monad
import data.zmod.basic
import data.fintype.card
import data.finset.lattice
import data.set.disjointed
import ring_theory.multiplicity
import algebra.invertible
import number_theory.basic
import group_theory.order_of_element
import ring_theory.witt_vector.mv_poly_temp

universes u v w u₁

-- ### FOR_MATHLIB

open_locale big_operators

namespace mv_polynomial
open finsupp

variables (σ R A : Type*) [comm_semiring R] [comm_semiring A]


section constant_coeff
open_locale classical
variables {σ R}

end constant_coeff

open_locale big_operators

lemma C_dvd_iff_dvd_coeff {σ : Type*} {R : Type*} [comm_ring R]
  (r : R) (φ : mv_polynomial σ R) :
  C r ∣ φ ↔ ∀ i, r ∣ (φ.coeff i) :=
begin
  split,
  { rintros ⟨φ, rfl⟩ c, rw coeff_C_mul, apply dvd_mul_right },
  { intro h,
    choose c hc using h,
    classical,
    let c' : (σ →₀ ℕ) → R := λ i, if i ∈ φ.support then c i else 0,
    let ψ : mv_polynomial σ R := ∑ i in φ.support, monomial i (c' i),
    use ψ,
    apply mv_polynomial.ext, intro i,
    simp only [coeff_C_mul, coeff_sum, coeff_monomial],
    rw [finset.sum_eq_single i, if_pos rfl],
    { dsimp [c'], split_ifs with hi hi,
      { rw hc },
      { rw finsupp.not_mem_support_iff at hi, rwa [mul_zero] } },
    { intros j hj hji, convert if_neg hji },
    { intro hi, rw [if_pos rfl], exact if_neg hi } }
end

-- Johan: why the hack does ring_hom.ker not exist!!!
-- Rob: it does now, why do you ask here?

lemma C_dvd_iff_map_hom_eq_zero {σ : Type*} {R : Type*} {S : Type*} [comm_ring R] [comm_ring S]
  (q : R →+* S) (hq : function.surjective q) (r : R) (hr : ∀ r' : R, q r' = 0 ↔ r ∣ r')
  (φ : mv_polynomial σ R) :
  C r ∣ φ ↔ map q φ = 0 :=
begin
  rw C_dvd_iff_dvd_coeff,
  split,
  { intro h, apply mv_polynomial.ext, intro i,
    simp only [coeff_map, *, ring_hom.coe_of, coeff_zero], },
  { rw mv_polynomial.ext_iff,
    simp only [coeff_map, *, ring_hom.coe_of, coeff_zero, imp_self] }
end

lemma C_dvd_iff_zmod {σ : Type*} (n : ℕ) (φ : mv_polynomial σ ℤ) :
  C (n:ℤ) ∣ φ ↔ map (int.cast_ring_hom (zmod n)) φ = 0 :=
begin
  apply C_dvd_iff_map_hom_eq_zero,
  { exact zmod.int_cast_surjective },
  { exact char_p.int_cast_eq_zero_iff (zmod n) n, }
end

end mv_polynomial

namespace mv_polynomial
variables {σ : Type*} {τ : Type*} {υ : Type*} {R : Type*} [comm_semiring R]



lemma equiv_of_family_aux (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
  (h : ∀ i, aeval g (f i) = X i) (φ : mv_polynomial σ R) :
  (aeval g) (aeval f φ) = φ :=
begin
  rw ← alg_hom.comp_apply,
  suffices : (aeval g).comp (aeval f) = alg_hom.id _ _,
  { rw [this, alg_hom.id_apply], },
  refine mv_polynomial.alg_hom_ext _ (alg_hom.id _ _) _,
  intro i,
  rw [alg_hom.comp_apply, alg_hom.id_apply, aeval_X, h],
end

noncomputable def equiv_of_family (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
  (hfg : ∀ i, aeval g (f i) = X i) (hgf : ∀ i, aeval f (g i) = X i) :
  mv_polynomial σ R ≃ₐ[R] mv_polynomial τ R :=
{ to_fun    := aeval f,
  inv_fun   := aeval g,
  left_inv  := equiv_of_family_aux f g hfg,
  right_inv := equiv_of_family_aux g f hgf,
  .. aeval f}

@[simp] lemma equiv_of_family_coe (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
  (hfg : ∀ i, aeval g (f i) = X i) (hgf : ∀ i, aeval f (g i) = X i) :
  (equiv_of_family f g hfg hgf : mv_polynomial σ R →ₐ[R] mv_polynomial τ R) = aeval f := rfl

@[simp] lemma equiv_of_family_symm_coe (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
  (hfg : ∀ i, aeval g (f i) = X i) (hgf : ∀ i, aeval f (g i) = X i) :
  ((equiv_of_family f g hfg hgf).symm : mv_polynomial τ R →ₐ[R] mv_polynomial σ R) = aeval g := rfl

@[simp] lemma equiv_of_family_apply (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
  (hfg : ∀ i, aeval g (f i) = X i) (hgf : ∀ i, aeval f (g i) = X i)
  (φ : mv_polynomial σ R) :
  equiv_of_family f g hfg hgf φ = aeval f φ := rfl

@[simp] lemma equiv_of_family_symm_apply (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
  (hfg : ∀ i, aeval g (f i) = X i) (hgf : ∀ i, aeval f (g i) = X i)
  (φ : mv_polynomial τ R) :
  (equiv_of_family f g hfg hgf).symm φ = aeval g φ := rfl

-- I think this stuff should move back to the witt_vector file
namespace witt_structure_machine
variable {idx : Type*}
variables (f : σ → mv_polynomial τ R) (g : τ → mv_polynomial σ R)
variables (hfg : ∀ i, aeval g (f i) = X i) (hgf : ∀ i, aeval f (g i) = X i)

noncomputable def structure_polynomial (Φ : mv_polynomial idx R) (t : τ) :
  mv_polynomial (idx × τ) R :=
aeval (λ s : σ, (aeval (λ i, (rename (λ t', (i,t')) (f s)))) Φ) (g t)

include hfg

theorem structure_polynomial_prop (Φ : mv_polynomial idx R) (s : σ) :
  aeval (structure_polynomial f g Φ) (f s) = aeval (λ b, (rename (λ i, (b,i)) (f s))) Φ :=
calc aeval (structure_polynomial f g Φ) (f s) =
      aeval (λ s', aeval (λ b, (rename (prod.mk b)) (f s')) Φ) (aeval g (f s)) :
      by { conv_rhs { rw [aeval_eq_eval₂_hom, map_aeval] },
           apply eval₂_hom_congr _ rfl rfl,
           ext1 r, symmetry, apply eval₂_hom_C, }
... = aeval (λ i, (rename (λ t', (i,t')) (f s))) Φ : by rw [hfg, aeval_X]

include hgf

theorem exists_unique (Φ : mv_polynomial idx R) :
  ∃! (φ : τ → mv_polynomial (idx × τ) R),
    ∀ (s : σ), aeval φ (f s) = aeval (λ i, (rename (λ t', (i,t')) (f s))) Φ :=
begin
  refine ⟨structure_polynomial f g Φ, structure_polynomial_prop _ _ hfg _, _⟩,
  { intros φ H,
    funext t,
    calc φ t = aeval φ (aeval (f) (g t))    : by rw [hgf, aeval_X]
         ... = structure_polynomial f g Φ t : _,
    rw [aeval_eq_eval₂_hom, map_aeval],
    apply eval₂_hom_congr _ _ rfl,
    { ext1 r, exact eval₂_C _ _ r, },
    { funext k, exact H k } }
end

end witt_structure_machine

section monadic_stuff

section

open_locale classical
variables (φ : mv_polynomial σ R) (f : σ → mv_polynomial τ R)

lemma vars_mul (φ ψ : mv_polynomial σ R) :
  (φ * ψ).vars ⊆ φ.vars ∪ ψ.vars :=
begin
  intro i,
  simp only [mem_vars, finset.mem_union],
  rintro ⟨d, hd, hi⟩,
  rw [finsupp.mem_support_iff, ← coeff, coeff_mul] at hd,
  contrapose! hd, cases hd,
  rw finset.sum_eq_zero,
  rintro ⟨d₁, d₂⟩ H,
  rw finsupp.mem_antidiagonal_support at H,
  subst H,
  obtain H|H : i ∈ d₁.support ∨ i ∈ d₂.support,
  { simpa only [finset.mem_union] using finsupp.support_add hi, },
  { suffices : coeff d₁ φ = 0, by simp [this],
    rw [coeff, ← finsupp.not_mem_support_iff], intro, solve_by_elim, },
  { suffices : coeff d₂ ψ = 0, by simp [this],
    rw [coeff, ← finsupp.not_mem_support_iff], intro, solve_by_elim, },
end

@[simp] lemma vars_one : (1 : mv_polynomial σ R).vars = ∅ :=
vars_C

lemma vars_pow (φ : mv_polynomial σ R) (n : ℕ) :
  (φ ^ n).vars ⊆ φ.vars :=
begin
  induction n with n ih,
  { simp },
  { rw pow_succ,
    apply finset.subset.trans (vars_mul _ _),
    exact finset.union_subset (finset.subset.refl _) ih }
end

lemma vars_prod {ι : Type*} {s : finset ι} (f : ι → mv_polynomial σ R) :
  (∏ i in s, f i).vars ⊆ s.bind (λ i, (f i).vars) :=
begin
  apply s.induction_on,
  { simp },
  { intros a s hs hsub,
    simp only [hs, finset.bind_insert, finset.prod_insert, not_false_iff],
    apply finset.subset.trans (vars_mul _ _),
    exact finset.union_subset_union (finset.subset.refl _) hsub }
end

lemma bind₁_vars : (bind₁ f φ).vars ⊆ φ.vars.bind (λ i, (f i).vars) :=
begin
  -- can we prove this using the `mono` tactic?
  -- are the lemmas above good `mono` lemmas?
  -- is `bind_mono` a good `mono` lemma?
  -- Rob: I've never used mono, so I'm not really sure...
  calc (bind₁ f φ).vars
      = (φ.support.sum (λ (x : σ →₀ ℕ), (bind₁ f) (monomial x (coeff x φ)))).vars : by { rw [← alg_hom.map_sum, ← φ.as_sum], }
  ... ≤ φ.support.bind (λ (i : σ →₀ ℕ), ((bind₁ f) (monomial i (coeff i φ))).vars) : vars_sum_subset _ _
  ... = φ.support.bind (λ (d : σ →₀ ℕ), (C (coeff d φ) * ∏ i in d.support, f i ^ d i).vars) : by simp only [bind₁_monomial]
  ... ≤ φ.support.bind (λ (d : σ →₀ ℕ), d.support.bind (λ i, (f i).vars)) : _ -- proof below
  ... ≤ φ.vars.bind (λ (i : σ), (f i).vars) : _, -- proof below
  { apply finset.bind_mono,
    intros d hd,
    calc (C (coeff d φ) * ∏ (i : σ) in d.support, f i ^ d i).vars
        ≤ (C (coeff d φ)).vars ∪ (∏ (i : σ) in d.support, f i ^ d i).vars : vars_mul _ _
    ... ≤ (∏ (i : σ) in d.support, f i ^ d i).vars : by { simp only [finset.empty_union, vars_C, finset.le_iff_subset, finset.subset.refl], }
    ... ≤ d.support.bind (λ (i : σ), (f i ^ d i).vars) : vars_prod _
    ... ≤ d.support.bind (λ (i : σ), (f i).vars) : _,
    apply finset.bind_mono,
    intros i hi,
    apply vars_pow, },
  { -- can this be golfed into a point-free proof?
    intro j,
    rw [finset.mem_bind],
    rintro ⟨d, hd, hj⟩,
    rw [finset.mem_bind] at hj,
    rcases hj with ⟨i, hi, hj⟩,
    rw [finset.mem_bind],
    refine ⟨i, _, hj⟩,
    rw [mem_vars],
    exact ⟨d, hd, hi⟩, }
end

section
variables {A : Type*} [integral_domain A]

lemma vars_C_mul (a : A) (ha : a ≠ 0) (φ : mv_polynomial σ A) :
  (C a * φ).vars = φ.vars :=
begin
  ext1 i,
  simp only [mem_vars, exists_prop, finsupp.mem_support_iff],
  apply exists_congr,
  intro d,
  apply and_congr _ iff.rfl,
  rw [← coeff, ← coeff, coeff_C_mul, mul_ne_zero_iff, eq_true_intro ha, true_and],
end

-- lemma vars_mul_eq (φ ψ : mv_polynomial σ A) (hφ : φ ≠ 0) (hψ : ψ ≠ 0) :
--   (φ * ψ).vars = φ.vars ∪ ψ.vars :=
-- begin
--   apply le_antisymm, { apply vars_mul },
--   intro i,
--   rw finset.mem_union,
--   simp only [mem_vars],
--   -- painful
-- end

-- lemma vars_pow_eq (φ : mv_polynomial σ A) (n : ℕ) :
--   (φ ^ (n+1)).vars = φ.vars :=
-- sorry

-- lemma vars_prod_eq {ι : Type*} {s : finset ι} (f : ι → mv_polynomial σ A) :
--   (∏ i in s, f i).vars = s.bind (λ i, (f i).vars) :=
-- sorry

end

end

end monadic_stuff

/-- Expand the polynomial by a factor of p, so `∑ aₙ xⁿ` becomes `∑ aₙ xⁿᵖ`. -/
-- this definition should also work for non-commutative `R`
noncomputable def expand (p : ℕ) : mv_polynomial σ R →ₐ[R] mv_polynomial σ R :=
{ commutes' := λ r, eval₂_hom_C _ _ _,
  .. (eval₂_hom C (λ i, (X i) ^ p) : mv_polynomial σ R →+* mv_polynomial σ R) }

@[simp] lemma expand_C (p : ℕ) (r : R) : expand p (C r : mv_polynomial σ R) = C r :=
eval₂_hom_C _ _ _

@[simp] lemma expand_X (p : ℕ) (i : σ) : expand p (X i : mv_polynomial σ R) = (X i) ^ p :=
eval₂_hom_X' _ _ _

lemma expand_comp_bind₁ (p : ℕ) (f : σ → mv_polynomial τ R) :
  (expand p).comp (bind₁ f) = bind₁ (λ i, expand p (f i)) :=
by { apply alg_hom_ext, intro i, simp only [alg_hom.comp_apply, bind₁_X_right], }

lemma expand_bind₁ (p : ℕ) (f : σ → mv_polynomial τ R) (φ : mv_polynomial σ R) :
  expand p (bind₁ f φ) = bind₁ (λ i, expand p (f i)) φ :=
by rw [← alg_hom.comp_apply, expand_comp_bind₁]

section
variables {S : Type*} [comm_semiring S]

@[simp]
lemma map_expand (f : R →+* S) (p : ℕ) (φ : mv_polynomial σ R) :
  map f (expand p φ) = expand p (map f φ) :=
by simp [expand, map_bind₁]

-- TODO: prove `rename_comp_expand`

@[simp]
lemma rename_expand (f : σ → τ) (p : ℕ) (φ : mv_polynomial σ R) :
  rename f (expand p φ) = expand p (rename f φ) :=
by simp [expand, bind₁_rename, rename_bind₁]

section
open_locale classical
lemma vars_rename {τ} (f : σ → τ) (φ : mv_polynomial σ R) :
  (rename f φ).vars ⊆ (φ.vars.image f) :=
begin
  -- I guess a higher level proof might be shorter
  -- should we prove `degrees_rename` first?
  intros i,
  rw [mem_vars, finset.mem_image],
  rintro ⟨d, hd, hi⟩,
  simp only [exists_prop, mem_vars],
  contrapose! hd,
  rw [rename_eq],
  rw [finsupp.not_mem_support_iff],
  simp only [finsupp.map_domain, finsupp.sum_apply, finsupp.single_apply],
  rw [finsupp.sum, finset.sum_eq_zero],
  intros d' hd',
  split_ifs with H, swap, refl,
  subst H,
  rw [finsupp.mem_support_iff, finsupp.sum_apply] at hi,
  contrapose! hi,
  rw [finsupp.sum, finset.sum_eq_zero],
  intros j hj,
  rw [finsupp.single_apply, if_neg],
  apply hd,
  exact ⟨d', hd', hj⟩
end

end

lemma constant_coeff_map (f : R →+* S) (φ : mv_polynomial σ R) :
  constant_coeff (mv_polynomial.map f φ) = f (constant_coeff φ) :=
coeff_map f φ 0

lemma constant_coeff_comp_map (f : R →+* S) :
  (constant_coeff : mv_polynomial σ S →+* S).comp (mv_polynomial.map f) = f.comp (constant_coeff) :=
by { ext, apply constant_coeff_map }

end

section aeval_eq_zero
variables {S : Type*} [comm_semiring S]

lemma eval₂_hom_eq_zero (f : R →+* S) (g : σ → S) (φ : mv_polynomial σ R)
  (h : ∀ d, φ.coeff d ≠ 0 → ∃ i ∈ d.support, g i = 0) :
  eval₂_hom f g φ = 0 :=
begin
  rw [φ.as_sum, ring_hom.map_sum, finset.sum_eq_zero],
  intros d hd,
  obtain ⟨i, hi, hgi⟩ : ∃ i ∈ d.support, g i = 0 := h d (finsupp.mem_support_iff.mp hd),
  rw [eval₂_hom_monomial, finsupp.prod, finset.prod_eq_zero hi, mul_zero],
  rw [hgi, zero_pow],
  rwa [nat.pos_iff_ne_zero, ← finsupp.mem_support_iff]
end

lemma aeval_eq_zero [algebra R S] (f : σ → S) (φ : mv_polynomial σ R)
  (h : ∀ d, φ.coeff d ≠ 0 → ∃ i ∈ d.support, f i = 0) :
  aeval f φ = 0 :=
eval₂_hom_eq_zero _ _ _ h

end aeval_eq_zero

section rename
open function

lemma coeff_rename_map_domain (f : σ → τ) (hf : injective f) (φ : mv_polynomial σ R) (d : σ →₀ ℕ) :
  (rename f φ).coeff (d.map_domain f) = φ.coeff d :=
begin
  apply induction_on' φ,
  { intros u r,
    rw [rename_monomial, coeff_monomial, coeff_monomial],
    simp only [(finsupp.map_domain_injective hf).eq_iff],
    split_ifs; refl, },
  { intros, simp only [*, ring_hom.map_add, coeff_add], }
end

lemma coeff_rename_eq_zero (f : σ → τ) (φ : mv_polynomial σ R) (d : τ →₀ ℕ)
  (h : ∀ u : σ →₀ ℕ, u.map_domain f ≠ d) :
  (rename f φ).coeff d = 0 :=
begin
  apply induction_on' φ,
  { intros u r,
    rw [rename_monomial, coeff_monomial],
    split_ifs,
    { exact (h _ ‹_›).elim },
    { refl } },
  { intros,  simp only [*, ring_hom.map_add, coeff_add, add_zero], }
end

lemma coeff_rename_ne_zero (f : σ → τ) (φ : mv_polynomial σ R) (d : τ →₀ ℕ)
  (h : (rename f φ).coeff d ≠ 0) :
  ∃ u : σ →₀ ℕ, u.map_domain f = d :=
by { contrapose! h, apply coeff_rename_eq_zero _ _ _ h }

end rename

section
open_locale classical
variables {S : Type*} [comm_semiring S]

lemma eval₂_hom_congr' {f₁ f₂ : R →+* S} {g₁ g₂ : σ → S} {p₁ p₂ : mv_polynomial σ R} :
  f₁ = f₂ → (∀ i, i ∈ p₁.vars → i ∈ p₂.vars → g₁ i = g₂ i) → p₁ = p₂ →
   eval₂_hom f₁ g₁ p₁ = eval₂_hom f₂ g₂ p₂ :=
begin
  rintro rfl h rfl,
  rename [p₁ p, f₁ f],
  rw p.as_sum,
  simp only [ring_hom.map_sum, eval₂_hom_monomial],
  apply finset.sum_congr rfl,
  intros d hd,
  congr' 1,
  simp only [finsupp.prod],
  apply finset.prod_congr rfl,
  intros i hi,
  have : i ∈ p.vars, { rw mem_vars, exact ⟨d, hd, hi⟩ },
  rw h i this this,
end

end

section move_this

-- move this
variables (σ) (R)
@[simp] lemma constant_coeff_comp_C :
  constant_coeff.comp (C : R →+* mv_polynomial σ R) = ring_hom.id R :=
by { ext, apply constant_coeff_C }

@[simp] lemma constant_coeff_comp_algebra_map :
  constant_coeff.comp (algebra_map R (mv_polynomial σ R)) = ring_hom.id R :=
constant_coeff_comp_C _ _

variable {σ}

@[simp] lemma constant_coeff_rename {τ : Type*} (f : σ → τ) (φ : mv_polynomial σ R) :
  constant_coeff (rename f φ) = constant_coeff φ :=
begin
  apply φ.induction_on,
  { intro a, simp only [constant_coeff_C, rename_C]},
  { intros p q hp hq, simp only [hp, hq, ring_hom.map_add] },
  { intros p n hp, simp only [hp, rename_X, constant_coeff_X, ring_hom.map_mul]}
end

@[simp] lemma constant_coeff_comp_rename {τ : Type*} (f : σ → τ) :
  (constant_coeff : mv_polynomial τ R →+* R).comp (rename f) = constant_coeff :=
by { ext, apply constant_coeff_rename }

end move_this

end mv_polynomial


namespace finset

variables {α : Type*} [fintype α]

lemma eq_univ_of_card (s : finset α) (hs : s.card = fintype.card α) :
  s = univ :=
eq_of_subset_of_card_le (subset_univ _) $ by rw [hs, card_univ]

end finset

namespace function
variables {α β : Type*}
open set

lemma injective_of_inj_on (f : α → β) (hf : inj_on f univ) : injective f :=
λ x y h, hf (mem_univ x) (mem_univ y) h

lemma surjective_of_surj_on (f : α → β) (hf : surj_on f univ univ) : surjective f :=
begin
  intro b,
  rcases hf (mem_univ b) with ⟨a, -, ha⟩,
  exact ⟨a, ha⟩
end

end function

namespace fintype
variables {α β : Type*} [fintype α] [fintype β]
open function finset

lemma bijective_iff_injective_and_card (f : α → β) :
  bijective f ↔ injective f ∧ card α = card β :=
begin
  split,
  { intro h, exact ⟨h.1, fintype.card_congr (equiv.of_bijective f h)⟩, },
  { rintro ⟨hf, h⟩,
    refine ⟨hf, _⟩,
    let s := finset.univ.map ⟨f, hf⟩,
    have hs : s = univ := s.eq_univ_of_card (by rw [card_map, card_univ, h]),
    intro b,
    suffices : b ∈ s,
    { rw mem_map at this, rcases this with ⟨a, -, ha⟩, exact ⟨a, ha⟩ },
    rw [hs],
    exact mem_univ _ }
end

lemma bijective_iff_surjective_and_card (f : α → β) :
  bijective f ↔ surjective f ∧ card α = card β :=
begin
  split,
  { intro h, exact ⟨h.2, fintype.card_congr (equiv.of_bijective f h)⟩, },
  { rintro ⟨hf, h⟩,
    refine ⟨_, hf⟩,
    apply injective_of_inj_on,
    rintro x - y - hxy,
    apply inj_on_of_surj_on_of_card_le
      (λ a _, f a)
      (λ b _, mem_univ _) _ _ (mem_univ x) (mem_univ y) (by simpa),
    { rintro b -, obtain ⟨a, rfl⟩ := hf b, exact ⟨a, mem_univ _, rfl⟩ },
    { rw [card_univ, card_univ, h] } }
end

end fintype

section isos_to_zmod
variables (R : Type*) (n : ℕ) [comm_ring R] [fintype R]

lemma zmod.cast_hom_inj [char_p R n] :
  function.injective (zmod.cast_hom (show n ∣ n, by refl) R) :=
begin
  rw ring_hom.injective_iff,
  intro x,
  obtain ⟨k, rfl⟩ := zmod.int_cast_surjective x,
  rw [ring_hom.map_int_cast,
      char_p.int_cast_eq_zero_iff R n, char_p.int_cast_eq_zero_iff (zmod n) n],
  exact id,
end

lemma zmod.cast_hom_bij [char_p R n] (hn : fintype.card R = n) :
  function.bijective (zmod.cast_hom (show n ∣ n, by refl) R) :=
begin
  haveI : fact (0 < n) :=
  begin
    classical, by_contra H,
    erw [nat.pos_iff_ne_zero, not_not] at H,
    unfreezingI { subst H, },
    rw fintype.card_eq_zero_iff at hn,
    exact hn 0
  end,
  rw [fintype.bijective_iff_injective_and_card, zmod.card, hn, eq_self_iff_true, and_true],
  apply zmod.cast_hom_inj,
end

-- this name is wrong, because the `iso` is not *to* `zmod`, but *from*.
noncomputable def iso_to_zmod [char_p R n] (hn : fintype.card R = n) :
  zmod n ≃+* R :=
ring_equiv.of_bijective _ (zmod.cast_hom_bij _  _ hn)

@[simp] lemma cast_card_eq_zero : (fintype.card R : R) = 0 :=
begin
  have : fintype.card R •ℕ (1 : R) = 0 :=
    @pow_card_eq_one (multiplicative R) _ _ (multiplicative.of_add 1),
  simpa only [mul_one, nsmul_eq_mul]
end

lemma char_p_of_ne_zero (hn : fintype.card R = n) (hR : ∀ i < n, (i : R) = 0 → i = 0) :
  char_p R n :=
{ cast_eq_zero_iff :=
  begin
    have H : (n : R) = 0, by { rw [← hn, cast_card_eq_zero] },
    intros k,
    split,
    { intro h,
      rw [← nat.mod_add_div k n, nat.cast_add, nat.cast_mul, H, zero_mul, add_zero] at h,
      rw nat.dvd_iff_mod_eq_zero,
      apply hR _ (nat.mod_lt _ _) h,
      rw [← hn, gt, fintype.card_pos_iff],
      exact ⟨0⟩, },
    { rintro ⟨k, rfl⟩, rw [nat.cast_mul, H, zero_mul], }
  end }

def char_p_of_prime_pow_ne_zero (p : ℕ) [hp : fact p.prime] (n : ℕ) (hn : fintype.card R = p ^ n)
  (hR : ∀ i ≤ n, (p ^ i : R) = 0 → i = n) :
  char_p R (p ^ n) :=
begin
  obtain ⟨c, hc⟩ := char_p.exists R, resetI,
  have hcpn : c ∣ p ^ n,
  { rw [← char_p.cast_eq_zero_iff R c, ← hn, cast_card_eq_zero], },
  obtain ⟨i, hi, hc⟩ : ∃ i ≤ n, c = p ^ i, by rwa nat.dvd_prime_pow hp at hcpn,
  obtain rfl : i = n,
  { apply hR i hi, rw [← nat.cast_pow, ← hc, char_p.cast_eq_zero] },
  rwa ← hc,
end

end isos_to_zmod

lemma inv_of_commute {M : Type*} [has_one M] [has_mul M] (m : M) [invertible m] :
  commute m (⅟m) :=
calc m * ⅟m = 1       : mul_inv_of_self m
        ... = ⅟ m * m : (inv_of_mul_self m).symm

-- move this
instance invertible_pow {M : Type*} [monoid M] (m : M) [invertible m] (n : ℕ) :
  invertible (m ^ n) :=
{ inv_of := ⅟ m ^ n,
  inv_of_mul_self := by rw [← (inv_of_commute m).symm.mul_pow, inv_of_mul_self, one_pow],
  mul_inv_of_self := by rw [← (inv_of_commute m).mul_pow, mul_inv_of_self, one_pow] }

section
-- move this
lemma prod_mk_injective {α β : Type*} (a : α) :
  function.injective (prod.mk a : β → α × β) :=
by { intros b₁ b₂ h, simpa only [true_and, prod.mk.inj_iff, eq_self_iff_true] using h }
end

-- ### end FOR_MATHLIB