open React
open Lwt

module VolumeManager (Config:App_stub.CONFIG) = struct

	module Devices = Devices.Devices

	type volume = { id: string;
	file_list: string list signal;
	send_file_list: string list -> unit }

	let volume_list_files n =
		n.file_list
	
	let volumes = Hashtbl.create 10
	
	let new_volume_loaded, send_vol = E.create ()

	let all_volumes () =
		Hashtbl.fold (fun _ a l -> a::l) volumes []
	
	let from_id n = Hashtbl.find volumes n
	
	let volume_id n = n.id

	let volume_path n = Sys.getcwd () ^ "/data2/" ^ volume_id n ^ "/"

	let public_volume n = true

	let scan_files v =
		let cwd = volume_path v in
		let rec add_files_from_directory path =
			let file_list = Sys.readdir (cwd ^ "/" ^ path) in
			Array.to_list file_list
			|> List.map (fun filename ->
				if Sys.is_directory (cwd ^ "/" ^ path ^ filename) then
					(path ^ filename) :: add_files_from_directory (path ^ filename ^ "/")
				else
					[path ^ filename])
			|> List.concat
		in
		let filelist = add_files_from_directory "" in
		Lwt.return filelist

	let load_volume v =
		let%lwt file_list = scan_files v in
		let%lwt intfy = Lwt_inotify.create () in
		let%lwt watch = Lwt_inotify.add_watch intfy (volume_path v) [Inotify.(S_All)] in
		Lwt_main.yield () >>= (fun () ->
			while%lwt true do
				Lwt_main.yield () >>= (fun () ->
					let%lwt ev = Lwt_inotify.read intfy in
					let (_, kind_list, _, filename) = ev in
					if  List.mem Inotify.Create kind_list then
						let Some filename = filename in
						Lwt.return (v.send_file_list (filename :: S.value v.file_list))
					else if List.mem Inotify.Delete kind_list ||
							List.mem Inotify.Moved_from kind_list then
						let%lwt file_list = scan_files v in
						Lwt.return (v.send_file_list file_list)
					else
						Lwt.return ())
			done;);
		Lwt.return (v.send_file_list file_list)

	let add_volume v =
		Hashtbl.add volumes v.id v;
		let%lwt () = load_volume v in
		Lwt.return (send_vol v)

	let photos_volumes, send_photos_volumes = E.create ()
	let files_volumes, send_files_volumes = E.create ()

	let load_volumes () =
		let file_list, send_file_list = S.create [] in
		let c = {id = "california";
			file_list = file_list;
			send_file_list = send_file_list; }
		in add_volume c; send_photos_volumes c;
		let file_list, send_file_list = S.create [] in
		{id = "low";
			file_list = file_list;
			send_file_list = send_file_list; }
		|> add_volume
	
	let volume_sync_for_device v device =
		let ev, send = E.create () in
		send 0.55;
		ev

	let volumes_enabled_for name =
		match name with
		| "photos" -> photos_volumes
		| "files" -> files_volumes
	

end