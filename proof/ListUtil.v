Require Import List Omega.

Notation "[ ]" := nil : list_scope.
Notation "[ a ; .. ; b ]" := (a :: .. (b :: []) ..) : list_scope.

Definition length_tailrec {A} (xs:list A) :=
  fold_left (fun x _ => S x) xs 0.

Lemma length_tailrec_equiv: forall A (xs: list A),
  length_tailrec xs = length xs.
Proof.
exact fold_left_length.
Qed.

Definition rev_tailrec {A} (xs: list A) := List.rev' xs.

Lemma rev_tailrec_equiv: forall A (xs: list A),
  rev_tailrec xs = rev xs.
Proof.
  intros.
  rewrite rev_alt.
  reflexivity.
Qed.

Definition map_tailrec {A B} (f: A -> B) (xs: list A) :=
  rev_tailrec (fold_left (fun acc x => f x :: acc) xs []).

Lemma map_tailrec_equiv: forall A B (f: A -> B) (xs: list A),
  map_tailrec f xs = map f xs.
Proof.
  intros.
  unfold map_tailrec.
  rewrite rev_tailrec_equiv.
  set (body := fun acc x => f x :: acc).
  assert (Hlemma: forall xs ys zs, fold_left body xs (ys ++ zs) = fold_left body xs ys ++ zs).
  { clear.
    intros xs.
    induction xs; [reflexivity|].
    intros.
    simpl.
    rewrite <-IHxs.
    reflexivity.
  }
  induction xs; [reflexivity|].
  simpl.
  rewrite <-IHxs.
  rewrite <-rev_unit.
  rewrite <-Hlemma.
  reflexivity.
Qed.

Lemma rev_append_app_left: forall A (xs ys zs: list A),
  rev_append (ys ++ xs) zs = rev_append xs (rev_append ys zs).
Proof.
  intros.
  rewrite !rev_append_rev.
  rewrite rev_app_distr.
  rewrite app_assoc.
  reflexivity.
Qed.

Lemma app_same : forall A (xs ys zs : list A),
  xs ++  ys = xs ++ zs -> ys = zs.
Proof.
induction xs; intros; simpl in H.
 auto.

 inversion H.
 apply IHxs in H1.
 auto.
Qed.
Lemma length_lt_O: forall A (x : A) xs,
  length (x::xs) > 0.
Proof.
intros.
simpl.
omega.
Qed.

Lemma length_inv: forall A (x y : A) xs ys,
  length (x :: xs) = length (y :: ys) ->
  length xs = length ys.
Proof.
intros.
inversion H.
auto.
Qed.

Hint Resolve length_lt_O.


Fixpoint take {A} n (xs : list A) :=
  match n, xs with
    | O , _ => []
    | _ , [] => []
    | S m, x::xs =>
      x::take m xs
  end.

Fixpoint drop {A} n (xs : list A) :=
  match n, xs with
    | O , _ => xs
    | _ , [] => []
    | S m, x::xs =>
      drop m xs
  end.

Definition split_at {A} (n : nat) (xs : list A) : list A * list A :=
  (take n xs, drop n xs).

Lemma take_length : forall A ( xs ys : list A) n,
  n = List.length xs ->
  take n (xs ++ ys) = xs.
Proof.
induction xs; intros; simpl in *.
 rewrite H.
 reflexivity.

 rewrite H.
 simpl.
 rewrite IHxs; auto.
Qed.

Lemma drop_length : forall A ( xs ys : list A) n,
  n = List.length xs ->
  drop n (xs ++ ys) = ys.
Proof.
induction xs; intros; simpl in *.
 rewrite H.
 reflexivity.

 rewrite H.
 simpl.
 rewrite IHxs; auto.
Qed.

Lemma split_at_length : forall A (xs ys : list A),
  (xs, ys) = split_at (length xs) (xs ++ ys).
Proof.
intros.
unfold split_at.
rewrite take_length, drop_length; auto.
Qed.

Lemma take_length_lt : forall A (xs ys : list A) n,
  ys = take n xs ->
  List.length ys <= n.
Proof.
induction xs; intros.
 rewrite H.
 destruct n; simpl; omega...

 destruct n.
  rewrite H.
  simpl.
  auto...

  destruct ys; [ discriminate |].
  inversion H.
  rewrite <- H2.
  apply IHxs in H2.
  simpl.
  omega...
Qed.

