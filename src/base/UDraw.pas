{* UltraStar Deluxe - Karaoke Game
 *
 * UltraStar Deluxe is the legal property of its developers, whose names
 * are too numerous to list here. Please refer to the COPYRIGHT
 * file distributed with this source distribution.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING. If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * $URL: https://ultrastardx.svn.sourceforge.net/svnroot/ultrastardx/trunk/src/base/UDraw.pas $
 * $Id: UDraw.pas 2514 2010-06-13 10:57:33Z tobigun $
 *}

unit UDraw;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses
  UCommon,
  UThemes,
  sdl2,
  UGraphicClasses,
  UIni;

procedure SingDraw;
procedure SingDrawLines;
procedure SingDrawBackground;
procedure SingDrawOscilloscopes;
procedure SingDrawOscilloscope(Position: TThemePosition; NrSound: integer);
procedure SingDrawNoteLines(Left, Top, Right: real; LineSpacing: integer = 15; LineThickness: single = 1);
procedure SingDrawLyricHelper(CP: integer; Left, LyricsMid: real);
procedure SingDrawLine(Left, Top, Right: real; Track, PlayerIndex: integer; LineSpacing: integer = 15);
procedure SingDrawPlayerLine(Left, Top, W: real; Track, PlayerIndex: integer; LineSpacing: integer = 15);
procedure SingDrawPlayerBGLine(Left, Top, Right: real; Track, PlayerIndex: integer; LineSpacing: integer = 15);
procedure SingDrawPitchTrace(Left, Top, W: real; Track, PlayerIndex: integer; LineSpacing: integer = 15);
procedure SingDrawPitchTraceReset;
procedure SingDrawPitchKey(Left, Top: real; PlayerIndex: integer);
procedure SingDrawTargetKey(Left, Top: real; Track, PlayerIndex: integer);

//Draw Editor NoteLines
procedure EditDrawLine(X, YBaseNote, W, H: real; Track: integer; NumLines: integer = 10);
procedure EditDrawBorderedBox(X, Y, W, H: integer; FillR: real = 0.9; FillG: real = 0.9; FillB: real = 0.9; FillAlpha: real = 0.5);
procedure EditDrawBeatDelimiters(X, Y, W, H: real; Track: integer);

// Draw Jukebox
procedure SingDrawJukebox;
procedure SingDrawJukeboxBackground;
procedure SingDrawJukeboxBlackBackground;
procedure SingDrawJukeboxTimeBar();
procedure SingDrawLyricHelperJukebox(Left, LyricsMid: real);

// Draw Webcam
procedure SingDrawWebCamFrame;

type
  TRecR = record
    Top:    real;
    Left:   real;
    Right:  real;
    Bottom: real;

    Width:  real;
    WMid:   real;
    Height: real;
    HMid:   real;
    Mid:    real;
  end;

const
P1_INVERTED = 99;

var
  NotesW:   array [0..UIni.IMaxPlayerCount-1] of real;
  NotesH:   array [0..UIni.IMaxPlayerCount-1] of real;
  Starfr:   integer;
  StarfrG:  integer;

  //SingBar
  TickOld:  cardinal;
  TickOld2: cardinal;

  FrameThread:  PSDL_Thread;
  Mutex:        PSDL_Mutex;

implementation

uses
  SysUtils,
  Math,
  UText,
  UGraphic,
  ULog,
  ULyrics,
  UNote,
  UParty,
  UMusic,
  URecord,
  URenderer,
  UScreenSingController,
  UScreenJukebox,
  USong,
  UWebcam;


procedure SingDrawWebCamFrame;
begin

  Webcam.GetWebcamFrame;

  if (Webcam.TextureCam <> nil) then
  begin
    with Webcam.TextureCam do
    begin
      X := 0;
      Y := 0;
      Z := 0;
      W := RenderW;
      H := renderH;
    end;
    Renderer.DrawTexture(Webcam.TextureCam);

  end;

  {
  // Save Frame to AVI
  if (ScreenSing.WebcamSave) then
  begin
    cvCvtColor(WebcamFrame, WebcamFrame, CV_RGB2BGR);
    //cvInvert(WebcamFrame, WebcamFrame, 0);
    cvWriteFrame(ScreenSing.WebCamVideoWriter, WebcamFrame);
  end;
  }

end;

procedure SingDrawBackground;
var
  Rec:    TRecR;
  TexRec: TRecR;
  // TODO: these (especially the aspects) should just be precomputed
  ScreenAspect: double;  // aspect of screen resolution and image
  ScaledTexWidth, ScaledTexHeight: double;
begin
  // TODO: this is also called if a video is playing
  if (ScreenSing.Tex_Background <> nil) then
  begin
    if (Ini.MovieSize <= 1) then  //HalfSize BG
    begin
      (* half screen + gradient *)
      Rec.Top := 110; // 80
      Rec.Bottom := Rec.Top + 20;
      Rec.Left  := 0;
      Rec.Right := 800;

      TexRec.Top := (Rec.Top / 600);
      TexRec.Bottom := (Rec.Bottom / 600);
      TexRec.Left := 0;
      TexRec.Right := 1;

      (* gradient draw *)
      (* top *)
      with ScreenSing.Tex_Background do
      begin
        X := Rec.Left;
        Y := Rec.Top;
        W := Rec.Right - Rec.Left;
        H := Rec.Bottom - Rec.Top;
        TexX1 := TexRec.Left;
        TexX2 := TexRec.Right;
        TexY1 := TexRec.Top;
        TexY2 := TexRec.Bottom;
        AlphaGradient := gdVertical;
        Alpha := 0; // Top alpha
        Alpha2 := 1; // Bottom alpha
      end;
      Renderer.DrawTexture(ScreenSing.Tex_Background);

      (* mid *)
      Rec.Top := Rec.Bottom;
      Rec.Bottom := 490 - 20; // 490 - 20
      TexRec.Top := TexRec.Bottom;
      TexRec.Bottom := (Rec.Bottom / 600);
      with ScreenSing.Tex_Background do
      begin
        Y := Rec.Top;
        H := Rec.Bottom - Rec.Top;
        TexY1 := TexRec.Top;
        TexY2 := TexRec.Bottom;
        AlphaGradient := gdNone;
        Alpha := 1;
      end;
      Renderer.DrawTexture(ScreenSing.Tex_Background);

      (* bottom *)
      Rec.Top := Rec.Bottom;
      Rec.Bottom := 490; // 490
      TexRec.Top := TexRec.Bottom;
      TexRec.Bottom := (Rec.Bottom / 600);
      with ScreenSing.Tex_Background do
      begin
        Y := Rec.Top;
        H := Rec.Bottom - Rec.Top;
        TexY1 := TexRec.Top;
        TexY2 := TexRec.Bottom;
        AlphaGradient := gdVertical;
        Alpha := 1; // Top alpha
        Alpha2 := 0; // Bottom alpha
      end;
      Renderer.DrawTexture(ScreenSing.Tex_Background);
    end
    else //Full Size BG
    begin
      // Three aspects to take into account:
      //  1. Screen/display resolution (e.g. 1920x1080 -> 16:9)
      //  2. Render aspect (fWidth x fHeight -> variable)
      //  3. Movie aspect (video frame aspect stored in fAspect)
      ScreenAspect := ScreenWPerScreen / ScreenH;

      case ScreenSing.BackgroundAspectCorrection of
        acoCrop: begin
          if (ScreenAspect >= ScreenSing.Tex_BackgroundAspectRatio) then
          begin
            ScaledTexWidth  := RenderW;
            ScaledTexHeight := RenderH * ScreenAspect/ScreenSing.Tex_BackgroundAspectRatio;
          end else
          begin
            ScaledTexHeight := RenderH;
            ScaledTexWidth  := RenderW * ScreenSing.Tex_BackgroundAspectRatio/ScreenAspect;
          end;
        end;

        acoHalfway: begin
          ScaledTexWidth  := (RenderW + RenderW * ScreenSing.Tex_BackgroundAspectRatio/ScreenAspect)/2;
          ScaledTexHeight := (RenderH + RenderH * ScreenAspect/ScreenSing.Tex_BackgroundAspectRatio)/2;
        end;

        acoLetterBox: begin
          if (ScreenAspect <= ScreenSing.Tex_BackgroundAspectRatio) then
          begin
            ScaledTexWidth  := RenderW;
            ScaledTexHeight := RenderH * ScreenAspect/ScreenSing.Tex_BackgroundAspectRatio;
          end else
          begin
            ScaledTexHeight := RenderH;
            ScaledTexWidth  := RenderW * ScreenSing.Tex_BackgroundAspectRatio/ScreenAspect;
          end;
        end else
          raise Exception.Create('Unhandled aspect correction!');
      end;

      //center video
      Rec.Left  := (RenderW - ScaledTexWidth) / 2;
      Rec.Right := Rec.Left + ScaledTexWidth;
      Rec.Top := (RenderH - ScaledTexHeight) / 2;
      Rec.Bottom := Rec.Top + ScaledTexHeight;
      with ScreenSing.Tex_Background do
      begin
        X := Rec.Left;
        Y := Rec.Top;
        W := Rec.Right - Rec.Left;
        H := Rec.Bottom - Rec.Top;
        TexX1 := 0;
        TexX2 := 1;
        TexY1 := 0;
        TexY2 := 1;
        AlphaGradient := gdNone;
        Alpha := 1;
      end;
      Renderer.DrawTexture(ScreenSing.Tex_Background);
    end;
  end;
end;

procedure SingDrawJukeboxBackground;
var
  Rec:    TRecR;
  TexRec: TRecR;
begin
  if (ScreenJukebox.Tex_Background <> nil) then
  begin
    if (Ini.MovieSize <= 1) then  //HalfSize BG
    begin
      (* half screen + gradient *)
      Rec.Top := 110; // 80
      Rec.Bottom := Rec.Top + 20;
      Rec.Left  := 0;
      Rec.Right := 800;

      TexRec.Top := (Rec.Top / 600);
      TexRec.Bottom := (Rec.Bottom / 600);
      TexRec.Left := 0;
      TexRec.Right := 1;

      (* gradient draw *)
      (* top *)
      with ScreenJukebox.Tex_Background do
      begin
        X := Rec.Left;
        Y := Rec.Top;
        W := Rec.Right - Rec.Left;
        H := Rec.Bottom - Rec.Top;
        TexX1 := TexRec.Left;
        TexX2 := TexRec.Right;
        TexY1 := TexRec.Top;
        TexY2 := TexRec.Bottom;
        AlphaGradient := gdVertical;
        Alpha := 0; // Top alpha
        Alpha2 := 1; // Bottom alpha
      end;
      Renderer.DrawTexture(ScreenJukebox.Tex_Background);

      (* mid *)
      Rec.Top := Rec.Bottom;
      Rec.Bottom := 490 - 20; // 490 - 20
      TexRec.Top := TexRec.Bottom;
      TexRec.Bottom := (Rec.Bottom / 600);
      with ScreenJukebox.Tex_Background do
      begin
        Y := Rec.Top;
        H := Rec.Bottom - Rec.Top;
        TexY1 := TexRec.Top;
        TexY2 := TexRec.Bottom;
        AlphaGradient := gdNone;
        Alpha := 1;
      end;
      Renderer.DrawTexture(ScreenJukebox.Tex_Background);

      (* bottom *)
      Rec.Top := Rec.Bottom;
      Rec.Bottom := 490; // 490
      TexRec.Top := TexRec.Bottom;
      TexRec.Bottom := (Rec.Bottom / 600);
      with ScreenJukebox.Tex_Background do
      begin
        Y := Rec.Top;
        H := Rec.Bottom - Rec.Top;
        TexY1 := TexRec.Top;
        TexY2 := TexRec.Bottom;
        AlphaGradient := gdVertical;
        Alpha := 1; // Top alpha
        Alpha2 := 0; // Bottom alpha
      end;
      Renderer.DrawTexture(ScreenJukebox.Tex_Background);
    end
    else //Full Size BG
    begin
      with ScreenJukebox.Tex_Background do
      begin
        X := 0;
        Y := 0;
        W := RenderW;
        H := RenderH;
        TexX1 := 0;
        TexX2 := 1;
        TexY1 := 0;
        TexY2 := 1;
        AlphaGradient := gdNone;
        Alpha := 1;
      end;
      Renderer.DrawTexture(ScreenJukebox.Tex_Background);
    end;
  end
  else
    SingDrawJukeboxBlackBackground;
