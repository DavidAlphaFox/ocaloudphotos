open React

type div_content = Html5_types.div_content_fun Eliom_content.Html5.elt

module type CONFIG = sig
  module App: Eliom_registration.ELIOM_APPL
end

module type DEVICES = sig
  type device
  val list_devices: unit -> device list
  val new_device : device event
  val all_devices : (string list) signal
  val name : device -> string
  val new_device: string -> unit
end

module type DATA = sig
  type volume

  module Devices : DEVICES

  open Devices

  val all_volumes : volume list signal
  val volumes_enabled_for : string -> volume list signal
  val new_volume_enabled_for : string -> volume event
  val volume_id : volume -> string
  val public_volume : volume -> bool
  val volume_path : volume -> string
  val volume_from_id : string -> volume

  val load_volumes : unit -> unit Lwt.t

  val new_volume_loaded : volume React.event

  val volume_list_files : volume -> Shared.file list signal

  val volume_sync_for_device : volume -> device -> float React.event

  exception Volume_not_found of string

end

type unit_service = (unit, unit, Eliom_service.get_service_kind, Eliom_service.attached,
                     Eliom_service.service_kind, [ `WithoutSuffix ], unit, 
                     unit, Eliom_service.registrable, [ `Appl ])
    Eliom_service.service 

[%%shared
type path_service =
  (string list, unit, Eliom_service.get_service_kind,
   Eliom_service.attached,
   Eliom_service.internal_service_kind, [ `WithSuffix ],
   [ `One of string list ] Eliom_parameter.param_name, 
   unit, Eliom_service.registrable,
   [ `Appl ])
    Eliom_service.service
]

module type MIMES = sig
  val register_public : string -> unit_service-> unit
  val get_all_public_services : unit -> (string * unit_service) list
  val register_sidebar : string -> (unit -> Html5_types.div Eliom_content.Html5.elt) -> unit
  val build_sidebar : unit -> Html5_types.div Eliom_content.Html5.elt list

end

module type ENV = sig
  module Config : CONFIG
  module Data : DATA
  module Mimes : MIMES
  module F : sig
    val main_box : (div_content list) -> Html5_types.html Eliom_content.Html5.elt
    val main_box_sidebar : (div_content list) -> Html5_types.html Eliom_content.Html5.elt
  end
end

module type FILES = sig
  type volume
  val service_for_volume: volume -> path_service
  val download_path: volume -> string -> string list
end

module type ENVBASE = sig
  include ENV
  module Files : FILES with type volume = Data.volume
end

