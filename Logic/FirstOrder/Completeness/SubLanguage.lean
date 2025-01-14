import Logic.FirstOrder.Basic

namespace LO

namespace FirstOrder

set_option linter.unusedVariables false

variable {L : Language.{u}} {L₁ : Language.{u}} {L₂ : Language.{u}}

namespace Language

def subLanguage (L : Language) (pfunc : ∀ k, L.Func k → Prop) (prel : ∀ k, L.Rel k → Prop) :
    Language where
  Func := fun k => Subtype (pfunc k)
  Rel  := fun k => Subtype (prel k)

section subLanguage

variable (L) {pf : (k : ℕ) → L.Func k → Prop} {pr : (k : ℕ) → L.Rel k → Prop}

def ofSubLanguage : subLanguage L pf pr →ᵥ L where
  func := Subtype.val
  rel  := Subtype.val

@[simp] lemma ofSubLanguage_onFunc {k : ℕ} :
    L.ofSubLanguage.func p = p.val := rfl

@[simp] lemma ofSubLanguage_onRel {k : ℕ} :
    L.ofSubLanguage.rel p = p.val := rfl

end subLanguage

end Language

namespace Semiterm

open Language
variable [∀ k, DecidableEq (L.Func k)]

def lang : Semiterm L μ n → Finset (Σ k, L.Func k)
  | #_       => ∅
  | &_       => ∅
  | func f v => insert ⟨_, f⟩ $ Finset.biUnion Finset.univ (fun i => lang (v i))

@[simp] lemma lang_func {k} (f : L.Func k) (v : Fin k → Semiterm L μ n) :
    ⟨k, f⟩ ∈ (func f v).lang := by simp[lang]

lemma lang_func_ss {k} (f : L.Func k) (v : Fin k → Semiterm L μ n) (i) :
    (v i).lang ⊆ (func f v).lang :=
  by intros x; simp[lang]; intros h; exact Or.inr ⟨i, h⟩