end;

procedure SingDrawJukeboxBlackBackground;
begin
  Renderer.DrawQuad(0, 0, 0, RenderW, RenderH, 0, 0, 0, 1);
end;

procedure SingDrawOscilloscopes;
begin;
  if PlayersPlay = 1 then
    SingDrawOscilloscope(Theme.Sing.Solo1PP1.Oscilloscope, 0);

  if PlayersPlay = 2 then
  begin
    SingDrawOscilloscope(Theme.Sing.Solo2PP1.Oscilloscope, 0);
    SingDrawOscilloscope(Theme.Sing.Solo2PP2.Oscilloscope, 1);
  end;

  if PlayersPlay = 3 then
  begin
    if (CurrentSong.isDuet) then
    begin
      SingDrawOscilloscope(Theme.Sing.Duet3PP1.Oscilloscope, 0);
      SingDrawOscilloscope(Theme.Sing.Duet3PP2.Oscilloscope, 1);
      SingDrawOscilloscope(Theme.Sing.Duet3PP3.Oscilloscope, 2);
    end
    else
    begin
      SingDrawOscilloscope(Theme.Sing.Solo3PP1.Oscilloscope, 0);
      SingDrawOscilloscope(Theme.Sing.Solo3PP2.Oscilloscope, 1);
      SingDrawOscilloscope(Theme.Sing.Solo3PP3.Oscilloscope, 2);
    end;
  end;

  if PlayersPlay = 4 then
  begin
    if (Screens = 2) then
    begin
      if ScreenAct = 1 then
      begin
        SingDrawOscilloscope(Theme.Sing.Solo2PP1.Oscilloscope, 0);
        SingDrawOscilloscope(Theme.Sing.Solo2PP2.Oscilloscope, 1);
      end;
      if ScreenAct = 2 then
      begin
        SingDrawOscilloscope(Theme.Sing.Solo2PP1.Oscilloscope, 2);
        SingDrawOscilloscope(Theme.Sing.Solo2PP2.Oscilloscope, 3);
      end;
    end
    else
    begin
      if (CurrentSong.isDuet) then
      begin
        SingDrawOscilloscope(Theme.Sing.Duet4PP1.Oscilloscope, 0);
        SingDrawOscilloscope(Theme.Sing.Duet4PP2.Oscilloscope, 1);
        SingDrawOscilloscope(Theme.Sing.Duet4PP3.Oscilloscope, 2);
        SingDrawOscilloscope(Theme.Sing.Duet4PP4.Oscilloscope, 3);
      end
      else
      begin
        SingDrawOscilloscope(Theme.Sing.Solo4PP1.Oscilloscope, 0);
        SingDrawOscilloscope(Theme.Sing.Solo4PP2.Oscilloscope, 1);
        SingDrawOscilloscope(Theme.Sing.Solo4PP3.Oscilloscope, 2);
        SingDrawOscilloscope(Theme.Sing.Solo4PP4.Oscilloscope, 3);
      end;
    end;
  end;

  if PlayersPlay = 6 then
  begin
    if (Screens = 2) then
    begin
      if (CurrentSong.isDuet) then
      begin
        if ScreenAct = 1 then
        begin
          SingDrawOscilloscope(Theme.Sing.Duet3PP1.Oscilloscope, 0);
          SingDrawOscilloscope(Theme.Sing.Duet3PP2.Oscilloscope, 1);
          SingDrawOscilloscope(Theme.Sing.Duet3PP3.Oscilloscope, 2);
        end;
        if ScreenAct = 2 then
        begin
          SingDrawOscilloscope(Theme.Sing.Duet3PP1.Oscilloscope, 3);
          SingDrawOscilloscope(Theme.Sing.Duet3PP2.Oscilloscope, 4);
          SingDrawOscilloscope(Theme.Sing.Duet3PP3.Oscilloscope, 5);
        end;
      end
      else
      begin
        if ScreenAct = 1 then
        begin
          SingDrawOscilloscope(Theme.Sing.Solo3PP1.Oscilloscope, 0);
          SingDrawOscilloscope(Theme.Sing.Solo3PP2.Oscilloscope, 1);
          SingDrawOscilloscope(Theme.Sing.Solo3PP3.Oscilloscope, 2);
        end;

        if ScreenAct = 2 then
        begin
          SingDrawOscilloscope(Theme.Sing.Solo3PP1.Oscilloscope, 3);
          SingDrawOscilloscope(Theme.Sing.Solo3PP2.Oscilloscope, 4);
          SingDrawOscilloscope(Theme.Sing.Solo3PP3.Oscilloscope, 5);
        end;
      end;
    end
    else
    begin
      if (CurrentSong.isDuet) then
      begin
        SingDrawOscilloscope(Theme.Sing.Duet6PP1.Oscilloscope, 0);
        SingDrawOscilloscope(Theme.Sing.Duet6PP2.Oscilloscope, 1);
        SingDrawOscilloscope(Theme.Sing.Duet6PP3.Oscilloscope, 2);
        SingDrawOscilloscope(Theme.Sing.Duet6PP4.Oscilloscope, 3);
        SingDrawOscilloscope(Theme.Sing.Duet6PP5.Oscilloscope, 4);
        SingDrawOscilloscope(Theme.Sing.Duet6PP6.Oscilloscope, 5);
      end
      else
      begin
        SingDrawOscilloscope(Theme.Sing.Solo6PP1.Oscilloscope, 0);
        SingDrawOscilloscope(Theme.Sing.Solo6PP2.Oscilloscope, 1);
        SingDrawOscilloscope(Theme.Sing.Solo6PP3.Oscilloscope, 2);
        SingDrawOscilloscope(Theme.Sing.Solo6PP4.Oscilloscope, 3);
        SingDrawOscilloscope(Theme.Sing.Solo6PP5.Oscilloscope, 4);
        SingDrawOscilloscope(Theme.Sing.Solo6PP6.Oscilloscope, 5);
      end;
    end;
  end;
end;

procedure SingDrawOscilloscope(Position: TThemePosition; NrSound: integer);
var
  SampleIndex: integer;
  Sound:       TCaptureBuffer;
  MaxX, MaxY:  real;
  Col: TRGB;
  PointList: TPointList;
begin;
  Sound := AudioInputProcessor.Sound[NrSound];

  if (Party.bPartyGame) then
    Col := GetPlayerColor(Ini.TeamColor[NrSound])
  else
    Col := GetPlayerColor(Ini.PlayerColor[NrSound]);

  MaxX := Position.W-1;
  MaxY := (Position.H-1) / 2;
  Sound.LockAnalysisBuffer();
  SetLength(PointList, Length(Sound.AnalysisBuffer));

  for SampleIndex := 0 to High(Sound.AnalysisBuffer) do
  begin
    PointList[SampleIndex].X := SampleIndex;
    PointList[SampleIndex].Y := Sound.AnalysisBuffer[SampleIndex];
  end;

  Sound.UnlockAnalysisBuffer();
  Renderer.DrawLineStrip(PointList, MaxX/High(Sound.AnalysisBuffer), MaxY/Low(Smallint), Position.X, Position.Y + MaxY, Col.R, Col.G, Col.B, 1);
end;

const
  // How many pitch samples are kept per player for the continuous trace.
  // At 60 fps this is roughly the last 8 seconds of singing.
  PitchTraceLength = 512;

type
  TPitchTraceSample = record
    Tone:  real;     // absolute tone as reported by the analyser
    Valid: boolean;  // false when the analyser only saw noise
  end;

var
  PitchTraceBuffer: array[0..IMaxPlayerCount-1, 0..PitchTraceLength-1] of TPitchTraceSample;
  PitchTraceCount:  array[0..IMaxPlayerCount-1] of integer;
  PitchTraceNext:   array[0..IMaxPlayerCount-1] of integer;

procedure SingDrawPitchTraceReset;
var
  PlayerIndex: integer;
begin
  for PlayerIndex := 0 to IMaxPlayerCount - 1 do
  begin
    PitchTraceCount[PlayerIndex] := 0;
    PitchTraceNext[PlayerIndex] := 0;
  end;
end;

procedure SingDrawPitchTrace(Left, Top, W: real; Track, PlayerIndex: integer; LineSpacing: integer);
var
  Sound:      TCaptureBuffer;
  CurrentLine: integer;
  Centre:     real;
  BaseNote:   integer;
  Slot, N, Index, Count, Used, Points, Window: integer;
  Tone, Fade, Sum: real;
  TargetTone: integer;
  HasTarget:  boolean;
  TargetY, Offset: real;
  Col, DotCol: TRGB;
  Segments:   TLineList;
  PtX, PtY, PtTone, Smoothed: array[0..PitchTraceLength-1] of real;
  PtOk: array[0..PitchTraceLength-1] of boolean;
