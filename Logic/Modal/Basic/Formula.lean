import Logic.Modal.LogicSymbol

namespace LO

namespace Modal

inductive Formula (α : Type u) : Type u where
  | verum  : Formula α
  | falsum : Formula α
  | atom   : α → Formula α
  | natom  : α → Formula α
  | and    : Formula α → Formula α → Formula α
  | or     : Formula α → Formula α → Formula α
  | box    : Formula α → Formula α
  | dia    : Formula α → Formula α

namespace Formula

variable
  {α : Type u} {α₁ : Type u₁} {α₂ : Type u₂} {α₃ : Type u₃}

def neg : Formula α → Formula α
  | verum   => falsum
  | falsum  => verum
  | atom a  => natom a
  | natom a => atom a
  | and p q => or (neg p) (neg q)
  | or p q  => and (neg p) (neg q)
  | box a   => dia $ neg a
  | dia a   => box $ neg a

lemma neg_neg (p : Formula α) : neg (neg p) = p :=
  by induction p <;> simp[*, neg]

instance : ModalLogicSymbol (Formula α) where
  tilde := neg
  arrow := fun p q => or (neg p) q
  wedge := and
  vee := or
  top := verum
  bot := falsum
  box := box
  dia := dia

section ToString

variable [ToString α]

def toStr : Formula α → String
  | ⊤       => "\\top"
  | ⊥       => "\\bot"
  | atom a  => "{" ++ toString a ++ "}"
  | natom a => "\\lnot {" ++ toString a ++ "}"
  | p ⋏ q   => "\\left(" ++ toStr p ++ " \\land " ++ toStr q ++ "\\right)"
  | p ⋎ q   => "\\left(" ++ toStr p ++ " \\lor "  ++ toStr q ++ "\\right)"
  | box p      => "\\Box " ++ toStr p
  | dia p      => "\\Diamond " ++ toStr p

instance : Repr (Formula α) := ⟨fun t _ => toStr t⟩

instance : ToString (Formula α) := ⟨toStr⟩

end ToString

@[simp] lemma neg_top : ~(⊤ : Formula α) = ⊥ := rfl

@[simp] lemma neg_bot : ~(⊥ : Formula α) = ⊤ := rfl

@[simp] lemma neg_atom (a : α) : ~(atom a) = natom a := rfl

@[simp] lemma neg_natom (a : α) : ~(natom a) = atom a := rfl

@[simp] lemma neg_and (p q : Formula α) : ~(p ⋏ q) = ~p ⋎ ~q := rfl

@[simp] lemma neg_or (p q : Formula α) : ~(p ⋎ q) = ~p ⋏ ~q := rfl

@[simp] lemma neg_box (p : Formula α) : ~(□p) = ◇(~p) := rfl

@[simp] lemma neg_dia (p : Formula α) : ~(◇p) = □(~p) := rfl

@[simp] lemma neg_neg' (p : Formula α) : ~~p = p := neg_neg p

@[simp] lemma neg_inj (p q : Formula α) : ~p = ~q ↔ p = q := by
  constructor
  · intro h; simpa using congr_arg (~·) h
  · exact congr_arg _

lemma neg_eq (p : Formula α) : ~p = neg p := rfl

lemma imp_eq (p q : Formula α) : p ⟶ q = ~p ⋎ q := rfl

lemma iff_eq (p q : Formula α) : p ⟷ q = (~p ⋎ q) ⋏ (~q ⋎ p) := rfl

@[simp] lemma and_inj (p₁ q₁ p₂ q₂ : Formula α) : p₁ ⋏ p₂ = q₁ ⋏ q₂ ↔ p₁ = q₁ ∧ p₂ = q₂ :=
by simp[Wedge.wedge]

@[simp] lemma or_inj (p₁ q₁ p₂ q₂ : Formula α) : p₁ ⋎ p₂ = q₁ ⋎ q₂ ↔ p₁ = q₁ ∧ p₂ = q₂ :=
by simp[Vee.vee]

@[simp] lemma box_inj (p q : Formula α) : □p = □q ↔ p = q := by simp[Box.box]

@[simp] lemma dia_inj (p q : Formula α) : ◇p = ◇q ↔ p = q := by simp[Dia.dia]

instance : DeMorgan (Formula α) where
  verum := rfl
  falsum := rfl
  and := by simp
  or := by simp
  imply := by simp[imp_eq]
  neg := by simp

def complexity : Formula α → ℕ
| ⊤       => 0
| ⊥       => 0
| atom _  => 0
| natom _ => 0
| p ⋏ q   => max p.complexity q.complexity + 1
| p ⋎ q   => max p.complexity q.complexity + 1
| box p   => p.complexity + 1
| dia p   => p.complexity + 1

@[simp] lemma complexity_top : complexity (⊤ : Formula α) = 0 := rfl

@[simp] lemma complexity_bot : complexity (⊥ : Formula α) = 0 := rfl

@[simp] lemma complexity_rel (a : α) : complexity (atom a) = 0 := rfl

@[simp] lemma complexity_nrel (a : α) : complexity (natom a) = 0 := rfl

@[simp] lemma complexity_and (p q : Formula α) : complexity (p ⋏ q) = max p.complexity q.complexity + 1 := rfl
@[simp] lemma complexity_and' (p q : Formula α) : complexity (and p q) = max p.complexity q.complexity + 1 := rfl

