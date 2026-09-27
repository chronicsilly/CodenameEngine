package funkin.backend.system.modules;

import flixel.FlxState;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.ScriptPack;
import funkin.menus.MainMenuState;
import haxe.CallStack;
import haxe.CallStack.StackItem;
import haxe.Timer;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.UncaughtErrorEvent;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import openfl.geom.ColorTransform;
import openfl.ui.Keyboard;

/**
 * Keeps the game window open when something throws, and draws an in-game screen
 * instead of the native crash dialog.
 *
 * `Main.new` calls `init()` before the Flixel loop starts.
 * Enter, Space, Escape, or a click runs `recoverToMainMenu()`.
 */
final class CrashHandler {
	/** While true, `FunkinGame` does not update the state that just crashed. */
	public static var blocking:Bool = false;

	static var overlay:CrashOverlay;
	static var recovered:Bool = false;
	static var installed:Bool = false;

	public static function init() {
		if (installed || Lib.current == null || Lib.current.loaderInfo == null) return;
		installed = true;
		// Do not removeEventListener first. OpenFL's map is still null until a listener is added, and that removal throws.
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	public static function onUncaughtError(e:UncaughtErrorEvent) {
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();
		if (blocking) return;
		present(describe(e.error), CallStack.exceptionStack());
	}

	#if (cpp || hl)
	static function onError(message:Dynamic):Void {
		// hxcpp shows a native dialog and calls exit(1) if this handler returns.
		// A normal throw skips that and comes back through onUncaughtError.
		if (!blocking)
			present(Std.string(message), CallStack.exceptionStack());
		throw Std.string(message);
	}
	#end

	/**
	 * Turns scripts on the active state off, then opens `MainMenuState`.
	 * The broken state is not updated again, so a script cannot keep throwing.
	 */
	public static function recoverToMainMenu():Void {
		if (recovered) return;
		recovered = true;

		try {
			MusicBeatState.skipTransIn = true;
			MusicBeatState.skipTransOut = true;
		} catch (_:Dynamic) {}

		try {
			if (FlxG.keys != null) FlxG.keys.reset();
		} catch (_:Dynamic) {}

		var queued = false;
		try {
			if (FlxG.game != null) {
				FlxG.switchState(new MainMenuState());
				queued = true;
			}
		} catch (err:Dynamic) {
			trace('Could not return to the main menu: $err');
		}

		if (!queued) {
			recovered = false;
			return;
		}

		blocking = false;
		if (overlay != null) overlay.dismiss();
	}

	public static function clearOverlay(screen:CrashOverlay) {
		if (overlay == screen) overlay = null;
	}

	static function present(message:String, stack:Array<StackItem>) {
		if (blocking) return;
		blocking = true;
		recovered = false;

		var report = formatReport(message, stack);
		trace(report);
		quarantine();

		try {
			showOverlay(report);
		} catch (err:Dynamic) {
			trace('Crash overlay failed: $err');
			blocking = false;
			recoverToMainMenu();
		}
	}

	static function showOverlay(report:String) {
		if (overlay != null) {
			overlay.dispose();
			overlay = null;
		}
		var root = Lib.current;
		if (root == null) throw "Game window is not ready";
		overlay = new CrashOverlay(report);
		root.addChild(overlay);
	}

	static function quarantine() {
		try {
			if (Script.curScript != null) Script.curScript.active = false;
			silenceTree(FlxG.state);
			if (FlxG.sound != null && FlxG.sound.music != null)
				FlxG.sound.music.pause();
		} catch (err:Dynamic) {
			trace('Crash quarantine failed: $err');
		}
	}

	static function silenceTree(state:FlxState) {
		var current = state;
		while (current != null) {
			if (current is MusicBeatState)
				silence((cast current:MusicBeatState).stateScripts);
			else if (current is MusicBeatSubstate)
				silence((cast current:MusicBeatSubstate).stateScripts);

			if (current is PlayState)
				silencePlayState(cast current);

			current = current.subState;
		}
	}

	static function silencePlayState(play:PlayState) {
		silence(play.scripts);
		if (play.strumLines != null) {
			for (line in play.strumLines.members) {
				if (line == null) continue;
				try if (line.vocals != null) line.vocals.pause() catch (_:Dynamic) {}
				if (line.characters == null) continue;
				for (character in line.characters)
					if (character != null) silence(character.scripts);
			}
		}
		try if (play.inst != null) play.inst.pause() catch (_:Dynamic) {}
		try if (play.vocals != null) play.vocals.pause() catch (_:Dynamic) {}
	}

	static function silence(pack:ScriptPack) {
		if (pack == null) return;
		pack.active = false;
		for (script in pack.scripts)
			if (script != null) script.active = false;
	}

	static function describe(error:Dynamic):String {
		if (error == null) return "Unknown error";
		if (Std.isOfType(error, Error))
			return (cast error:Error).message;
		if (Std.isOfType(error, ErrorEvent))
			return (cast error:ErrorEvent).text;
		return Std.string(error);
	}

	static function formatReport(message:String, stack:Array<StackItem>):String {
		if (message == null || message.length == 0) message = "Unknown error";
		message = message.split("\r\n").join("\n").split("\r").join("\n");

		var lines = [];
		if (stack != null) for (item in stack) lines.push(formatItem(item));
		var traceText = lines.length == 0 ? "(no stack trace was captured)" : lines.join("\n");
		var report = 'ERROR\n$message\n\nSTACK\n$traceText';
		if (report.length > 8000) report = report.substr(0, 8000) + "\n...";
		return report;
	}

	static function formatItem(item:StackItem):String {
		return switch (item) {
			case CFunction:
				"Native function";
			case Module(name):
				'Module $name';
			case FilePos(parent, file, line, col):
				var at = col != null && col > 0 ? '$file:$line:$col' : '$file:$line';
				var who = if (parent == null) "" else switch (parent) {
					case Method(cls, fn): '${shortClass(cls)}.$fn()';
					case LocalFunction(v): 'local function $v';
					default: "";
				}
				who == "" ? at : '$who\n$at';
			case LocalFunction(v):
				'Local function $v';
			case Method(cls, fn):
				'${shortClass(cls)}.$fn()';
		}
	}

	static function shortClass(cls:Null<String>):String {
		if (cls == null || cls.length == 0) return "";
		var dot = cls.lastIndexOf(".");
		return dot < 0 ? cls : cls.substr(dot + 1);
	}
}

/**
 * Full-screen crash screen. It animates on its own enter-frame listener so it
 * keeps moving after Flixel updates are paused.
 */
class CrashOverlay extends Sprite {
	static inline var INTRO_TIME:Float = 0.5;