begin
  if (Ini.PitchTrace = 0) then
    Exit;
  if (PlayerIndex < 0) or (PlayerIndex >= IMaxPlayerCount) then
    Exit;
  if (PlayerIndex > High(AudioInputProcessor.Sound)) then
    Exit;
  if (Track < 0) or (CurrentSong.Tracks = nil) or (Track > High(CurrentSong.Tracks)) then
    Exit;

  CurrentLine := CurrentSong.Tracks[Track].CurrentLine;
  if (CurrentLine < 0) or (CurrentLine > High(CurrentSong.Tracks[Track].Lines)) then
    Exit;

  // A line that carries no notes still holds the High(Integer) sentinel USong
  // uses while parsing. Adding to it overflows, and the octave fold below would
  // then run for hundreds of millions of iterations per sample and freeze the
  // render thread outright.
  if (CurrentSong.Tracks[Track].Lines[CurrentLine].HighNote < 0) then
    Exit;

  // The staff is positioned from the current line's base note. This is valid
  // from the moment the song loads, so the trace can be drawn before the first
  // lyric arrives.
  BaseNote := CurrentSong.Tracks[Track].Lines[CurrentLine].BaseNote;
  if (BaseNote < -128) or (BaseNote > 128) then
    Exit;

  // Fold against the note actually being sung, matching what the scoring code
  // in UNote does. Folding against the line's base note instead puts the trace
  // a whole octave from the player's own hit markers on lines spanning more
  // than an octave.
  Centre := BaseNote + 6;
  HasTarget := false;
  TargetTone := 0;
  for N := 0 to CurrentSong.Tracks[Track].Lines[CurrentLine].HighNote do
    with CurrentSong.Tracks[Track].Lines[CurrentLine].Notes[N] do
      if (NoteType <> ntFreestyle) then
      begin
        // The note being sung right now wins; otherwise remember the first one
        // still ahead so the guide line can be drawn before it arrives.
        if (StartBeat <= LyricsState.MidBeat) and
           (StartBeat + Duration > LyricsState.MidBeat) then
        begin
          Centre := Tone;
          TargetTone := Tone;
          HasTarget := true;
          Break;
        end
        else if (not HasTarget) and (StartBeat > LyricsState.MidBeat) then
        begin
          TargetTone := Tone;
          HasTarget := true;
        end;
      end;

  Sound := AudioInputProcessor.Sound[PlayerIndex];
  if (Sound = nil) then
    Exit;

  // ToneAbs rather than Tone: the scoring code rewrites Tone in place to line
  // it up with the note being sung, so the same pitch can be stored under
  // different values depending on whether a note was active.
  //
  // Only append while the song is actually being analysed. Draw keeps running
  // when paused or finished, and appending there would overwrite the whole
  // history with one repeated reading.
  if (not ScreenSing.Paused) then
  begin
    Slot := PitchTraceNext[PlayerIndex];
    PitchTraceBuffer[PlayerIndex][Slot].Tone  := Sound.ToneAbs;
    PitchTraceBuffer[PlayerIndex][Slot].Valid := Sound.ToneValid;
    PitchTraceNext[PlayerIndex] := (Slot + 1) mod PitchTraceLength;
    if (PitchTraceCount[PlayerIndex] < PitchTraceLength) then
      Inc(PitchTraceCount[PlayerIndex]);
  end;

  Count := PitchTraceCount[PlayerIndex];
  if (Count < 2) then
    Exit;

  if (Party.bPartyGame) then
    Col := GetPlayerColor(Ini.TeamColor[Min(PlayerIndex, High(Ini.TeamColor))])
  else
    Col := GetPlayerColor(Ini.PlayerColor[PlayerIndex]);
  DotCol := Col;

  // Samples are laid out by age rather than by beat: the newest sits at the
  // right-hand edge and older ones scroll away to the left. Anchoring to the
  // beat of a lyric line would blank the trace whenever no line is active,
  // which is exactly when it is most useful - finding the pitch before the
  // singing starts.
  // A horizontal guide at the pitch the song is about to ask for. Seeing the
  // line before the note arrives is what makes it possible to slide onto the
  // pitch early rather than discovering it once the syllable has started.
  if HasTarget then
  begin
    TargetY := Top - (TargetTone - BaseNote) * LineSpacing / 2;
    Renderer.DrawLine(Left, TargetY, Left + W, TargetY, 0, 1,
                      Col.R, Col.G, Col.B, 0.35);
  end;

  // Lay the samples out oldest-first so the trail can be joined up left to
  // right as one continuous line.
  Points := 0;
  for N := Count - 1 downto 0 do
  begin
    Index := (PitchTraceNext[PlayerIndex] - 1 - N + 2 * PitchTraceLength) mod PitchTraceLength;

    PtOk[Points] := PitchTraceBuffer[PlayerIndex][Index].Valid;
    PtX[Points] := Left + W * (1 - N / (PitchTraceLength - 1));

    if PtOk[Points] then
    begin
      Tone := PitchTraceBuffer[PlayerIndex][Index].Tone;
      Tone := Tone - 12 * Floor((Tone - Centre + 6) / 12);
      PtY[Points] := Top - (Tone - BaseNote) * LineSpacing / 2;
      PtTone[Points] := Tone;
    end;

    Inc(Points);
  end;

  // Average each point with its neighbours. The detector only produces a new
  // reading every few frames, so the raw trail is a staircase; smoothing turns
  // it into the curve the ear actually hears.
  for N := 0 to Points - 1 do
  begin
    if not PtOk[N] then
      Continue;
    Sum := 0;
    Window := 0;
    for Index := Max(0, N - 3) to Min(Points - 1, N + 3) do
      if PtOk[Index] then
      begin
        Sum := Sum + PtY[Index];
        Inc(Window);
      end;
    if (Window > 0) then
      Smoothed[N] := Sum / Window
    else
      Smoothed[N] := PtY[N];
  end;

  SetLength(Segments, Points);
  Used := 0;

  for N := 0 to Points - 2 do
  begin
    // A break in detection leaves a gap rather than a line drawn across
    // silence, which would imply a pitch that was never sung.
    if (not PtOk[N]) or (not PtOk[N + 1]) then
      Continue;

    DotCol := Col;
    if HasTarget and (N >= Points - 5) then
    begin
      Offset := Abs(PtTone[N] - TargetTone);
      if (Offset <= 0.5) then
      begin
        DotCol.R := 0.25; DotCol.G := 0.95; DotCol.B := 0.35;
      end
      else if (Offset <= 1.5) then
      begin
        DotCol.R := 0.98; DotCol.G := 0.75; DotCol.B := 0.20;
      end
      else
      begin
        DotCol.R := 0.95; DotCol.G := 0.30; DotCol.B := 0.30;
      end;
    end;

    // Fade into the past so the eye lands on the current pitch.
    Fade := 0.2 + 0.8 * (N / Points);

    Segments[Used].X1 := PtX[N];
    Segments[Used].Y1 := Smoothed[N];
    Segments[Used].X2 := PtX[N + 1];
    Segments[Used].Y2 := Smoothed[N + 1];
    Segments[Used].Z := 0;
    Segments[Used].Thickness := 2;
    Segments[Used].ColR := DotCol.R;
    Segments[Used].ColG := DotCol.G;
    Segments[Used].ColB := DotCol.B;
    Segments[Used].Alpha := Fade;
    Inc(Used);
  end;

  if (Used > 0) then
  begin
    SetLength(Segments, Used);
    Renderer.DrawLines(Segments);
  end;

  // A marker on the head of the line, so the current pitch is unmistakable.
  for N := Points - 1 downto 0 do
    if PtOk[N] then
    begin
      Renderer.DrawQuad(PtX[N] - 3, Smoothed[N] - 3, 0, 6, 6,
                        DotCol.R, DotCol.G, DotCol.B, 1);
      Break;
    end;
end;

procedure SingDrawPitchKey(Left, Top: real; PlayerIndex: integer);
var
  Sound: TCaptureBuffer;
  Note:  UTF8String;
  Col:   TRGB;
begin
  if (Ini.PitchKey = 0) then
    Exit;
  if (PlayerIndex < 0) or (PlayerIndex >= IMaxPlayerCount) then
    Exit;
  if (PlayerIndex > High(AudioInputProcessor.Sound)) then
    Exit;

  Sound := AudioInputProcessor.Sound[PlayerIndex];
  if (Sound = nil) then
    Exit;

  // ToneString already yields names like 'A4' or 'C#3', and '-' when the
  // analyser has no usable pitch. It does not depend on the song having a
  // note at this moment, so the readout stays live through the intro and
  // between phrases.
  Note := Sound.ToneString;

  // Append how far inside the semitone the pitch sits, so holding a note that
  // is technically 'A4' but consistently thirty cents flat is visible.
  if Sound.ToneValid then
  begin
    if (Sound.ToneCents > 0) then
      Note := Note + ' +' + IntToStr(Sound.ToneCents)
    else if (Sound.ToneCents < 0) then
      Note := Note + ' ' + IntToStr(Sound.ToneCents);
  end;

  if (Party.bPartyGame) then
    Col := GetPlayerColor(Ini.TeamColor[Min(PlayerIndex, High(Ini.TeamColor))])
  else
    Col := GetPlayerColor(Ini.PlayerColor[PlayerIndex]);

  SetFontStyle(ftOutline);
  SetFontSize(18);
  SetFontPos(Left, Top);
  SetFontZ(0);
  if Sound.ToneValid then
    SetFontColor(1, 0.85, 0.15, 1)
  else
    SetFontColor(0.45, 0.45, 0.45, 1);
  PrintText(Note);
  SetFontStyle(ftRegular);
  SetFontSize(10);
  SetFontZ(0);
  SetFontColor(1, 1, 1, 1);
end;

const
  // URecord keeps its own copy of this table in its implementation section,
  // so it cannot be reached from here.
  SongToneNames: array[0..11] of UTF8String = (
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  );

function SongToneToName(Tone: integer): UTF8String;
var
  Step, Octave: integer;
begin
  // UltraStar song tones are semitones with 0 = C4.
  Step := ((Tone mod 12) + 12) mod 12;
  Octave := 4 + Floor(Tone / 12);
  Result := SongToneNames[Step] + IntToStr(Octave);
end;

procedure SingDrawTargetKey(Left, Top: real; Track, PlayerIndex: integer);
var
  CurrentLine: integer;
  N: integer;
  Beat: real;
  TargetTone: integer;
  Active: boolean;
  Found: boolean;
  Caption: UTF8String;
  Sound: TCaptureBuffer;
  Delta: integer;
  ArrowX, ArrowY: real;
begin
  if (Ini.PitchKey = 0) then
    Exit;
  if (CurrentSong.Tracks = nil) or (Track > High(CurrentSong.Tracks)) then
    Exit;

  CurrentLine := CurrentSong.Tracks[Track].CurrentLine;
  if (CurrentLine > High(CurrentSong.Tracks[Track].Lines)) then
    Exit;

  Beat := LyricsState.MidBeat;
  Found := false;
  Active := false;
  TargetTone := 0;

  // Prefer the note being sung right now; otherwise look ahead to the next
  // one in this line so the target is known before the syllable arrives.
  for N := 0 to CurrentSong.Tracks[Track].Lines[CurrentLine].HighNote do
  begin
    with CurrentSong.Tracks[Track].Lines[CurrentLine].Notes[N] do
    begin
      if (NoteType = ntFreestyle) then
        Continue;

      if (StartBeat <= Beat) and (StartBeat + Duration > Beat) then
      begin
        TargetTone := Tone;
        Active := true;
        Found := true;
        Break;
      end;

      if (not Found) and (StartBeat > Beat) then
      begin
        TargetTone := Tone;
        Found := true;
      end;
    end;
  end;

  if not Found then
    Exit;

  if Active then
    Caption := 'target ' + SongToneToName(TargetTone)
  else
    Caption := 'next ' + SongToneToName(TargetTone);

  SetFontStyle(ftOutline);
  SetFontSize(18);
  SetFontPos(Left, Top);
  SetFontZ(0);
  // Solid while the note is being sung, dimmed while it is still ahead.
  if Active then
    SetFontColor(1, 1, 1, 1)
  else
    SetFontColor(0.7, 0.7, 0.7, 0.75);
  PrintText(Caption);

  // A triangle showing which way to move to reach the note. Drawn rather than
  // printed so it does not depend on the font carrying arrow glyphs.
  if (PlayerIndex >= 0) and (PlayerIndex < IMaxPlayerCount) and
     (PlayerIndex <= High(AudioInputProcessor.Sound)) then
  begin
    Sound := AudioInputProcessor.Sound[PlayerIndex];
    if (Sound <> nil) and Sound.ToneValid then
    begin
      // Compare within the octave: the singer is not expected to match the
      // song's register, only its pitch class, which is how scoring works too.
      Delta := ((TargetTone - Sound.ToneAbs) mod 12 + 18) mod 12 - 6;
      ArrowX := Left + TextWidth(Caption) + 6;
      ArrowY := Top + 9;
      if (Delta >= 1) then
        Renderer.DrawTriangle(ArrowX, ArrowY - 6, ArrowX + 5, ArrowY + 3,
                              ArrowX - 5, ArrowY + 3, 0, 0.45, 0.85, 1, 0.9)
      else if (Delta <= -1) then
        Renderer.DrawTriangle(ArrowX, ArrowY + 6, ArrowX + 5, ArrowY - 3,
                              ArrowX - 5, ArrowY - 3, 0, 0.45, 0.85, 1, 0.9);
    end;
  end;
  SetFontStyle(ftRegular);
  SetFontSize(10);
  SetFontZ(0);
  SetFontColor(1, 1, 1, 1);
