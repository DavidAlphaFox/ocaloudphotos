[%%shared
    open Eliom_lib
    open Eliom_content
]

open Config
open Data
open Mimes
open User
open Photos
open Files
open Welcome
open Irc

module Ocaloudcore_app =
  Eliom_registration.App (
  struct
    let application_name = "ocaloudcore"
  end)

module Config = Config(Ocaloudcore_app)
module Data = Data.Volume_manager.VolumeManager(Config)


(* Apps can register to read, write, use a filetype, and ask for apps
 * that can do those things. *)
module Mimes = Mimes(Config)
module User = User(Data)

module Env = struct
  module Mimes = Mimes
  module Config = Config
  module Data = Data
  module F = Widgets.S(Mimes)
  module Form = Myform.Form(Data)
end

module Files = Files(Env)

module EnvBase = struct
  include Env
  module Files = Files
end

module Photos = Photos(EnvBase)
module Irc  = IrcApp(EnvBase)

module Welcome = Welcome(Env)

let _ = Data.load_volumes ()

let main_service =
  Eliom_service.App.service ~path:["main"] ~get_params:Eliom_parameter.unit ()

let () =
  Config.App.register
    ~service:main_service
    (fun () () ->
           Lwt.return
           (Eliom_tools.F.html
              ~title:"reactivenodes"
              ~css:[["css"; "reactivenodes.css"]]
              Html5.F.(body [p [pcdata "ocaloud v1"]])
           ))

let () = Mimes.register_public "main" main_service

(* let _ = Bep.Main.start_syncing ()*)
[%%client
    open Files
    open Photos
    open Irc
    open Myform
]
