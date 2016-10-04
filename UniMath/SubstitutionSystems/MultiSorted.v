(**

This file formalizes multisorted binding signatures:

- Definition of multisorted binding signatures ([MultiSortedSig])
- Construction of a functor from a multisorted binding signature ([MultiSortedSigToFunctor])



Written by: Anders Mörtberg, 2016. The formalization follows a note written by Benedikt Ahrens and
Ralph Matthes, and is also inspired by discussions with them and Vladimir Voevodsky.

*)
Require Import UniMath.Foundations.Basics.PartD.
Require Import UniMath.Foundations.Basics.Sets.
Require Import UniMath.Foundations.Combinatorics.Lists.

Require Import UniMath.CategoryTheory.precategories.
Require Import UniMath.CategoryTheory.functor_categories.
Require Import UniMath.CategoryTheory.UnicodeNotations.
Require Import UniMath.CategoryTheory.whiskering.
Require Import UniMath.CategoryTheory.limits.graphs.limits.
Require Import UniMath.CategoryTheory.limits.graphs.colimits.
Require Import UniMath.CategoryTheory.limits.binproducts.
Require Import UniMath.CategoryTheory.limits.products.
Require Import UniMath.CategoryTheory.limits.bincoproducts.
Require Import UniMath.CategoryTheory.limits.coproducts.
Require Import UniMath.CategoryTheory.limits.terminal.
Require Import UniMath.CategoryTheory.limits.initial.
Require Import UniMath.CategoryTheory.FunctorAlgebras.
Require Import UniMath.CategoryTheory.exponentials.
Require Import UniMath.CategoryTheory.CocontFunctors.
Require Import UniMath.CategoryTheory.Monads.
Require Import UniMath.CategoryTheory.category_hset.
Require Import UniMath.CategoryTheory.category_hset_structures.
Require Import UniMath.CategoryTheory.HorizontalComposition.

Require Import UniMath.SubstitutionSystems.Signatures.
Require Import UniMath.SubstitutionSystems.SignatureExamples.
Require Import UniMath.SubstitutionSystems.SumOfSignatures.
Require Import UniMath.SubstitutionSystems.BinProductOfSignatures.
Require Import UniMath.SubstitutionSystems.SubstitutionSystems.
Require Import UniMath.SubstitutionSystems.LiftingInitial.
Require Import UniMath.SubstitutionSystems.MonadsFromSubstitutionSystems.

Local Notation "[ C , D ]" := (functor_Precategory C D).
Local Notation "# F" := (functor_on_morphisms F)(at level 3).

(** Swapping of functor arguments *)
(* TODO: Move upstream as well? *)
Section functor_swap.

Context {C D : precategory} {E : Precategory}.