end;

procedure SingDrawNoteLines(Left, Top, Right: real; LineSpacing: integer; LineThickness: single);
var
  Count: integer;
  Y: single;
begin
  for Count := 0 to 9 do
  begin
    Y := Top + Count * LineSpacing;
    Renderer.DrawLine(Left, Y, Right, Y, 0, LineThickness, Skin_P1_LinesR, Skin_P1_LinesG, Skin_P1_LinesB, 0.4);
  end;
end;

// draw blank Notebars
procedure SingDrawLine(Left, Top, Right: real; Track, PlayerIndex: integer; LineSpacing: integer);
var
  Rec:   TRecR;
  Count: integer;
  TempR: real;
  PlayerNumber: integer;
  Texture: TTexture;
  ColorR, ColorG, ColorB, A: single;
  GoldenStarPos: real;
begin
  if (ScreenSing.settings.NotesVisible[Track]) then
  begin
    // the textures start counting at 1, but everything else just starts at 0
    PlayerNumber := PlayerIndex + 1;

    if not CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].HasLength(TempR) then TempR := 0
    else TempR := (Right-Left) / TempR;

    with CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine] do
    begin
      for Count := 0 to HighNote do
      begin
        with Notes[Count] do
        begin
          if NoteType <> ntFreestyle then
          begin
            If (NoteType = ntRap) or (NoteType = ntRapGolden) then
              Texture := Tex_plain_Left_Rap[PlayerNumber]
            else
              Texture := Tex_plain_Left[PlayerNumber];
            if Ini.EffectSing = 0 then
              // If Golden note Effect of then Change not Color
            begin
              case NoteType of
                ntNormal:
                begin
                  ColorR := 1;
                  ColorG := 1;
                  ColorB := 1;
                  A := 1; // We set alpha to 1, cause we can control the transparency through the png itself
                end;
                ntGolden:
                begin
                  ColorR := 1;
                  ColorG := 1;
                  ColorB := 0.3;
                  A := 1; // no stars, paint yellow -> glColor4f(1, 1, 0.3, 0.85); - we could
                end;
                ntRap:
                begin
                  ColorR := 1;
                  ColorG := 1;
                  ColorB := 1;
                  A := 1;
                end;
                ntRapGolden:
                begin
                  ColorR := 1;
                  ColorG := 1;
                  ColorB := 0.3;
                  A := 1;
                end;
              end; // case
            end //Else all Notes same Color
            else
            begin
              ColorR := 1;
              ColorG := 1;
              ColorB := 1;
              A := 1;
            end;

            // left part
            Rec.Left  := (StartBeat - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + Left + 0.5;
            Rec.Right := Rec.Left + NotesW[PlayerIndex];
            Rec.Top := Top - (Tone-BaseNote)*LineSpacing/2 - NotesH[PlayerIndex];
            Rec.Bottom := Rec.Top + 2 * NotesH[PlayerIndex];
            with Texture do
            begin
              X := Rec.Left;
              Y := Rec.Top;
              W := Rec.Right - Rec.Left;
              H := Rec.Bottom - Rec.Top;
              ColR := ColorR;
              ColG := ColorG;
              ColB := ColorB;
              Alpha := A;
            end;
            Renderer.DrawTexture(Texture);

            //We keep the postion of the top left corner b4 it's overwritten
            GoldenStarPos := Rec.Left;
            //done

            // middle part
            Rec.Left := Rec.Right;
            Rec.Right := (StartBeat + Duration - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + Left - NotesW[PlayerIndex] - 0.5;

            // the left note is more right than the right note itself, sounds weird - so we fix that xD
            if Rec.Right <= Rec.Left then
              Rec.Right := Rec.Left;

            If (NoteType = ntRap) or (NoteType = ntRapGolden) then
              Texture := Tex_plain_Mid_Rap[PlayerNumber]
            else
              Texture := Tex_plain_Mid[PlayerNumber];

            with Texture do
            begin
              X := Rec.Left;
              Y := Rec.Top;
              W := Rec.Right - Rec.Left;
              H := Rec.Bottom - Rec.Top;
              ColR := ColorR;
              ColG := ColorG;
              ColB := ColorB;
              Alpha := A;
              TexX1 := 0;
              TexX2 := round((Rec.Right-Rec.Left)/32);
              TexY1 := 0;
              TexY2 := 1;
            end;
            Renderer.DrawTexture(Texture);

            // right part
            Rec.Left  := Rec.Right;
            Rec.Right := Rec.Right + NotesW[PlayerIndex];


            if (NoteType = ntRap) or (NoteType = ntRapGolden) then
              Texture := Tex_plain_Right_Rap[PlayerNumber]
            else
              Texture := Tex_plain_Right[PlayerNumber];
            with Texture do
            begin
              X := Rec.Left;
              Y := Rec.Top;
              W := Rec.Right - Rec.Left;
              H := Rec.Bottom - Rec.Top;
              ColR := ColorR;
              ColG := ColorG;
              ColB := ColorB;
              Alpha := A;
            end;
            Renderer.DrawTexture(Texture);

            // Golden Star Patch
            if ((NoteType = ntGolden) or (NoteType = ntRapGolden)) and (Ini.EffectSing=1) then
            begin
              GoldenRec.SaveGoldenStarsRec(GoldenStarPos, Rec.Top, Rec.Right, Rec.Bottom);
            end;
          end; // if not FreeStyle
        end; // with
      end; // for
    end; // with
  end;
end;

// draw sung notes
procedure SingDrawPlayerLine(Left, Top, W: real; Track, PlayerIndex: integer; LineSpacing: integer);
var
  TempR:      real;
  Rec:        TRecR;
  N: integer;
  Texture: TTexture;
//  R, G, B, A: real;
  NotesH2:    real;
begin
  if (ScreenSing.Settings.InputVisible) then
  begin
    //Log.LogStatus('Player notes', 'SingDraw');

    //if Player[NrGracza].LengthNote > 0 then
    begin
      if not CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].HasLength(TempR) then TempR := 0
      else TempR := W / TempR;

      for N := 0 to Player[PlayerIndex].HighNote do
      begin
        with Player[PlayerIndex].Note[N] do
        begin
          // Left part of note
          Rec.Left  := Left + (Start - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + 0.5;
          Rec.Right := Rec.Left + NotesW[PlayerIndex];

          // Draw it in half size, if not hit
          if Hit then
          begin
            NotesH2 := NotesH[PlayerIndex]
          end
          else
          begin
            NotesH2 := int(NotesH[PlayerIndex] * 0.65);
          end;

          Rec.Top    := Top - (Tone-CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].BaseNote)*LineSpacing/2 - NotesH2;
          Rec.Bottom := Rec.Top + 2 * NotesH2;

          // draw the left part
          If (NoteType = ntRap) or (NoteType = ntRapGolden) then
            Texture := Tex_Left_Rap[PlayerIndex+1]
          else
            Texture := Tex_Left[PlayerIndex+1];
          with Texture do
          begin
            X := Rec.Left;
            Y := Rec.Top;
            W := Rec.Right - Rec.Left;
            H := Rec.Bottom - Rec.Top;
            ColR := 1;
            ColG := 1;
            ColB := 1;
            Alpha := 1;
          end;
          Renderer.DrawTexture(Texture);

          // Middle part of the note
          Rec.Left  := Rec.Right;
          Rec.Right := Left + (Start + Duration - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR - NotesW[PlayerIndex] - 0.5;

          // new
          if (Start + Duration - 1 = LyricsState.CurrentBeatD) then
            Rec.Right := Rec.Right - (1-Frac(LyricsState.MidBeatD)) * TempR;

          // the left note is more right than the right note itself, sounds weird - so we fix that xD
          if Rec.Right <= Rec.Left then
            Rec.Right := Rec.Left;

          // draw the middle part
          If (NoteType = ntRap) or (NoteType = ntRapGolden) then
            Texture := Tex_Mid_Rap[PlayerIndex+1]
          else
            Texture := Tex_Mid[PlayerIndex+1];

          with Texture do
          begin
            X := Rec.Left;
            Y := Rec.Top;
            W := Rec.Right - Rec.Left;
            H := Rec.Bottom - Rec.Top;
            ColR := 1;
            ColG := 1;
            ColB := 1;
            Alpha := 1;
            TexX1 := 0;
            TexY1 := 0;
            TexX2 := round((Rec.Right-Rec.Left)/32);
            TexY2 := 1;
          end;
          Renderer.DrawTexture(Texture);

          // the right part of the note
          Rec.Left  := Rec.Right;
          Rec.Right := Rec.Right + NotesW[PlayerIndex];

          If (NoteType = ntRap) or (NoteType = ntRapGolden) then
            Texture := Tex_Right_Rap[PlayerIndex+1]
          else
            Texture := Tex_Right[PlayerIndex+1];
          with Texture do
          begin
            X := Rec.Left;
            Y := Rec.Top;
            W := Rec.Right - Rec.Left;
            H := Rec.Bottom - Rec.Top;
            ColR := 1;
            ColG := 1;
            ColB := 1;
            Alpha := 1;
          end;
          Renderer.DrawTexture(Texture);

          // Perfect note is stored
          if Perfect and (Ini.EffectSing=1) then
          begin
            //A := 1 - 2*(LyricsState.GetCurrentTime() - GetTimeFromBeat(Start + Duration));
            if not (Start + Duration - 1 = LyricsState.CurrentBeatD) then
            begin
              //Star animation counter
              //inc(Starfr);
              //Starfr := Starfr mod 128;
             // if not(CurrentSong.isDuet) or (PlayerIndex mod 2 = Track) then
                GoldenRec.SavePerfectNotePos(Rec.Left, Rec.Top);
            end;
          end;
        end; // with
      end; // for

      // actually we need a comparison here, to determine if the singing process
      // is ahead Rec.Right even if there is no singing

      if (Ini.EffectSing = 1) then
        GoldenRec.GoldenNoteTwinkle(Rec.Top,Rec.Bottom,Rec.Right, PlayerIndex);
    end; // if
  end; // if
end;

//draw Note glow
procedure SingDrawPlayerBGLine(Left, Top, Right: real; Track, PlayerIndex: integer; LineSpacing: integer);
var
  Rec:            TRecR;
  Count:          integer;
  TempR:          real;
  W, H:           real;
  A:          single;
  Texture:        TTexture;
begin
  if (ScreenSing.settings.NotesVisible[PlayerIndex]) then
  begin
    A := sqrt((1 + sin(AudioPlayback.Position * 3)))/2 + 0.05;

    if not CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].HasLength(TempR) then TempR := 0
    else TempR := (Right-Left) / TempR;

    with CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine] do
    begin
      for Count := 0 to HighNote do
      begin
        with Notes[Count] do
        begin
          if NoteType <> ntFreestyle then
          begin
            // begin: 14, 20
            // easy: 6, 11
            W := NotesW[PlayerIndex] * 2 + 2;
            H := NotesH[PlayerIndex] * 1.5 + 3.5;

            // left
            Rec.Right := (StartBeat - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + Left + 0.5 + 4;
            Rec.Left  := Rec.Right - W;
            Rec.Top := Top - (Tone-BaseNote)*LineSpacing/2 - H;
            Rec.Bottom := Rec.Top + 2 * H;

            If (NoteType = ntRap) or (NoteType = ntRapGolden) then
              Texture := Tex_BG_Left_Rap[PlayerIndex+1]
            else
              Texture := Tex_BG_Left[PlayerIndex+1];
            with Texture do
            begin
              X := Rec.Left;
              Y := Rec.Top;
              W := Rec.Right - Rec.Left;
              H := Rec.Bottom - Rec.Top;
              Alpha := A;
            end;
            Renderer.DrawTexture(Texture);

            // middle part
            Rec.Left  := Rec.Right;
            Rec.Right := (StartBeat + Duration - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + Left - 0.5 - 4;

            // the left note is more right than the right note itself, sounds weird - so we fix that xD
            if Rec.Right <= Rec.Left then
              Rec.Right := Rec.Left;

            If (NoteType = ntRap) or (NoteType = ntRapGolden) then
              Texture := Tex_BG_Mid_Rap[PlayerIndex+1]
            else
              Texture := Tex_BG_Mid[PlayerIndex+1];
            with Texture do
            begin
              X := Rec.Left;
              Y := Rec.Top;
              W := Rec.Right - Rec.Left;
              H := Rec.Bottom - Rec.Top;
              Alpha := A;
            end;
            Renderer.DrawTexture(Texture);

            // right part
            Rec.Left  := Rec.Right;
            Rec.Right := Rec.Left + W;

            If (NoteType = ntRap) or (NoteType = ntRapGolden) then
              Texture := Tex_BG_Right_Rap[PlayerIndex+1]
            else
              Texture := Tex_BG_Right[PlayerIndex+1];
            with Texture do
            begin
              X := Rec.Left;
              Y := Rec.Top;
              W := Rec.Right - Rec.Left;
              H := Rec.Bottom - Rec.Top;
              Alpha := A;
            end;
            Renderer.DrawTexture(Texture);

          end; // if not FreeStyle
        end; // with
      end; // for
    end; // with

  end;
end;

(**
 * Draws the lyrics helper bar.
 * Left: position the bar starts at
 * LyricsMid: the middle of the lyrics relative to the position Left 
 *)
procedure SingDrawLyricHelper(CP: integer; Left, LyricsMid: real);
var
  Bounds: TRecR;           // bounds of the lyric help bar
  BarProgress: real;       // progress of the lyrics helper
  BarMoveDelta: real;      // current beat relative to the beat the bar starts to move at
  BarAlpha: real;          // transparency
  CurLine:  PLine;         // current lyric line (beat specific)
  LineWidth: real;         // lyric line width
  FirstNoteBeat: integer;  // beat of the first note in the current line
  FirstNoteDelta: integer; // time in beats between the start of the current line and its first note
  MoveStartX: real;        // x-pos. the bar starts to move from
  MoveDist: real;          // number of pixels the bar will move
  LyricEngine: TLyricEngine;
  Col: TRGB;
const
  BarWidth  = 50; // width  of the lyric helper bar
  BarHeight = 30; // height of the lyric helper bar
  BarMoveLimit = 40; // max. number of beats remaining before the bar starts to move
begin
  // get current lyrics line and the time in beats of its first note
  CurLine := @CurrentSong.Tracks[CP].Lines[CurrentSong.Tracks[CP].CurrentLine];

  // FIXME: accessing ScreenSing is not that generic
  if (CurrentSong.isDuet) and (PlayersPlay <> 1) then
  begin
    if (CP = 1) then
      LyricEngine := ScreenSing.LyricsDuetP2
    else
      LyricEngine := ScreenSing.LyricsDuetP1;
  end
  else
    LyricEngine := ScreenSing.Lyrics;

  LyricEngine.FontFamily := Ini.LyricsFont;
  LyricEngine.FontStyle  := Ini.LyricsStyle;

  // do not draw the lyrics helper if the current line does not contain any note
  if (Length(CurLine.Notes) > 0) then
  begin
    // start beat of the first note of this line
    FirstNoteBeat := CurLine.Notes[0].StartBeat;
    // time in beats between the start of the current line and its first note
    FirstNoteDelta := FirstNoteBeat - CurLine.StartBeat;

    // beats from current beat to the first note of the line
    BarMoveDelta := FirstNoteBeat - LyricsState.MidBeat;

    if (FirstNoteDelta > 8) and  // if the wait-time is large enough
       (BarMoveDelta > 0) then   // and the first note of the line is not reached
    begin
      // let the bar blink to the beat
      BarAlpha := 0.75 + cos(BarMoveDelta/2) * 0.25;

      // if the number of beats to the first note is too big,
      // the bar stays on the left side.
      if (BarMoveDelta > BarMoveLimit) then
        BarMoveDelta := BarMoveLimit;

      // limit number of beats the bar moves
      if (FirstNoteDelta > BarMoveLimit) then
        FirstNoteDelta := BarMoveLimit;

      // calc bar progress
      BarProgress := 1 - BarMoveDelta / FirstNoteDelta;

      // retrieve the width of the upper lyrics line on the display
      if (LyricEngine.GetUpperLine() <> nil) then
        LineWidth := LyricEngine.GetUpperLine().Width
      else
        LineWidth := 0;

      // distance the bar will move (LyricRec.Left to beginning of text)
      MoveDist := LyricsMid - LineWidth / 2 - BarWidth;
      // if the line is too long the helper might move from right to left
      // so we have to assure the start position is left of the text.
      if (MoveDist >= 0) then
        MoveStartX := Left
      else
        MoveStartX := Left + MoveDist;

      // determine lyric help bar position and size
      Bounds.Left := MoveStartX + BarProgress * MoveDist;
      Bounds.Right := Bounds.Left + BarWidth;
      if (CurrentSong.isDuet) and (PlayersPlay <> 1) then
      begin
        if (CP = 0) then
          Bounds.Top := Theme.LyricBarDuetP1.IndicatorYOffset + Theme.LyricBarDuetP1.UpperY
        else
          Bounds.Top := Theme.LyricBarDuetP2.IndicatorYOffset + Theme.LyricBarDuetP2.UpperY ;
      end
      else
        Bounds.Top := Theme.LyricBar.IndicatorYOffset + Theme.LyricBar.UpperY ;

      Bounds.Bottom := Bounds.Top + BarHeight + 3;

      // draw lyric help bar
      if (CurrentSong.isDuet) then
      begin
        if (PlayersPlay = 1) or (PlayersPlay = 2) then
          Col := GetLyricBarColor(Ini.SingColor[CP])
        else
        begin
          if (PlayersPlay = 3) or (PlayersPlay = 6) then
          begin
            //if (PlayersPlay = 3) then
              Col := GetLyricBarColor(Ini.SingColor[CP]);

            //if (PlayersPlay = 6) then
            //  Col := GetLyricBarColor(CP + 1);
          end
          else
          begin
            if ScreenAct = 1 then
              Col := GetLyricBarColor(Ini.SingColor[CP])
            else
              Col := GetLyricBarColor(Ini.SingColor[CP + 2]);
          end;
        end;
      end
      else
        Col := GetLyricBarColor(1);

      with Tex_Lyric_Help_Bar do
      begin
        X := Bounds.Left;
        Y := Bounds.Top;
        W := Bounds.Right - Bounds.Left;
        H := Bounds.Bottom - Bounds.Top;
        ColR := Col.R;
        ColG := Col.G;
        ColB := Col.B;
        Alpha := BarAlpha;
      end;
      Renderer.DrawTexture(Tex_Lyric_Help_Bar);
    end;
  end;
end;

(**
 * Draws the lyrics helper bar jukebox.
 * Left: position the bar starts at
 * LyricsMid: the middle of the lyrics relative to the position Left
 *)
procedure SingDrawLyricHelperJukebox(Left, LyricsMid: real);
var
  Bounds: TRecR;           // bounds of the lyric help bar
  BarProgress: real;       // progress of the lyrics helper
  BarMoveDelta: real;      // current beat relative to the beat the bar starts to move at
  BarAlpha: real;          // transparency
  CurLine:  PLine;         // current lyric line (beat specific)
  LineWidth: real;         // lyric line width
  FirstNoteBeat: integer;  // beat of the first note in the current line
  FirstNoteDelta: integer; // time in beats between the start of the current line and its first note
  MoveStartX: real;        // x-pos. the bar starts to move from
  MoveDist: real;          // number of pixels the bar will move
  LyricEngine: TLyricEngine;
const
  BarWidth  = 50; // width  of the lyric helper bar
  BarHeight = 30; // height of the lyric helper bar
  BarMoveLimit = 40; // max. number of beats remaining before the bar starts to move
begin

  // get current lyrics line and the time in beats of its first note
  CurLine := @CurrentSong.Tracks[0].Lines[CurrentSong.Tracks[0].CurrentLine];

  // FIXME: accessing ScreenSing is not that generic
  LyricEngine := ScreenJukebox.Lyrics;

  // do not draw the lyrics helper if the current line does not contain any note
  if (Length(CurLine.Notes) > 0) then
  begin
    // start beat of the first note of this line
    FirstNoteBeat := CurLine.Notes[0].StartBeat;
    // time in beats between the start of the current line and its first note
    FirstNoteDelta := FirstNoteBeat - CurLine.StartBeat;

    // beats from current beat to the first note of the line
    BarMoveDelta := FirstNoteBeat - LyricsState.MidBeat;

    if (FirstNoteDelta > 8) and  // if the wait-time is large enough
       (BarMoveDelta > 0) then   // and the first note of the line is not reached
    begin
      // let the bar blink to the beat
      BarAlpha := 0.75 + cos(BarMoveDelta/2) * 0.25;

      // if the number of beats to the first note is too big,
      // the bar stays on the left side.
      if (BarMoveDelta > BarMoveLimit) then
        BarMoveDelta := BarMoveLimit;

      // limit number of beats the bar moves
      if (FirstNoteDelta > BarMoveLimit) then
        FirstNoteDelta := BarMoveLimit;

      // calc bar progress
      BarProgress := 1 - BarMoveDelta / FirstNoteDelta;

      // retrieve the width of the upper lyrics line on the display
      if (LyricEngine.GetUpperLine() <> nil) then
        LineWidth := LyricEngine.GetUpperLine().Width
      else
        LineWidth := 0;

      // distance the bar will move (LyricRec.Left to beginning of text)
      MoveDist := LyricsMid - LineWidth/2 - BarWidth;

      if (LineWidth/2 + (BarWidth - Left) * 2 >= 400) then
        Bounds.Left := - BarProgress * MoveDist + Left - BarWidth
      else
      begin
        // if the line is too long the helper might move from right to left
        // so we have to assure the start position is left of the text.
        if (MoveDist >= 0) then
          MoveStartX := Left
        else
          MoveStartX := Left + MoveDist;

        // determine lyric help bar position and size
        Bounds.Left := MoveStartX + BarProgress * MoveDist;
      end;

      Bounds.Right := Bounds.Left + BarWidth;
      Bounds.Top := Theme.LyricBarJukebox.IndicatorYOffset + ScreenJukeBox.Lyrics.UpperLineY;
      Bounds.Bottom := Bounds.Top + BarHeight + 3;

      // draw lyric help bar
      with Tex_Lyric_Help_Bar do
      begin
        X := Bounds.Left;
        Y := Bounds.Top;
        W := Bounds.Right - Bounds.Left;
        H := Bounds.Bottom - Bounds.Top;
        ColR := ScreenJukebox.LyricHelper.R;
        ColG := ScreenJukebox.LyricHelper.G;
        ColB := ScreenJukebox.LyricHelper.B;
        Alpha := BarAlpha;
      end;
      Renderer.DrawTexture(Tex_Lyric_Help_Bar);
    end;
  end;
end;

procedure SingDrawLines;
var
  NR: TRecR;         // lyrics area bounds (NR = NoteRec?)
begin
  // positions
  NR.Left := 20;
  NR.Right := 780;
  NR.Width := 760; //NR.Right - NR.Left;
  NR.WMid  := 380;//NR.Width / 2;
  NR.Mid   := 400;//NR.Left + NR.WMid;

  // draw note-lines

  // to-do : needs fix when party mode works w/ 2 screens
  if (PlayersPlay = 1) and (Ini.NoteLines = 1) and (ScreenSing.settings.NotesVisible[0]) then
    SingDrawNoteLines(NR.Left, Skin_P2_NotesB - 105, NR.Right, 15);

  if (PlayersPlay = 2) and (Ini.NoteLines = 1) then
  begin
    if (ScreenSing.settings.NotesVisible[0]) then
      SingDrawNoteLines(Nr.Left, Skin_P1_NotesB - 105, Nr.Right, 15);
    if (ScreenSing.settings.NotesVisible[1]) then
      SingDrawNoteLines(Nr.Left, Skin_P2_NotesB - 105, Nr.Right, 15);
  end;

  if (PlayersPlay = 3) and (Ini.NoteLines = 1) then begin
    if (ScreenSing.settings.NotesVisible[0]) then
      SingDrawNoteLines(Nr.Left, 120, Nr.Right, 12);
    if (ScreenSing.settings.NotesVisible[1]) then
      SingDrawNoteLines(Nr.Left, 245, Nr.Right, 12);
    if (ScreenSing.settings.NotesVisible[2]) then
      SingDrawNoteLines(Nr.Left, 370, Nr.Right, 12);
  end;

  if (PlayersPlay = 4) and (Ini.NoteLines = 1) then
  begin
    if (ScreenSing.settings.NotesVisible[0]) then
    begin
      if (Screens = 2) then
        SingDrawNoteLines(Nr.Left, Skin_P1_NotesB - 105, Nr.Right, 15)
      else
      begin
        SingDrawNoteLines(Nr.Left, Skin_P1_NotesB - 105, Nr.Right/2 - 5, 15);
        SingDrawNoteLines(Nr.Right/2 - 20 + Nr.Left, Skin_P1_NotesB - 105, Nr.Right, 15)
      end;
    end;

    if (ScreenSing.settings.NotesVisible[1]) then
    begin
      if (Screens = 2) then
        SingDrawNoteLines(Nr.Left, Skin_P2_NotesB - 105, Nr.Right, 15)
      else
      begin
        SingDrawNoteLines(Nr.Left, Skin_P2_NotesB - 105, Nr.Right/2 - 5, 15);
        SingDrawNoteLines(Nr.Right/2 - 20 + Nr.Left, Skin_P2_NotesB - 105, Nr.Right, 15)
      end;
    end;
  end;

  if (PlayersPlay = 6) and (Ini.NoteLines = 1) then begin
    if (ScreenSing.settings.NotesVisible[0]) then
    begin
      if (Screens = 2) then
        SingDrawNoteLines(Nr.Left, 120, Nr.Right, 12)
      else
      begin
        SingDrawNoteLines(Nr.Left, 120, Nr.Right/2 - 5, 12);
        SingDrawNoteLines(Nr.Right/2 - 20 + Nr.Left, 120, Nr.Right, 12);
      end;
    end;

    if (ScreenSing.settings.NotesVisible[1]) then
    begin
      if (Screens = 2) then
        SingDrawNoteLines(Nr.Left, 245, Nr.Right, 12)
      else
      begin
        SingDrawNoteLines(Nr.Left, 245, Nr.Right/2 - 5, 12);
        SingDrawNoteLines(Nr.Right/2 - 20 + Nr.Left, 245, Nr.Right, 12);
      end;
    end;

    if (ScreenSing.settings.NotesVisible[2]) then
    begin
      if (Screens = 2) then
        SingDrawNoteLines(Nr.Left, 370, Nr.Right, 12)
      else
      begin
        SingDrawNoteLines(Nr.Left, 370, Nr.Right/2 - 5, 12);
        SingDrawNoteLines(Nr.Right/2 - 20 + Nr.Left, 370, Nr.Right, 12);
      end;
    end;
  end;
end;

procedure SingDraw;
var
  NR: TRecR;         // lyrics area bounds (NR = NoteRec?)
  LyricEngine: TLyricEngine;
  LyricEngineDuetP1: TLyricEngine;
  LyricEngineDuetP2: TLyricEngine;
  I: integer;
  Difficulty: integer;
  TrackP1, TrackP2, TrackP3, TrackP4, TrackP5, TrackP6: integer;
  PlayerTracks: array[0..5] of integer;
const
  LineSpacingOneRow = 15;
  LineSpacingTwoRows = 15;
  LineSpacingThreeRows = 12;
  // TODO: it looks like all these TopXRowsY constants are actually referring to the bottom. But all the functions they call have historically called it Top.
  TopOneRow1 = Skin_P2_NotesB;
  TopTwoRows1 = Skin_P1_NotesB;
  TopTwoRows2 = Skin_P2_NotesB;
  TopThreeRows1 = 120+95;
  TopThreeRows2 = 245+95;
  TopThreeRows3 = 370+95;
begin
  // positions
  NR.Left := 20;
  NR.Right := 780;
  NR.Width := 760; //NR.Right - NR.Left;
  NR.WMid  := 380; //NR.Width / 2;
  NR.Mid   := 400; //NR.Left + NR.WMid;

  TrackP1 := 0;
  TrackP2 := 0;
  TrackP3 := 0;
  TrackP4 := 0;
  TrackP5 := 0;
  TrackP6 := 0;
  // FIXME: accessing ScreenSing is not that generic
  if (CurrentSong.isDuet) and (PlayersPlay <> 1) then
  begin
    LyricEngineDuetP1 := ScreenSing.LyricsDuetP1;
    LyricEngineDuetP2 := ScreenSing.LyricsDuetP2;
    TrackP2 := 1;
    TrackP4 := 1;
    TrackP6 := 1;
  end
  else
    LyricEngine := ScreenSing.Lyrics;

  // draw lyrics
  if (ScreenSing.Settings.LyricsVisible) then
  begin
    if (CurrentSong.isDuet) and (PlayersPlay <> 1) then
    begin
      LyricEngineDuetP1.Draw(LyricsState.MidBeat);
      SingDrawLyricHelper(0, NR.Left, NR.WMid);

      LyricEngineDuetP2.Draw(LyricsState.MidBeat);
      SingDrawLyricHelper(1, NR.Left, NR.WMid);
    end
    else
    begin
      LyricEngine.Draw(LyricsState.MidBeat);
      SingDrawLyricHelper(0, NR.Left, NR.WMid);
    end;
  end;

  // oscilloscope
  if (ScreenSing.Settings.OscilloscopeVisible) then
  begin
    SingDrawOscilloscopes;
  end;

  for I := 1 to PlayersPlay do
  begin

    if (ScreenSong.Mode = smNormal) or (ScreenSong.Mode = smMedley) then
      Difficulty := Player[I - 1].Level
    else
      Difficulty := Ini.Difficulty;

    case Difficulty of
      0:
        begin
          NotesH[I - 1] := 11; // 9
          NotesW[I - 1] := 6; // 5
        end;
      1:
        begin
          NotesH[I - 1] := 8; // 7
          NotesW[I - 1] := 4; // 4
        end;
      2:
        begin
          NotesH[I - 1] := 5;
          NotesW[I - 1] := 3;
        end;
    end;

    if PlayersPlay = 3 then
    begin
      NotesW[I - 1] := NotesW[I - 1] * 0.8;
      NotesH[I - 1] := NotesH[I - 1] * 0.8;
    end;

    if PlayersPlay = 4 then
    begin
      if (Screens = 1) then
      begin
        NotesW[I - 1] := NotesW[I - 1] * 0.9;
      end;
    end;

    if PlayersPlay = 6 then
    begin
      NotesW[I - 1] := NotesW[I - 1] * 0.8;
      NotesH[I - 1] := NotesH[I - 1] * 0.8;
    end;

  end;

  // draw notes lines
  if (ScreenSing.Settings.InputVisible) then
    SingDrawLines;

  // Live note readout. Deliberately outside the per-layout blocks below,
  // which only run where the song has notes - this must keep updating during
  // the intro, instrumental sections and the gaps between phrases.
  // Each player reads their own track: in a duet the even-numbered players
  // sing track 1, and passing 0 for everyone would show them all player one's
  // target note.
  PlayerTracks[0] := TrackP1;
  PlayerTracks[1] := TrackP2;
  PlayerTracks[2] := TrackP3;
  PlayerTracks[3] := TrackP4;
  PlayerTracks[4] := TrackP5;
  PlayerTracks[5] := TrackP6;

  for I := 0 to PlayersPlay - 1 do
    if (I <= High(PlayerTracks)) then
    begin
      SingDrawPitchKey(20, 25 + I * 26, I);
      SingDrawTargetKey(100, 25 + I * 26, PlayerTracks[I], I);
    end;
  // Draw the Notes
  if (PlayersPlay = 1) then
  begin
    // SINGLESCREEN
    SingDrawPlayerBGLine(NR.Left + 20, TopOneRow1, NR.Right - 20, TrackP1, 0, LineSpacingOneRow);  // Background glow    - colorized in playercolor
    SingDrawLine(NR.Left + 20, TopOneRow1, NR.Right - 20, TrackP1, 0, LineSpacingOneRow);             // Plain unsung notes - colorized in playercolor
    SingDrawPlayerLine(NR.Left + 20, TopOneRow1, NR.Width - 40, TrackP1, 0, LineSpacingOneRow);       // imho the sung notes
    SingDrawPitchTrace(NR.Left + 20, TopOneRow1, NR.Width - 40, TrackP1, 0, LineSpacingOneRow);
  end;

  if (PlayersPlay = 2) then
  begin
    // SINGLESCREEN
    SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP1, 0, LineSpacingTwoRows);
    SingDrawLine(NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP1, 0, LineSpacingTwoRows);
    SingDrawPlayerLine(NR.Left + 20, TopTwoRows1, NR.Width - 40, TrackP1, 0, LineSpacingTwoRows);
    SingDrawPitchTrace(NR.Left + 20, TopTwoRows1, NR.Width - 40, TrackP1, 0, LineSpacingTwoRows);

    SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP2, 1, LineSpacingTwoRows);
    SingDrawLine(NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP2, 1, LineSpacingTwoRows);
    SingDrawPlayerLine(NR.Left + 20, TopTwoRows2, NR.Width - 40, TrackP2, 1, LineSpacingTwoRows);
    SingDrawPitchTrace(NR.Left + 20, TopTwoRows2, NR.Width - 40, TrackP2, 1, LineSpacingTwoRows);
  end;

  if (PlayersPlay = 3) then
  begin
    // SINGLESCREEN
    SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP1, 0, LineSpacingThreeRows);
    SingDrawLine(NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP1, 0, LineSpacingThreeRows);
    SingDrawPlayerLine(NR.Left + 20, TopThreeRows1, NR.Width - 40, TrackP1, 0, LineSpacingThreeRows);
    SingDrawPitchTrace(NR.Left + 20, TopThreeRows1, NR.Width - 40, TrackP1, 0, LineSpacingThreeRows);

    SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP2, 1, LineSpacingThreeRows);
    SingDrawLine(NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP2, 1, LineSpacingThreeRows);
    SingDrawPlayerLine(NR.Left + 20, TopThreeRows2, NR.Width - 40, TrackP2, 1, LineSpacingThreeRows);
    SingDrawPitchTrace(NR.Left + 20, TopThreeRows2, NR.Width - 40, TrackP2, 1, LineSpacingThreeRows);

    SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP3, 2, LineSpacingThreeRows);
    SingDrawLine(NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP3, 2, LineSpacingThreeRows);
    SingDrawPlayerLine(NR.Left + 20, TopThreeRows3, NR.Width - 40, TrackP3, 2, LineSpacingThreeRows);
    SingDrawPitchTrace(NR.Left + 20, TopThreeRows3, NR.Width - 40, TrackP3, 2, LineSpacingThreeRows);
  end;

  if (PlayersPlay = 4) then
  begin
    if (Screens = 2) then
    begin
      // MULTISCREEN
      if (ScreenAct = 1) then
      begin
        // MULTISCREEN - SCREEN 1
        SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP1, 0, LineSpacingTwoRows);
        SingDrawLine(NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP1, 0, LineSpacingTwoRows);
        SingDrawPlayerLine(NR.Left + 20, TopTwoRows1, NR.Width - 40, TrackP1, 0, LineSpacingTwoRows);
        SingDrawPitchTrace(NR.Left + 20, TopTwoRows1, NR.Width - 40, TrackP1, 0, LineSpacingTwoRows);

        SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP2, 1, LineSpacingTwoRows);
        SingDrawLine(NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP2, 1, LineSpacingTwoRows);
        SingDrawPlayerLine(NR.Left + 20, TopTwoRows2, NR.Width - 40, TrackP2, 1, LineSpacingTwoRows);
        SingDrawPitchTrace(NR.Left + 20, TopTwoRows2, NR.Width - 40, TrackP2, 1, LineSpacingTwoRows);
      end;
      if (ScreenAct = 2) then
      begin
        // MULTISCREEN - SCREEN 2
        SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP3, 2, LineSpacingTwoRows);
        SingDrawLine(NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP3, 2, LineSpacingTwoRows);
        SingDrawPlayerLine(NR.Left + 20, TopTwoRows1, NR.Width - 40, TrackP3, 2, LineSpacingTwoRows);
        SingDrawPitchTrace(NR.Left + 20, TopTwoRows1, NR.Width - 40, TrackP3, 2, LineSpacingTwoRows);

        SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP4, 3, LineSpacingTwoRows);
        SingDrawLine(NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP4, 3, LineSpacingTwoRows);
        SingDrawPlayerLine(NR.Left + 20, TopTwoRows2, NR.Width - 40, TrackP4, 3, LineSpacingTwoRows);
        SingDrawPitchTrace(NR.Left + 20, TopTwoRows2, NR.Width - 40, TrackP4, 3, LineSpacingTwoRows);
      end;
    end
    else
    begin
      // SINGLESCREEN
      SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows1, NR.Right/2 - 20, TrackP1, 0, LineSpacingTwoRows);
      SingDrawLine(NR.Left + 20, TopTwoRows1, NR.Right/2 - 20, TrackP1, 0, LineSpacingTwoRows);
      SingDrawPlayerLine(NR.Left + 20, TopTwoRows1, NR.Width/2 - 50, TrackP1, 0, LineSpacingTwoRows);
      SingDrawPitchTrace(NR.Left + 20, TopTwoRows1, NR.Width/2 - 50, TrackP1, 0, LineSpacingTwoRows);

      SingDrawPlayerBGLine(NR.Left + 20, TopTwoRows2, NR.Right/2 - 20, TrackP2, 1, LineSpacingTwoRows);
      SingDrawLine(NR.Left + 20, TopTwoRows2, NR.Right/2 - 20, TrackP2, 1, LineSpacingTwoRows);
      SingDrawPlayerLine(NR.Left + 20, TopTwoRows2, NR.Width/2 - 50, TrackP2, 1, LineSpacingTwoRows);
      SingDrawPitchTrace(NR.Left + 20, TopTwoRows2, NR.Width/2 - 50, TrackP2, 1, LineSpacingTwoRows);

      SingDrawPlayerBGLine(NR.Right/2 - 20 + NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP3, 2, LineSpacingTwoRows);
      SingDrawLine(NR.Right/2 - 20 + NR.Left + 20, TopTwoRows1, NR.Right - 20, TrackP3, 2, LineSpacingTwoRows);
      SingDrawPlayerLine(NR.Width/2 - 10 + NR.Left + 20, TopTwoRows1, NR.Width/2 - 30, TrackP3, 2, LineSpacingTwoRows);
      SingDrawPitchTrace(NR.Width/2 - 10 + NR.Left + 20, TopTwoRows1, NR.Width/2 - 30, TrackP3, 2, LineSpacingTwoRows);

      SingDrawPlayerBGLine(NR.Right/2 - 20 + NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP4, 3, LineSpacingTwoRows);
      SingDrawLine(NR.Right/2 - 20 + NR.Left + 20, TopTwoRows2, NR.Right - 20, TrackP4, 3, LineSpacingTwoRows);
      SingDrawPlayerLine(NR.Width/2 - 10 + NR.Left + 20, TopTwoRows2, NR.Width/2 - 30, TrackP4, 3, LineSpacingTwoRows);
      SingDrawPitchTrace(NR.Width/2 - 10 + NR.Left + 20, TopTwoRows2, NR.Width/2 - 30, TrackP4, 3, LineSpacingTwoRows);
    end;
  end;

  if (PlayersPlay = 6) then
  begin
    if (Screens = 2) then
    begin
      // MULTISCREEN
      if (ScreenAct = 1) then
      begin
        // MULTISCREEN - SCREEN 1
        SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP1, 0, LineSpacingThreeRows);
        SingDrawLine(NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP1, 0, LineSpacingThreeRows);
        SingDrawPlayerLine(NR.Left + 20, TopThreeRows1, NR.Width - 40, TrackP1, 0, LineSpacingThreeRows);
        SingDrawPitchTrace(NR.Left + 20, TopThreeRows1, NR.Width - 40, TrackP1, 0, LineSpacingThreeRows);

        SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP2, 1, LineSpacingThreeRows);
        SingDrawLine(NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP2, 1, LineSpacingThreeRows);
        SingDrawPlayerLine(NR.Left + 20, TopThreeRows2, NR.Width - 40, TrackP2, 1, LineSpacingThreeRows);
        SingDrawPitchTrace(NR.Left + 20, TopThreeRows2, NR.Width - 40, TrackP2, 1, LineSpacingThreeRows);

        SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP3, 2, LineSpacingThreeRows);
        SingDrawLine(NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP3, 2, LineSpacingThreeRows);
        SingDrawPlayerLine(NR.Left + 20, TopThreeRows3, NR.Width - 40, TrackP3, 2, LineSpacingThreeRows);
        SingDrawPitchTrace(NR.Left + 20, TopThreeRows3, NR.Width - 40, TrackP3, 2, LineSpacingThreeRows);
      end;
      if (ScreenAct = 2) then
      begin
        // MULTISCREEN - SCREEN 2
        SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP4, 3, LineSpacingThreeRows);
        SingDrawLine(NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP4, 3, LineSpacingThreeRows);
        SingDrawPlayerLine(NR.Left + 20, TopThreeRows1, NR.Width - 40, TrackP4, 3, LineSpacingThreeRows);
        SingDrawPitchTrace(NR.Left + 20, TopThreeRows1, NR.Width - 40, TrackP4, 3, LineSpacingThreeRows);

        SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP5, 4, LineSpacingThreeRows);
        SingDrawLine(NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP5, 4, LineSpacingThreeRows);
        SingDrawPlayerLine(NR.Left + 20, TopThreeRows2, NR.Width - 40, TrackP5, 4, LineSpacingThreeRows);
        SingDrawPitchTrace(NR.Left + 20, TopThreeRows2, NR.Width - 40, TrackP5, 4, LineSpacingThreeRows);

        SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP6, 5, LineSpacingThreeRows);
        SingDrawLine(NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP6, 5, LineSpacingThreeRows);
        SingDrawPlayerLine(NR.Left + 20, TopThreeRows3, NR.Width - 40, TrackP6, 5, LineSpacingThreeRows);
        SingDrawPitchTrace(NR.Left + 20, TopThreeRows3, NR.Width - 40, TrackP6, 5, LineSpacingThreeRows);
      end;
    end
    else
    begin
      // SINGLESCREEN
      SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows1, NR.Right/2 - 20, TrackP1, 0, LineSpacingThreeRows);
      SingDrawLine(NR.Left + 20, TopThreeRows1, NR.Right/2 - 20, TrackP1, 0, LineSpacingThreeRows);
      SingDrawPlayerLine(NR.Left + 20, TopThreeRows1, NR.Width/2 - 50, TrackP1, 0, LineSpacingThreeRows);
      SingDrawPitchTrace(NR.Left + 20, TopThreeRows1, NR.Width/2 - 50, TrackP1, 0, LineSpacingThreeRows);

      SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows2, NR.Right/2 - 20, TrackP2, 1, LineSpacingThreeRows);
      SingDrawLine(NR.Left + 20, TopThreeRows2, NR.Right/2 - 20, TrackP2, 1, LineSpacingThreeRows);
      SingDrawPlayerLine(NR.Left + 20, TopThreeRows2, NR.Width/2 - 50, TrackP2, 1, LineSpacingThreeRows);
      SingDrawPitchTrace(NR.Left + 20, TopThreeRows2, NR.Width/2 - 50, TrackP2, 1, LineSpacingThreeRows);

      SingDrawPlayerBGLine(NR.Left + 20, TopThreeRows3, NR.Right/2 - 20, TrackP3, 2, LineSpacingThreeRows);
      SingDrawLine(NR.Left + 20, TopThreeRows3, NR.Right/2 - 20, TrackP3, 2, LineSpacingThreeRows);
      SingDrawPlayerLine(NR.Left + 20, TopThreeRows3, NR.Width/2 - 50, TrackP3, 2, LineSpacingThreeRows);
      SingDrawPitchTrace(NR.Left + 20, TopThreeRows3, NR.Width/2 - 50, TrackP3, 2, LineSpacingThreeRows);

      SingDrawPlayerBGLine(NR.Right/2 - 20 + NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP4, 3, LineSpacingThreeRows);
      SingDrawLine(NR.Right/2 - 20 + NR.Left + 20, TopThreeRows1, NR.Right - 20, TrackP4, 3, LineSpacingThreeRows);
      SingDrawPlayerLine(NR.Width/2 - 10 + NR.Left + 20, TopThreeRows1, NR.Width/2 - 30, TrackP4, 3, LineSpacingThreeRows);
      SingDrawPitchTrace(NR.Width/2 - 10 + NR.Left + 20, TopThreeRows1, NR.Width/2 - 30, TrackP4, 3, LineSpacingThreeRows);

      SingDrawPlayerBGLine(NR.Right/2 - 20 + NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP5, 4, LineSpacingThreeRows);
      SingDrawLine(NR.Right/2 - 20 + NR.Left + 20, TopThreeRows2, NR.Right - 20, TrackP5, 4, LineSpacingThreeRows);
      SingDrawPlayerLine(NR.Width/2 - 10 + NR.Left + 20, TopThreeRows2, NR.Width/2 - 30, TrackP5, 4, LineSpacingThreeRows);
      SingDrawPitchTrace(NR.Width/2 - 10 + NR.Left + 20, TopThreeRows2, NR.Width/2 - 30, TrackP5, 4, LineSpacingThreeRows);

      SingDrawPlayerBGLine(NR.Right/2 - 20 + NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP6, 5, LineSpacingThreeRows);
      SingDrawLine(NR.Right/2 - 20 + NR.Left + 20, TopThreeRows3, NR.Right - 20, TrackP6, 5, LineSpacingThreeRows);
      SingDrawPlayerLine(NR.Width/2 - 10 + NR.Left + 20, TopThreeRows3, NR.Width/2 - 30, TrackP6, 5, LineSpacingThreeRows);
      SingDrawPitchTrace(NR.Width/2 - 10 + NR.Left + 20, TopThreeRows3, NR.Width/2 - 30, TrackP6, 5, LineSpacingThreeRows);
    end;
  end;
