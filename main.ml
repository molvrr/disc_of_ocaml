[@@@warning "-20..70"]

module WSS_Client = Websocketaf_lwt.Client (Gluten_lwt_unix.Client.SSL)

let error_handler e = ()

let on_read bs ~off ~len =
  let _ = Lwt_io.print @@ Bigstringaf.to_string bs in
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

let _ =
  Lwt_main.run
    (let nonce = "ABCASDKJD" in
     let host = "gateway.discord.gg" in
     let port = 443 in
     let resource = "/v10?encoding=json" in
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
     p)
;;
