unit CatMatch;
{
  Catarinka - Regular Expression and various other useful matching functions

  Copyright (c) 2003-2020 Felipe Daragon
  License: 3-clause BSD
  See https://github.com/felipedaragon/catarinka/ for details

  Uses the RegExpr library by Andrey V. Sorokin.
  MatchWildcard function by Arsne von Wyss
  CompareVersionNumber() function by Martin Prikryl (@martinprikryl) with small
  changes and suggestions by Tithen-Firion
  CompareVersionString() function is my extension to Martin's function
}

interface

{$I Catarinka.inc}

uses
{$IFDEF DXE2_OR_UP}
  System.Classes, System.SysUtils, RegExpr;
{$ELSE}
  Classes, SysUtils, RegExpr;
{$ENDIF}

type
  TCatRegExpr = TRegExpr;

function RegExpFind(const s, re: string): string;
function RegExpReplace(const s, re, sreplacement: string): string; overload;
function RegExpReplace(const s, re: string; refunc: TRegExprReplaceFunction): string; overload;
function CatCaseWildOf(const s: string; labels: array of string;
  const casesensitive: Boolean = true): integer;
function CatCaseWildXOf(const s: string; labels: array of string;
  const casesensitive: Boolean = true): integer;  
function CatMatchSignature(const sigpattern, s: string): boolean;
function CompareVersionNumber(const version1, version2: string;
  const Silent:boolean=true): Integer;
function CompareVersionString(const version1, version2: string;
  const Silent:boolean=true): Integer;
function IsWildCardString(const s:string):boolean;
function IsValidEmail(email: string): boolean;
function ExtractVersionFromString(s:string):string;
function MatchStrInSepStr(const s,tags:string;separator:string=','):boolean;
function MatchVersion(curver, vercheck:string):boolean;
function MatchVersionRange(curver, vercheck:string):boolean;
function MatchVersionEx(curver, vercheck:string):boolean;
function MatchWildcard(s, Mask: string; IgnoreCase: Boolean = false): Boolean;
function MatchWildcardX(s, Mask: string; IgnoreCase: Boolean = false): Boolean;

implementation

uses CatStrings, CatStringLoop;

{ 
  Case Statement with wildcard matching
  Usage examples:
  case CatCaseWildOf(inputstring, ['1:do?', '2:c*', '3:b??d']) of
   1: result := ...
   2: result := ...
   3: result := ...
  else
   result := 'nomatch';  
  end;
  case CatCaseWildOf(a, ['1:http://*', '2:https://*']) of
   1: result := 'http URL';
   2: result := 'https URL';
  else
   result := 'nomatch';
  end;  
  
  
  Check CatStrings.pas for non-wildcard version of this function
}
function CatCaseWildOf(const s: string; labels: array of string;
  const casesensitive: Boolean = true): integer;
var
  i: integer;
begin
  result := -1; // label not found
  for i := low(labels) to high(labels) do
  begin
    if MatchWildcard(s, after(labels[i],':'), not casesensitive) = true then
      result := StrToIntDef(before(labels[i],':'), -1);
    if result <> -1 then
      break;
  end;
end;

function CatCaseWildXOf(const s: string; labels: array of string;
  const casesensitive: Boolean = true): integer;
var
  i: integer;
begin
  result := -1; // label not found
  for i := low(labels) to high(labels) do
  begin
    if MatchWildcardX(s, after(labels[i],':'), not casesensitive) = true then
      result := StrToIntDef(before(labels[i],':'), -1);
    if result <> -1 then
      break;
  end;
end;

function RegExpReplace(const s, re, sreplacement: string): string;
var
  r: TRegExpr;
begin
  r := TRegExpr.Create;
  try
    r.Expression := re;
    result := r.Replace(s, sreplacement, true);
  finally
    r.Free;
  end;
end;

function RegExpReplace(const s, re: string; refunc: TRegExprReplaceFunction): string;
var
  r: TRegExpr;
begin
  r := TRegExpr.Create;
  try
    r.Expression := re;
    result := r.ReplaceEx(s, refunc);
  finally
    r.Free;
  end;
end;

function RegExpFind(const s, re: string): string;
var
  r: TRegExpr;
begin
  result := emptystr;
  r := TRegExpr.Create;
  try
    r.Expression := re;
    if r.Exec(s) then
      repeat
        result := result + r.Match[0] + ', ';
      until not r.ExecNext;
  finally
    r.Free;
  end;
end;