end;

procedure SingDrawJukebox;
var
  NR: TRecR;         // lyrics area bounds (NR = NoteRec?)
  LyricEngine: TLyricEngine;
begin
  // positions
  NR.Left := 20;
  NR.Right := 780;
  NR.Width := 760; //NR.Right - NR.Left;
  NR.WMid  := 380; //NR.Width / 2;
  NR.Mid   := 400; //NR.Left + NR.WMid;

  // FIXME: accessing ScreenJukebox is not that generic
  LyricEngine := ScreenJukebox.Lyrics;

  // draw Lyrics
  if (ScreenJukebox.ShowLyrics) then
  begin
    if (ScreenJukebox.LyricsStart) or ((not(ScreenJukebox.LyricsStart) and (LyricsState.GetCurrentTime() * 1000 >= LyricsState.StartTime - 3000))) then
    begin
        LyricEngine.Draw(LyricsState.MidBeat);
        SingDrawLyricHelperJukebox(NR.Left, NR.WMid);
        ScreenJukebox.LyricsStart := true;
    end;
  end;
end;

// Draw Note Bars for Editor
// There are 11 reasons for a new procedure:   (nice binary :D )
// 1. It does not look good when you draw the golden note star effect in the editor
// 2. You can see the freestyle notes in the editor semitransparent
// 3. It is easier and faster then changing the old procedure
procedure EditDrawLine(X, YBaseNote, W, H: real; Track: integer; NumLines: integer);
var
  Rec:   TRecR;
  Count: integer;
  TempR: real;
  GoldenStarPos: real;
  Space: real;
  Texture: TTexture;
  ColorR, ColorG, ColorB, A: single;