	var pixels:BitmapData;
	var ownsPixels:Bool = false;
	var background:Bitmap;
	var ghostRed:Bitmap;
	var ghostCyan:Bitmap;
	var flash:Shape;
	var scan:Shape;
	var slices:Shape;
	var info:Bitmap;
	var fullText:String;
	var fieldWidth:Float = -1;
	var fittedHeight:Float = -1;
	var flashW:Float = -1;
	var flashH:Float = -1;
	var elapsed:Float = 0;
	var intro:Float = 0;
	var lastStamp:Float;
	var dismissing:Bool = false;
	var disposed:Bool = false;
	var keyStage:Stage;
	public function new(report:String) {
		super();
		fullText = report;
		mouseEnabled = true;
		mouseChildren = false;
		lastStamp = Timer.stamp();
		build();
		addEventListener(Event.ADDED_TO_STAGE, onAdded);
		addEventListener(Event.ENTER_FRAME, onFrame);
		addEventListener(MouseEvent.CLICK, onClick);
	}

	function loadBackground():BitmapData {
		var path = "assets/images/game/codenameerrorbg.png";
		try {
			var resolved = Paths.image("game/codenameerrorbg");
			if (resolved != null) path = resolved;
		} catch (_:Dynamic) {}
		try {
			if (Assets.exists(path)) return Assets.getBitmapData(path);
		} catch (_:Dynamic) {}
		ownsPixels = true;
		return new BitmapData(16, 16, false, 0xFF14001E);
	}

	function build() {
		pixels = loadBackground();

		background = new Bitmap(pixels, null, true);
		ghostCyan = new Bitmap(pixels, null, true);
		ghostRed = new Bitmap(pixels, null, true);
		ghostCyan.blendMode = BlendMode.ADD;
		ghostRed.blendMode = BlendMode.ADD;
		ghostCyan.transform.colorTransform = new ColorTransform(0.35, 0.85, 1, 1, 0, 40, 80);
		ghostRed.transform.colorTransform = new ColorTransform(1, 0.2, 0.45, 1, 60, 0, 20);

		flash = new Shape();
		scan = new Shape();
		slices = new Shape();
		info = new Bitmap(new BitmapData(1, 1, true, 0), null, false);
		info.smoothing = false;

		addChild(background);
		addChild(ghostCyan);
		addChild(ghostRed);
		addChild(flash);
		addChild(scan);
		addChild(slices);
		addChild(info);
	}

	function onAdded(_) {
		removeEventListener(Event.ADDED_TO_STAGE, onAdded);
		keyStage = stage;
		if (keyStage != null) {
			keyStage.addEventListener(Event.RESIZE, onResize);
			keyStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, true, 1000);
		}
		place();
	}

	function onResize(_) place();

	function onKey(e:KeyboardEvent) {
		if (dismissing || elapsed < 0.45) return;
		switch (e.keyCode) {
			case Keyboard.ENTER, Keyboard.SPACE, Keyboard.ESCAPE:
				e.stopImmediatePropagation();
				CrashHandler.recoverToMainMenu();
		}
	}

	function onClick(_) {
		if (dismissing || elapsed < 0.45) return;
		CrashHandler.recoverToMainMenu();
	}

	public function dismiss() {
		dismissing = true;
	}

