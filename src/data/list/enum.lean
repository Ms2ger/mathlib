/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Kenny Lau, Scott Morrison
-/
import data.list.chain
import data.list.nodup
import data.list.of_fn

open nat

namespace list
/- iota and intervals -/

universe u

variables {α : Type u}

/-- `Ico'_ℕ s n` is the list of natural numbers `[s, s+1, ..., s+n-1]`.
It is intended mainly for proving properties of `range` and `iota`. -/
@[simp] def Ico'_ℕ : ℕ → ℕ → list ℕ
| s 0     := []
| s (n+1) := s :: Ico'_ℕ (s+1) n

@[simp] theorem length_Ico'_ℕ : ∀ (s n : ℕ), length (Ico'_ℕ s n) = n
| s 0     := rfl
| s (n+1) := congr_arg succ (length_Ico'_ℕ _ _)

@[simp] theorem Ico'_ℕ_eq_nil {s n : ℕ} : Ico'_ℕ s n = [] ↔ n = 0 :=
by rw [← length_eq_zero, length_Ico'_ℕ]

@[simp] theorem mem_Ico'_ℕ {m : ℕ} : ∀ {s n : ℕ}, m ∈ Ico'_ℕ s n ↔ s ≤ m ∧ m < s + n
| s 0     := (false_iff _).2 $ λ ⟨H1, H2⟩, not_le_of_lt H2 H1
| s (succ n) :=
  have m = s → m < s + n + 1,
    from λ e, e ▸ lt_succ_of_le (le_add_right _ _),
  have l : m = s ∨ s + 1 ≤ m ↔ s ≤ m,
    by simpa only [eq_comm] using (@le_iff_eq_or_lt _ _ s m).symm,
  (mem_cons_iff _ _ _).trans $ by simp only [mem_Ico'_ℕ,
    or_and_distrib_left, or_iff_right_of_imp this, l, add_right_comm]; refl

theorem map_add_Ico'_ℕ (a) : ∀ s n : ℕ, map ((+) a) (Ico'_ℕ s n) = Ico'_ℕ (a + s) n
| s 0     := rfl
| s (n+1) := congr_arg (cons _) (map_add_Ico'_ℕ (s+1) n)

theorem map_sub_Ico'_ℕ (a) :
  ∀ (s n : ℕ) (h : a ≤ s), map (λ x, x - a) (Ico'_ℕ s n) = Ico'_ℕ (s - a) n
| s 0     _ := rfl
| s (n+1) h :=
begin
  convert congr_arg (cons (s-a)) (map_sub_Ico'_ℕ (s+1) n (nat.le_succ_of_le h)),
  rw nat.succ_sub h,
  refl,
end

theorem chain_succ_Ico'_ℕ : ∀ s n : ℕ, chain (λ a b, b = succ a) s (Ico'_ℕ (s+1) n)
| s 0     := chain.nil
| s (n+1) := (chain_succ_Ico'_ℕ (s+1) n).cons rfl

theorem chain_lt_Ico'_ℕ (s n : ℕ) : chain (<) s (Ico'_ℕ (s+1) n) :=
(chain_succ_Ico'_ℕ s n).imp (λ a b e, e.symm ▸ lt_succ_self _)

theorem pairwise_lt_Ico'_ℕ : ∀ s n : ℕ, pairwise (<) (Ico'_ℕ s n)
| s 0     := pairwise.nil
| s (n+1) := (chain_iff_pairwise (by exact λ a b c, lt_trans)).1 (chain_lt_Ico'_ℕ s n)

theorem nodup_Ico'_ℕ (s n : ℕ) : nodup (Ico'_ℕ s n) :=
(pairwise_lt_Ico'_ℕ s n).imp (λ a b, ne_of_lt)

@[simp] theorem Ico'_ℕ_append : ∀ s m n : ℕ, Ico'_ℕ s m ++ Ico'_ℕ (s+m) n = Ico'_ℕ s (n+m)
| s 0     n := rfl
| s (m+1) n := show s :: (Ico'_ℕ (s+1) m ++ Ico'_ℕ (s+m+1) n) = s :: Ico'_ℕ (s+1) (n+m),
               by rw [add_right_comm, Ico'_ℕ_append]

theorem Ico'_ℕ_sublist_right {s m n : ℕ} : Ico'_ℕ s m <+ Ico'_ℕ s n ↔ m ≤ n :=
⟨λ h, by simpa only [length_Ico'_ℕ] using length_le_of_sublist h,
 λ h, by rw [← nat.sub_add_cancel h, ← Ico'_ℕ_append]; apply sublist_append_left⟩

theorem Ico'_ℕ_subset_right {s m n : ℕ} : Ico'_ℕ s m ⊆ Ico'_ℕ s n ↔ m ≤ n :=
⟨λ h, le_of_not_lt $ λ hn, lt_irrefl (s+n) $
  (mem_Ico'_ℕ.1 $ h $ mem_Ico'_ℕ.2 ⟨le_add_right _ _, nat.add_lt_add_left hn s⟩).2,
 λ h, (Ico'_ℕ_sublist_right.2 h).subset⟩

theorem nth_Ico'_ℕ : ∀ s {m n : ℕ}, m < n → nth (Ico'_ℕ s n) m = some (s + m)
| s 0     (n+1) _ := rfl
| s (m+1) (n+1) h := (nth_Ico'_ℕ (s+1) (lt_of_add_lt_add_right h)).trans $
    by rw add_right_comm; refl

theorem Ico'_ℕ_concat (s n : ℕ) : Ico'_ℕ s (n + 1) = Ico'_ℕ s n ++ [s+n] :=
by rw add_comm n 1; exact (Ico'_ℕ_append s n 1).symm

theorem range_core_Ico'_ℕ : ∀ s n : ℕ, range_core s (Ico'_ℕ s n) = Ico'_ℕ 0 (n + s)
| 0     n := rfl
| (s+1) n := by rw [show n+(s+1) = n+1+s, from add_right_comm n s 1];
    exact range_core_Ico'_ℕ s (n+1)

theorem range_eq_Ico'_ℕ (n : ℕ) : range n = Ico'_ℕ 0 n :=
(range_core_Ico'_ℕ n 0).trans $ by rw zero_add

theorem range_succ_eq_map (n : ℕ) : range (n + 1) = 0 :: map succ (range n) :=
by rw [range_eq_Ico'_ℕ, range_eq_Ico'_ℕ, Ico'_ℕ,
       add_comm, ← map_add_Ico'_ℕ];
   congr; exact funext one_add

theorem Ico'_ℕ_eq_map_range (s n : ℕ) : Ico'_ℕ s n = map ((+) s) (range n) :=
by rw [range_eq_Ico'_ℕ, map_add_Ico'_ℕ]; refl

@[simp] theorem length_range (n : ℕ) : length (range n) = n :=
by simp only [range_eq_Ico'_ℕ, length_Ico'_ℕ]

@[simp] theorem range_eq_nil {n : ℕ} : range n = [] ↔ n = 0 :=
by rw [← length_eq_zero, length_range]

theorem pairwise_lt_range (n : ℕ) : pairwise (<) (range n) :=
by simp only [range_eq_Ico'_ℕ, pairwise_lt_Ico'_ℕ]

theorem nodup_range (n : ℕ) : nodup (range n) :=
by simp only [range_eq_Ico'_ℕ, nodup_Ico'_ℕ]

theorem range_sublist {m n : ℕ} : range m <+ range n ↔ m ≤ n :=
by simp only [range_eq_Ico'_ℕ, Ico'_ℕ_sublist_right]

theorem range_subset {m n : ℕ} : range m ⊆ range n ↔ m ≤ n :=
by simp only [range_eq_Ico'_ℕ, Ico'_ℕ_subset_right]

@[simp] theorem mem_range {m n : ℕ} : m ∈ range n ↔ m < n :=
by simp only [range_eq_Ico'_ℕ, mem_Ico'_ℕ, nat.zero_le, true_and, zero_add]

@[simp] theorem not_mem_range_self {n : ℕ} : n ∉ range n :=
mt mem_range.1 $ lt_irrefl _

@[simp] theorem self_mem_range_succ (n : ℕ) : n ∈ range (n + 1) :=
by simp only [succ_pos', lt_add_iff_pos_right, mem_range]

theorem nth_range {m n : ℕ} (h : m < n) : nth (range n) m = some m :=
by simp only [range_eq_Ico'_ℕ, nth_Ico'_ℕ _ h, zero_add]

theorem range_concat (n : ℕ) : range (succ n) = range n ++ [n] :=
by simp only [range_eq_Ico'_ℕ, Ico'_ℕ_concat, zero_add]

theorem iota_eq_reverse_Ico'_ℕ : ∀ n : ℕ, iota n = reverse (Ico'_ℕ 1 n)
| 0     := rfl
| (n+1) := by simp only [iota, Ico'_ℕ_concat, iota_eq_reverse_Ico'_ℕ n, reverse_append, add_comm]; refl

@[simp] theorem length_iota (n : ℕ) : length (iota n) = n :=
by simp only [iota_eq_reverse_Ico'_ℕ, length_reverse, length_Ico'_ℕ]

theorem pairwise_gt_iota (n : ℕ) : pairwise (>) (iota n) :=
by simp only [iota_eq_reverse_Ico'_ℕ, pairwise_reverse, pairwise_lt_Ico'_ℕ]

theorem nodup_iota (n : ℕ) : nodup (iota n) :=
by simp only [iota_eq_reverse_Ico'_ℕ, nodup_reverse, nodup_Ico'_ℕ]

theorem mem_iota {m n : ℕ} : m ∈ iota n ↔ 1 ≤ m ∧ m ≤ n :=
by simp only [iota_eq_reverse_Ico'_ℕ, mem_reverse, mem_Ico'_ℕ, add_comm, lt_succ_iff]

theorem reverse_Ico'_ℕ : ∀ s n : ℕ,
  reverse (Ico'_ℕ s n) = map (λ i, s + n - 1 - i) (range n)
| s 0     := rfl
| s (n+1) := by rw [Ico'_ℕ_concat, reverse_append, range_succ_eq_map];
  simpa only [show s + (n + 1) - 1 = s + n, from rfl, (∘),
    λ a i, show a - 1 - i = a - succ i, from pred_sub _ _,
    reverse_singleton, map_cons, nat.sub_zero, cons_append,
    nil_append, eq_self_iff_true, true_and, map_map]
  using reverse_Ico'_ℕ s n

/-- All elements of `fin n`, from `0` to `n-1`. -/
def fin_range (n : ℕ) : list (fin n) :=
(range n).pmap fin.mk (λ _, list.mem_range.1)

@[simp] lemma fin_range_zero : fin_range 0 = [] := rfl

@[simp] lemma mem_fin_range {n : ℕ} (a : fin n) : a ∈ fin_range n :=
mem_pmap.2 ⟨a.1, mem_range.2 a.2, fin.eta _ _⟩

lemma nodup_fin_range (n : ℕ) : (fin_range n).nodup :=
nodup_pmap (λ _ _ _ _, fin.veq_of_eq) (nodup_range _)

@[simp] lemma length_fin_range (n : ℕ) : (fin_range n).length = n :=
by rw [fin_range, length_pmap, length_range]

@[simp] lemma fin_range_eq_nil {n : ℕ} : fin_range n = [] ↔ n = 0 :=
by rw [← length_eq_zero, length_fin_range]

@[to_additive]
theorem prod_range_succ {α : Type u} [monoid α] (f : ℕ → α) (n : ℕ) :
  ((range n.succ).map f).prod = ((range n).map f).prod * f n :=
by rw [range_concat, map_append, map_singleton,
  prod_append, prod_cons, prod_nil, mul_one]

/-- A variant of `prod_range_succ` which pulls off the first
  term in the product rather than the last.-/
@[to_additive "A variant of `sum_range_succ` which pulls off the first term in the sum
  rather than the last."]
theorem prod_range_succ' {α : Type u} [monoid α] (f : ℕ → α) (n : ℕ) :
  ((range n.succ).map f).prod = f 0 * ((range n).map (λ i, f (succ i))).prod :=
nat.rec_on n
  (show 1 * f 0 = f 0 * 1, by rw [one_mul, mul_one])
  (λ _ hd, by rw [list.prod_range_succ, hd, mul_assoc, ←list.prod_range_succ])

@[simp] theorem enum_from_map_fst : ∀ n (l : list α),
  map prod.fst (enum_from n l) = Ico'_ℕ n l.length
| n []       := rfl
| n (a :: l) := congr_arg (cons _) (enum_from_map_fst _ _)

@[simp] theorem enum_map_fst (l : list α) :
  map prod.fst (enum l) = range l.length :=
by simp only [enum, enum_from_map_fst, range_eq_Ico'_ℕ]

@[simp] lemma nth_le_range {n} (i) (H : i < (range n).length) :
  nth_le (range n) i H = i :=
option.some.inj $ by rw [← nth_le_nth _, nth_range (by simpa using H)]

theorem of_fn_eq_pmap {α n} {f : fin n → α} :
  of_fn f = pmap (λ i hi, f ⟨i, hi⟩) (range n) (λ _, mem_range.1) :=
by rw [pmap_eq_map_attach]; from ext_le (by simp)
  (λ i hi1 hi2, by { simp at hi1, simp [nth_le_of_fn f ⟨i, hi1⟩, -subtype.val_eq_coe] })

theorem of_fn_id (n) : of_fn id = fin_range n := of_fn_eq_pmap

theorem of_fn_eq_map {α n} {f : fin n → α} :
  of_fn f = (fin_range n).map f :=
by rw [← of_fn_id, map_of_fn, function.right_id]

theorem nodup_of_fn {α n} {f : fin n → α} (hf : function.injective f) :
  nodup (of_fn f) :=
by rw of_fn_eq_pmap; from nodup_pmap
  (λ _ _ _ _ H, fin.veq_of_eq $ hf H) (nodup_range n)

end list