begin
  Space := H / (NumLines - 1);

  if not CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].HasLength(TempR) then TempR := 0
  else TempR := W / TempR;

  with CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine] do
  begin
    for Count := 0 to HighNote do
    begin
      with Notes[Count] do
      begin

        // Golden Note Patch
        case NoteType of
          ntFreestyle:
          begin
            ColorR := 1;
            ColorG := 1;
            ColorB := 1;
            A := 0.35;
          end;
          ntNormal:
          begin
            ColorR := 1;
            ColorG := 1;
            ColorB := 1;
            A := 0.85;
          end;
          ntGolden:
          begin
            ColorR := 1;
            ColorG := 1;
            ColorB := 0.3;
            A := 0.85;
          end;
          ntRap:
          begin
            if (Color = P1_INVERTED) then
            begin
              ColorR := 1;
              ColorG := 1;
              ColorB := 1;
              A := 0.75;
            end
            else
            begin
              ColorR := 1;
              ColorG := 1;
              ColorB := 1;
              A := 0.5;
            end;
          end;
          ntRapGolden:
          begin
            if (Color = P1_INVERTED) then
            begin
              ColorR := 1;
              ColorG := 1;
              ColorB := 0.3;
              A := 0.75;
            end
            else
            begin
              ColorR := 1;
              ColorG := 1;
              ColorB := 0.3;
              A := 0.5;
            end;
          end;
        end; // case

        // left part
        Rec.Left  := (StartBeat - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + X + 0.5;
        Rec.Right := Rec.Left + NotesW[0];
        Rec.Top := YBaseNote - (Tone-BaseNote)*Space/2 - NotesH[0];
        Rec.Bottom := Rec.Top + 2 * NotesH[0];
        If (NoteType = ntRap) or (NoteType = ntRapGolden) then
        begin
          If Color = P1_INVERTED then
            Texture := Tex_Left_Rap_Inv
          else
            Texture := Tex_Left_Rap[Color];
        end
        else
        begin
          If Color = P1_INVERTED then
            Texture := Tex_Left_Inv
          else
            Texture := Tex_Left[Color];
        end;
        with Texture do
        begin
          X := Rec.Left;
          Y := Rec.Top;
          W := Rec.Right - Rec.Left;
          H := Rec.Bottom - Rec.Top;
          ColR := ColorR;
          ColG := ColorG;
          ColB := ColorB;
          Alpha := A;
          TexX1 := 0;
          TexX2 := 1;
          TexY1 := 0;
          TexY2 := 1;
        end;
        Renderer.DrawTexture(Texture);
        GoldenStarPos := Rec.Left;

        // middle part
        Rec.Left  := Rec.Right;
        Rec.Right := (StartBeat + Duration - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat) * TempR + X - NotesW[0] - 0.5;

        If (NoteType = ntRap) or (NoteType = ntRapGolden) then
        begin
          If Color = P1_INVERTED then
            Texture := Tex_Mid_Rap_Inv
          else
            Texture := Tex_Mid_Rap[Color];
        end
        else
        begin
          If Color = P1_INVERTED then
            Texture := Tex_Mid_Inv
          else
            Texture := Tex_Mid[Color];
        end;
        with Texture do
        begin
          X := Rec.Left;
          Y := Rec.Top;
          W := Rec.Right - Rec.Left;
          H := Rec.Bottom - Rec.Top;
          ColR := ColorR;
          ColG := ColorG;
          ColB := ColorB;
          Alpha := A;
          TexX1 := 0;
          TexX2 := 1;
          TexY1 := 0;
          TexY2 := 1;
        end;
        Renderer.DrawTexture(Texture);

        // right part
        Rec.Left  := Rec.Right;
        Rec.Right := Rec.Right + NotesW[0];

        If (NoteType = ntRap) or (NoteType = ntRapGolden) then
        begin
          If Color = P1_INVERTED then
            Texture := Tex_Right_Rap_Inv
          else
            Texture := Tex_Right_Rap[Color]
        end
        else
        begin
          If Color = P1_INVERTED then
            Texture := Tex_Right_Inv
          else
            Texture := Tex_Right[Color]
        end;
        with Texture do
        begin
          X := Rec.Left;
          Y := Rec.Top;
          W := Rec.Right - Rec.Left;
          H := Rec.Bottom - Rec.Top;
          ColR := ColorR;
          ColG := ColorG;
          ColB := ColorB;
          Alpha := A;
          TexX1 := 0;
          TexX2 := 1;
          TexY1 := 0;
          TexY2 := 1;
        end;
        Renderer.DrawTexture(Texture);

        if ((NoteType = ntGolden) or (NoteType = ntRapGolden)) and (Ini.EffectSing = 1) then
        begin
          GoldenRec.SaveGoldenStarsRec(GoldenStarPos, Rec.Top, Rec.Right, Rec.Bottom);
        end;
        
      end; // with
    end; // for
  end; // with
end;

procedure EditDrawBorderedBox(X, Y, W, H: integer; FillR, FillG, FillB, FillAlpha: real);
begin
  Renderer.Blend := false;
  Renderer.DrawQuad(X, Y, 0, W, H, FillR, FillG, FillB, FillAlpha);
  Renderer.DrawBoundedBox(X-1, Y-1, X+W+1, Y+H+1, 0, 2, 0, 0, 0, 1);
  Renderer.Blend := true;
end;

procedure EditDrawBeatDelimiters(X, Y, W, H: real; Track: integer);
var
  Count, I: integer;
  TempR: real;
  LineList: TLineList;
begin
  if ((CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].EndBeat < CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat)) then
    Exit;

  if not CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].HasLength(TempR) then TempR := 0
  else TempR := W / TempR;

  if (CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].ScoreValue > 0) and ( W > 0 ) and ((CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].EndBeat > CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat)) then
      TempR := W / (CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].EndBeat - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat)
    else
      TempR := 0;
  SetLength(LineList, CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].EndBeat - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat + 1);
  I := 0;
  for Count := CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat to CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].EndBeat do
  begin
    with LineList[I] do
    begin
      X1 := X + TempR * (Count - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat);
      Y1 := Y;
      X2 := X + TempR * (Count - CurrentSong.Tracks[Track].Lines[CurrentSong.Tracks[Track].CurrentLine].Notes[0].StartBeat);
      Y2 := Y + H;
      Z := 0;
      Thickness := 2;
      ColR := 0;
      ColG := 0;
      ColB := 0;
    end;
    if (Count mod USong.DEFAULT_RESOLUTION) = CurrentSong.Tracks[Track].NotesGAP then
      LineList[I].Alpha := 1
    else
      LineList[I].Alpha := 0.3;
    I := I + 1;
  end;
  Renderer.DrawLines(LineList);