def toSubLanguage' (pf : ∀ k, L.Func k → Prop) (pr : ∀ k, L.Rel k → Prop) : ∀ t : Semiterm L μ n,
    (∀ k f, ⟨k, f⟩ ∈ t.lang → pf k f) → Semiterm (subLanguage L pf pr) μ n
  | #x,                    _ => #x
  | &x,                    _ => &x
  | func (arity := k) f v, h => func ⟨f, h k f (by simp)⟩
      (fun i => toSubLanguage' pf pr (v i) (fun k' f' h' => h k' f' (lang_func_ss f v i h')))

@[simp] lemma lMap_toSubLanguage' (pf : ∀ k, L.Func k → Prop) (pr : ∀ k, L.Rel k → Prop)
  (t : Semiterm L μ n) (h : ∀ k f, ⟨k, f⟩ ∈ t.lang → pf k f) :
    (t.toSubLanguage' pf pr h).lMap L.ofSubLanguage = t :=
  by induction t <;> simp[*, toSubLanguage', lMap_func]

end Semiterm

namespace Semiformula

variable [∀ k, DecidableEq (L.Func k)] [∀ k, DecidableEq (L.Rel k)]

noncomputable def langFunc : ∀ {n}, Semiformula L μ n → Finset (Σ k, L.Func k)
  | _, ⊤        => ∅
  | _, ⊥        => ∅
  | _, rel  _ v => Finset.biUnion Finset.univ (fun i => (v i).lang)
  | _, nrel _ v => Finset.biUnion Finset.univ (fun i => (v i).lang)
  | _, p ⋏ q    => langFunc p ∪ langFunc q
  | _, p ⋎ q    => langFunc p ∪ langFunc q
  | _, ∀' p     => langFunc p
  | _, ∃' p     => langFunc p

noncomputable def langRel : ∀ {n}, Semiformula L μ n → Finset (Σ k, L.Rel k)
  | _, ⊤        => ∅
  | _, ⊥        => ∅
  | _, rel  r _ => {⟨_, r⟩}
  | _, nrel r _ => {⟨_, r⟩}
  | _, p ⋏ q    => langRel p ∪ langRel q
  | _, p ⋎ q    => langRel p ∪ langRel q
  | _, ∀' p     => langRel p
  | _, ∃' p     => langRel p

lemma langFunc_rel_ss {k} (r : L.Rel k) (v : Fin k → Semiterm L μ n) (i) :
    (v i).lang ⊆ (rel r v).langFunc :=
  by intros x; simp[langFunc]; intros h; exact ⟨i, h⟩

def toSubLanguage' (pf : ∀ k, L.Func k → Prop) (pr : ∀ k, L.Rel k → Prop) : ∀ {n} (p : Semiformula L μ n),
    (∀ k f, ⟨k, f⟩ ∈ p.langFunc → pf k f) →
    (∀ k r, ⟨k, r⟩ ∈ p.langRel → pr k r) →
    Semiformula (L.subLanguage pf pr) μ n
  | _, ⊤,        _,  _  => ⊤
  | _, ⊥,        _,  _  => ⊥
  | _, rel r v,  hf, hr =>
      rel ⟨r, hr _ r (by simp[langRel])⟩
        (fun i => (v i).toSubLanguage' pf pr (fun k f h => hf k f (langFunc_rel_ss r v i h)))
  | _, nrel r v, hf, hr =>
      nrel ⟨r, hr _ r (by simp[langRel])⟩
        (fun i => (v i).toSubLanguage' pf pr (fun k f h => hf k f (langFunc_rel_ss r v i h)))
  | _, p ⋏ q,    hf, hr =>
      toSubLanguage' pf pr p (fun k f h => hf k f (Finset.mem_union_left _ h)) (fun k r h => hr k r (Finset.mem_union_left _ h)) ⋏
      toSubLanguage' pf pr q (fun k f h => hf k f (Finset.mem_union_right _ h)) (fun k r h => hr k r (Finset.mem_union_right _ h))
  | _, p ⋎ q,    hf, hr =>
      toSubLanguage' pf pr p (fun k f h => hf k f (Finset.mem_union_left _ h)) (fun k r h => hr k r (Finset.mem_union_left _ h)) ⋎
      toSubLanguage' pf pr q (fun k f h => hf k f (Finset.mem_union_right _ h)) (fun k r h => hr k r (Finset.mem_union_right _ h))
  | _, ∀' p,     hf, hr => ∀' toSubLanguage' pf pr p hf hr
  | _, ∃' p,     hf, hr => ∃' toSubLanguage' pf pr p hf hr

@[simp] lemma lMap_toSubLanguage'
  (pf : ∀ k, L.Func k → Prop) (pr : ∀ k, L.Rel k → Prop) {n} (p : Semiformula L μ n)
  (hf : ∀ k f, ⟨k, f⟩ ∈ p.langFunc → pf k f) (hr : ∀ k r, ⟨k, r⟩ ∈ p.langRel → pr k r) :
    lMap L.ofSubLanguage (p.toSubLanguage' pf pr hf hr) = p := by
  induction p using rec' <;> simp[*, toSubLanguage', lMap_rel, lMap_nrel]

noncomputable def languageFuncIndexed (p : Semiformula L μ n) (k) : Finset (L.Func k) :=
  Finset.preimage (langFunc p) (Sigma.mk k) (Set.injOn_of_injective sigma_mk_injective _)

noncomputable def languageRelIndexed (p : Semiformula L μ n) (k) : Finset (L.Rel k) :=
  Finset.preimage (langRel p) (Sigma.mk k) (Set.injOn_of_injective sigma_mk_injective _)

abbrev languageFinset (Γ : Finset (Semiformula L μ n)) : Language :=
  Language.subLanguage L (fun k f => ∃ p ∈ Γ, ⟨k, f⟩ ∈ langFunc p) (fun k r => ∃ p ∈ Γ, ⟨k, r⟩ ∈ langRel p)

noncomputable instance (Γ : Finset (Semiformula L μ n)) (k) : Fintype ((languageFinset Γ).Func k) :=
  Fintype.subtype (Γ.biUnion (languageFuncIndexed · k)) (by simp[languageFuncIndexed])

noncomputable instance (Γ : Finset (Semiformula L μ n)) (k) : Fintype ((languageFinset Γ).Rel k) :=
  Fintype.subtype (Γ.biUnion (languageRelIndexed · k)) (by simp[languageRelIndexed])

def toSubLanguageFinsetSelf {Γ : Finset (Semiformula L μ n)} {p} (h : p ∈ Γ) : Semiformula (languageFinset Γ) μ n :=
  p.toSubLanguage' _ _ (fun _ _ hf => ⟨p, h, hf⟩) (fun _ _ hr => ⟨p, h, hr⟩)

@[simp] lemma lMap_toSubLanguageFinsetSelf {Γ : Finset (Semiformula L μ n)} {p} (h : p ∈ Γ) :
    lMap L.ofSubLanguage (toSubLanguageFinsetSelf h) = p :=
  lMap_toSubLanguage' _ _ _ _ _

end Semiformula

namespace Structure

instance subLanguageStructure {pf : ∀ k, L.Func k → Prop} {pr : ∀ k, L.Rel k → Prop}
  {M : Type w} (s : Structure L M) : Structure (Language.subLanguage L pf pr) M :=
  s.lMap (Language.ofSubLanguage L)

noncomputable def extendStructure (Φ : L₁ →ᵥ L₂) {M : Type w} [Nonempty M] (s : Structure L₁ M) : Structure L₂ M where
  func := fun {k} f₂ v => Classical.epsilon (fun y => ∃ f₁ : L₁.Func k, Φ.func f₁ = f₂ ∧ y = s.func f₁ v)
  rel  := fun {k} r₂ v => ∃ r₁ : L₁.Rel k, Φ.rel r₁ = r₂ ∧ s.rel r₁ v

namespace extendStructure

variable
  (Φ : L₁ →ᵥ L₂)
  (injf : ∀ k, Function.Injective (Φ.func : L₁.Func k → L₂.Func k))
  (injr : ∀ k, Function.Injective (Φ.rel : L₁.Rel k → L₂.Rel k))
  {M : Type u} [Nonempty M] (s₁ : Structure L₁ M)
  {n} (e : Fin n → M) (ε : μ → M)

protected lemma func
  {k} (injf : Function.Injective (Φ.func : L₁.Func k → L₂.Func k)) (f₁ : L₁.Func k) (v : Fin k → M) :
    (s₁.extendStructure Φ).func (Φ.func f₁) v = s₁.func f₁ v := by
  simp[extendStructure]
  have : ∃ y, ∃ f₁' : L₁.Func k, Φ.func f₁' = Φ.func f₁ ∧ y = s₁.func f₁' v := ⟨s₁.func f₁ v, f₁, rfl, rfl⟩
  rcases Classical.epsilon_spec this with ⟨f', f'eq, h⟩
  rcases injf f'eq with rfl; exact h

protected lemma rel
  {k} (injr : Function.Injective (Φ.rel : L₁.Rel k → L₂.Rel k)) (r₁ : L₁.Rel k) (v : Fin k → M) :
    (s₁.extendStructure Φ).rel (Φ.rel r₁) v ↔ s₁.rel r₁ v := by
  simp[extendStructure]; refine ⟨by intros h; rcases h with ⟨r₁', e, h⟩; rcases injr e; exact h, by intros h; refine ⟨r₁, rfl, h⟩⟩

lemma val_lMap
    (injf : ∀ k, Function.Injective (Φ.func : L₁.Func k → L₂.Func k))
    (s₁ : Structure L₁ M) (t : Semiterm L₁ μ n) :
    Semiterm.val (s₁.extendStructure Φ) e ε (t.lMap Φ) = Semiterm.val s₁ e ε t := by
  induction t <;> simp[*, Semiterm.lMap_func, Semiterm.val_func]
  case func k f v ih =>
    exact extendStructure.func Φ s₁ (injf k) f (fun i => Semiterm.val s₁ e ε (v i))

open Semiformula

lemma eval_lMap {p : Semiformula L₁ μ n} :
    Eval (s₁.extendStructure Φ) e ε (lMap Φ p) ↔ Eval s₁ e ε p := by
  induction p using Semiformula.rec' <;> simp[*, val_lMap Φ e ε injf s₁, Semiformula.lMap_rel, Semiformula.lMap_nrel, eval_rel, eval_nrel]
  · case hrel k r v =>
    exact extendStructure.rel Φ s₁ (injr k) r (fun i => Semiterm.val s₁ e ε (v i))
  · case hnrel k r v =>
    simpa[not_iff_not] using
      extendStructure.rel Φ s₁ (injr k) r (fun i => Semiterm.val s₁ e ε (v i))

lemma models_lMap (σ : Sentence L₁) :
    Semantics.realize (s₁.extendStructure Φ).toStruc (Semiformula.lMap Φ σ) ↔ Semantics.realize s₁.toStruc σ := by
  simp[Semantics.realize, Val, eval_lMap Φ injf injr]

end extendStructure

end Structure

section lMap

variable
  (Φ : L₁ →ᵥ L₂)
  (injf : ∀ k, Function.Injective (Φ.func : L₁.Func k → L₂.Func k))
  (injr : ∀ k, Function.Injective (Φ.rel : L₁.Rel k → L₂.Rel k))

lemma lMap_models_lMap_iff {T : Theory L₁} {σ : Sentence L₁} :
    Theory.lMap Φ T ⊨ Semiformula.lMap Φ σ ↔ T ⊨ σ := by
  constructor
  · intro h s₁ hs₁
    exact (Structure.extendStructure.models_lMap Φ injf injr s₁.struc σ).mp $ h
      (by simp[Semantics.realizeTheory, Theory.lMap];
          intro σ hσ; exact (Structure.extendStructure.models_lMap (Φ := Φ) injf injr s₁.struc σ).mpr (hs₁ hσ))
  · exact lMap_models_lMap

lemma satisfiableTheory_lMap {T : Theory L₁} (s : Semantics.SatisfiableTheory T) :
    Semantics.SatisfiableTheory (Semiformula.lMap Φ '' T) := by
  rcases s with ⟨⟨M, i, s⟩, hM⟩
  exact ⟨⟨M, i, s.extendStructure Φ⟩, by
    simp[Semantics.realizeTheory]
    intro σ hσ
    exact (Structure.extendStructure.models_lMap Φ injf injr s σ).mpr (hM hσ)⟩

end lMap

end FirstOrder

end LO