Lemma functor_swap : functor C [D,E] → functor D [C,E].
Proof.
intros F.
mkpair.
- mkpair.
  + intro d; simpl.
  { mkpair.
    - mkpair.
      + intro c.
        apply (pr1 (F c) d).
      + intros a b f; apply (# F f).
    - abstract (split;
      [ now intro x; simpl; rewrite (functor_id F)
      | now intros a b c f g; simpl; rewrite (functor_comp F)]).
  }
  + intros a b f; simpl.
  { mkpair.
    - intros x; apply (# (pr1 (F x)) f).
    - abstract (intros c d g; simpl; apply pathsinv0, nat_trans_ax).
  }
- abstract (split;
  [ intros d; apply (nat_trans_eq (homset_property E)); intro c; simpl; apply functor_id
  | intros a b c f g; apply (nat_trans_eq (homset_property E)); intro x; simpl; apply functor_comp]).
Defined.

(* Lift the result to functor categories. It might be good to decompose this proof as the natural
transformations constructed might be useful later *)
Lemma functor_cat_swap : functor [C, [D, E]] [D, [C, E]].
Proof.
mkpair.
- apply (tpair _ functor_swap); simpl; intros F G α.
  mkpair.
  + intros d; simpl.
    mkpair.
    * intro c; apply (α c).
    * abstract (intros a b f; apply (nat_trans_eq_pointwise (nat_trans_ax α _ _ f) d)).
  + abstract (intros a b f; apply (nat_trans_eq (homset_property E)); intro c; simpl; apply nat_trans_ax).
- abstract (split;
  [ intro F; apply (nat_trans_eq (functor_category_has_homsets _ _ (homset_property E))); simpl; intro d;
    now apply (nat_trans_eq (homset_property E))
  | intros F G H α β; cbn; apply (nat_trans_eq (functor_category_has_homsets _ _ (homset_property E))); intro d;
    now apply (nat_trans_eq (homset_property E))]).
Defined.

End functor_swap.

(** * Discrete precategories *)
Section DiscreteCategory.

Variable (A : UU).

Definition discrete_precategory_data : precategory_data.
Proof.
mkpair.
- apply (A,,paths).
- mkpair; [ apply idpath | apply @pathscomp0 ].
Defined.

Definition is_precategory_discrete_precategory_data : is_precategory discrete_precategory_data.
Proof.
split; [split|]; trivial; intros.
+ apply pathscomp0rid.
+ apply path_assoc.
Qed.

Definition discrete_precategory : precategory :=
  (discrete_precategory_data,,is_precategory_discrete_precategory_data).

Lemma has_homsets_discrete_precategory (H : isofhlevel 3 A) : has_homsets discrete_precategory.
Proof.
intros ? ? ? ? ? ?; apply H.
Qed.

(** To define a functor out of a discrete category it suffices to give a function *)
Lemma functor_discrete_precategory (D : precategory) (f : A → D) :
  functor discrete_precategory D.
Proof.
mkpair.
+ mkpair.
  - apply f.
  - intros s t []; apply identity.
+ abstract (now split; [intro|intros a b c [] []; simpl; rewrite id_left]).
Defined.

End DiscreteCategory.

(** * Definition of multisorted binding signatures *)
Section MBindingSig.

Variable (sort : UU) (C : Precategory) (BP : BinProducts C) (BC : BinCoproducts C) (TC : Terminal C).
Variable (eq : isdeceq sort). (* Can we eliminate this assumption? *)

(** Define the discrete category of sorts *)
Let sort_cat : precategory := discrete_precategory sort.

Let hsC : has_homsets C := homset_property C.

(* (* TODO: Maybe this should be the global definition? *) *)
(* Let C : Precategory := (HSET,,has_homsets_HSET). *)

(** This represents "sort → C" *)
Let sortToC : Precategory := [sort_cat,C].

Local Lemma has_homsets_sortToC : has_homsets sortToC.
Proof.
apply homset_property.
Qed.

Local Definition BinProductsSortToCToC : BinProducts [sortToC,C].
Proof.
apply (BinProducts_functor_precat _ _ BP).
Defined.

Definition mk_sortToC (f : sort → C) : sortToC :=
  functor_discrete_precategory _ _ f.

(** Given a sort s this applies the sortToC to s and returns C *)
Definition sortToCToC (s : sort) : functor sortToC C.
Proof.
mkpair.
+ mkpair.
  - intro f; apply (pr1 f s).
  - simpl; intros a b f; apply (f s).
+ abstract (split; [intro f; apply idpath|intros f g h fg gh; apply idpath]).
Defined.



(** Definition of multi sorted signatures *)
Definition MultiSortedSig : UU :=
  Π (s : sort), Σ (I : UU), (I → list (list sort × sort)). (* × (isaset I). *)

Definition indices (M : MultiSortedSig) : sort → UU := fun s => pr1 (M s).

Definition args (M : MultiSortedSig) (s : sort) : indices M s → list (list sort × sort) :=
  pr2 (M s).

(* Lemma isaset_indices (M : MultiSortedSig) (s : sort) : isaset (indices M s). *)
(* Proof. *)
(* apply (pr2 (pr2 (M s))). *)
(* Qed. *)



Local Notation "'1'" := (TerminalObject TC).
Local Notation "a ⊕ b" := (BinCoproductObject _ (BC a b)) (at level 50).

(* Code for option as a function, below is the definition as a functor *)
(* Definition option : sort -> sortToC -> sortToC. *)
(* Proof. *)
(* intros s f. *)
(* apply mk_sortToC; intro t. *)
(* induction (eq s t) as [H|H]. *)
(* - apply (pr1 f t ⊕ 1). *)
(* - apply (pr1 f t). *)
(* Defined. *)

(* The function part of Definition 3 *)
Definition option_functor_data  (s : sort) : functor_data sortToC sortToC.
Proof.
mkpair.
+ intro f.
  apply mk_sortToC; intro t.
  induction (eq s t) as [H|H].
  * apply (pr1 f t ⊕ 1).
  * apply (pr1 f t).
+ intros F G α.
  mkpair.
  * simpl; intro t.
    induction (eq s t) as [p|p]; simpl; clear p.
    { apply (BinCoproductOfArrows _ _ _ (α t) (identity _)). }
    { apply α. }
  * abstract (now intros t1 t2 []; cbn; induction (eq s t1); simpl; rewrite id_left, id_right).
Defined.

Lemma is_functor_option_functor s : is_functor (option_functor_data s).
Proof.
split.
+ intros F; apply (nat_trans_eq hsC); intro t; simpl.
  induction (eq s t) as [p|p]; trivial; simpl; clear p.
  now apply pathsinv0, BinCoproductArrowUnique; rewrite id_left, id_right.
+ intros F G H αFG αGH; apply (nat_trans_eq hsC); intro t; simpl.
  induction (eq s t) as [p|p]; trivial; simpl; clear p.
  apply pathsinv0; eapply pathscomp0; [apply precompWithBinCoproductArrow|].
  rewrite !id_left; apply BinCoproductArrowUnique.
  * now rewrite BinCoproductIn1Commutes, assoc.
  * now rewrite BinCoproductIn2Commutes, id_left.
Qed.

(* This is Definition 3 (sorted context extension) from the note *)
Definition option_functor (s : sort) : functor sortToC sortToC :=
  tpair _ _ (is_functor_option_functor s).

(* option_functor for lists (also called option in the note) *)
Definition option_list (xs : list sort) : functor sortToC sortToC.
Proof.
use (foldr _ _ xs).
+ intros s F.
  apply (functor_composite (option_functor s) F).
+ apply functor_identity.
Defined.

(* This is X^a, defined as a function *)
Definition exp_fun (X : functor sortToC sortToC) (a : list sort × sort) :
  functor sortToC C.
Proof.
(* Version 1: *)
(* apply (functor_composite (functor_composite (option_list (pr1 a)) X) *)
(*                          (sortToCToC (pr2 a))). *)

(* Version 2: (same thing but reorganized using associativity) *)
apply (functor_composite (option_list (pr1 a))
                         (functor_composite X (sortToCToC (pr2 a)))).
Defined.

(* This stops Coq from unfolding horcomp too much *)
Local Arguments horcomp : simpl never.

(* This is X^a as a functor between functor categories *)
Lemma exp_functor (a : list sort × sort) : functor [sortToC,sortToC] [sortToC,C].
Proof.
mkpair.
- mkpair.
  + intro X; apply (exp_fun X a).
  + intros F G α.
    use (@horcomp sortToC _ C _ _ _ _ (nat_trans_id _)).
    use horcomp; [ assumption | apply nat_trans_id ].
- abstract (split;
  [ intro F; cbn;
    rewrite (horcomp_id_postwhisker _ _ _ has_homsets_sortToC hsC);
    rewrite post_whisker_identity; try apply hsC;
    rewrite (horcomp_id_postwhisker _ _ _ has_homsets_sortToC hsC);
    now rewrite post_whisker_identity; try apply hsC
  | intros F G H α β; cbn;
    rewrite !(horcomp_id_postwhisker _ _ _ has_homsets_sortToC hsC);
    rewrite !(horcomp_id_prewhisker hsC (option_list (pr1 a)));
    rewrite (post_whisker_composition sortToC _ _ hsC (sortToCToC (pr2 a)));
    now rewrite (pre_whisker_composition _ _ _ hsC)]).
Defined.

(* First version: *)
(* Definition exp_funs (xs : list (list sort × sort)) (X : functor sortToC sortToC) : *)
(*   functor sortToC C. *)
(* Proof. *)
(* set (XS := map (exp_fun X) xs). *)
(* (* The output for the empty list *) *)
(* set (T := constant_functor sortToC C emptyC). *)
(* apply (foldr1 (fun F G => BinProductObject _ (BinProductsSortToCToC F G)) T XS). *)
(* Defined. *)

(* This defines X^as where as is a list. Outputs a product of functors if the list is nonempty and
otherwise the constant functor. *)
Definition exp_functors (xs : list (list sort × sort)) :
  functor [sortToC,sortToC] [sortToC,C].
Proof.
(* Apply the exp functor to every element of the list *)
set (XS := map exp_functor xs).
(* If the list is empty we output the constant functor *)
set (T := constant_functor [sortToC,sortToC] [sortToC,C]
                           (constant_functor sortToC C TC)).
(* TODO: Maybe use indexed finite products instead of a fold? *)
apply (foldr1 (fun F G => BinProduct_of_functors _ _ BinProductsSortToCToC F G) T XS).
Defined.

(* This lemma is just here to check that the correct sort_cat gets pulled out when reorganizing
   arguments *)
Definition MultiSortedSigToFunctor_helper (C E F : precategory) (D G : Precategory)
  (H : functor F [[C,D],[E,G]]) : functor [C,D] [E,[F,G]] :=
    functor_composite (functor_swap H) functor_cat_swap.

(** * The functor constructed from a multisorted binding signature *)
Definition MultiSortedSigToFunctor (M : MultiSortedSig) (CC : Π s, Coproducts (indices M s) C) :
  functor [sortToC,sortToC] [sortToC,sortToC].
Proof.
(* First reorganize so that the last sort argument is first: *)
apply MultiSortedSigToFunctor_helper.
(* As we're defining a functor out of a discrete category it suffices to give a function: *)
apply functor_discrete_precategory; intro s.
(* This is then a coproduct of functors (for this to exist the indices need to be a set) *)
use (coproduct_of_functors (indices M s)).
+ apply Coproducts_functor_precat, CC.
+ intros y; apply (exp_functors (args M s y)).
Defined.

End MBindingSig.
