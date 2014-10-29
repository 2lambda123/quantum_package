open Qptypes;;
open Qputils;;
open Core.Std;;

module Mo_basis : sig
  type t = 
    { mo_tot_num      : MO_number.t ;
      mo_label        : MO_label.t;
      mo_occ          : MO_occ.t array;
      mo_coef         : (MO_coef.t array) array;
    } with sexp
  ;;
  val read : unit -> t
  val to_string : t -> string
  val debug : t -> string
end = struct
  type t = 
    { mo_tot_num      : MO_number.t ;
      mo_label        : MO_label.t;
      mo_occ          : MO_occ.t array;
      mo_coef         : (MO_coef.t array) array;
    } with sexp
  ;;

  let get_default = Qpackage.get_ezfio_default "mo_basis";;

  let read_mo_label () = 
    if not (Ezfio.has_mo_basis_mo_label ()) then
       Ezfio.set_mo_basis_mo_label "None"
    ;
    Ezfio.get_mo_basis_mo_label ()
    |> MO_label.of_string
  ;;

  let read_mo_tot_num () =
    Ezfio.get_mo_basis_mo_tot_num ()
    |> MO_number.of_int
  ;;

  let read_mo_occ () =
    if not (Ezfio.has_mo_basis_mo_label ()) then
      begin
        let elec_alpha_num = Ezfio.get_electrons_elec_alpha_num () 
        and elec_beta_num = Ezfio.get_electrons_elec_beta_num ()
        and mo_tot_num = MO_number.to_int (read_mo_tot_num ()) in
        let data = Array.init mo_tot_num ~f:(fun i ->
          if (i<elec_beta_num) then 2.
          else if (i < elec_alpha_num) then 1.
          else 0.) |> Array.to_list in
        Ezfio.ezfio_array_of_list ~rank:1 
          ~dim:[| mo_tot_num |] ~data:data
        |> Ezfio.set_mo_basis_mo_occ
      end;
    (Ezfio.get_mo_basis_mo_occ () ).Ezfio.data
    |> Ezfio.flattened_ezfio_data
    |> Array.map ~f:MO_occ.of_float
  ;;

  let read_mo_coef () =
    let a = (Ezfio.get_mo_basis_mo_coef () ).Ezfio.data
    |> Ezfio.flattened_ezfio_data
    |> Array.map ~f:MO_coef.of_float
    in
    let mo_tot_num = read_mo_tot_num () |> MO_number.to_int in
    let ao_num = (Array.length a)/mo_tot_num in
    Array.init mo_tot_num ~f:(fun j ->
      Array.sub ~pos:(j*ao_num) ~len:(ao_num) a
    )
  ;;

  let read () =
    { mo_tot_num      = read_mo_tot_num ();
      mo_label        = read_mo_label () ;
      mo_occ          = read_mo_occ ();
      mo_coef         = read_mo_coef ();
    }
  ;;

  let mo_coef_to_string mo_coef =
    let ao_num = Array.length mo_coef.(0) 
    and mo_tot_num = Array.length mo_coef in
    let rec print_five imin imax =
      match (imax-imin+1) with 
      | 1 ->
          let header = [ Printf.sprintf "  #%15d" (imin+1) ; ] in
          let new_lines = 
            List.init ao_num ~f:(fun i ->
              Printf.sprintf "  %3d %15.10f " (i+1)
              (MO_coef.to_float mo_coef.(imin  ).(i)) )
          in header @ new_lines
      | 2 ->
          let header = [ Printf.sprintf "  #%15d %15d" (imin+1) (imin+2) ; ] in
          let new_lines = 
            List.init ao_num ~f:(fun i ->
              Printf.sprintf "  %3d %15.10f %15.10f" (i+1)
              (MO_coef.to_float mo_coef.(imin  ).(i))
              (MO_coef.to_float mo_coef.(imin+1).(i)) )
          in header @ new_lines
      | 3 ->
          let header = [ Printf.sprintf "  #%15d %15d %15d"
              (imin+1) (imin+2) (imin+3); ] in
          let new_lines = 
            List.init ao_num ~f:(fun i ->
              Printf.sprintf "  %3d %15.10f %15.10f %15.10f" (i+1)
              (MO_coef.to_float mo_coef.(imin  ).(i))
              (MO_coef.to_float mo_coef.(imin+1).(i))
              (MO_coef.to_float mo_coef.(imin+2).(i)) )
          in header @ new_lines
      | 4 ->
          let header = [ Printf.sprintf "  #%15d %15d %15d %15d"
              (imin+1) (imin+2) (imin+3) (imin+4) ; ] in
          let new_lines = 
            List.init ao_num ~f:(fun i ->
              Printf.sprintf "  %3d %15.10f %15.10f %15.10f %15.10f" (i+1)
              (MO_coef.to_float mo_coef.(imin  ).(i))
              (MO_coef.to_float mo_coef.(imin+1).(i))
              (MO_coef.to_float mo_coef.(imin+2).(i))
              (MO_coef.to_float mo_coef.(imin+3).(i)) )
          in header @ new_lines
      | 5 ->
          let header = [ Printf.sprintf "  #%15d %15d %15d %15d %15d"
              (imin+1) (imin+2) (imin+3) (imin+4) (imin+5) ; ] in
          let new_lines = 
            List.init ao_num ~f:(fun i ->
              Printf.sprintf "  %3d %15.10f %15.10f %15.10f %15.10f %15.10f" (i+1)
              (MO_coef.to_float mo_coef.(imin  ).(i))
              (MO_coef.to_float mo_coef.(imin+1).(i))
              (MO_coef.to_float mo_coef.(imin+2).(i))
              (MO_coef.to_float mo_coef.(imin+3).(i))
              (MO_coef.to_float mo_coef.(imin+4).(i)) )
          in header @ new_lines 
      | _ -> assert false
    in
    let rec create_list accu i = 
      if (i+5 < mo_tot_num) then
        create_list ( (print_five i (i+4) |> String.concat ~sep:"\n")::accu ) (i+5)
      else
        (print_five i (mo_tot_num-1) |> String.concat ~sep:"\n")::accu |> List.rev
    in
    create_list [] 0 |> String.concat ~sep:"\n\n"
  ;;

  let to_string b =
    Printf.sprintf "
Label of the molecular orbitals ::

  mo_label = %s

Total number of MOs ::

  mo_tot_num = %s

MO coefficients ::

%s
"
    (MO_label.to_string b.mo_label)
    (MO_number.to_string b.mo_tot_num)
    (mo_coef_to_string b.mo_coef)

  ;;

  let debug b =
    Printf.sprintf "
mo_label        = %s
mo_tot_num      = \"%s\"
mo_occ          = %s
mo_coef         = %s
"
    (MO_label.to_string b.mo_label)
    (MO_number.to_string b.mo_tot_num)
    (b.mo_occ |> Array.to_list |> List.map
      ~f:(MO_occ.to_string) |> String.concat ~sep:", " )
    (b.mo_coef |> Array.map
      ~f:(fun x-> Array.map ~f:MO_coef.to_string x |> String.concat_array
      ~sep:"," ) |>
      String.concat_array ~sep:"\n" )
  ;;

end