// Allows to match a string using different methods:
// [somestring] -- case sensitive contains
// wild:[somestring] -- case sensitive wild match
// regexp:[expression] -- regular expression
// icase:[somestring] -- case insensitive contains
// icase:wild:[somestring] -- case insensitive wild match (* and ?)
function CatMatchSignature(const sigpattern, s: string): boolean;
const
  cIgnoreCase = 'icase:';
  cReEx = 'regexp:';
  cWild = 'wild:';
var
  sig, content, pat: string;
begin
  sig := sigpattern;
  content := s;
  if BeginsWith(sig,cIgnoreCase) then
  begin
    sig := after(sig, cIgnoreCase);
    sig := lowercase(sig);
    content := lowercase(content);
  end;
  if BeginsWith(sig,cReEx) then
  begin
    pat := after(sig, cReEx);
    result := (RegExpFind(content, pat) <> emptystr);
  end
  else
  if BeginsWith(sig,cWild) then
  begin
    pat := after(sig, cWild);
    result := MatchWildcard(content, pat);
  end
  else
  begin
    result := (pos(sig, content) <> 0);
  end;
end;

// Thanks ffert2907
function IsValidEmail(email: string): boolean;
const
  charslist = ['_', '-', '.', '0'..'9', 'A'..'Z', 'a'..'z'];
var
  Arobasc, lastpoint : boolean;
  i, n : integer;
  c : char;
begin
  n := Length(email);
  i := 1;
  Arobasc := false;
  lastpoint := false;
  result := true;
  while (i <= n) do begin
    c := email[i];
    if c = '@' then
    begin
      if Arobasc then  // Only 1 Arobasc
      begin
        result := false;
        exit;
      end;
      Arobasc := true;
    end
    else if (c = '.') and Arobasc then  // at least 1 . after arobasc
    begin
      lastpoint := true;
    end
    else if not(c in charslist) then  // valid chars
    begin
      result := false;
      exit;
    end;
    inc(i);
  end;
  if not(lastpoint) or (email[n] = '.')then  // not finish by . and have a . after arobasc
    result := false;
end;

function ExtractVersionFromString(s:string):string;
begin
  result := RegExpFind(s, '\d+(\.\d+)+');
  if pos(',', result) <> 0 then
  result := before(result, ',');
end;

function NextIntFromVersion(var S: string;const Silent:boolean=true): Integer;
var
  P: integer;
begin
    P := Pos('.', S);
    if P > 0 then
    begin
      if silent = true then
        result := StrToIntDef(Copy(S, 1, P - 1), 0)
      else
        result := StrToInt(Copy(S, 1, P - 1));
      Delete(S, 1, P);
    end
      else
    if S <> emptystr then
    begin
      if silent = true then
      result := StrToIntDef(S, 0) else
      result := StrToInt(S);
      S := emptystr;
    end
      else
    begin
      result := 0;
    end;
end;

{
Compares version numbers
 Returns 0, if the versions are equal.
 Returns -1, if the V1 is older than the V2.
 Returns 1, if the V1 is newer than the V2.
 1.12 is considered newer than 1.1.
 1.1 is considered the same as 1.1.0.
 If silent is false, throws an exception, when a version is syntactically invalid (only digits and dots are allowed).
}
// Thanks Martin Prikryl (@martinprikryl) and Tithen-Firion
function CompareVersionNumber(const version1, version2: string;
  const Silent:boolean=true): Integer;
var
  v1, v2:string;
  N1, N2: Integer;
begin
  Result := 0;
  v1 := version1;
  v2 := version2;
  while (Result = 0) and ((V1 <> EmptyStr) or (V2 <> EmptyStr)) do
  begin
    N1 := NextIntFromVersion(V1);
    N2 := NextIntFromVersion(V2);
    if N1 < N2 then Result := -1
      else
    if N1 > N2 then Result := 1;
  end;
end;


// This function I wrote extends the CompareVersion function by martinprikryl (above)
// to compare versions that contain alphanumeric extensions like:
// v1.0 or V1.0
// 1.0 RC1
// 1.0a or 1.0A
// 1.5.0-beta.11 and similar
// ToDo: conclude comparison between alpha, beta and RC stages
function CompareVersionString(const version1, version2: string;
  const Silent:boolean=true): Integer;
var
 v1,v2:string;
 v1ext, v2ext:string;
 v1extnum, v2extnum: string;
 function CompareVersionAlphaExtension(curver, vercheck:string):integer;
 begin
   result := 0;
    if curver < vercheck  then
        result := -1
    else if curver > vercheck  then
        result := 1;
 end;