	function onFrame(_) {
		var now = Timer.stamp();
		var dt = now - lastStamp;
		lastStamp = now;
		if (dt < 0 || dt > 0.05) dt = 1 / 60;
		elapsed += dt;

		if (dismissing) {
			alpha -= dt / 0.28;
			if (alpha <= 0) dispose();
			return;
		}

		if (intro < 1) intro = Math.min(1, intro + dt / INTRO_TIME);
		place();
	}

	function bake(textW:Float, maxH:Float):BitmapData {
		var message = fullText + "\n\nPRESS ENTER TO RETURN TO THE MENU";
		var size = 22;
		var result:BitmapData = null;
		try {
			while (true) {
				var label = new FlxText(0, 0, Std.int(textW), message, size);
				label.alignment = FlxTextAlign.CENTER;
				label.setFormat(Paths.font("pixel.otf"), size, 0xFFFFFFFF, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
				label.borderSize = 2;
				label.antialiasing = false;
				var textHeight = label.height;
				var tooTall = textHeight > maxH && size > 14;
				if (!tooTall && label.graphic != null && label.graphic.bitmap != null)
					result = label.graphic.bitmap.clone();
				label.destroy();
				if (!tooTall || size <= 14) break;
				size -= 2;
			}
		} catch (err:Dynamic) {
			trace('Could not draw crash text: $err');
		}
		if (result == null)
			result = new BitmapData(Std.int(textW), 40, true, 0x00000000);
		return result;
	}

	function place() {
		var w = stage != null ? stage.stageWidth : Lib.current != null && Lib.current.stage != null ? Lib.current.stage.stageWidth : 1280;
		var h = stage != null ? stage.stageHeight : Lib.current != null && Lib.current.stage != null ? Lib.current.stage.stageHeight : 720;
		if (w < 2) w = 1280;
		if (h < 2) h = 720;

		var ease = 1 - Math.pow(1 - intro, 3);
		var breathe = 1 + Math.sin(elapsed * 1.5) * 0.006;
		var glitching = (elapsed % 2.8) > 2.55;
		var zoom = (1 + (1 - ease) * 0.07) * breathe;
		var bw = pixels.width <= 0 ? 1 : pixels.width;
		var bh = pixels.height <= 0 ? 1 : pixels.height;
		var scaleX = (w / bw) * zoom;
		var scaleY = (h / bh) * zoom;
		var glitchX = glitching ? (Math.random() * 16 - 8) : 0;

		background.scaleX = ghostRed.scaleX = ghostCyan.scaleX = scaleX;
		background.scaleY = ghostRed.scaleY = ghostCyan.scaleY = scaleY;
		background.x = (w - bw * scaleX) / 2 + glitchX;
		background.y = (h - bh * scaleY) / 2;
		var fringe = Math.sin(elapsed * 3) * 7 + (glitching ? 6 : 0);
		ghostRed.x = background.x + fringe;
		ghostRed.y = background.y;
		ghostCyan.x = background.x - fringe;
		ghostCyan.y = background.y;
		ghostRed.alpha = (glitching ? 0.55 : 0.22) * ease;
		ghostCyan.alpha = (glitching ? 0.45 : 0.18) * ease;

		if (flashW != w || flashH != h) {
			flash.graphics.clear();
			flash.graphics.beginFill(0xFFFF1744);
			flash.graphics.drawRect(0, 0, w, h);
			flash.graphics.endFill();
			flashW = w;
			flashH = h;
		}
		flash.alpha = (1 - ease) * 0.7;

		scan.graphics.clear();
		scan.graphics.beginFill(0xFFFFFF, 0.16);
		scan.graphics.drawRect(0, (elapsed * 220) % h, w, 8);
		scan.graphics.endFill();

		slices.graphics.clear();
		if (glitching) {
			slices.graphics.beginFill(0xFFFF2A6A, 0.28);
			for (i in 0...4)
				slices.graphics.drawRect(Math.random() * 30 - 15, Math.random() * h, w, 4 + Math.random() * 16);
			slices.graphics.endFill();
		}

		var textW = Math.min(w * 0.78, 1000);
		if (textW < 200) textW = w * 0.9;
		var maxH = h * 0.72;
		if (fieldWidth != textW || fittedHeight != h) {
			fieldWidth = textW;
			fittedHeight = h;
			var previous = info.bitmapData;
			info.bitmapData = bake(textW, maxH);
			if (previous != null) previous.dispose();
		}

		var hover = Math.sin(elapsed * 1.5) * 5;
		info.alpha = ease;
		info.x = (w - info.width) / 2;
		info.y = (h - info.height) / 2 + hover;
	}

	public function dispose() {
		if (disposed) return;
		disposed = true;
		removeEventListener(Event.ENTER_FRAME, onFrame);
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(Event.ADDED_TO_STAGE, onAdded);
		if (keyStage != null) {
			keyStage.removeEventListener(Event.RESIZE, onResize);
			keyStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey, true);
			keyStage = null;
		}
		if (parent != null) parent.removeChild(this);
		if (ownsPixels && pixels != null) pixels.dispose();
		CrashHandler.clearOverlay(this);
	}
}
