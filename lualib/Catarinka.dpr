library Catarinka;

{
  Catarinka Lua Library
  Copyright (c) 2013-2020 Felipe Daragon
  License: 3-clause BSD
  See https://github.com/felipedaragon/catarinka/ for details
}

uses
  Lua,
  uMain in 'uMain.pas';

 // Reduces exe size
{$IFDEF RELEASE}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}
 // Reduces exe size end

{$R *.res}

function luaopen_Catarinka(L: plua_State): integer; cdecl;
begin
  Result := RegisterCatarinka(L);
end;

Exports
  luaopen_Catarinka;

begin

end.