begin
  v1ext := emptystr;
  v2ext := emptystr;
  v1 := version1;
  v2 := version2;
  if IsAlphaNumeric(v1) then begin
    v1 := ExtractVersionFromString(v1);
    v1ext := After(version1, v1);
    v1extnum := ExtractNumbers(v1ext);
  end;
  if IsAlphaNumeric(v2) then begin
    v2 := ExtractVersionFromString(v2);
    v2ext := After(version2, v2);
    v2extnum := ExtractNumbers(v2ext);
  end;
  result := CompareVersionNumber(v1, v2);

  // If versions are identical and extended version information is available
  // conclude by comparing numbers from extension part
  if result = 0 then begin
    // compares case like 1.5.0-beta.10 versus 1.5.0-beta.11
    if (v1ext <> emptystr) and (v2ext <> emptystr) then
    result := CompareVersionNumber(v1extnum, v2extnum);

    // compare cases like 1.0.1a, 1.0.1b
    if (v1ext = emptystr) and (length(v2ext) = 1) and (v2ext[1] in ['a'..'z','A'..'Z']) then
      v1ext := 'a';
    if (v2ext = emptystr) and (length(v1ext) = 1) and (v1ext[1] in ['a'..'z','A'..'Z']) then
      v2ext := 'a';
    if (length(v1ext) =1) and (length(v2ext) = 1) then begin
      result := CompareVersionAlphaExtension(lowercase(v1ext), lowercase(v2ext));

    end;
  end;
end;

// Matches a string against a separated string (comma-based if separator is ommited)
function MatchStrInSepStr(const s,tags:string;separator:string=','):boolean;
var Tag: TSepStringLoop;
begin
  result := false;
  if tags <> emptystr then
  begin
      Tag := TSepStringLoop.Create(tags, separator);
      while Tag.Found do
      begin
        if Tag.Current = s then
          result := true;
      end;
      Tag.Free;
  end;
end;

function IsWildCardString(const s:string):boolean;
begin
  result := ContainsAnyOfChars(s, ['*','?']);
end;

// expects expression like: <3.4.0 or <=3.4.0
// when using just the equal sign, can be followed by a wildcard, ex:
// =* (matches any version), =3.*, =3.1.??
function MatchVersion(curver, vercheck:string):boolean;
var
  outver: string;
  compres: integer;
begin
  result := false;
  outver := ExtractVersionFromString(vercheck);
    if beginswith(vercheck, '=') = false then
      compres := CompareVersionNumber(curver, outver);
    if beginswith(vercheck, '>=') then begin
        //if curver >= outver  then
        if (compres = 1) or (compres = 0) then
        result := true;
    end else
    if beginswith(vercheck, '<=') then begin
        //if curver <= outver  then
        if (compres = -1) or (compres = 0) then
        result := true;
    end else
    if beginswith(vercheck, '<') then begin
        //if curver < outver  then
        if (compres = -1) then
        result := true;
    end else
    if beginswith(vercheck, '>') then begin
        //if curver > outver  then
        if (compres = 1) then
        result := true;
    end else
    if beginswith(vercheck, '=') then begin
        outver := after(vercheck, '=');
        if IsWildCardString(outver) = false then begin
          compres := CompareVersionNumber(curver, outver);
          if (compres = 0) then
          result := true;
        end else begin
          if matchwildcard(curver, outver) = true  then
          result := true;
        end;
    end;
end;

// expects a version check range separated by spaces like:
// >=1.4.2 <1.6.2
// must match all to return true
function MatchVersionRange(curver, vercheck:string):boolean;
var
  s: TSepStringLoop;
begin
  result := true;
  s := TSepStringLoop.Create(vercheck,' ');
  while s.Found do begin
    if MatchVersion(curver,s.Current) = false then
        result := false;
  end;
  s.Free;
end;

// expects version check list separated by commas like:
// <1.12.2,>=1.12.3 <2.2.2,>=2.2.3 <3.0.0
// must match at least one of the checks to return true
// wildcards can be used when using just equal sign, ex:
// usage examples:
// MatchVersionEx('2.2.3','<1.12.2,>=1.12.3 <2.2.2,>=2.2.3 <3.0.0') -> true
// MatchVersionEx('3.0.1','<1.12.2,>=1.12.3 <2.2.2,>=2.2.3 <3.0.0') -> false
// MatchVersionEx('2.1.11','=2.1.??,=3.*') -> true
function MatchVersionEx(curver, vercheck:string):boolean;
var
  s: TSepStringLoop;