Lemma split_at_length_lt : forall A (xs ys zs : list A) n,
  (xs, ys) = split_at n zs ->
  List.length xs <= n.
Proof.
intros.
unfold split_at in *.
inversion H.
apply (take_length_lt _ zs).
reflexivity.
Qed.

Lemma split_at_soundness : forall A (xs ys zs : list A) n,
  (ys,zs) = split_at n xs ->
  xs = ys ++ zs.
Proof.
induction xs; induction n; intros; simpl;
  try (inversion H; reflexivity).

  unfold split_at in *.
  simpl in H.
  destruct ys.
   inversion H.

   rewrite (IHxs ys zs n); auto.
    inversion H.
    reflexivity.

    inversion H.
    reflexivity.
Qed.

Lemma take_nil : forall A n,
  take n ([] : list A) = [].
Proof.
induction n; auto.
Qed.

Lemma take_drop_length : forall A ( xs ys : list A) n,
  take n xs = ys ->
  drop n xs = [ ] ->
  xs  = ys.
Proof.
induction xs; intros; simpl in *.
 rewrite take_nil in H.
 assumption.

 destruct n.
  simpl in H0.
  discriminate.

  simpl in *.
  destruct ys.
   discriminate.

   inversion H.
   rewrite H3.
   apply IHxs in H3; auto.
   rewrite H3.
   reflexivity.
Qed.

Fixpoint pair { A } ( xs : list A ) :=
  match xs with
    | [] => []
    | [x] => []
    | k :: v :: ys =>
      (k, v) :: pair ys
  end.

Definition unpair {A} (xs : list (A * A)) :=
  flat_map (fun x => [ fst x; snd x]) xs.

Lemma pair_unpair : forall A ( xs : list ( A * A )),
  pair (unpair xs) = xs.
Proof.
induction xs; intros; simpl; auto.
rewrite IHxs.
destruct a.
simpl.
reflexivity.
Qed.

Lemma unpair_pair : forall A n ( xs : list A),
  List.length xs = 2 * n ->
  unpair (pair xs) = xs.
Proof.
induction n; intros.
 destruct xs; auto.
 simpl in H.
 discriminate.

 destruct xs.
  simpl in H.
  discriminate...

  destruct xs.
   simpl in H.
   assert (1 <> S (n + S (n + 0))); [ omega | contradiction ]...

   replace (2 * S n) with (2 + 2 * n) in H; [| omega ].
   simpl in *.
   inversion H.
   apply IHn in H1.
   rewrite H1.
   reflexivity.
Qed.

Lemma pair_length' : forall A n (xs : list A),
  n = List.length (pair xs) ->
  2 * n <= List.length xs.
Proof.
induction n; intros; simpl.
 omega...

 destruct xs; simpl in *; [ discriminate |].
 destruct xs; simpl in *; [ discriminate |].
 inversion H.
 apply IHn in H1.
 omega.
Qed.


Lemma pair_length : forall A (xs : list A),
  2 * List.length (pair xs) <= List.length xs.
Proof.
intros.
apply pair_length'.
reflexivity.
Qed.

Lemma unpair_length : forall A ( xs : list (A * A)),
  List.length (unpair xs) = 2 * List.length xs.
Proof.
induction xs; simpl; auto.
rewrite IHxs.
omega.
Qed.

Lemma unpair_split_at: forall A (x1 x2 : A) xs ys,
  (unpair ((x1, x2) :: xs), ys) =
  split_at (2 * length ((x1, x2) :: xs)) (x1 :: x2 :: unpair xs ++ ys).
Proof.
intros.
replace (2 * (length ((x1,x2) :: xs))) with (length (unpair ((x1,x2)::xs))).
 apply split_at_length.

 simpl.
 rewrite unpair_length.
 omega.
Qed.

(* Class of functions that prepend something to their argument. These
 * will typically be tail-recursive functions that maintain an
 * accumulator. *)
Definition Prepending {A} (f: list A -> list A) := forall ys zs,
  f (ys ++ zs) = f ys ++ zs.

Lemma Prepending_nil: forall {A} f, Prepending f -> forall (zs: list A),
  f zs = f [] ++ zs.
Proof.
  unfold Prepending. intros * H *. apply (H [] zs).
Qed.

Lemma Prepending_rev_append: forall A (xs: list A),
  Prepending (rev_append xs).
Proof.
unfold Prepending.
intros.
rewrite !rev_append_rev.
rewrite app_assoc.
reflexivity.
Qed.
