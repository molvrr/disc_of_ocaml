[@@@warning "-20..70"]

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module WSS_Client = Websocketaf_lwt.Client (Gluten_lwt_unix.Client.SSL)

module Option = struct
  include Option

  let value_exn opt =
    match opt with
    | Some x -> x
    | None -> failwith "No value"
  ;;
end

let uri = Uri.of_string "wss://gateway.discord.gg:443/v10?encoding=json"

module Payload = struct
  type t =
    { t : string option
    ; s : int option
    ; op : int
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Intent = struct
  type t =
    | Guilds
    | GuildMembers
    | GuildModeration
    | GuildEmojisAndStickers
    | GuildIntegrations
    | GuildWebhooks
    | GuildInvites
    | GuildVoiceStates
    | GuildPresences
    | GuildMessages
    | GuildMessageReactions
    | GuildMessageTyping
    | DirectMessages
    | DirectMessageReactions
    | DirectMessageTyping
    | MessageContent
    | GuildScheduledEvents
    | AutoModerationConfiguration
    | AutoModerationExecution

  let to_int = function
    | AutoModerationConfiguration -> 1 lsl 20
    | AutoModerationExecution -> 1 lsl 21
    (* FIXME: Mudar isso quando der merda *)
    | x -> 1 lsl Obj.magic x
  ;;

  let calculate intents = List.fold_left ( lor ) 0 @@ List.map to_int intents
end

let error_handler e = ()

let on_read bs ~off ~len =
  let str = Bigstringaf.to_string bs in
  let json = Yojson.Safe.from_string str in
  let payload = Payload.t_of_yojson json in
  let _ = Lwt_io.print @@ string_of_int payload.op in
  ()
;;

let handler ~opcode ~is_fin ~len payload =
  let _ =
    match opcode with
    | `Text -> Websocketaf.Payload.schedule_read ~on_eof:(fun () -> ()) ~on_read payload
    | _ -> ()
  in
  ()
;;

let websocket_handler wsd =
  Websocketaf.Websocket_connection.{ frame = handler; eof = (fun () -> ()) }
;;

let ( let* ) = Lwt.bind

let main =
  let nonce = "0123456789ABCDEFG" in
  let host = Option.value_exn @@ Uri.host uri in
  let port = Option.value_exn @@ Uri.port uri in
  let resource = Uri.path uri in
  let* addresses =
    Lwt_unix.getaddrinfo host (Int.to_string port) [ Unix.(AI_FAMILY PF_INET) ]
  in
  let address = List.hd addresses in
  let socket = Lwt_unix.socket PF_INET SOCK_STREAM 0 in
  let* () = Lwt_unix.connect socket address.ai_addr in
  let ctx = Ssl.create_context Ssl.TLSv1_2 Ssl.Client_context in
  let* websocket = Lwt_ssl.ssl_connect socket ctx in
  let* client =
    WSS_Client.connect
      ~nonce
      ~host
      ~port
      ~resource
      ~error_handler
      ~websocket_handler
      websocket
  in
  let p, u = Lwt.wait () in
  p
;;
