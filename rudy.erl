-module(rudy).
-export([init/1,handler/1,request/1,reply/1, start/1, stop/0]).

start(Port) ->
  register(rudy, spawn(fun() ->
    init(Port)
  end)).

init(Port) ->
  Opt = [list, {active, false}, {reuseaddr,true}],
  case gen_tcp:listen(Port,Opt) of    % open a listening socket
    {ok, Listen} ->
      handler(Listen),
      gen_tcp:close(Listen),          % Close a listening socket
      ok;
    {error, Error} ->                 % Otherwise throw error
      error
    end.

handler(Listen) ->
  case gen_tcp:accept(Listen) of      %Listen to the socket for client requests
    {ok, Client} ->
      request(Client),                %Pass client's request to request procedure
      gen_tcp:close(Client),
      handler(Listen);                % Do a self recurssive call

    {error, Error} ->
      error
    end.

request(Client) ->
  Recv = gen_tcp:recv(Client, 0),
  case Recv of
    {ok, Str} ->
      Request = http:parse_request(Str), % Receive a request from http parser
      Response = reply(Request),         % Call reply function to deliver a message
      gen_tcp:send(Client, Response);
    {error, Error} ->
      io:format("rudy:error: ~w~n", [Error])
  end,
  gen_tcp:close(Client).


reply({{get, URI, _}, _, _}) ->
  % timer:sleep(40),
  http:ok("DISTRIBUTED SYSTEMS").

stop() ->
  exit(whereis(rudy), "time to die").