begin
  result := false;
  s := TSepStringLoop.Create(vercheck,',');
  while s.Found do begin
    if MatchVersionRange(curver,s.Current) = true then begin
        result := true;
        s.Stop;
    end;
  end;
  s.Free;
end;

function MatchWildcard_Pos(const substr, s: string; Start: integer): integer;
var
  i, J, len: integer;
begin
  len := length(substr);
  if len = 0 then
  begin
    result := 1;
    Exit;
  end;
  for i := Start to Succ(length(s) - len) do
  begin
    J := 1;
    while J <= len do
    begin
      if not((substr[J] = '?') or (substr[J] = s[Pred(i + J)])) then
        break;
      inc(J);
    end;
    if J > len then
    begin
      result := i;
      Exit;
    end;
  end;
  result := 0;
end;

{
  This function takes two strings and compares them. The first string
  can be anything, but should not contain pattern characters (* or ?).
  The pattern string can have as many of these pattern characters as you want.
  For example: MatchStrings('Pascal','*as*') would return True.

  Contributed by Arsne von Wyss (1999)
}
function MatchWildcard(s, Mask: string; IgnoreCase: Boolean = false): Boolean;
const
  WildSize = 0; { minimal number of characters representing a "*" }
var
  Min, Max, At, MaskSTart, MaskEnd: integer;
  T: string;
begin
  if IgnoreCase then
  begin
    s := uppercase(s);
    mask := uppercase(mask);
  end;
  s := s + #0;
  Mask := Mask + #0;
  Min := 1;
  Max := 1;
  MaskEnd := 0;
  while length(Mask) >= MaskEnd do
  begin
    MaskSTart := MaskEnd + 1;
    repeat
      inc(MaskEnd);
    until (MaskEnd > length(Mask)) or (Mask[MaskEnd] = '*');
    T := Copy(Mask, MaskSTart, MaskEnd - MaskSTart);
    At := MatchWildcard_Pos(T, s, Min);
    if (At = 0) or (At > Max) then
    begin
      result := false;
      Exit;
    end;
    Min := At + length(T) + WildSize;
    Max := length(s);
  end;
  result := true;
end;

function MatchWildcardX_Pos(const substr, s: string; Start: integer): integer;
var
  i, J, len: integer;
begin
  len := length(substr);
  if len = 0 then
  begin
    result := 1;
    Exit;
  end;
  for i := Start to Succ(length(s) - len) do
  begin
    J := 1;
    while J <= len do
    begin
      if (substr[J] = '#') and (IsInteger(s[Pred(i + J)]) <> true) then
        break;
      if (substr[J] = '�') and (IsAlpha(s[Pred(i + J)]) <> true) then
        break;
      if not(ContainsAnyOfChars(substr[J], ['?','#','�']) or (substr[J] = s[Pred(i + J)])) then
        break;
      inc(J);
    end;
    if J > len then
    begin
      result := i;
      Exit;
    end;
  end;
  result := 0;
end;

// Extended version of MatchWildcard() function that allows the following
// additional chars to be used as part of the mask:
// # (hash) to match a number
// � (inverted interrogation) to match a letter (A..Z, a..z)
// by Felipe Daragon
function MatchWildcardX(s, Mask: string; IgnoreCase: Boolean = false): Boolean;
const
  WildSize = 0; { minimal number of characters representing a "*" }
var
  Min, Max, At, MaskSTart, MaskEnd: integer;
  T: string;
begin
  if IgnoreCase then
  begin
    s := uppercase(s);
    mask := uppercase(mask);
  end;
  s := s + #0;
  Mask := Mask + #0;
  Min := 1;
  Max := 1;
  MaskEnd := 0;
  while length(Mask) >= MaskEnd do
  begin
    MaskSTart := MaskEnd + 1;
    repeat
      inc(MaskEnd);
    until (MaskEnd > length(Mask)) or (Mask[MaskEnd] = '*');
    T := Copy(Mask, MaskSTart, MaskEnd - MaskSTart);
    At := MatchWildcardX_Pos(T, s, Min);
    if (At = 0) or (At > Max) then
    begin
      result := false;
      Exit;
    end;
    Min := At + length(T) + WildSize;
    Max := length(s);
  end;
  result := true;
end;

// ------------------------------------------------------------------------//
end.