@[simp] lemma complexity_or (p q : Formula α) : complexity (p ⋎ q) = max p.complexity q.complexity + 1 := rfl
@[simp] lemma complexity_or' (p q : Formula α) : complexity (or p q) = max p.complexity q.complexity + 1 := rfl

@[simp] lemma complexity_box (p : Formula α) : complexity (□p) = p.complexity + 1 := rfl
@[simp] lemma complexity_box' (p : Formula α) : complexity (box p) = p.complexity + 1 := rfl

@[simp] lemma complexity_dia (p : Formula α) : complexity (◇p) = p.complexity + 1 := rfl
@[simp] lemma complexity_dia' (p : Formula α) : complexity (dia p) = p.complexity + 1 := rfl

@[elab_as_elim]
def cases' {C : Formula α → Sort w}
    (hverum  : C ⊤)
    (hfalsum : C ⊥)
    (hrel    : ∀ a : α, C (atom a))
    (hnrel   : ∀ a : α, C (natom a))
    (hand    : ∀ (p q : Formula α), C (p ⋏ q))
    (hor     : ∀ (p q : Formula α), C (p ⋎ q))
    (hbox    : ∀ (p : Formula α), C (□p))
    (hdia    : ∀ (p : Formula α), C (◇p))
    : (p : Formula α) → C p
  | ⊤       => hverum
  | ⊥       => hfalsum
  | atom a  => hrel a
  | natom a => hnrel a
  | p ⋏ q   => hand p q
  | p ⋎ q   => hor p q
  | box p   => hbox p
  | dia p   => hdia p

@[elab_as_elim]
def rec' {C : Formula α → Sort w}
  (hverum  : C ⊤)
  (hfalsum : C ⊥)
  (hrel    : ∀ a : α, C (atom a))
  (hnrel   : ∀ a : α, C (natom a))
  (hand    : ∀ (p q : Formula α), C p → C q → C (p ⋏ q))
  (hor     : ∀ (p q : Formula α), C p → C q → C (p ⋎ q))
  (hbox    : ∀ (p : Formula α), C p → C (□p))
  (hdia    : ∀ (p : Formula α), C p → C (◇p))
  : (p : Formula α) → C p
  | ⊤       => hverum
  | ⊥       => hfalsum
  | atom a  => hrel a
  | natom a => hnrel a
  | p ⋏ q   => hand p q (rec' hverum hfalsum hrel hnrel hand hor hbox hdia p) (rec' hverum hfalsum hrel hnrel hand hor hbox hdia q)
  | p ⋎ q   => hor p q (rec' hverum hfalsum hrel hnrel hand hor hbox hdia p) (rec' hverum hfalsum hrel hnrel hand hor hbox hdia q)
  | box p   => hbox p (rec' hverum hfalsum hrel hnrel hand hor hbox hdia p)
  | dia p   => hdia p (rec' hverum hfalsum hrel hnrel hand hor hbox hdia p)

@[simp] lemma complexity_neg (p : Formula α) : complexity (~p) = complexity p :=
  by induction p using rec' <;> simp[*]

section Decidable

variable [DecidableEq α]

def hasDecEq : (p q : Formula α) → Decidable (p = q)
  | ⊤,       q => by cases q using cases' <;>
      { simp; try { exact isFalse not_false }; try { exact isTrue trivial } }
  | ⊥,       q => by cases q using cases' <;>
      { simp; try { exact isFalse not_false }; try { exact isTrue trivial } }
  | atom a,  q => by
      cases q using cases' <;> try { simp; exact isFalse not_false }
      simp; exact decEq _ _
  | natom a, q => by
      cases q using cases' <;> try { simp; exact isFalse not_false }
      simp; exact decEq _ _
  | p ⋏ q,   r => by
      cases r using cases' <;> try { simp; exact isFalse not_false }
      case hand p' q' =>
        exact match hasDecEq p p' with
        | isTrue hp =>
          match hasDecEq q q' with
          | isTrue hq  => isTrue (hp ▸ hq ▸ rfl)
          | isFalse hq => isFalse (by simp[hp, hq])
        | isFalse hp => isFalse (by simp[hp])
  | p ⋎ q,   r => by
      cases r using cases' <;> try { simp; exact isFalse not_false }
      case hor p' q' =>
        exact match hasDecEq p p' with
        | isTrue hp =>
          match hasDecEq q q' with
          | isTrue hq  => isTrue (hp ▸ hq ▸ rfl)
          | isFalse hq => isFalse (by simp[hp, hq])
        | isFalse hp => isFalse (by simp[hp])
  | □p,      q => by
      cases q using cases' <;> try { simp; exact isFalse not_false }
      case hbox p' =>
        exact match hasDecEq p p' with
        | isTrue hp  => isTrue (hp ▸ rfl)
        | isFalse hp => isFalse (by simp [hp];)
  |◇p,      q => by
      cases q using cases' <;> try { simp; exact isFalse not_false }
      case hdia p' =>
        exact match hasDecEq p p' with
        | isTrue hp  => isTrue (hp ▸ rfl)
        | isFalse hp => isFalse (by simp [hp];)

instance : DecidableEq (Formula α) := hasDecEq

end Decidable

lemma ne_of_ne_complexity {p q : Formula α} (h : p.complexity ≠ q.complexity) : p ≠ q :=
  by rintro rfl; contradiction

end Formula

abbrev Theory (α : Type*) := Set (Formula α)

end Modal

end LO