end;

procedure SingDrawJukeboxTimeBar();
var
  x, y:           real;
  width, height:  real;
  LyricsProgress: real;
  CurLyricsTime:  real;
begin

  if (ScreenJukebox.SongListVisible) then
  begin
    x := Theme.Jukebox.StaticTimeProgress.x;
    y := Theme.Jukebox.StaticTimeProgress.y;

    width  := Theme.Jukebox.StaticTimeProgress.w;
    height := Theme.Jukebox.StaticTimeProgress.h;
  end;

  if (ScreenJukebox.SongMenuVisible) then
  begin
    x := Theme.Jukebox.StaticSongMenuTimeProgress.x;
    y := Theme.Jukebox.StaticSongMenuTimeProgress.y;

    width  := Theme.Jukebox.StaticSongMenuTimeProgress.w;
    height := Theme.Jukebox.StaticSongMenuTimeProgress.h;
  end;

  CurLyricsTime := LyricsState.GetCurrentTime();
  if (CurLyricsTime > 0) and
      (LyricsState.TotalTime > 0) then
  begin
    LyricsProgress := CurLyricsTime / LyricsState.TotalTime;
    // avoid that the bar "overflows" for inaccurate song lengths
    if (LyricsProgress > 1.0) then
      LyricsProgress := 1.0;
    Tex_JukeboxTimeProgress.X := x;
    Tex_JukeboxTimeProgress.Y := y;
    Tex_JukeboxTimeProgress.W := width * LyricsProgress;
    Tex_JukeboxTimeProgress.H := height;
    Tex_JukeboxTimeProgress.ColR := Theme.Jukebox.StaticSongMenuTimeProgress.ColR;
    Tex_JukeboxTimeProgress.ColG := Theme.Jukebox.StaticSongMenuTimeProgress.ColG;
    Tex_JukeboxTimeProgress.ColB := Theme.Jukebox.StaticSongMenuTimeProgress.ColB;
    Tex_JukeboxTimeProgress.Alpha := 1;
    Tex_JukeboxTimeProgress.TexX1 := 0;
    Tex_JukeboxTimeProgress.TexY1 := 0;
    Tex_JukeboxTimeProgress.TexX2 := (width * LyricsProgress) / 8;
    Tex_JukeboxTimeProgress.TexY2 := 1;
    Renderer.DrawTexture(Tex_JukeboxTimeProgress);
  end;
end;

end.
