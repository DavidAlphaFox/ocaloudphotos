open React

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

	val all_volumes : unit -> volume list
	val volumes_enabled_for : string -> volume event
	val volume_id : volume -> string
	val public_volume : volume -> bool
	val volume_path : volume -> string
	val from_id : string -> volume

	val load_volumes : unit -> unit Lwt.t

	val new_volume_loaded : volume React.event

	val volume_list_files : volume -> string list signal

	val volume_sync_for_device : volume -> device -> float React.event
end

type unit_service = (unit, unit, Eliom_service.get_service_kind, Eliom_service.attached,
	Eliom_service.service_kind, [ `WithoutSuffix ], unit, 
	unit, Eliom_service.registrable, [ `Appl ])
	Eliom_service.service 

type path_service =
	(string list, unit, Eliom_service.get_service_kind,
	Eliom_service.attached,
	 Eliom_service.internal_service_kind, [ `WithSuffix ],
	[ `One of string list ] Eliom_parameter.param_name, 
	unit, Eliom_service.registrable,
	[ `Appl ])
	Eliom_service.service

module type MIMES = sig
	val register_public : string -> unit_service-> unit
	val get_all_public_services : unit -> (string * unit_service) list
end

module type ENV = sig
	module Config : CONFIG
	module Data : DATA
	module Mimes : MIMES
end

module type FILES = sig
	type volume
	val service_for_volume: volume -> path_service
	val download_path: volume -> string -> string list
end

module type ENVBASE = sig
	module Config : CONFIG
	module Data : DATA
	module Mimes : MIMES
	module Files : FILES with type volume = Data.volume
end
