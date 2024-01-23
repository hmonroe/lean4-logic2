import Logic.FirstOrder.Completeness.Completeness
import Logic.FirstOrder.Arith.Theory

namespace LO

namespace FirstOrder

namespace Arith
open Language

section model

variable (M : Type*) [Zero M] [One M] [Add M] [Mul M] [LT M]

instance standardModel : Structure ℒₒᵣ M where
  func := fun _ f =>
    match f with
    | ORing.Func.zero => fun _ => 0
    | ORing.Func.one  => fun _ => 1
    | ORing.Func.add  => fun v => v 0 + v 1
    | ORing.Func.mul  => fun v => v 0 * v 1
  rel := fun _ r =>
    match r with
    | ORing.Rel.eq => fun v => v 0 = v 1
    | ORing.Rel.lt => fun v => v 0 < v 1

instance : Structure.Eq ℒₒᵣ M :=
  ⟨by intro a b; simp[standardModel, Semiformula.Operator.val, Semiformula.Operator.Eq.sentence_eq, Semiformula.eval_rel]⟩

instance : Structure.Zero ℒₒᵣ M := ⟨rfl⟩

instance : Structure.One ℒₒᵣ M := ⟨rfl⟩

instance : Structure.Add ℒₒᵣ M := ⟨fun _ _ => rfl⟩

instance : Structure.Mul ℒₒᵣ M := ⟨fun _ _ => rfl⟩

instance : Structure.Eq ℒₒᵣ M := ⟨fun _ _ => iff_of_eq rfl⟩

instance : Structure.LT ℒₒᵣ M := ⟨fun _ _ => iff_of_eq rfl⟩

instance : ORing ℒₒᵣ := ORing.mk

lemma standardModel_unique (s : Structure ℒₒᵣ M)
    [Structure.Zero ℒₒᵣ M] [Structure.One ℒₒᵣ M] [Structure.Add ℒₒᵣ M] [Structure.Mul ℒₒᵣ M]
    [Structure.Eq ℒₒᵣ M] [Structure.LT ℒₒᵣ M] : s = standardModel M := Structure.ext _ _
  (funext₃ fun k f _ =>
    match k, f with
    | _, Language.Zero.zero => by simp[Matrix.empty_eq]; rfl
    | _, Language.One.one   => by simp[Matrix.empty_eq]; rfl
    | _, Language.Add.add   => by simp; rfl
    | _, Language.Mul.mul   => by simp; rfl)
  (funext₃ fun k r _ =>
    match k, r with
    | _, Language.Eq.eq => by simp; rfl
    | _, Language.LT.lt => by simp; rfl)

end model

namespace Standard

variable {μ : Type v} (e : Fin n → ℕ) (ε : μ → ℕ)

lemma modelsTheoryPAminus : ℕ ⊧ₘ* 𝐏𝐀⁻ := by
  intro σ h
  rcases h <;> simp[models_def, ←le_iff_eq_or_lt]
  case addAssoc => intro l m n; exact add_assoc l m n
  case addComm  => intro m n; exact add_comm m n
  case mulAssoc => intro l m n; exact mul_assoc l m n
  case mulComm  => intro m n; exact mul_comm m n
  case addEqOfLt => intro m n h; exact ⟨n - m, Nat.add_sub_of_le (le_of_lt h)⟩
  case oneLeOfZeroLt => intro n hn; exact hn
  case mulLtMul => rintro l m n h hl; exact (mul_lt_mul_right hl).mpr h
  case distr => intro l m n; exact Nat.mul_add l m n
  case ltTrans => intro l m n; exact Nat.lt_trans
  case ltTri => intro n m; exact Nat.lt_trichotomy n m

lemma modelsSuccInd (p : Semiformula ℒₒᵣ ℕ 1) : ℕ ⊧ₘ (∀ᶠ* succInd p) := by
  simp[Empty.eq_elim, succInd, models_iff, Matrix.constant_eq_singleton, Matrix.comp_vecCons',
    Semiformula.eval_substs, Semiformula.eval_rew_q Rew.toS, Function.comp]
  intro e hzero hsucc x; induction' x with x ih
  · exact hzero
  · exact hsucc x ih

lemma modelsPeano : ℕ ⊧ₘ* 𝐏𝐀 ∪ 𝐏𝐀⁻ ∪ 𝐄𝐪 :=
  by simp[Theory.Peano, Theory.IndScheme, modelsTheoryPAminus, Set.univ]; rintro _ p _ rfl; simp [modelsSuccInd]

end Standard

theorem Peano.Consistent : System.Consistent (𝐏𝐀 ∪ 𝐏𝐀⁻ ∪ 𝐄𝐪) :=
  Sound.consistent_of_model Standard.modelsPeano

section

variable (L : Language.{u}) [ORing L]

structure Cut (M : Type w) [s : Structure L M] where
  domain : Set M
  closedSucc : ∀ x ∈ domain, (ᵀ“#0 + 1”).bVal s ![x] ∈ domain
  closedLt : ∀ x y : M, Semiformula.PVal s ![x, y] “#0 < #1” → y ∈ domain → x ∈ domain

structure ClosedCut (M : Type w) [s : Structure L M] extends Structure.ClosedSubset L M where
  closedLt : ∀ x y : M, Semiformula.PVal s ![x, y] “#0 < #1” → y ∈ domain → x ∈ domain

end

abbrev Theory.trueArith : Theory ℒₒᵣ := Structure.theory ℒₒᵣ ℕ

notation "𝐓𝐀" => Theory.trueArith

variable (T : Theory ℒₒᵣ) [𝐄𝐪 ≾ T]

lemma oRing_consequence_of (σ : Sentence ℒₒᵣ)
  (H : ∀ (M : Type)
         [Zero M] [One M] [Add M] [Mul M] [LT M]
         [Theory.Mod M T],
         M ⊧ₘ σ) :
    T ⊨ σ := consequence_of T σ fun M _ _ _ _ _ s _ _ ↦ by
  rcases standardModel_unique M s
  exact H M

end Arith

end FirstOrder

end LO
