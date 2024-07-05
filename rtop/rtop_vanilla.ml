let () = try Topdirs.dir_directory (Sys.getenv "OCAML_TOPLEVEL_PATH") with | Not_found -> ();;
let () = Reason_toploop.main ()
let () = print_string
"
                   ___  _______   ________  _  __
                  / _ \\/ __/ _ | / __/ __ \\/ |/ /
                 / , _/ _// __ |_\\ \\/ /_/ /    /
                /_/|_/___/_/ |_/___/\\____/_/|_/

  Execute statements/let bindings. Hit <enter> after the semicolon. Ctrl-d to quit.

        >   let myVar = \"Hello Reason!\";
        >   let myList: list(string) = [\"first\", \"second\"];
        >   #use \"./src/myFile.re\"; /* loads the file into here */
"

let () =
    let open Reason_toolchain.From_current in
    let wrap f g fmt x = g fmt (f x) in
    Toploop.print_out_value :=
      wrap copy_out_value Reason_oprint.print_out_value;
    Toploop.print_out_type :=
      wrap copy_out_type Reason_oprint.print_out_type;
    Toploop.print_out_class_type :=
      wrap copy_out_class_type Reason_oprint.print_out_class_type;
    Toploop.print_out_module_type :=
      wrap copy_out_module_type Reason_oprint.print_out_module_type;
    Toploop.print_out_type_extension :=
      wrap copy_out_type_extension Reason_oprint.print_out_type_extension;
    Toploop.print_out_sig_item :=
      wrap copy_out_sig_item Reason_oprint.print_out_sig_item;
    Toploop.print_out_signature :=
      wrap (List.map copy_out_sig_item) Reason_oprint.print_out_signature;
    Toploop.print_out_phrase :=
      wrap copy_out_phrase Reason_oprint.print_out_phrase;
    Toploop.loop Format.std_formatter

